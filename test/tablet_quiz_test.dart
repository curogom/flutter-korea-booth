import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/data/question_repository.dart';
import 'package:flutter_korea_booth/main.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/state/quiz_controller.dart';
import 'package:flutter_korea_booth/ui/quiz_page.dart';

import 'controller_recording_test.dart' show Recorder;
import 'quiz_analytics_test.dart' show RecordingAnalytics;
import 'quiz_controller_test.dart' show LiveRepository, fixtures;

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  for (final size in [
    const Size(1024, 600),
    const Size(1280, 720),
    const Size(1180, 720),
  ]) {
    for (final language in ['ko', 'en']) {
      testWidgets('all 17 demo questions work by touch in $language at $size', (
        tester,
      ) async {
        setSize(tester, size);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bank = (await tester.runAsync(loadSampleQuestions))!;
        for (final source in bank) {
          await tester.pumpWidget(
            BoothApp(
              key: UniqueKey(),
              initialLocale: Locale(language),
              repository: SampleQuestionRepository([
                for (var i = 0; i < 4; i++)
                  QuizQuestion.fromJson('${source.id}-$i', source.toJson()),
              ]),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await tester.ensureVisible(find.byKey(const Key('start-quiz')));
          await tester.tap(find.byKey(const Key('start-quiz')));
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text(source.textFor(language).prompt), findsOneWidget);
          for (final id in optionIds) {
            final answer = find.byKey(Key('answer-$id'));
            await tester.ensureVisible(answer);
            expect(tester.getSize(answer).height, greaterThanOrEqualTo(70));
          }
          final correct = find.byKey(Key('answer-${source.correctOptionId}'));
          await tester.ensureVisible(correct);
          await tester.tap(correct);
          await tester.pump(const Duration(milliseconds: 200));
          final confirm = find.byKey(const Key('confirm-answer'));
          await tester.ensureVisible(confirm);
          expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
          await tester.tap(confirm);
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.text(source.textFor(language).explanation),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${source.id}/$language',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    }
  }

  for (final language in ['ko', 'en']) {
    testWidgets(
      'rotation, background and scrolling preserve the $language run',
      (tester) async {
        setSize(tester, const Size(1024, 600));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        addTearDown(
          () => tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          ),
        );
        final analytics = RecordingAnalytics();
        await tester.pumpWidget(
          BoothApp(
            repository: SampleQuestionRepository(
              fixtures(prompt: 'long prompt ' * 25),
            ),
            initialLocale: Locale(language),
            analytics: analytics,
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(find.byKey(const Key('start-quiz')));
        await tester.tap(find.byKey(const Key('start-quiz')));
        await tester.pump(const Duration(milliseconds: 400));
        final c = tester.widget<QuizPage>(find.byType(QuizPage)).controller;
        final runId = c.runId;
        final ids = c.session.map((q) => q.id).toList();
        await tester.ensureVisible(find.byKey(const Key('answer-b')));
        await tester.tap(find.byKey(const Key('answer-b')));
        for (final size in [
          const Size(1280, 720),
          const Size(768, 1024),
          const Size(1180, 720),
        ]) {
          setSize(tester, size);
          await tester.pump(const Duration(milliseconds: 400));
          expect(c.runId, runId);
          expect(c.session.map((q) => q.id), ids);
          expect(c.selection, 'b');
          expect(tester.takeException(), isNull);
        }
        final confirm = find.byKey(const Key('confirm-answer'));
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pump(const Duration(seconds: 1));
        final scroll = tester
            .widget<SingleChildScrollView>(find.byKey(const Key('quiz-scroll')))
            .controller!;
        expect(scroll.offset, greaterThan(0));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump(const Duration(seconds: 5));
        expect(c.phase, QuizPhase.reveal);
        expect(c.round, 0);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 1999));
        expect(c.phase, QuizPhase.reveal);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 400));
        expect(c.phase, QuizPhase.question);
        expect(c.round, 1);
        expect(scroll.offset, 0);
        expect(c.runId, runId);
        expect(c.score, 1);
        expect(
          analytics.events.where((e) => e.name == 'question_answered'),
          hasLength(1),
        );
        expect(
          analytics.events.where((e) => e.name == 'quiz_start'),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'interrupted final reveal completes once after a full visible delay',
    (tester) async {
      final repo = LiveRepository(),
          analytics = RecordingAnalytics(),
          recorder = Recorder();
      final c = QuizController(repo, analytics: analytics, recorder: recorder);
      repo.updates.add(fixtures());
      c.start();
      for (var i = 0; i < 3; i++) {
        c.select('b');
        c.confirm();
        await tester.pump(const Duration(seconds: 2));
      }
      c.select('b');
      c.confirm();
      await tester.pump(const Duration(milliseconds: 1999));
      c.setForeground(false);
      c.setForeground(false);
      c.select('a');
      c.confirm();
      await tester.pump(const Duration(seconds: 30));
      expect(c.phase, QuizPhase.reveal);
      expect(analytics.events.where((e) => e.name == 'quiz_complete'), isEmpty);
      c.setForeground(true);
      await tester.pump(const Duration(seconds: 1));
      c.setForeground(true); // A repeated resume must not extend the countdown.
      await tester.pump(const Duration(milliseconds: 999));
      expect(c.phase, QuizPhase.reveal);
      await tester.pump(const Duration(milliseconds: 1));
      await c.recordSaved;
      expect(c.phase, QuizPhase.result);
      expect(c.score, 4);
      expect(
        analytics.events.where((e) => e.name == 'question_answered'),
        hasLength(4),
      );
      expect(
        analytics.events.where((e) => e.name == 'quiz_complete'),
        hasLength(1),
      );
      expect(
        recorder.records.where((r) => r.status == 'completed'),
        hasLength(1),
      );
      c.dispose();
      await repo.updates.close();
    },
  );

  testWidgets('reset while hidden cancels the reveal without resuming it', (
    tester,
  ) async {
    final repo = LiveRepository();
    final c = QuizController(repo);
    repo.updates.add(fixtures());
    c.start();
    c.select('b');
    c.confirm();
    c.setForeground(false);
    c.reset();
    c.start();
    expect(c.phase, QuizPhase.home);
    c.setForeground(true);
    await tester.pump(const Duration(seconds: 3));
    expect(c.phase, QuizPhase.home);
    expect(c.answers, isEmpty);
    c.dispose();
    await repo.updates.close();
  });
}
