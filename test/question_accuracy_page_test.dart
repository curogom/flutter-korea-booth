import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:flutter_korea_booth/data/firebase_config.dart';
import 'package:flutter_korea_booth/l10n/generated/app_localizations.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/model/quiz_run.dart';
import 'package:flutter_korea_booth/model/reporting_period.dart';
import 'package:flutter_korea_booth/storage/run_ledger.dart';
import 'package:flutter_korea_booth/ui/question_accuracy.dart';

import 'question_accuracy_test.dart' show accuracyQuestions, accuracyRun;
import 'question_editor_test.dart' show EditorRepository;
import 'run_ledger_test.dart' show RecordRemote;

class AccuracyRepository extends EditorRepository {
  bool fail = false;
  @override
  Stream<List<QuizQuestion>> watchAll() => fail
      ? Stream.error(StateError('catalog unavailable'))
      : Stream.value(accuracyQuestions());
}

Widget accuracyApp(
  RunLedger ledger,
  AccuracyRepository repository,
  String language,
) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(
    body: QuestionAccuracyPage(ledger: ledger, repository: repository),
  ),
);

void main() {
  testWidgets(
    'period filtering excludes earlier runs and all-time restores them',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await databaseFactoryMemory.openDatabase('period-accuracy');
      final ledger = RunLedger(db);
      final period = ReportingPeriod.initial();
      await tester.runAsync(() async {
        await ledger.initialize();
        final inside = accuracyRun('inside', ['b']);
        await ledger.saveRun(
          QuizRun.fromJson({
            ...inside.toJson(),
            'startedAt': period.startsAt.toIso8601String(),
          }),
        );
        await ledger.saveRun(accuracyRun('before', ['a']));
        await ledger.saveRun(
          accuracyRun('other-environment', ['a'], environment: 'development'),
        );
      });
      Widget app(ReportingPeriod? scope) => MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuestionAccuracyPage(
            ledger: ledger,
            repository: AccuracyRepository(),
            period: scope,
            environment: 'production',
          ),
        ),
      );
      await tester.pumpWidget(app(period));
      await tester.pumpAndSettle();
      final table = find.byKey(const Key('question-accuracy-table'));
      expect(
        (tester.widget<DataTable>(table).rows.first.cells[1].child as Text)
            .data,
        '1',
      );
      expect(
        (tester.widget<DataTable>(table).rows.first.cells[4].child as Text)
            .data,
        '100.0%',
      );
      await tester.pumpWidget(app(null));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<DataTable>(table).rows.first.cells[1].child as Text)
            .data,
        '2',
      );
      expect(
        (tester.widget<DataTable>(table).rows.first.cells[4].child as Text)
            .data,
        '50.0%',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      ledger.dispose();
      await db.close();
    },
  );
  for (final width in [320.0, 1200.0]) {
    for (final language in ['ko', 'en']) {
      testWidgets(
        'accuracy table and language filter work in $language at $width px',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = await databaseFactoryMemory.openDatabase(
            'accuracy-$width-$language',
          );
          final remote = RecordRemote()..online = true;
          final ledger = RunLedger(db, remote: remote);
          await tester.runAsync(() async {
            await ledger.initialize();
            await ledger.saveRun(
              accuracyRun('one', [
                'b',
                'b',
                'b',
                'a',
              ], environment: FirebaseConfig.environment),
            );
            await ledger.flush();
          });
          await tester.pumpWidget(
            accuracyApp(ledger, AccuracyRepository(), language),
          );
          await tester.pumpAndSettle();
          final tableFinder = find.byKey(const Key('question-accuracy-table'));
          var table = tester.widget<DataTable>(tableFinder);
          expect(table.rows.length, 4);
          expect((table.rows.first.cells[1].child as Text).data, '1');
          expect((table.rows.first.cells[4].child as Text).data, '100.0%');
          expect((table.rows.last.cells[4].child as Text).data, '0.0%');
          expect(find.byType(FilledButton), findsNothing);
          await tester.tap(find.byKey(const Key('accuracy-language-en')));
          await tester.pumpAndSettle();
          table = tester.widget<DataTable>(tableFinder);
          expect((table.rows.first.cells[1].child as Text).data, '0');
          expect((table.rows.first.cells[4].child as Text).data, '—');
          await tester.tap(find.byKey(const Key('accuracy-language-all')));
          await tester.pumpAndSettle();
          expect(
            (tester.widget<DataTable>(tableFinder).rows.first.cells[1].child
                    as Text)
                .data,
            '1',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          ledger.dispose();
          await db.close();
        },
      );
    }
  }
  testWidgets(
    'catalog failure keeps response counts and reload restores question titles',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await databaseFactoryMemory.openDatabase('accuracy-retry');
      final ledger = RunLedger(db);
      final repository = AccuracyRepository()..fail = true;
      await tester.runAsync(() async {
        await ledger.initialize();
        await ledger.saveRun(
          accuracyRun('partial', [
            'b',
          ], environment: FirebaseConfig.environment),
        );
      });
      await tester.pumpWidget(accuracyApp(ledger, repository, 'ko'));
      await tester.pumpAndSettle();
      expect(find.textContaining('일부 기록이 최신 상태가 아닐 수 있습니다'), findsOneWidget);
      final finder = find.byKey(const Key('question-accuracy-table'));
      expect(
        (tester.widget<DataTable>(finder).rows.single.cells[1].child as Text)
            .data,
        '1',
      );
      repository.fail = false;
      await tester.tap(find.byKey(const Key('accuracy-refresh')));
      await tester.pumpAndSettle();
      expect(find.textContaining('일부 기록이 최신 상태가 아닐 수 있습니다'), findsNothing);
      expect(find.text('ko original 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      ledger.dispose();
      await db.close();
    },
  );
}
