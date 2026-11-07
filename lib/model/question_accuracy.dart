import 'question.dart';
import 'quiz_run.dart';

List<QuizRun> mergeParticipationRuns(
  Iterable<QuizRun> local,
  Iterable<QuizRun> remote, {
  required String environment,
}) {
  final latest = <String, QuizRun>{};
  for (final run in [...local, ...remote]) {
    if (run.environment != environment) continue;
    final previous = latest[run.id];
    if (previous == null || run.version >= previous.version) {
      latest[run.id] = run;
    }
  }
  return latest.values.toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
}

class QuestionAccuracy {
  const QuestionAccuracy({
    required this.id,
    required this.question,
    required this.responses,
    required this.correct,
  });
  final String id;
  final QuizQuestion? question;
  final int responses, correct;
  int get incorrect => responses - correct;
  double? get rate => responses == 0 ? null : correct / responses;
}

List<QuestionAccuracy> calculateQuestionAccuracy(
  Iterable<QuizRun> runs,
  Iterable<QuizQuestion> questions, {
  String? language,
}) {
  final catalog = {for (final question in questions) question.id: question};
  final counts = <String, ({int responses, int correct})>{
    for (final id in catalog.keys) id: (responses: 0, correct: 0),
  };
  for (final run in runs) {
    // Run language is the last selected language, including mid-run switches.
    if (language != null && run.language != language) continue;
    for (var index = 0; index < run.answers.length; index++) {
      final id = run.questionIds[index];
      final previous = counts[id] ?? (responses: 0, correct: 0);
      counts[id] = (
        responses: previous.responses + 1,
        // Grade against the answer frozen when this run started.
        correct:
            previous.correct +
            (run.answers[index] == run.correctAnswers[index] ? 1 : 0),
      );
    }
  }
  return counts.entries
      .map(
        (entry) => QuestionAccuracy(
          id: entry.key,
          question: catalog[entry.key],
          responses: entry.value.responses,
          correct: entry.value.correct,
        ),
      )
      .toList()
    ..sort((a, b) {
      final byOrder = (a.question?.order ?? 1000001).compareTo(
        b.question?.order ?? 1000001,
      );
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
}
