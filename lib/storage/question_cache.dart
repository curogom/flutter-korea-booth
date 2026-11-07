import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../data/question_repository.dart';
import '../model/question.dart';

class QuestionPack {
  QuestionPack(List<QuizQuestion> values, this.savedAt)
    : questions = List.unmodifiable(values) {
    if (questions.any((q) => !q.active || q.id.isEmpty) ||
        questions.map((q) => q.id).toSet().length != questions.length) {
      throw const FormatException('Invalid published catalog');
    }
  }
  final List<QuizQuestion> questions;
  final DateTime savedAt;
  List<Map<String, dynamic>> get _data =>
      questions.map((q) => {'id': q.id, ...q.toJson()}).toList()
        ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  String get revision =>
      sha256.convert(utf8.encode(jsonEncode(_data))).toString();
  Map<String, Object?> toJson() => {
    'schema': 1,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'revision': revision,
    'questions': _data,
  };
  factory QuestionPack.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1) {
      throw const FormatException('Unknown question pack');
    }
    final values = (json['questions'] as List).map((value) {
      final data = Map<String, dynamic>.from(value as Map);
      return QuizQuestion.fromJson(data['id'] as String, data);
    }).toList()..sort((a, b) => a.order.compareTo(b.order));
    final pack = QuestionPack(
      values,
      DateTime.parse(json['savedAt'] as String),
    );
    if (pack.revision != json['revision']) {
      throw const FormatException('Question pack checksum mismatch');
    }
    return pack;
  }
}

abstract interface class QuestionPackStore {
  Future<QuestionPack?> readPack();
  Future<void> writePack(QuestionPack pack);
}

class DatabaseQuestionPackStore implements QuestionPackStore {
  DatabaseQuestionPackStore(this.database);
  final Database database;
  final _record = stringMapStoreFactory.store('catalog').record('published');
  @override
  Future<QuestionPack?> readPack() async {
    final data = await _record.get(database);
    return data == null ? null : QuestionPack.fromJson(data);
  }

  @override
  Future<void> writePack(QuestionPack pack) async {
    await _record.put(database, pack.toJson());
  }
}

class CachedQuestionRepository extends ChangeNotifier
    implements QuestionAdminRepository {
  CachedQuestionRepository(this.remote, this.store);
  final QuestionAdminRepository remote;
  final QuestionPackStore store;
  bool usingSavedPack = false;
  QuestionPack? pack;
  Object? syncError, storageError;
  bool _disposed = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  Stream<List<QuizQuestion>> watchPublished() => Stream.multi((output) {
    StreamSubscription<List<QuizQuestion>>? subscription;
    var cancelled = false;
    Future<void> serial = Future.value();
    Timer? firstResponse;
    void fail(Object error) {
      if (cancelled) return;
      syncError = error;
      usingSavedPack = pack != null;
      _changed();
      if (pack == null) output.addError(error);
    }

    output.onCancel = () {
      cancelled = true;
      firstResponse?.cancel();
      return subscription?.cancel();
    };
    Future<void> initialize() async {
      try {
        final cached = await store.readPack();
        if (cancelled) return;
        if (cached != null) {
          pack = cached;
          usingSavedPack = true;
          _changed();
          output.add(cached.questions);
        }
      } catch (error) {
        storageError = error;
        _changed();
      }
      if (cancelled) return;
      firstResponse = Timer(
        const Duration(seconds: 8),
        () => fail(TimeoutException('No question catalog response')),
      );
      subscription = remote.watchPublished().listen(
        (questions) {
          firstResponse?.cancel();
          serial = serial.then((_) async {
            if (cancelled) return;
            try {
              final next = QuestionPack(questions, DateTime.now().toUtc());
              try {
                await store.writePack(next);
                storageError = null;
              } catch (error) {
                storageError = error;
              }
              if (cancelled) return;
              pack = next;
              syncError = null;
              usingSavedPack =
                  remote is FirestoreQuestionRepository &&
                  (remote as FirestoreQuestionRepository).fromCache;
              _changed();
              output.add(next.questions);
            } catch (error) {
              fail(error);
            }
          });
        },
        onError: (Object error) {
          serial = serial.then((_) {
            fail(error);
          });
        },
      );
    }

    unawaited(initialize());
  });
  @override
  Stream<List<QuizQuestion>> watchAll() => remote.watchAll();
  @override
  String newId() => remote.newId();
  @override
  Future<void> save(QuizQuestion question) => remote.save(question);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
