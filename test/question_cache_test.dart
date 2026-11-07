import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:flutter_korea_booth/data/question_repository.dart';
import 'package:flutter_korea_booth/model/question.dart';
import 'package:flutter_korea_booth/storage/question_cache.dart';

import 'quiz_controller_test.dart' show fixtures;

class CatalogRemote implements QuestionAdminRepository {
  final updates = StreamController<List<QuizQuestion>>.broadcast(sync: true);
  final listening = Completer<void>();
  @override
  Stream<List<QuizQuestion>> watchPublished() {
    if (!listening.isCompleted) listening.complete();
    return updates.stream;
  }

  @override
  Stream<List<QuizQuestion>> watchAll() => updates.stream;
  @override
  String newId() => 'new';
  @override
  Future<void> save(QuizQuestion question) async {}
}

void main() {
  test('question packs detect tampering and preserve bilingual content', () {
    final original = QuestionPack(fixtures(), DateTime.utc(2026, 11, 4));
    final restored = QuestionPack.fromJson(original.toJson());
    expect(restored.revision, original.revision);
    expect(restored.questions.first.textFor('en').prompt, startsWith('en'));
    expect(
      () => QuestionPack.fromJson({...original.toJson(), 'revision': 'wrong'}),
      throwsFormatException,
    );
    expect(
      () => QuestionPack([...fixtures(), fixtures().first], DateTime.now()),
      throwsFormatException,
    );
  });
  test(
    'saved catalog is restored before the server and later updated',
    () async {
      final db = await databaseFactoryMemory.openDatabase('cache-restore');
      final store = DatabaseQuestionPackStore(db);
      await store.writePack(QuestionPack(fixtures(), DateTime.now()));
      final remote = CatalogRemote();
      final repo = CachedQuestionRepository(remote, store);
      final stream = StreamIterator(repo.watchPublished());
      expect(await stream.moveNext(), isTrue);
      expect(repo.usingSavedPack, isTrue);
      await remote.listening.future;
      remote.updates.add(fixtures(prompt: 'new'));
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.first.textFor('ko').prompt, contains('new'));
      expect(repo.usingSavedPack, isFalse);
      expect((await store.readPack())!.revision, repo.pack!.revision);
      await stream.cancel();
      repo.dispose();
      await remote.updates.close();
      await db.close();
    },
  );
  test(
    'server errors preserve the validated pack and expose sync status',
    () async {
      final db = await databaseFactoryMemory.openDatabase('cache-offline');
      final store = DatabaseQuestionPackStore(db);
      await store.writePack(QuestionPack(fixtures(), DateTime.now()));
      final remote = CatalogRemote();
      final repo = CachedQuestionRepository(remote, store);
      final failed = Completer<void>();
      repo.addListener(() {
        if (repo.syncError != null && !failed.isCompleted) failed.complete();
      });
      final stream = StreamIterator(repo.watchPublished());
      await stream.moveNext();
      await remote.listening.future;
      remote.updates.addError(const FormatException('bad remote document'));
      await failed.future;
      expect(repo.pack!.questions.length, 4);
      expect(repo.usingSavedPack, isTrue);
      expect((await store.readPack())!.questions.length, 4);
      await stream.cancel();
      repo.dispose();
      await remote.updates.close();
      await db.close();
    },
  );
  test(
    'an explicit empty server catalog invalidates old published questions',
    () async {
      final db = await databaseFactoryMemory.openDatabase('cache-revoked');
      final store = DatabaseQuestionPackStore(db);
      await store.writePack(QuestionPack(fixtures(), DateTime.now()));
      final remote = CatalogRemote();
      final repo = CachedQuestionRepository(remote, store);
      final stream = StreamIterator(repo.watchPublished());
      await stream.moveNext();
      await remote.listening.future;
      remote.updates.add([]);
      expect(await stream.moveNext(), isTrue);
      expect(stream.current, isEmpty);
      expect((await store.readPack())!.questions, isEmpty);
      await stream.cancel();
      repo.dispose();
      await remote.updates.close();
      await db.close();
    },
  );
  test(
    'a fresh device reports failure and can recover without a bundled fallback',
    () async {
      final db = await databaseFactoryMemory.openDatabase('cache-empty');
      final remote = CatalogRemote();
      final repo = CachedQuestionRepository(
        remote,
        DatabaseQuestionPackStore(db),
      );
      final failed = Completer<void>(),
          received = Completer<List<QuizQuestion>>();
      final subscription = repo.watchPublished().listen(
        (questions) {
          if (!received.isCompleted) received.complete(questions);
        },
        onError: (Object error) {
          if (!failed.isCompleted) failed.complete();
        },
      );
      await remote.listening.future;
      remote.updates.addError(StateError('offline'));
      await failed.future;
      expect(repo.pack, isNull);
      remote.updates.add(fixtures());
      expect((await received.future).length, 4);
      await subscription.cancel();
      repo.dispose();
      await remote.updates.close();
      await db.close();
    },
  );
  test('catalog survives closing and reopening its database', () async {
    const name = 'cache-reopen';
    var db = await databaseFactoryMemory.openDatabase(name);
    await DatabaseQuestionPackStore(db)
        .writePack(QuestionPack(fixtures(), DateTime.now()));
    await db.close();
    db = await databaseFactoryMemory.openDatabase(name);
    expect(
      (await DatabaseQuestionPackStore(db).readPack())!.questions.length,
      4,
    );
    await db.close();
  });
}
