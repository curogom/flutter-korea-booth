import 'quiz_run.dart';

class ReportingPeriod {
  ReportingPeriod({
    required this.startsAt,
    required this.endsAt,
    this.environment = 'production',
  }) {
    if (!endsAt.isAfter(startsAt) ||
        !['production', 'development', 'emulator'].contains(environment)) {
      throw const FormatException('Invalid reporting period');
    }
  }

  static const timeZone = 'Asia/Seoul';
  static ReportingPeriod initial({String environment = 'production'}) =>
      ReportingPeriod(
        startsAt: DateTime.parse('2030-01-01T10:00:00+09:00'),
        endsAt: DateTime.parse('2030-01-01T18:00:00+09:00'),
        environment: environment,
      );
  final DateTime startsAt, endsAt;
  final String environment;

  bool contains(QuizRun run) =>
      run.environment == environment &&
      !run.startedAt.isBefore(startsAt) &&
      run.startedAt.isBefore(endsAt);

  String get key =>
      '$environment:${startsAt.toIso8601String()}:${endsAt.toIso8601String()}';

  static DateTime parseKoreanTime(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$')
        .firstMatch(text.trim());
    if (match == null) throw const FormatException('YYYY-MM-DD HH:mm');
    final parts = [for (var i = 1; i <= 5; i++) int.parse(match.group(i)!)];
    final wall = DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4]);
    if ([
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    ].indexed.any((entry) => entry.$2 != parts[entry.$1])) {
      throw const FormatException('Invalid date or time');
    }
    return wall.subtract(const Duration(hours: 9));
  }

  static String formatKoreanTime(DateTime time) {
    final wall = time.toUtc().add(const Duration(hours: 9));
    String two(int value) => '$value'.padLeft(2, '0');
    return '${wall.year}-${two(wall.month)}-${two(wall.day)} '
        '${two(wall.hour)}:${two(wall.minute)}';
  }
}
