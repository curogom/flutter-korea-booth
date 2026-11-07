import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/data/question_repository.dart';
import 'package:flutter_korea_booth/main.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/state/quiz_controller.dart';

import 'quiz_controller_test.dart' show LiveRepository;

final reviewedAnswers = {
  for (var i = 1; i <= 17; i++)
    'demo-addition-${i.toString().padLeft(2, '0')}': 'abcd'[(i - 1) % 4],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the 17 original demo IDs and answers are consistent', () async {
    final bank = await loadSampleQuestions();
    expect(bank.map((q) => q.id), orderedEquals(reviewedAnswers.keys));
    expect(
      bank.map((q) => q.order),
      orderedEquals(List.generate(17, (i) => i + 1)),
    );
    for (final q in bank) {
      expect(q.active, isTrue);
      expect(q.correctOptionId, reviewedAnswers[q.id]);
      expect(q.translations.keys.toSet(), {'ko', 'en'});
      for (final language in ['ko', 'en']) {
        expect(q.textFor(language).options.keys, orderedEquals(optionIds));
        expect(q.textFor(language).options.values.toSet().length, 4);
      }
    }
  });

  for (final language in ['ko', 'en']) {
    for (var correct = 0; correct <= 4; correct++) {
      testWidgets(
        'demo bank scores $correct/4 in $language with stable answer IDs',
        (tester) async {
          final bank = (await tester.runAsync(loadSampleQuestions))!;
          final repo = LiveRepository();
          final controller = QuizController(
            repo,
            random: Random(17 + correct),
            language: language,
          );
          repo.updates.add(bank);
          controller.start();
          expect(controller.session.length, 4);
          expect(controller.session.map((q) => q.id).toSet().length, 4);
          for (var index = 0; index < 4; index++) {
            final answer = reviewedAnswers[controller.current.id]!;
            controller.select(
              index < correct
                  ? answer
                  : optionIds.firstWhere((id) => id != answer),
            );
            controller.setLanguage(language == 'ko' ? 'en' : 'ko');
            controller.confirm();
            await tester.pump(const Duration(milliseconds: 1999));
            expect(controller.phase, QuizPhase.reveal);
            await tester.pump(const Duration(milliseconds: 1));
          }
          expect(controller.phase, QuizPhase.result);
          expect(controller.score, correct);
          expect(controller.passed, correct >= 3);
          controller.dispose();
          await repo.updates.close();
        },
      );
    }
  }

  testWidgets(
    'all demo questions preserve a selected answer across Korean and English',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bank = (await tester.runAsync(loadSampleQuestions))!;
      for (final q in bank) {
        await tester.pumpWidget(
          BoothApp(
            key: UniqueKey(),
            repository: SampleQuestionRepository([
              for (var i = 0; i < 4; i++)
                QuizQuestion.fromJson('${q.id}-$i', q.toJson()),
            ]),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(find.byKey(const Key('start-quiz')));
        await tester.tap(find.byKey(const Key('start-quiz')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(q.textFor('ko').prompt), findsOneWidget);
        final answer = find.byKey(Key('answer-${reviewedAnswers[q.id]}'));
        await tester.ensureVisible(answer);
        await tester.tap(answer);
        await tester.pump();
        await tester.tap(find.byKey(const Key('language-picker')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('English').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(q.textFor('en').prompt), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('confirm-answer')));
        await tester.tap(find.byKey(const Key('confirm-answer')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(q.textFor('en').explanation), findsOneWidget);
        expect(find.text('Correct! One step forward.'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: q.id);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
