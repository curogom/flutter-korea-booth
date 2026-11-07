import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../data/run_repository.dart';
import '../data/run_sync_failure.dart';
import '../model/quiz_run.dart';

class RunLedger extends ChangeNotifier implements QuizRunRecorder {
  RunLedger(this.database, {this.remote});
  final Database database;
  final RunRemoteRepository? remote;
  final _runs = stringMapStoreFactory.store('runs');
  final _pending = stringMapStoreFactory.store('outbox');
  final _failures = stringMapStoreFactory.store('sync_failures');
  static final _owners = Expando<RunLedger>();
  Future<void>? _initializing;
  bool _initialized = false;
  bool _disposed = false;
  Future<void>? _activeFlush;
  Object? syncError;
  int pendingCount = 0;
  Map<String, String> rejectedCodes = const {};
  int get rejectedCount => rejectedCodes.length;
  bool get isSyncing => _activeFlush != null;
  Timer? _retry;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() {
    if (_disposed) return Future.error(StateError('Ledger is disposed'));
    if (_initializing != null) return _initializing!;
    final owner = _owners[database];
    if (owner != null && owner != this && !owner._disposed) {
      return Future.error(
        StateError('This database already has an active ledger'),
      );
    }
    _owners[database] = this;
    return _initializing = _initialize().catchError((
      Object error,
      StackTrace stack,
    ) {
      if (_owners[database] == this) _owners[database] = null;
      _initializing = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _initialize() async {
    // The browser session lock is acquired before opening this database.
    // A second owner in this process is also rejected before recovery.
    // A process restart starts a fresh player. Preserve the interrupted run for auditing.
    await database.transaction((txn) async {
      for (final row in await _runs.find(txn)) {
        final data = Map<String, dynamic>.from(row.value);
        if (data['status'] == 'started') {
          data['status'] = 'interrupted';
          data['finishedAt'] = DateTime.now().toUtc().toIso8601String();
          data['version'] = (data['version'] as int) + 1;
          await _runs.record(row.key).put(txn, data);
          await _pending.record(row.key).put(txn, data);
        }
      }
    });
    _initialized = true;
    await _refresh();
    _retry = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(flush()),
    );
    unawaited(flush());
  }

  Future<void> _refresh() async {
    pendingCount = await _pending.count(database);
    final failures = await _failures.find(database);
    rejectedCodes = Map.unmodifiable({
      for (final row in failures) row.key: row.value['code'] as String,
    });
    if (rejectedCount > 0 && syncError == null) {
      syncError = const RunSyncFailure(
        RunSyncFailureKind.record,
        'records-need-review',
      );
    }
    _changed();
  }

  @override
  Future<void> saveRun(QuizRun run) async {
    if (!_initialized || _disposed || _owners[database] != this) {
      throw StateError('An initialized active ledger is required');
    }
    await database.transaction((txn) async {
      final record = _runs.record(run.id), previous = await record.get(txn);
      if (previous != null && (previous['version'] as int) >= run.version) {
        return;
      }
      final data = run.toJson();
      await record.put(txn, data);
      await _pending.record(run.id).put(txn, data);
      await _failures.record(run.id).delete(txn);
    });
    await _refresh();
    unawaited(flush());
  }

  Stream<List<QuizRun>> watchLocal() => _runs
      .query(finder: Finder(sortOrders: [SortOrder('startedAt', false)]))
      .onSnapshots(database)
      .map(
        (rows) => rows
            .map(
              (row) => QuizRun.fromJson(Map<String, dynamic>.from(row.value)),
            )
            .toList(),
      );
  Future<void> flush({bool retryRejected = false}) {
    if (_disposed || remote == null) return Future.value();
    final active = _activeFlush;
    if (active != null) {
      return retryRejected
          ? active.then((_) => flush(retryRejected: true))
          : active;
    }
    _activeFlush = _drain(retryRejected: retryRejected).whenComplete(() {
      _activeFlush = null;
      _changed();
    });
    _changed();
    return _activeFlush!;
  }

  Future<void> _drain({required bool retryRejected}) async {
    final attempted = <String, int>{};
    syncError = null;
    try {
      while (!_disposed) {
        final rows = await _pending.find(database);
        if (rows.isEmpty) break;
        var attemptedAny = false;
        for (final row in rows) {
          if (_disposed) break;
          final version = row.value['version'] is int
              ? row.value['version'] as int
              : -1;
          if (attempted[row.key] == version) continue;
          final failure = await _failures.record(row.key).get(database);
          if (!retryRejected && failure?['version'] == version) continue;
          attempted[row.key] = version;
          attemptedAny = true;
          try {
            final run = QuizRun.fromJson(Map<String, dynamic>.from(row.value));
            await remote!.saveRun(run);
            await database.transaction((txn) async {
              final latest = await _pending.record(row.key).get(txn);
              if (latest?['version'] == version) {
                await _pending.record(row.key).delete(txn);
                await _failures.record(row.key).delete(txn);
              }
            });
          } catch (error) {
            syncError = error;
            if (error is TimeoutException ||
                (error is RunSyncFailure &&
                    error.kind != RunSyncFailureKind.record)) {
              // Connectivity/authentication failures affect the entire queue.
              return;
            }
            // Preserve the record and skip this version on automatic retries.
            // Unknown per-record errors are isolated as well, never discarded.
            await database.transaction((txn) async {
              final latest = await _pending.record(row.key).get(txn);
              final latestVersion = latest?['version'] is int
                  ? latest!['version'] as int
                  : -1;
              if (latest != null && latestVersion == version) {
                await _failures.record(row.key).put(txn, {
                  'version': version,
                  'code': error is RunSyncFailure
                      ? error.code
                      : 'invalid-record',
                  'failedAt': DateTime.now().toUtc().toIso8601String(),
                });
              }
            });
          }
        }
        if (!attemptedAny) break;
      }
      if (await _failures.count(database) == 0) syncError = null;
    } catch (error) {
      syncError = error;
    } finally {
      if (!_disposed) {
        await _refresh();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    if (_owners[database] == this) _owners[database] = null;
    super.dispose();
  }
}
