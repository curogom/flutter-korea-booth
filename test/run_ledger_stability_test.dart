import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:flutter_korea_booth/data/run_repository.dart';
import 'package:flutter_korea_booth/data/run_sync_failure.dart';
import 'package:flutter_korea_booth/model/quiz_run.dart';
import 'package:flutter_korea_booth/storage/run_ledger.dart';

import 'run_ledger_test.dart' show recordedRun;

QuizRun record(String id, {String status = 'completed', int version = 6}) =>
    QuizRun.fromJson({
      ...recordedRun(status: status, version: version).toJson(),
      'id': id,
    });

class StableRemote implements RunRemoteRepository {
  final records = <String, QuizRun>{};
  final attempts = <String>[];
  Object? globalFailure;
  bool rejectBad = false;
  Completer<void>? firstRequest;
  final firstStarted = Completer<void>();
  @override
  Future<void> saveRun(QuizRun next) async {
    attempts.add(next.id);
    if (!firstStarted.isCompleted) firstStarted.complete();
    if (firstRequest != null && attempts.length == 1) {
      await firstRequest!.future;
    }
    if (globalFailure != null) throw globalFailure!;
    if (rejectBad && next.id == 'a-bad') {
      throw StateError('a specific record was rejected');
    }
    final old = records[next.id];
    if (old != null && old.version >= next.version) return;
    if (old != null && old.status != 'started') {
      throw const RunSyncFailure(
        RunSyncFailureKind.record,
        'terminal-record-conflict',
      );
    }
    records[next.id] = next;
  }

  @override
  Stream<List<QuizRun>> watchRecent(String environment) =>
      Stream.value(records.values.toList());
}

void main() {
  test(
    'a second owner is refused before it can interrupt an active run',
    () async {
      final db = await databaseFactoryMemory.openDatabase('stability-owners');
      final remote = StableRemote();
      final first = RunLedger(db, remote: remote);
      final second = RunLedger(db, remote: remote);
      await first.initialize();
      await first.saveRun(record('active', status: 'started', version: 1));
      await first.flush();
      await expectLater(second.initialize(), throwsStateError);
      expect(remote.records['active']!.status, 'started');
      expect((await first.watchLocal().first).single.status, 'started');
      await first.saveRun(record('active'));
      await first.flush();
      expect(remote.records['active']!.status, 'completed');
      expect(first.pendingCount, 0);
      second.dispose();
      first.dispose();
      await db.close();
    },
  );
  test('reinitialization of the same owner is idempotent and a released owner can recover', () async {
    final db = await databaseFactoryMemory.openDatabase(
      'stability-reinitialize',
    );
    final first = RunLedger(db);
    await first.initialize();
    await first.saveRun(record('active', status: 'started', version: 1));
    await first.initialize();
    expect((await first.watchLocal().first).single.status, 'started');
    first.dispose();
    final next = RunLedger(db);
    await next.initialize();
    expect((await next.watchLocal().first).single.status, 'interrupted');
    await expectLater(first.saveRun(record('active')), throwsStateError);
    next.dispose();
    await db.close();
  });
  test(
    'one rejected record is preserved while healthy records synchronize',
    () async {
      final db = await databaseFactoryMemory.openDatabase('stability-poisoned');
      final remote = StableRemote()..rejectBad = true;
      final ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(record('a-bad'));
      await ledger.saveRun(record('z-healthy'));
      await ledger.flush();
      expect(remote.records['z-healthy']!.status, 'completed');
      expect(ledger.pendingCount, 1);
      expect(ledger.rejectedCount, 1);
      expect((await ledger.watchLocal().first).length, 2);
      final attempts = remote.attempts.length;
      await ledger.flush();
      await ledger.flush();
      expect(remote.attempts.length, attempts);
      remote.rejectBad = false;
      await ledger.flush(retryRejected: true);
      expect(ledger.pendingCount, 0);
      expect(ledger.rejectedCount, 0);
      expect(ledger.syncError, isNull);
      ledger.dispose();
      await db.close();
    },
  );
  test(
    'rejected metadata survives restart without deleting the original',
    () async {
      const name = 'stability-rejected-restart';
      var db = await databaseFactoryMemory.openDatabase(name);
      final remote = StableRemote()..rejectBad = true;
      var ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(record('a-bad'));
      await ledger.flush();
      final attempts = remote.attempts.length;
      ledger.dispose();
      await db.close();
      db = await databaseFactoryMemory.openDatabase(name);
      ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.flush();
      expect(ledger.rejectedCount, 1);
      expect(remote.attempts.length, attempts);
      expect((await ledger.watchLocal().first).single.id, 'a-bad');
      ledger.dispose();
      await db.close();
    },
  );
  test(
    'a newer local version clears the rejected state and is attempted again',
    () async {
      final db = await databaseFactoryMemory.openDatabase(
        'stability-new-version',
      );
      final remote = StableRemote()..rejectBad = true;
      final ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(record('a-bad'));
      await ledger.flush();
      remote.rejectBad = false;
      await ledger.saveRun(record('a-bad', version: 7));
      await ledger.flush();
      expect(remote.records['a-bad']!.version, 7);
      expect(ledger.pendingCount, 0);
      expect(ledger.rejectedCount, 0);
      ledger.dispose();
      await db.close();
    },
  );
  test(
    'a transport timeout remains retryable instead of quarantining the run',
    () async {
      final db = await databaseFactoryMemory.openDatabase('stability-timeout');
      final remote = StableRemote()
        ..globalFailure = TimeoutException('transport stalled');
      final ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(record('a'));
      await ledger.flush();
      expect(ledger.pendingCount, 1);
      expect(ledger.rejectedCount, 0);
      remote.globalFailure = null;
      await ledger.flush();
      expect(ledger.pendingCount, 0);
      expect(remote.records.containsKey('a'), isTrue);
      ledger.dispose();
      await db.close();
    },
  );
  for (final kind in [
    RunSyncFailureKind.retryable,
    RunSyncFailureKind.authentication,
  ]) {
    test(
      '$kind pauses the queue without quarantining records and recovers',
      () async {
        final db = await databaseFactoryMemory.openDatabase(
          'stability-global-${kind.name}',
        );
        final remote = StableRemote()
          ..globalFailure = RunSyncFailure(kind, 'temporary');
        final ledger = RunLedger(db, remote: remote);
        await ledger.initialize();
        await ledger.saveRun(record('a'));
        await ledger.saveRun(record('z'));
        await ledger.flush();
        expect(ledger.pendingCount, 2);
        expect(ledger.rejectedCount, 0);
        remote.globalFailure = null;
        await ledger.flush();
        expect(remote.records.length, 2);
        expect(ledger.pendingCount, 0);
        expect(ledger.syncError, isNull);
        ledger.dispose();
        await db.close();
      },
    );
  }
  test(
    'a malformed queued record is retained without blocking valid records',
    () async {
      final db = await databaseFactoryMemory.openDatabase(
        'stability-malformed',
      );
      final pending = stringMapStoreFactory.store('outbox');
      await pending.record('a-malformed').put(db, {'not': 'a run'});
      final remote = StableRemote();
      final ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(record('z-healthy'));
      await ledger.flush();
      expect(remote.records.containsKey('z-healthy'), isTrue);
      expect(await pending.record('a-malformed').get(db), {'not': 'a run'});
      expect(ledger.rejectedCodes['a-malformed'], 'invalid-record');
      expect(ledger.pendingCount, 1);
      ledger.dispose();
      await db.close();
    },
  );
  test(
    'failure of an older in-flight version cannot quarantine its replacement',
    () async {
      final db = await databaseFactoryMemory.openDatabase('stability-inflight');
      final remote = StableRemote()..firstRequest = Completer<void>();
      final ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(record('a-bad', status: 'started', version: 1));
      await remote.firstStarted.future;
      await ledger.saveRun(record('a-bad', version: 6));
      remote.firstRequest!.completeError(
        const RunSyncFailure(RunSyncFailureKind.record, 'old-rejected'),
      );
      await ledger.flush();
      expect(remote.records['a-bad']!.version, 6);
      expect(ledger.pendingCount, 0);
      expect(ledger.rejectedCount, 0);
      ledger.dispose();
      await db.close();
    },
  );
}
