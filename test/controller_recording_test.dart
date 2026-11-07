import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/model/quiz_run.dart';
import 'package:flutter_korea_booth/state/quiz_controller.dart';

import 'quiz_controller_test.dart' show LiveRepository, fixtures;

class Recorder implements QuizRunRecorder {
  final records = <QuizRun>[];
  @override
  Future<void> saveRun(QuizRun run) async {
    records.add(run);
  }
}

void main() {
  testWidgets(
    'completion records frozen questions, final score and one receipt ID',
    (tester) async {
      final repo = LiveRepository(), recorder = Recorder();
      final c = QuizController(
        repo,
        recorder: recorder,
        runIdFactory: () => 'receipt-one',
        environment: 'development',
      );
      repo.updates.add(fixtures());
      c.start();
      repo.updates.add(fixtures(prompt: 'edited'));
      for (var i = 0; i < 4; i++) {
        c.select(i < 3 ? 'b' : 'a');
        c.confirm();
        await tester.pump(const Duration(seconds: 2));
      }
      await c.recordSaved;
      final run = recorder.records.last;
      expect(run.status, 'completed');
      expect(run.score, 3);
      expect(run.passed, isTrue);
      expect(run.answers, ['b', 'b', 'b', 'a']);
      expect(run.questionIds, c.session.map((q) => q.id));
      expect(run.id, c.runId);
      expect(recorder.records.where((r) => r.status == 'completed').length, 1);
      c.reset();
      expect(recorder.records.last.status, 'completed');
      c.dispose();
      await repo.updates.close();
    },
  );
  testWidgets(
    'reset preserves abandoned progress and the next run gets a distinct ID',
    (tester) async {
      final repo = LiveRepository(), recorder = Recorder();
      var index = 0;
      final c = QuizController(
        repo,
        recorder: recorder,
        runIdFactory: () => 'receipt-${++index}',
      );
      repo.updates.add(fixtures());
      c.start();
      c.select('b');
      c.confirm();
      c.reset();
      await c.recordSaved;
      expect(recorder.records.last.status, 'abandoned');
      expect(recorder.records.last.answers, ['b']);
      c.start();
      expect(c.runId, 'receipt-2');
      c.dispose();
      await repo.updates.close();
    },
  );
}
