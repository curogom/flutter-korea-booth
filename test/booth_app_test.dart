import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/main.dart';
import 'package:flutter_korea_booth/data/question_repository.dart';
import 'package:flutter_korea_booth/model/question.dart';

import 'quiz_controller_test.dart' show fixtures, LiveRepository;

void main() {
  testWidgets('public demo hides admin and denies all private routes',
      (tester) async {
    await tester.pumpWidget(BoothApp(
      repository: SampleQuestionRepository(fixtures()),
      initialLocale: const Locale('en'),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.tune_rounded), findsNothing);
    for (final route in ['/admin', '/admin/reports', '/sign-in']) {
      final context = tester.element(find.byKey(const Key('start-quiz')));
      Navigator.of(context).pushNamed(route);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
          find.text(
              'Admin, sign-in and reporting pages are not available in this public demo.'),
          findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Host sign-in'), findsNothing);
      await tester.tap(find.text('Back to start'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('start-quiz')), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final language in ['ko', 'en']) {
    for (final score in [2, 3]) {
      testWidgets(
        'result shows demo disclaimer only for a passed run in $language at $score points',
        (tester) async {
          await tester.pumpWidget(
            BoothApp(
              repository: SampleQuestionRepository(fixtures()),
              initialLocale: Locale(language),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.byKey(const Key('start-quiz')));
          await tester.pump(const Duration(milliseconds: 400));
          for (var question = 0; question < 4; question++) {
            await tester.ensureVisible(
              find.byKey(Key(question < score ? 'answer-b' : 'answer-a')),
            );
            await tester.tap(
              find.byKey(Key(question < score ? 'answer-b' : 'answer-a')),
            );
            await tester.pump(const Duration(milliseconds: 200));
            await tester.ensureVisible(find.byKey(const Key('confirm-answer')));
            await tester.tap(find.byKey(const Key('confirm-answer')));
            await tester.pump(const Duration(seconds: 2));
            await tester.pump(const Duration(milliseconds: 400));
          }
          expect(find.byKey(const Key('result-score')), findsOneWidget);
          expect(
            find.textContaining(
              language == 'ko'
                  ? '경품이나 보상은 제공하지 않습니다'
                  : 'No prizes or rewards are issued',
            ),
            score >= 3 ? findsOneWidget : findsNothing,
          );
          expect(find.byKey(const Key('receipt-code')), findsNothing);
          expect(
            find.textContaining(
              language == 'ko' ? '참여 코드:' : 'Participation code:',
            ),
            findsNothing,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  for (final width in [320.0, 1024.0]) {
    testWidgets('added guide questions fit both languages at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bank = (await tester.runAsync(loadSampleQuestions))!;
      for (final question in bank.where((question) => question.order >= 5)) {
        for (final language in ['ko', 'en']) {
          final questions = List.generate(
            4,
            (index) => QuizQuestion.fromJson(
              '${question.id}-$index',
              question.toJson(),
            ),
          );
          await tester.pumpWidget(
            BoothApp(
              repository: SampleQuestionRepository(questions),
              initialLocale: Locale(language),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await tester.ensureVisible(find.byKey(const Key('start-quiz')));
          await tester.tap(find.byKey(const Key('start-quiz')));
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text(question.textFor(language).prompt), findsOneWidget);
          await tester.ensureVisible(find.byKey(const Key('answer-d')));
          await tester.ensureVisible(find.byKey(const Key('confirm-answer')));
          expect(
            tester.takeException(),
            isNull,
            reason: '${question.id}/$language',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  }
  for (final width in [320.0, 1024.0]) {
    testWidgets('Korean and English quiz layout works at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BoothApp(repository: SampleQuestionRepository(fixtures())),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('데모 퀴즈 시작'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('language-picker')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('English').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Start the demo quiz'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('start-quiz')));
      await tester.tap(find.byKey(const Key('start-quiz')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('question-prompt')), findsOneWidget);
      expect(find.textContaining('en original'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('answer-a')));
      await tester.tap(find.byKey(const Key('answer-a')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.ensureVisible(find.byKey(const Key('confirm-answer')));
      await tester.tap(find.byKey(const Key('confirm-answer')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('That’s okay'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Check answer'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'loading failure offers retry and successful recovery enables the quiz',
    (tester) async {
      final repo = LiveRepository();
      await tester.pumpWidget(BoothApp(repository: repo));
      await tester.pump();
      expect(find.text('문제를 불러오는 중이에요.'), findsOneWidget);
      repo.updates.addError(StateError('offline'));
      await tester.pump();
      expect(find.byKey(const Key('retry-questions')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('retry-questions')));
      await tester.tap(find.byKey(const Key('retry-questions')));
      await tester.pump();
      expect(repo.listenCount, 2);
      repo.updates.add(fixtures());
      await tester.pump();
      expect(find.byKey(const Key('retry-questions')), findsNothing);
      await tester.tap(find.byKey(const Key('start-quiz')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('question-prompt')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.updates.close();
    },
  );
  testWidgets('switching languages keeps the selected answer and grading ID', (
    tester,
  ) async {
    await tester.pumpWidget(
      BoothApp(repository: SampleQuestionRepository(fixtures())),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('start-quiz')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('answer-b')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('language-picker')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('English').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('en original'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('confirm-answer')));
    await tester.tap(find.byKey(const Key('confirm-answer')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Correct! One step forward.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
