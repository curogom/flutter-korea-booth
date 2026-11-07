import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/data/question_repository.dart';
import 'package:flutter_korea_booth/l10n/generated/app_localizations.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/ui/admin_page.dart';

import 'quiz_controller_test.dart' show fixtures;

class EditorRepository implements QuestionAdminRepository {
  int saveCalls = 0;
  bool failNextSave = false;
  final saved = <QuizQuestion>[];
  @override
  String newId() => 'generated-draft-id';
  @override
  Stream<List<QuizQuestion>> watchPublished() => Stream.value([]);
  @override
  Stream<List<QuizQuestion>> watchAll() => Stream.value(saved);
  @override
  Future<void> save(QuizQuestion question) async {
    saveCalls++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('network failure');
    }
    saved.add(question);
  }
}

Future<void> openEditor(
  WidgetTester tester,
  EditorRepository repo, {
  QuizQuestion? question,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    QuestionEditor(repository: repo, question: question),
              ),
            ),
            child: const Text('Open editor'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  final button = find.byKey(const Key('save-question'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> fillTranslation(WidgetTester tester, String language) async {
  for (final key in ['prompt', 'a', 'b', 'c', 'd', 'explanation']) {
    final field = find.byKey(ValueKey('question-$language-$key'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '  $language $key  ');
  }
}

void main() {
  testWidgets(
    'new questions remain drafts and require both complete translations',
    (tester) async {
      final repo = EditorRepository();
      await openEditor(tester, repo);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('publish-question')))
            .value,
        isFalse,
      );
      await fillTranslation(tester, 'ko');
      await save(tester);
      expect(repo.saveCalls, 0);
      expect(find.text('Open editor'), findsNothing);
      await fillTranslation(tester, 'en');
      await save(tester);
      expect(repo.saveCalls, 1);
      final q = repo.saved.single;
      expect(q.id, 'generated-draft-id');
      expect(q.active, isFalse);
      expect(q.correctOptionId, 'a');
      expect(q.textFor('ko').prompt, 'ko prompt');
      expect(q.textFor('en').options['d'], 'en d');
      expect(find.text('Open editor'), findsOneWidget);
    },
  );
  testWidgets('failed saves keep edits on screen and can be retried', (
    tester,
  ) async {
    final repo = EditorRepository()..failNextSave = true;
    await openEditor(tester, repo, question: fixtures().first);
    final prompt = find.byKey(const ValueKey('question-en-prompt'));
    await tester.enterText(prompt, 'Edited English prompt');
    await save(tester);
    expect(repo.saved, isEmpty);
    expect(repo.saveCalls, 1);
    expect(find.text('Edited English prompt'), findsOneWidget);
    expect(find.text('Open editor'), findsNothing);
    final context = tester.element(find.byType(QuestionEditor));
    expect(find.text(AppLocalizations.of(context).saveError), findsOneWidget);
    await save(tester);
    expect(repo.saved.single.id, fixtures().first.id);
    expect(repo.saved.single.textFor('en').prompt, 'Edited English prompt');
    expect(repo.saved.single.correctOptionId, 'b');
    expect(find.text('Open editor'), findsOneWidget);
  });
  testWidgets(
    'out of range order blocks saving without discarding translations',
    (tester) async {
      final repo = EditorRepository();
      await openEditor(tester, repo, question: fixtures().first);
      await tester.enterText(
        find.byKey(const Key('question-order')),
        '1000001',
      );
      await save(tester);
      expect(repo.saveCalls, 0);
      expect(find.text('ko original 0'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('question-order')));
      await tester.enterText(
        find.byKey(const Key('question-order')),
        '1000000',
      );
      await save(tester);
      expect(repo.saved.single.order, 1000000);
    },
  );
}
