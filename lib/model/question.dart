import 'package:flutter/foundation.dart';

const optionIds = ['a', 'b', 'c', 'd'];

@immutable
class QuestionText {
  QuestionText({
    required this.prompt,
    required this.explanation,
    required Map<String, String> options,
  }) : options = Map.unmodifiable(options) {
    if (prompt.trim().isEmpty ||
        prompt.length > 500 ||
        explanation.trim().isEmpty ||
        explanation.length > 1000 ||
        options.length != 4 ||
        optionIds.any(
          (id) =>
              options[id]?.trim().isNotEmpty != true ||
              options[id]!.length > 120,
        )) {
      throw const FormatException('Invalid question translation');
    }
  }
  final String prompt;
  final String explanation;
  final Map<String, String> options;
  factory QuestionText.fromJson(Map<String, dynamic> data) => QuestionText(
    prompt: data['prompt'] as String,
    explanation: data['explanation'] as String,
    options: Map<String, String>.from(data['options'] as Map),
  );
  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'explanation': explanation,
    'options': options,
  };
}

@immutable
class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.order,
    required this.active,
    required this.correctOptionId,
    required Map<String, QuestionText> translations,
  }) : translations = Map.unmodifiable(translations) {
    if (!optionIds.contains(correctOptionId) ||
        order < 0 ||
        order > 1000000 ||
        !translations.containsKey('ko') ||
        !translations.containsKey('en')) {
      throw const FormatException('Invalid question');
    }
  }
  final String id;
  final int order;
  final bool active;
  final String correctOptionId;
  final Map<String, QuestionText> translations;
  QuestionText textFor(String language) =>
      translations[language] ?? translations['en']!;
  factory QuizQuestion.fromJson(String id, Map<String, dynamic> json) =>
      QuizQuestion(
        id: id,
        order: json['order'] as int,
        active: json['active'] as bool,
        correctOptionId: json['correctOptionId'] as String,
        translations: (json['translations'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            QuestionText.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        ),
      );
  Map<String, dynamic> toJson() => {
    'order': order,
    'active': active,
    'correctOptionId': correctOptionId,
    'translations': translations.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };
  QuizQuestion withActive(bool value) => QuizQuestion(
    id: id,
    order: order,
    active: value,
    correctOptionId: correctOptionId,
    translations: translations,
  );
}
