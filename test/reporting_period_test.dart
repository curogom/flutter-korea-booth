import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_korea_booth/data/reporting_period_repository.dart';
import 'package:flutter_korea_booth/model/reporting_period.dart';
import 'package:flutter_korea_booth/model/quiz_run.dart';
import 'package:flutter_korea_booth/state/reporting_period_controller.dart';

import 'question_accuracy_test.dart' show accuracyRun;

class PeriodRepository implements ReportingPeriodRepository {
  final updates = StreamController<ReportingPeriod>.broadcast(sync: true);
  ReportingPeriod? saved;
  bool fail = false;
  @override
  Stream<ReportingPeriod> watch() => updates.stream;
  @override
  Future<void> save(ReportingPeriod value) async {
    if (fail) throw StateError('offline');
    saved = value;
  }
}

void main() {
  test('KST conversion is explicit and independent of the host time zone', () {
    final period = ReportingPeriod.initial();
    expect(period.startsAt, DateTime.utc(2030, 1, 1, 1));
    expect(period.endsAt, DateTime.utc(2030, 1, 1, 9));
    expect(
      ReportingPeriod.parseKoreanTime('2030-01-01 10:00'),
      period.startsAt,
    );
    expect(ReportingPeriod.formatKoreanTime(period.endsAt), '2030-01-01 18:00');
    for (final input in [
      '2026-02-30 10:00',
      '2030-01-01 24:00',
      '2026-13-01 10:00',
      '2030-01-01 10:60',
      '11/07 10:00',
    ]) {
      expect(
        () => ReportingPeriod.parseKoreanTime(input),
        throwsFormatException,
      );
    }
  });
  test('a reporting cohort includes the start, excludes the end and filters environment', () {
    final period = ReportingPeriod.initial();
    final base = accuracyRun('sample', [
      'b',
    ], environment: 'production').toJson();
    for (final (time, environment, expected) in [
      (
        period.startsAt.subtract(const Duration(milliseconds: 1)),
        'production',
        false,
      ),
      (period.startsAt, 'production', true),
      (
        period.endsAt.subtract(const Duration(milliseconds: 1)),
        'production',
        true,
      ),
      (period.endsAt, 'production', false),
      (period.startsAt, 'development', false),
    ]) {
      final run = accuracyRun('sample', ['b'], environment: environment);
      final shifted = {
        ...base,
        ...run.toJson(),
        'startedAt': time.toIso8601String(),
      };
      expect(period.contains(QuizRun.fromJson(shifted)), expected);
    }
    expect(
      () => ReportingPeriod(startsAt: period.endsAt, endsAt: period.startsAt),
      throwsFormatException,
    );
  });
  test(
    'live updates replace the period; errors retain the last valid setting',
    () async {
      final repository = PeriodRepository();
      final controller = ReportingPeriodController(repository)..start();
      final changed = ReportingPeriod(
        startsAt: DateTime.utc(2030, 1, 1),
        endsAt: DateTime.utc(2030, 1, 1, 10),
        environment: 'development',
      );
      repository.updates.add(changed);
      expect(controller.period, same(changed));
      repository.updates.addError(StateError('offline'));
      expect(controller.period, same(changed));
      expect(controller.error, isNotNull);
      controller.showAllTime(true);
      expect(controller.activePeriod, isNull);
      repository.fail = true;
      await expectLater(
        controller.save(ReportingPeriod.initial()),
        throwsStateError,
      );
      expect(controller.period, same(changed));
      repository.fail = false;
      await controller.save(ReportingPeriod.initial());
      expect(controller.activePeriod, isNotNull);
      expect(controller.error, isNull);
      controller.dispose();
      await repository.updates.close();
    },
  );
}
