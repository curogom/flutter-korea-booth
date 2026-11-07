import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../analytics/quiz_analytics.dart';
import '../data/question_repository.dart';
import '../model/question.dart';
import '../model/quiz_run.dart';
import '../storage/question_cache.dart';

enum QuizPhase { home, question, reveal, result }

class QuizController extends ChangeNotifier {
  QuizController(
    this._repository, {
    Random? random,
    this._analytics = const NoopQuizAnalytics(),
    this._language = 'ko',
    this._recorder = const NoopRunRecorder(),
    this._environment = 'development',
    String Function()? runIdFactory,
  }) : _random = random ?? Random(),
       _runIdFactory = runIdFactory ?? _newRunId {
    if (_repository is CachedQuestionRepository) {
      (_repository).addListener(_cacheChanged);
    }
    _listen();
  }
  void _cacheChanged() {
    if (!_disposed) notifyListeners();
  }

  bool get usingSavedQuestions =>
      _repository is CachedQuestionRepository && (_repository).usingSavedPack;
  bool get hasCatalogSyncError =>
      _repository is CachedQuestionRepository &&
      (_repository).syncError != null;
  String get catalogRevision => _repository is CachedQuestionRepository
      ? ((_repository).pack?.revision ?? '')
      : '';

  void _listen() {
    final generation = ++_generation;
    _subscription = _repository.watchPublished().listen(
      (questions) {
        if (_disposed || generation != _generation) return;
        _catalog = List.unmodifiable(questions);
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (Object value) {
        if (_disposed || generation != _generation) return;
        loading = false;
        error = value;
        notifyListeners();
      },
      onDone: () {
        if (_disposed || generation != _generation || !loading) return;
        loading = false;
        error = StateError('Question stream closed before loading');
        notifyListeners();
      },
    );
  }

  static const sessionLength = 4;
  static const passingScore = 3;
  static const revealDuration = Duration(seconds: 2);
  static String _newRunId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  final QuizRunRecorder _recorder;
  final String _environment;
  DateTime? _startedAt;
  int _recordVersion = 0;
  String _sessionRevision = '';
  Future<void> _recordSaved = Future.value();
  Future<void> get recordSaved => _recordSaved;
  Object? recordingError;
  String? get runId => _runId;
  final QuizAnalytics _analytics;
  final String Function() _runIdFactory;
  String _language;
  String? _runId;
  final _runTime = Stopwatch(), _responseTime = Stopwatch();
  final Random _random;
  final QuestionRepository _repository;
  late StreamSubscription<List<QuizQuestion>> _subscription;
  bool _disposed = false;
  int _generation = 0;
  List<QuizQuestion> _catalog = [];
  List<QuizQuestion> _session = [];
  final List<String> _answers = [];
  Timer? _timer;
  bool _foreground = true;
  bool get isForeground => _foreground;
  int revealRevision = 0;
  bool loading = true;
  Object? error;
  QuizPhase phase = QuizPhase.home;
  int round = 0;
  String? selection;
  bool get canStart =>
      !loading && error == null && _catalog.length >= sessionLength;
  QuizQuestion get current => _session[round];
  List<String> get answers => List.unmodifiable(_answers);
  List<QuizQuestion> get session => List.unmodifiable(_session);
  int get score => _answers.indexed
      .where((entry) => entry.$2 == _session[entry.$1].correctOptionId)
      .length;
  bool get passed => score >= passingScore;
  bool get isCorrect =>
      phase == QuizPhase.reveal && selection == current.correctOptionId;

  void _record(String status) {
    if (_runId == null || _startedAt == null) return;
    final run = QuizRun(
      id: _runId!,
      environment: _environment,
      startedAt: _startedAt!,
      language: _language,
      status: status,
      questionIds: _session.map((q) => q.id).toList(),
      correctAnswers: _session.map((q) => q.correctOptionId).toList(),
      answers: List.of(_answers),
      version: ++_recordVersion,
      durationMs: _runTime.elapsedMilliseconds,
      finishedAt: status == 'started' ? null : DateTime.now().toUtc(),
      catalogRevision: _sessionRevision,
    );
    _recordSaved = Future<void>.sync(() => _recorder.saveRun(run))
        .catchError((Object error) {
          if (!_disposed && _runId == run.id) {
            recordingError = error;
            notifyListeners();
          }
        });
  }

  void _track(String name, Map<String, Object> values) {
    final id = _runId;
    if (id == null) return;
    final parameters = <String, Object>{
      'quiz_run_id': id,
      'language': _language,
      'booth_id': 'flutter_korea_2026',
      ...values,
    };
    // Analytics must never delay an answer, the two-second timer, or recovery.
    unawaited(
      Future<void>.sync(() => _analytics.logEvent(name, parameters))
          .catchError((Object error) {
            debugPrint('Analytics event failed: $name');
          }),
    );
  }

  void setLanguage(String language) {
    if (!['ko', 'en'].contains(language) || language == _language) return;
    final previous = _language;
    _language = language;
    if (phase == QuizPhase.question || phase == QuizPhase.reveal) {
      _track('quiz_language_changed', {'previous_language': previous});
    }
  }

  void _abandon(String reason) {
    if (phase == QuizPhase.question || phase == QuizPhase.reveal) {
      _record('abandoned');
      _track('quiz_abandon', {
        'answered_count': _answers.length,
        'duration_ms': _runTime.elapsedMilliseconds,
        'reason': reason,
      });
    }
    _runTime.stop();
    _responseTime.stop();
    _runId = null;
  }

  void retry() {
    if (_disposed || phase != QuizPhase.home || loading) return;
    unawaited(_subscription.cancel());
    loading = true;
    error = null;
    _listen();
    notifyListeners();
  }

  void start() {
    if (!_foreground || phase != QuizPhase.home || !canStart) return;
    _timer?.cancel();
    // Freeze an immutable question snapshot; live edits apply to the next player.
    _session = List<QuizQuestion>.of(_catalog)..shuffle(_random);
    _session = List.unmodifiable(_session.take(sessionLength));
    _answers.clear();
    round = 0;
    selection = null;
    phase = QuizPhase.question;
    _runId = _runIdFactory();
    _startedAt = DateTime.now().toUtc();
    _recordVersion = 0;
    recordingError = null;
    _sessionRevision = catalogRevision;
    _runTime
      ..reset()
      ..start();
    _responseTime
      ..reset()
      ..start();
    _record('started');
    _track('quiz_start', {'question_count': sessionLength});
    notifyListeners();
  }

  void select(String id) {
    if (!_foreground ||
        phase != QuizPhase.question ||
        !optionIds.contains(id)) {
      return;
    }
    selection = id;
    notifyListeners();
  }

  void confirm() {
    if (!_foreground || phase != QuizPhase.question || selection == null) {
      return;
    }
    _answers.add(selection!);
    _record('started');
    _responseTime.stop();
    _track('question_answered', {
      'question_id': current.id,
      'question_position': round + 1,
      'selected_option': selection!,
      'is_correct': selection == current.correctOptionId ? 1 : 0,
      'response_ms': _responseTime.elapsedMilliseconds,
    });
    phase = QuizPhase.reveal;
    revealRevision++;
    notifyListeners();
    _scheduleReveal();
  }

  void setForeground(bool foreground) {
    if (_disposed || foreground == _foreground) return;
    _foreground = foreground;
    _timer?.cancel();
    if (foreground && phase == QuizPhase.reveal) {
      // After an interruption, show the explanation for a full two seconds.
      // Answers and analytics have already been recorded, so never confirm again.
      revealRevision++;
      _scheduleReveal();
    }
    notifyListeners();
  }

  void _scheduleReveal() {
    _timer?.cancel();
    _timer = Timer(revealDuration, () {
      if (_disposed || !_foreground || phase != QuizPhase.reveal) return;
      if (round == sessionLength - 1) {
        phase = QuizPhase.result;
        _runTime.stop();
        _record('completed');
        _track('quiz_complete', {
          'score': score,
          'passed': passed ? 1 : 0,
          'question_count': sessionLength,
          'duration_ms': _runTime.elapsedMilliseconds,
        });
      } else {
        round++;
        selection = null;
        phase = QuizPhase.question;
        _responseTime
          ..reset()
          ..start();
      }
      notifyListeners();
    });
  }

  void reset() {
    _abandon('reset');
    _timer?.cancel();
    _answers.clear();
    selection = null;
    round = 0;
    phase = QuizPhase.home;
    notifyListeners();
  }

  @override
  void dispose() {
    _abandon('dispose');
    _disposed = true;
    if (_repository is CachedQuestionRepository) {
      (_repository).removeListener(_cacheChanged);
    }
    _timer?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
