import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:flutter_korea_booth/data/run_repository.dart';
import 'package:flutter_korea_booth/data/run_sync_failure.dart';
import 'package:flutter_korea_booth/model/quiz_run.dart';
import 'package:flutter_korea_booth/storage/run_ledger.dart';

QuizRun recordedRun({String status = 'completed', int version = 6}) => QuizRun(
  id: 'run-1',
  environment: 'development',
  startedAt: DateTime.utc(2026, 11, 4),
  language: 'ko',
  status: status,
  questionIds: ['a', 'b', 'c', 'd'],
  correctAnswers: ['b', 'b', 'b', 'b'],
  answers: status == 'started' ? [] : ['b', 'b', 'b', 'a'],
  version: version,
  finishedAt: status == 'started' ? null : DateTime.utc(2026, 11, 4, 0, 1),
);

class RecordRemote implements RunRemoteRepository {
  bool online = false;
  final runs = <String, QuizRun>{};
  int writes = 0;
  @override
  Future<void> saveRun(QuizRun run) async {
    if (!online) {
      throw const RunSyncFailure(RunSyncFailureKind.retryable, 'unavailable');
    }
    if ((runs[run.id]?.version ?? 0) < run.version) {
      runs[run.id] = run;
      writes++;
    }
  }

  @override
  Stream<List<QuizRun>> watchRecent(String environment) =>
      Stream.value(runs.values.toList());
}

void main() {
  test(
    'offline records survive restart and synchronize once connection returns',
    () async {
      const name = 'ledger-restart';
      var db = await databaseFactoryMemory.openDatabase(name);
      final remote = RecordRemote();
      var ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(recordedRun());
      await ledger.flush();
      expect(ledger.pendingCount, 1);
      ledger.dispose();
      await db.close();
      db = await databaseFactoryMemory.openDatabase(name);
      ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.flush();
      expect((await ledger.watchLocal().first).single.status, 'completed');
      expect(ledger.pendingCount, 1);
      remote.online = true;
      await ledger.flush();
      expect(ledger.pendingCount, 0);
      expect(remote.runs.length, 1);
      await ledger.flush();
      expect(remote.writes, 1);
      ledger.dispose();
      await db.close();
    },
  );
  test('out of order snapshots cannot overwrite newer completion', () async {
    final db = await databaseFactoryMemory.openDatabase('ledger-version');
    final ledger = RunLedger(db);
    await ledger.initialize();
    await ledger.saveRun(recordedRun());
    await ledger.saveRun(recordedRun(status: 'started', version: 1));
    final run = (await ledger.watchLocal().first).single;
    expect(run.status, 'completed');
    expect(run.version, 6);
    ledger.dispose();
    await db.close();
  });
  test('restart preserves an unfinished run as interrupted', () async {
    const name = 'ledger-interrupted';
    var db = await databaseFactoryMemory.openDatabase(name);
    var ledger = RunLedger(db);
    await ledger.initialize();
    await ledger.saveRun(recordedRun(status: 'started', version: 1));
    ledger.dispose();
    await db.close();
    db = await databaseFactoryMemory.openDatabase(name);
    ledger = RunLedger(db);
    await ledger.initialize();
    final run = (await ledger.watchLocal().first).single;
    expect(run.status, 'interrupted');
    expect(run.version, 2);
    expect(run.passed, isFalse);
    ledger.dispose();
    await db.close();
  });
  test(
    'successful completion is recorded offline without staff confirmation',
    () async {
      final db = await databaseFactoryMemory.openDatabase(
        'ledger-direct-completion',
      );
      final remote = RecordRemote();
      final ledger = RunLedger(db, remote: remote);
      await ledger.initialize();
      await ledger.saveRun(recordedRun());
      await ledger.flush();
      final run = (await ledger.watchLocal().first).single;
      expect(run.status, 'completed');
      expect(run.passed, isTrue);
      expect(run.toJson().containsKey('claimedAt'), isFalse);
      expect(run.toJson().containsKey('claimedBy'), isFalse);
      expect(ledger.pendingCount, 1);
      expect(remote.runs, isEmpty);
      ledger.dispose();
      await db.close();
    },
  );
  test(
    'legacy collection metadata leaves participation history readable',
    () async {
      final db = await databaseFactoryMemory.openDatabase(
        'ledger-legacy-record',
      );
      final store = stringMapStoreFactory.store('runs');
      final legacy = {
        ...recordedRun().toJson(),
        'claimedAt': '2026-11-04T01:00:00.000Z',
        'claimedBy': 'old-operator',
      };
      await store.record('run-1').put(db, legacy);
      final ledger = RunLedger(db);
      await ledger.initialize();
      final restored = (await ledger.watchLocal().first).single;
      expect(restored.status, 'completed');
      expect(restored.score, 3);
      expect(restored.passed, isTrue);
      expect(restored.toJson().containsKey('claimedAt'), isFalse);
      expect(
        (await store.record('run-1').get(db))!['claimedBy'],
        'old-operator',
      );
      ledger.dispose();
      await db.close();
    },
  );
}
