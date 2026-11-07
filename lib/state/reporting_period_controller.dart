import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/reporting_period_repository.dart';
import '../model/reporting_period.dart';

class ReportingPeriodController extends ChangeNotifier {
  ReportingPeriodController(this.repository, {ReportingPeriod? initial})
    : period = initial ?? ReportingPeriod.initial();
  final ReportingPeriodRepository repository;
  ReportingPeriod period;
  bool allTime = false;
  Object? error;
  StreamSubscription<ReportingPeriod>? _subscription;
  bool _disposed = false;

  ReportingPeriod? get activePeriod => allTime ? null : period;
  String get key => '${period.key}:$allTime';

  void start() {
    _subscription ??= repository.watch().listen(
      (value) {
        if (_disposed) return;
        period = value;
        error = null;
        notifyListeners();
      },
      onError: (Object value) {
        if (_disposed) return;
        error = value;
        notifyListeners();
      },
    );
  }

  void showAllTime(bool value) {
    allTime = value;
    notifyListeners();
  }

  Future<void> save(ReportingPeriod value) async {
    await repository.save(value);
    if (_disposed) return;
    period = value;
    allTime = false;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
