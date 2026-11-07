import 'package:firebase_analytics/firebase_analytics.dart';

abstract interface class QuizAnalytics {
  Future<void> logEvent(String name, Map<String, Object> parameters);
}

class NoopQuizAnalytics implements QuizAnalytics {
  const NoopQuizAnalytics();
  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async {}
}

class FirebaseQuizAnalytics implements QuizAnalytics {
  FirebaseQuizAnalytics(this.analytics, {this.debugMode = false});
  final FirebaseAnalytics analytics;
  final bool debugMode;
  Future<bool>? _ready;

  Future<bool> _initialize() async {
    if (!await analytics.isSupported()) return false;
    await analytics.setAnalyticsCollectionEnabled(true);
    return true;
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async {
    try {
      if (!await (_ready ??= _initialize())) return;
      await analytics.logEvent(
        name: name,
        parameters: {
          ...parameters,
          'app_environment': debugMode ? 'development' : 'production',
          if (debugMode) 'debug_mode': 1,
        },
      );
    } catch (_) {
      _ready = null;
      rethrow;
    }
  }
}
