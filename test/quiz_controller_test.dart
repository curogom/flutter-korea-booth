import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/data/question_repository.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/state/quiz_controller.dart';

class LiveRepository implements QuestionRepository {
  final updates = StreamController<List<QuizQuestion>>.broadcast(sync: true);
  int listenCount = 0;
  @override
  Stream<List<QuizQuestion>> watchPublished() {
    listenCount++;
    return updates.stream;
  }
}

List<QuizQuestion> fixtures({String prompt = 'original'}) => List.generate(
  4,
  (index) => QuizQuestion(
    id: '$index',
    order: index,
    active: true,
    correctOptionId: 'b',
    translations: {
      for (final language in ['ko', 'en'])
        language: QuestionText(
          prompt: '$language $prompt $index',
          explanation: 'Because B',
          options: {'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D'},
        ),
    },
  ),
);

void main() {
  testWidgets(
    'selection is editable and only confirmation scores; advance is exactly two seconds',
    (tester) async {
      final repo = LiveRepository();
      final controller = QuizController(repo, random: Random(1));
      repo.updates.add(fixtures());
      controller.start();
      controller.select('a');
      controller.select('b');
      expect(controller.score, 0);
      controller.confirm();
      controller.confirm();
      expect(controller.answers.length, 1);
      expect(controller.score, 1);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(controller.phase, QuizPhase.reveal);
      await tester.pump(const Duration(milliseconds: 1));
      expect(controller.phase, QuizPhase.question);
      expect(controller.round, 1);
      expect(controller.selection, isNull);
      controller.dispose();
      await repo.updates.close();
    },
  );
  testWidgets('reset cancels pending progression', (tester) async {
    final repo = LiveRepository();
    final c = QuizController(repo);
    repo.updates.add(fixtures());
    c.start();
    c.select('b');
    c.confirm();
    c.reset();
    await tester.pump(const Duration(seconds: 3));
    expect(c.phase, QuizPhase.home);
    expect(c.answers, isEmpty);
    c.dispose();
    await repo.updates.close();
  });
  testWidgets('live edits affect the next player, not a running session', (
    tester,
  ) async {
    final repo = LiveRepository();
    final c = QuizController(repo, random: Random(2));
    repo.updates.add(fixtures());
    c.start();
    final oldPrompt = c.current.textFor('ko').prompt;
    repo.updates.add(fixtures(prompt: 'updated'));
    expect(c.current.textFor('ko').prompt, oldPrompt);
    c.reset();
    c.start();
    expect(c.current.textFor('ko').prompt, contains('updated'));
    c.dispose();
    await repo.updates.close();
  });
  for (final correct in [0, 2, 3, 4]) {
    testWidgets(
      '$correct correct answers produce the expected threshold result',
      (tester) async {
        final repo = LiveRepository();
        final c = QuizController(repo);
        repo.updates.add(fixtures());
        c.start();
        for (var index = 0; index < 4; index++) {
          c.select(index < correct ? 'b' : 'a');
          c.confirm();
          await tester.pump(const Duration(seconds: 2));
        }
        expect(c.phase, QuizPhase.result);
        expect(c.score, correct);
        expect(c.passed, correct >= 3);
        c.dispose();
        await repo.updates.close();
      },
    );
  }
  testWidgets('fewer than four published questions cannot start a session', (
    tester,
  ) async {
    final repo = LiveRepository();
    final c = QuizController(repo);
    repo.updates.add(fixtures().take(3).toList());
    c.start();
    expect(c.canStart, isFalse);
    expect(c.phase, QuizPhase.home);
    c.dispose();
    await repo.updates.close();
  });
  testWidgets('stream failure blocks starting and retry subscribes again', (
    tester,
  ) async {
    final repo = LiveRepository();
    final c = QuizController(repo);
    repo.updates.add(fixtures());
    repo.updates.addError(StateError('offline'));
    expect(c.canStart, isFalse);
    c.start();
    expect(c.phase, QuizPhase.home);
    c.retry();
    expect(c.loading, isTrue);
    expect(c.error, isNull);
    expect(repo.listenCount, 2);
    repo.updates.add(fixtures(prompt: 'recovered'));
    expect(c.canStart, isTrue);
    c.start();
    expect(c.current.textFor('ko').prompt, contains('recovered'));
    c.dispose();
    await repo.updates.close();
  });
  testWidgets(
    'catalog failure during a session keeps its questions and timer',
    (tester) async {
      final repo = LiveRepository();
      final c = QuizController(repo);
      repo.updates.add(fixtures());
      c.start();
      final ids = c.session.map((q) => q.id).toList();
      c.select('b');
      c.confirm();
      repo.updates.addError(StateError('permission lost'));
      c.retry(); // A running quiz must keep its frozen snapshot.
      expect(repo.listenCount, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(c.phase, QuizPhase.question);
      expect(c.round, 1);
      expect(c.score, 1);
      expect(c.session.map((q) => q.id), ids);
      c.reset();
      expect(c.canStart, isFalse);
      repo.updates.add(fixtures());
      expect(c.error, isNull);
      expect(c.canStart, isTrue);
      c.dispose();
      await repo.updates.close();
    },
  );
  testWidgets('unpublished questions disappear only from the next session', (
    tester,
  ) async {
    final repo = LiveRepository();
    final c = QuizController(repo);
    repo.updates.add(fixtures());
    c.start();
    repo.updates.add(fixtures().take(3).toList());
    for (var i = 0; i < 4; i++) {
      c.select('b');
      c.confirm();
      await tester.pump(const Duration(seconds: 2));
    }
    expect(c.phase, QuizPhase.result);
    expect(c.score, 4);
    c.reset();
    c.start();
    expect(c.phase, QuizPhase.home);
    expect(c.canStart, isFalse);
    c.dispose();
    await repo.updates.close();
  });
  testWidgets(
    'invalid actions and repeat start cannot alter an active answer',
    (tester) async {
      final repo = LiveRepository();
      final c = QuizController(repo);
      repo.updates.add(fixtures());
      c.start();
      c.select('z');
      c.confirm();
      expect(c.selection, isNull);
      expect(c.answers, isEmpty);
      c.select('b');
      c.confirm();
      c.select('a');
      c.start();
      c.confirm();
      expect(c.phase, QuizPhase.reveal);
      expect(c.selection, 'b');
      expect(c.answers, ['b']);
      expect(c.score, 1);
      c.dispose();
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      await repo.updates.close();
    },
  );
  testWidgets(
    'a stream ending before its first catalog leaves a recoverable error',
    (tester) async {
      final repo = LiveRepository();
      final c = QuizController(repo);
      await repo.updates.close();
      expect(c.loading, isFalse);
      expect(c.error, isA<StateError>());
      expect(c.canStart, isFalse);
      c.dispose();
    },
  );
  test('localized text shares stable answer IDs and falls back to English', () {
    final q = fixtures().first;
    expect(q.textFor('ko').options.keys, optionIds);
    expect(q.textFor('en').options.keys, optionIds);
    expect(q.textFor('fr').prompt, startsWith('en'));
    expect(() => q.translations.clear(), throwsUnsupportedError);
    expect(() => q.textFor('ko').options.clear(), throwsUnsupportedError);
  });
}
