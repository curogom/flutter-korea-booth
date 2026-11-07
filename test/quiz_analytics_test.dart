import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/analytics/quiz_analytics.dart';
import 'package:flutter_korea_booth/state/quiz_controller.dart';

import 'quiz_controller_test.dart' show LiveRepository, fixtures;

class RecordingAnalytics implements QuizAnalytics {
  final events = <({String name, Map<String, Object> parameters})>[];
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async {
    events.add((name: name, parameters: Map.unmodifiable(parameters)));
    if (fail) throw StateError('Analytics unavailable');
    await pending?.future;
  }
}

void main() {
  testWidgets(
    'one start, four confirmed answers and one completion per quiz run',
    (tester) async {
      final repo = LiveRepository();
      final analytics = RecordingAnalytics();
      final c = QuizController(
        repo,
        analytics: analytics,
        runIdFactory: () => 'run-one',
      );
      repo.updates.add(fixtures());
      c.start();
      c.start();
      for (var round = 0; round < 4; round++) {
        c.select('a');
        c.select(round < 3 ? 'b' : 'a');
        c.confirm();
        c.confirm();
        await tester.pump(const Duration(seconds: 2));
      }
      expect(analytics.events.map((e) => e.name), [
        'quiz_start',
        'question_answered',
        'question_answered',
        'question_answered',
        'question_answered',
        'quiz_complete',
      ]);
      expect(
        analytics.events.every((e) => e.parameters['quiz_run_id'] == 'run-one'),
        isTrue,
      );
      final answers = analytics.events
          .where((e) => e.name == 'question_answered')
          .toList();
      expect(answers.map((e) => e.parameters['question_position']), [
        1,
        2,
        3,
        4,
      ]);
      expect(answers.map((e) => e.parameters['is_correct']), [1, 1, 1, 0]);
      expect(answers.first.parameters['selected_option'], 'b');
      expect(answers.first.parameters['question_id'], c.session.first.id);
      expect(answers.first.parameters['response_ms'], isA<int>());
      expect(analytics.events.last.parameters['score'], 3);
      expect(analytics.events.last.parameters['passed'], 1);
      expect(analytics.events.last.parameters['duration_ms'], isA<int>());
      c.reset();
      c.dispose();
      expect(analytics.events.where((e) => e.name == 'quiz_abandon'), isEmpty);
      await repo.updates.close();
    },
  );
  testWidgets(
    'each player gets a new run ID and reset records partial progress once',
    (tester) async {
      final repo = LiveRepository();
      final analytics = RecordingAnalytics();
      var run = 0;
      final c = QuizController(
        repo,
        analytics: analytics,
        runIdFactory: () => 'run-${++run}',
      );
      repo.updates.add(fixtures());
      c.start();
      c.select('b');
      c.confirm();
      c.reset();
      c.reset();
      c.start();
      final starts = analytics.events
          .where((e) => e.name == 'quiz_start')
          .toList();
      expect(starts.map((e) => e.parameters['quiz_run_id']), [
        'run-1',
        'run-2',
      ]);
      final abandon = analytics.events.singleWhere(
        (e) => e.name == 'quiz_abandon',
      );
      expect(abandon.parameters['quiz_run_id'], 'run-1');
      expect(abandon.parameters['answered_count'], 1);
      expect(abandon.parameters['reason'], 'reset');
      expect(analytics.events.where((e) => e.name == 'quiz_complete'), isEmpty);
      await tester.pump(const Duration(seconds: 3));
      expect(c.round, 0);
      c.dispose();
      await repo.updates.close();
    },
  );
  testWidgets('language changes preserve the run and selected answer', (
    tester,
  ) async {
    final repo = LiveRepository();
    final analytics = RecordingAnalytics();
    final c = QuizController(
      repo,
      analytics: analytics,
      runIdFactory: () => 'same-run',
    );
    repo.updates.add(fixtures());
    c.start();
    c.select('b');
    c.setLanguage('en');
    c.setLanguage('en');
    c.confirm();
    expect(c.selection, 'b');
    expect(c.score, 1);
    final change = analytics.events.singleWhere(
      (e) => e.name == 'quiz_language_changed',
    );
    expect(change.parameters['previous_language'], 'ko');
    expect(change.parameters['language'], 'en');
    expect(analytics.events.last.parameters['language'], 'en');
    expect(analytics.events.last.parameters['quiz_run_id'], 'same-run');
    c.dispose();
    await repo.updates.close();
  });
  testWidgets('a pending Analytics request never delays quiz advancement', (
    tester,
  ) async {
    final repo = LiveRepository();
    final analytics = RecordingAnalytics()..pending = Completer<void>();
    final c = QuizController(repo, analytics: analytics);
    repo.updates.add(fixtures());
    c.start();
    c.select('b');
    c.confirm();
    await tester.pump(const Duration(milliseconds: 1999));
    expect(c.phase, QuizPhase.reveal);
    await tester.pump(const Duration(milliseconds: 1));
    expect(c.phase, QuizPhase.question);
    expect(c.round, 1);
    analytics.pending!.complete();
    await tester.pump();
    c.dispose();
    await repo.updates.close();
  });
  testWidgets(
    'Analytics errors do not escape or change scoring and progression',
    (tester) async {
      final repo = LiveRepository();
      final analytics = RecordingAnalytics()..fail = true;
      final c = QuizController(repo, analytics: analytics);
      repo.updates.add(fixtures());
      c.start();
      c.select('b');
      c.confirm();
      await tester.pump(const Duration(seconds: 2));
      expect(c.score, 1);
      expect(c.round, 1);
      expect(c.phase, QuizPhase.question);
      expect(tester.takeException(), isNull);
      c.dispose();
      await repo.updates.close();
      await tester.pump();
    },
  );
}
