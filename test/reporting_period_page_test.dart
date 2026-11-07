import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/model/reporting_period.dart';
import 'package:flutter_korea_booth/l10n/generated/app_localizations.dart';
import 'package:flutter_korea_booth/state/reporting_period_controller.dart';
import 'package:flutter_korea_booth/ui/reporting_period_bar.dart';

import 'reporting_period_test.dart' show PeriodRepository;

void main() {
  for (final width in [320.0, 1200.0]) {
    for (final language in ['ko', 'en']) {
      testWidgets(
        'period editing validates and persists in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = PeriodRepository();
          final controller = ReportingPeriodController(repository);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => SingleChildScrollView(
                    child: ReportingPeriodBar(controller: controller),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const Key('report-all-time')));
          await tester.pumpAndSettle();
          expect(controller.activePeriod, isNull);
          await tester.tap(find.byKey(const Key('report-edit-period')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('report-end')),
            '2030-01-01 09:00',
          );
          await tester.tap(find.byKey(const Key('report-save')));
          await tester.pumpAndSettle();
          expect(repository.saved, isNull);
          expect(find.byType(AlertDialog), findsOneWidget);
          await tester.enterText(
            find.byKey(const Key('report-end')),
            '2030-01-01 19:00',
          );
          repository.fail = true;
          await tester.tap(find.byKey(const Key('report-save')));
          await tester.pumpAndSettle();
          expect(repository.saved, isNull);
          expect(find.byType(AlertDialog), findsOneWidget);
          repository.fail = false;
          await tester.tap(find.byKey(const Key('report-save')));
          await tester.pumpAndSettle();
          expect(
            repository.saved!.endsAt,
            ReportingPeriod.parseKoreanTime('2030-01-01 19:00'),
          );
          expect(controller.allTime, isFalse);
          expect(find.byType(AlertDialog), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
          await repository.updates.close();
        },
      );
    }
  }
}
