import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../model/question.dart';

abstract interface class QuestionRepository {
  Stream<List<QuizQuestion>> watchPublished();
}

abstract interface class QuestionAdminRepository implements QuestionRepository {
  Stream<List<QuizQuestion>> watchAll();
  String newId();
  Future<void> save(QuizQuestion question);
}

Future<List<QuizQuestion>> loadSampleQuestions() async {
  final list = jsonDecode(
    await rootBundle.loadString('assets/data/questions.json'),
  ) as List;
  return list.map((value) {
    final data = Map<String, dynamic>.from(value as Map);
    return QuizQuestion.fromJson(data['id'] as String, data);
  }).toList();
}

class SampleQuestionRepository implements QuestionRepository {
  SampleQuestionRepository(this.questions);
  final List<QuizQuestion> questions;
  @override
  Stream<List<QuizQuestion>> watchPublished() =>
      Stream.value(questions.where((q) => q.active).toList());
}

class FirestoreQuestionRepository implements QuestionAdminRepository {
  FirestoreQuestionRepository(this.firestore);
  final FirebaseFirestore firestore;
  bool fromCache = false;
  CollectionReference<Map<String, dynamic>> get collection =>
      firestore.collection('questions');
  List<QuizQuestion> _decode(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final questions = snapshot.docs
        .map((doc) => QuizQuestion.fromJson(doc.id, doc.data()))
        .toList();
    questions.sort((a, b) => a.order.compareTo(b.order));
    return questions;
  }

  @override
  Stream<List<QuizQuestion>> watchPublished() => collection
      .where('active', isEqualTo: true)
      .snapshots(includeMetadataChanges: true)
      .where(
        (snapshot) =>
            !snapshot.metadata.isFromCache || snapshot.docs.isNotEmpty,
      )
      .map((snapshot) {
        fromCache = snapshot.metadata.isFromCache;
        return _decode(snapshot);
      });
  @override
  Stream<List<QuizQuestion>> watchAll() => collection.snapshots().map(_decode);
  @override
  String newId() => collection.doc().id;
  @override
  Future<void> save(QuizQuestion question) => collection.doc(question.id).set({
    ...question.toJson(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
