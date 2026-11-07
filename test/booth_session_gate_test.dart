import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/storage/booth_session_status.dart';
import 'package:flutter_korea_booth/ui/booth_session_gate.dart';

void main() {
  for (final language in ['ko', 'en']) {
    for (final width in [320.0, 1200.0]) {
      for (final status in [
        BoothSessionStatus.alreadyOpen,
        BoothSessionStatus.unavailable,
      ]) {
        testWidgets('startup gate $status in $language at $width', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final pending = Completer<void>();
          var attempts = 0;
          await tester.pumpWidget(
            BoothSessionGate(
              status: status,
              locale: Locale(language),
              onRetry: () async {
                attempts++;
                await pending.future;
              },
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(FilledButton), findsOneWidget);
          expect(
            find.text(language == 'ko' ? '다시 시도' : 'Try again'),
            findsOneWidget,
          );
          await tester.tap(find.byType(FilledButton));
          await tester.pump();
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull,
          );
          expect(attempts, 1);
          pending.complete();
          await tester.pumpAndSettle();
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNotNull,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
