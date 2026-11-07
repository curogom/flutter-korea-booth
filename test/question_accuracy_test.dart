import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/model/question_accuracy.dart';
import 'package:flutter_korea_booth/model/quiz_run.dart';

import 'quiz_controller_test.dart' show fixtures;

QuizRun accuracyRun(
  String id,
  List<String> answers, {
  String language = 'ko',
  String environment = 'production',
  int version = 6,
  List<String> ids = const ['a', 'b', 'c', 'd'],
}) => QuizRun(
  id: id,
  environment: environment,
  startedAt: DateTime.utc(2026, 11, 4),
  language: language,
  status: answers.length == 4 ? 'completed' : 'abandoned',
  questionIds: ids,
  correctAnswers: ['b', 'b', 'b', 'b'],
  answers: answers,
  version: version,
);

List<QuizQuestion> accuracyQuestions() => fixtures().indexed
    .map(
      (entry) => QuizQuestion.fromJson(['a', 'b', 'c', 'd'][entry.$1], {
        ...entry.$2.toJson(),
        // Simulate an edit after responses were recorded.
        'correctOptionId': 'a',
      }),
    )
    .toList();

void main() {
  test('counts confirmed answers from completed and partial runs using frozen keys', () {
    final rows = calculateQuestionAccuracy([
      accuracyRun('complete', ['b', 'a', 'b', 'a']),
      accuracyRun('partial', ['a', 'b']),
      accuracyRun('unanswered', []),
    ], accuracyQuestions());
    expect(rows.map((row) => row.responses), [2, 2, 1, 1]);
    expect(rows.map((row) => row.correct), [1, 1, 1, 0]);
    expect(rows.map((row) => row.incorrect), [1, 1, 0, 1]);
    expect(rows.map((row) => row.rate), [.5, .5, 1.0, 0.0]);
  });
  test(
    'merging local and remote versions counts each run once in its environment',
    () {
      final local = accuracyRun('same', ['b'], version: 2);
      final remote = accuracyRun('same', ['b', 'b'], version: 3);
      final merged = mergeParticipationRuns(
        [
          local,
          accuracyRun('other-environment', ['b'], environment: 'emulator'),
        ],
        [remote],
        environment: 'production',
      );
      expect(merged.length, 1);
      expect(merged.single.version, 3);
      final rows = calculateQuestionAccuracy(merged, accuracyQuestions());
      expect(rows.map((row) => row.responses), [1, 1, 0, 0]);
      final newerLocal = accuracyRun('same', ['b', 'b', 'b', 'a'], version: 6);
      expect(
        mergeParticipationRuns(
          [newerLocal],
          [remote],
          environment: 'production',
        ).single.version,
        6,
      );
    },
  );
  test('language filtering uses the last language recorded for each run', () {
    final rows = calculateQuestionAccuracy(
      [
        accuracyRun('ko', ['b'], language: 'ko'),
        accuracyRun('en', ['a'], language: 'en'),
      ],
      accuracyQuestions(),
      language: 'en',
    );
    expect(rows.first.responses, 1);
    expect(rows.first.correct, 0);
    expect(rows.first.rate, 0);
    expect(rows[1].rate, isNull);
  });
  test('unanswered catalog rows stay blank and historical questions remain visible', () {
    final rows = calculateQuestionAccuracy([
      accuracyRun('historical', ['b'], ids: ['deleted', 'b', 'c', 'd']),
    ], accuracyQuestions());
    expect(rows.length, 5);
    expect(rows.first.responses, 0);
    expect(rows.first.rate, isNull);
    expect(rows.last.id, 'deleted');
    expect(rows.last.question, isNull);
    expect(rows.last.correct, 1);
  });
}
