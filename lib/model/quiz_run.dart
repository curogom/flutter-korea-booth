import 'question.dart';

class QuizRun {
  QuizRun({
    required this.id,
    required this.environment,
    required this.startedAt,
    required this.language,
    required this.status,
    required this.questionIds,
    required this.correctAnswers,
    required this.answers,
    required this.version,
    this.finishedAt,
    this.durationMs = 0,
    this.catalogRevision = '',
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(id) ||
        ![
          'started',
          'completed',
          'abandoned',
          'interrupted',
        ].contains(status) ||
        questionIds.length != 4 ||
        correctAnswers.length != 4 ||
        answers.length > 4 ||
        [
          ...correctAnswers,
          ...answers,
        ].any((value) => !optionIds.contains(value)) ||
        version < 1 ||
        (status == 'completed' && answers.length != 4) ||
        !['ko', 'en'].contains(language)) {
      throw const FormatException('Invalid quiz run');
    }
  }
  final String id, environment, language, status, catalogRevision;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<String> questionIds, correctAnswers, answers;
  final int version, durationMs;
  int get score => answers.indexed
      .where((entry) => entry.$2 == correctAnswers[entry.$1])
      .length;
  bool get passed => status == 'completed' && score >= 3;
  Map<String, dynamic> toJson() => {
    'id': id,
    'environment': environment,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'language': language,
    'status': status,
    'questionIds': questionIds,
    'correctAnswers': correctAnswers,
    'answers': answers,
    'version': version,
    'durationMs': durationMs,
    'catalogRevision': catalogRevision,
    'score': score,
    'passed': passed,
  };
  factory QuizRun.fromJson(Map<String, dynamic> json) => QuizRun(
    id: json['id'] as String,
    environment: json['environment'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: json['finishedAt'] == null
        ? null
        : DateTime.parse(json['finishedAt'] as String),
    language: json['language'] as String,
    status: json['status'] as String,
    questionIds: List<String>.from(json['questionIds'] as List),
    correctAnswers: List<String>.from(json['correctAnswers'] as List),
    answers: List<String>.from(json['answers'] as List),
    version: json['version'] as int,
    durationMs: json['durationMs'] as int,
    catalogRevision: json['catalogRevision'] as String,
  );
}

abstract interface class QuizRunRecorder {
  Future<void> saveRun(QuizRun run);
}

class NoopRunRecorder implements QuizRunRecorder {
  const NoopRunRecorder();
  @override
  Future<void> saveRun(QuizRun run) async {}
}
