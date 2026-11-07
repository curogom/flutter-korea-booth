import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/quiz_run.dart';
import '../model/reporting_period.dart';
import 'run_sync_failure.dart';

abstract interface class RunRemoteRepository {
  Future<void> saveRun(QuizRun run);
  Stream<List<QuizRun>> watchRecent(String environment);
}

abstract interface class RunRangeRemoteRepository
    implements RunRemoteRepository {
  Stream<List<QuizRun>> watchPeriod(ReportingPeriod period);
}

class FirestoreRunRepository implements RunRangeRemoteRepository {
  FirestoreRunRepository(this.firestore)
    : _auth = FirebaseAuth.instanceFor(app: firestore.app);
  final FirebaseFirestore firestore;
  final FirebaseAuth _auth;
  CollectionReference<Map<String, dynamic>> get _runs =>
      firestore.collection('booth_runs');
  @override
  Future<void> saveRun(QuizRun run) async {
    try {
      final user = _auth.currentUser;
      if (user == null ||
          (await user.getIdTokenResult()).claims?['quizAdmin'] != true) {
        throw const RunSyncFailure(
          RunSyncFailureKind.authentication,
          'host-sign-in-required',
        );
      }
      RunSyncFailure? rejected;
      await firestore.runTransaction((transaction) async {
        rejected = null;
        final ref = _runs.doc(run.id);
        final existing = await transaction.get(ref);
        if (existing.exists) {
          final data = existing.data()!;
          if (data['version'] is! int) {
            rejected = const RunSyncFailure(
              RunSyncFailureKind.record,
              'invalid-server-record',
            );
            return;
          }
          if ((data['version'] as int) >= run.version) return;
          if (data['status'] != 'started') {
            rejected = const RunSyncFailure(
              RunSyncFailureKind.record,
              'terminal-record-conflict',
            );
            return;
          }
        }
        final data = run.toJson()..remove('id');
        data['startedAt'] = Timestamp.fromDate(run.startedAt);
        data['finishedAt'] = run.finishedAt == null
            ? null
            : Timestamp.fromDate(run.finishedAt!);
        data['updatedAt'] = FieldValue.serverTimestamp();
        transaction.set(ref, data, SetOptions(merge: true));
      });
      // Raise outside the SDK callback so web JS error wrapping cannot change
      // a record-specific conflict into an unknown connectivity failure.
      if (rejected != null) throw rejected!;
    } on FirebaseException catch (error) {
      final kind = switch (error.code) {
        'unauthenticated' ||
        'user-token-expired' ||
        'invalid-user-token' ||
        'user-disabled' => RunSyncFailureKind.authentication,
        'permission-denied' ||
        'invalid-argument' ||
        'out-of-range' => RunSyncFailureKind.record,
        _ => RunSyncFailureKind.retryable,
      };
      throw RunSyncFailure(kind, error.code);
    }
  }

  @override
  Stream<List<QuizRun>> watchRecent(String environment) => _runs
      .where('environment', isEqualTo: environment)
      .orderBy('startedAt', descending: true)
      .limit(500)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          for (final field in ['startedAt', 'finishedAt']) {
            if (data[field] is Timestamp) {
              data[field] = (data[field] as Timestamp)
                  .toDate()
                  .toUtc()
                  .toIso8601String();
            }
          }
          return QuizRun.fromJson({'id': doc.id, ...data});
        }).toList(),
      );

  @override
  Stream<List<QuizRun>> watchPeriod(ReportingPeriod period) => _runs
      .where('environment', isEqualTo: period.environment)
      .where(
        'startedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(period.startsAt),
      )
      .where('startedAt', isLessThan: Timestamp.fromDate(period.endsAt))
      .orderBy('startedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          for (final field in ['startedAt', 'finishedAt']) {
            if (data[field] is Timestamp) {
              data[field] = (data[field] as Timestamp)
                  .toDate()
                  .toUtc()
                  .toIso8601String();
            }
          }
          return QuizRun.fromJson({'id': doc.id, ...data});
        }).toList(),
      );
}
