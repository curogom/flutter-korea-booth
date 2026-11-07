import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/reporting_period.dart';

abstract interface class ReportingPeriodRepository {
  Stream<ReportingPeriod> watch();
  Future<void> save(ReportingPeriod period);
}

class FirestoreReportingPeriodRepository implements ReportingPeriodRepository {
  FirestoreReportingPeriodRepository(FirebaseFirestore firestore)
    : _document = firestore.doc('event_settings/reporting');
  final DocumentReference<Map<String, dynamic>> _document;

  @override
  Stream<ReportingPeriod> watch() => _document.snapshots().map((snapshot) {
    final data = snapshot.data();
    if (data == null) return ReportingPeriod.initial();
    if (data['timeZone'] != ReportingPeriod.timeZone ||
        data['environment'] is! String ||
        data['startsAt'] is! Timestamp ||
        data['endsAt'] is! Timestamp) {
      throw const FormatException('Invalid reporting settings');
    }
    return ReportingPeriod(
      startsAt: (data['startsAt'] as Timestamp).toDate(),
      endsAt: (data['endsAt'] as Timestamp).toDate(),
      environment: data['environment'] as String,
    );
  });

  @override
  Future<void> save(ReportingPeriod period) =>
      _document.firestore.runTransaction((transaction) async {
        // Require an online commit; do not queue a scope change indefinitely offline.
        await transaction.get(_document);
        transaction.set(_document, {
          'timeZone': ReportingPeriod.timeZone,
          'environment': period.environment,
          'startsAt': Timestamp.fromDate(period.startsAt),
          'endsAt': Timestamp.fromDate(period.endsAt),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
}
