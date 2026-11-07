import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/data/question_repository.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/state/quiz_controller.dart';

import 'quiz_controller_test.dart' show fixtures, LiveRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bundled bilingual questions decode with unique IDs and valid answers',
    () async {
      final questions = await loadSampleQuestions();
      expect(questions.where((q) => q.active).length, 17);
      expect(questions.map((q) => q.id).toSet().length, questions.length);
      for (final q in questions) {
        expect(q.translations.keys, containsAll(['ko', 'en']));
        for (final text in q.translations.values) {
          expect(text.options[q.correctOptionId]?.isNotEmpty, isTrue);
        }
      }
    },
  );
  test('every run draws four unique questions from the entire demo 17-question bank', () async {
    final bank = await loadSampleQuestions();
    final repo = LiveRepository();
    final controller = QuizController(repo, random: Random(20261107));
    repo.updates.add(bank);
    final seen = <String>{};
    final selections = <String>{};
    for (var run = 0; run < 40; run++) {
      controller.start();
      final ids = controller.session.map((question) => question.id).toList();
      expect(ids.length, 4);
      expect(ids.toSet().length, 4);
      expect(
        ids.every((id) => bank.any((question) => question.id == id)),
        isTrue,
      );
      seen.addAll(ids);
      selections.add((List<String>.of(ids)..sort()).join(','));
      controller.reset();
    }
    expect(seen, bank.map((question) => question.id).toSet());
    expect(selections.length, greaterThan(1));
    controller.dispose();
    await repo.updates.close();
  });
  test('Firestore round trip preserves translations and answer IDs across publication changes', () {
    final original = fixtures().first;
    final restored = QuizQuestion.fromJson(
      original.id,
      original.toJson(),
    ).withActive(false);
    expect(restored.id, original.id);
    expect(restored.active, isFalse);
    expect(restored.correctOptionId, original.correctOptionId);
    expect(restored.textFor('ko').toJson(), original.textFor('ko').toJson());
    expect(restored.textFor('en').toJson(), original.textFor('en').toJson());
  });
  test('invalid translation content and unstable choice IDs fail decoding', () {
    final text = fixtures().first.textFor('ko').toJson();
    for (final invalid in [
      {...text, 'prompt': '  '},
      {...text, 'explanation': ''},
      {
        ...text,
        'options': {'a': 'A', 'b': 'B', 'c': 'C', 'x': 'X'},
      },
      {
        ...text,
        'options': {'a': 'A', 'b': '  ', 'c': 'C', 'd': 'D'},
      },
    ]) {
      expect(() => QuestionText.fromJson(invalid), throwsFormatException);
    }
    final q = fixtures().first;
    expect(
      () =>
          QuizQuestion.fromJson(q.id, {...q.toJson(), 'correctOptionId': 'z'}),
      throwsFormatException,
    );
    expect(
      () => QuizQuestion.fromJson(q.id, {...q.toJson(), 'order': -1}),
      throwsFormatException,
    );
  });
}
