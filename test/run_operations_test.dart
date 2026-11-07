import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:flutter_korea_booth/data/firebase_config.dart';
import 'package:flutter_korea_booth/l10n/generated/app_localizations.dart';
import 'package:flutter_korea_booth/model/quiz_run.dart';
import 'package:flutter_korea_booth/storage/run_ledger.dart';
import 'package:flutter_korea_booth/ui/run_operations.dart';
import 'package:flutter_korea_booth/data/run_sync_failure.dart';

import 'run_ledger_test.dart' show RecordRemote, recordedRun;

class RejectedRemote extends RecordRemote {
  bool repaired = false;
  @override
  Future<void> saveRun(QuizRun run) async {
    if (!repaired) {
      throw const RunSyncFailure(
        RunSyncFailureKind.record,
        'terminal-record-conflict',
      );
    }
    await super.saveRun(run);
  }
}

void main() {
  testWidgets(
    'rejected records remain visible and can be retried after repair',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await databaseFactoryMemory.openDatabase(
        'operations-rejected',
      );
      final remote = RejectedRemote()..online = true;
      final ledger = RunLedger(db, remote: remote);
      await tester.runAsync(() async {
        await ledger.initialize();
        await ledger.saveRun(
          QuizRun.fromJson({
            ...recordedRun().toJson(),
            'environment': FirebaseConfig.environment,
          }),
        );
        await ledger.flush();
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RunOperations(ledger: ledger)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('동기화 확인 필요: 1'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      remote.repaired = true;
      final retry = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '지금 동기화'),
      );
      await tester.runAsync(() async {
        retry.onPressed!();
        await ledger.flush();
      });
      await tester.pumpAndSettle();
      expect(ledger.rejectedCount, 0);
      expect(ledger.pendingCount, 0);
      expect(find.text('동기화 확인 필요: 1'), findsNothing);
      expect(find.byIcon(Icons.sync_problem), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      ledger.dispose();
      await db.close();
    },
  );
  for (final width in [360.0, 1200.0]) {
    for (final language in ['ko', 'en']) {
      testWidgets('participation is read-only in $language at $width px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = await databaseFactoryMemory.openDatabase(
          'operations-$width-$language',
        );
        final remote = RecordRemote()..online = true;
        final ledger = RunLedger(db, remote: remote);
        await tester.runAsync(() async {
          await ledger.initialize();
          await ledger.saveRun(
            QuizRun.fromJson({
              ...recordedRun().toJson(),
              'environment': FirebaseConfig.environment,
            }),
          );
          await ledger.flush();
        });
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RunOperations(ledger: ledger)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('RUN-1 · 3/4 · KO'), findsOneWidget);
        expect(find.byKey(const Key('claim-run-1')), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
        expect(
          find.textContaining(language == 'ko' ? '성공: 1' : 'Passed: 1'),
          findsOneWidget,
        );
        expect(
          find.textContaining(language == 'ko' ? '지급 완료' : 'Collected'),
          findsNothing,
        );
        await tester.enterText(find.byKey(const Key('run-search')), 'missing');
        await tester.pumpAndSettle();
        expect(find.text('RUN-1 · 3/4 · KO'), findsNothing);
        await tester.enterText(find.byKey(const Key('run-search')), 'run-1');
        await tester.pumpAndSettle();
        expect(find.text('RUN-1 · 3/4 · KO'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        ledger.dispose();
        await db.close();
      });
    }
  }
}
