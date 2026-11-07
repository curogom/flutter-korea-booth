import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';

import 'dart:convert';

import 'storage/local_database.dart';
import 'storage/booth_session.dart';
import 'storage/question_cache.dart';
import 'storage/run_ledger.dart';
import 'model/quiz_run.dart';

import 'analytics/quiz_analytics.dart';
import 'data/admin_sign_in.dart';
import 'data/firebase_config.dart';
import 'data/question_repository.dart';
import 'data/reporting_period_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'state/quiz_controller.dart';
import 'ui/admin_page.dart';
import 'ui/admin_session_boundary.dart';
import 'ui/quiz_page.dart';
import 'ui/visuals.dart';
import 'ui/booth_session_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final saved = preferences.getString('language');
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final language = ['ko', 'en'].contains(saved)
      ? saved!
      : device == 'ko'
      ? 'ko'
      : 'en';
  QuestionRepository repository;
  if (FirebaseConfig.configured) {
    final namespace =
        '${FirebaseConfig.emulator ? 'demo-quiz' : FirebaseConfig.projectId}-${FirebaseConfig.environment}';
    final session = await acquireBoothSession('booth-$namespace');
    if (session != BoothSessionStatus.acquired) {
      runApp(
        BoothSessionGate(
          status: session,
          locale: Locale(language),
          onRetry: main,
        ),
      );
      return;
    }
    try {
      await FirebaseConfig.initialize();
      final database = await openBoothDatabase(
        'booth-${sha256.convert(utf8.encode(namespace)).toString().substring(0, 16)}',
      );
      repository = CachedQuestionRepository(
        FirestoreQuestionRepository(FirebaseFirestore.instance),
        DatabaseQuestionPackStore(database),
      );
    } catch (error) {
      releaseBoothSession();
      debugPrint('Firebase initialization failed: $error');
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'Firebase 설정을 확인해주세요.\nPlease check the Firebase configuration.',
              ),
            ),
          ),
        ),
      );
      return;
    }
  } else {
    repository = SampleQuestionRepository(await loadSampleQuestions());
  }
  runApp(
    BoothApp(
      repository: repository,
      reportingRepository: FirebaseConfig.configured
          ? FirestoreReportingPeriodRepository(FirebaseFirestore.instance)
          : null,
      initialLocale: Locale(language),
      onLocaleChanged: (locale) async {
        await preferences.setString('language', locale.languageCode);
      },
    ),
  );
}

class BoothApp extends StatefulWidget {
  const BoothApp({
    super.key,
    required this.repository,
    this.analytics = const NoopQuizAnalytics(),
    this.reportingRepository,
    this.ledger,
    this.initialLocale = const Locale('ko'),
    this.onLocaleChanged,
  });
  final QuestionRepository repository;
  final QuizAnalytics analytics;
  final ReportingPeriodRepository? reportingRepository;
  final RunLedger? ledger;
  final Locale initialLocale;
  final Future<void> Function(Locale)? onLocaleChanged;
  @override
  State<BoothApp> createState() => _BoothAppState();
}

class _BoothAppState extends State<BoothApp> {
  late final QuizController _quiz = QuizController(
    widget.repository,
    analytics: widget.analytics,
    recorder: widget.ledger ?? const NoopRunRecorder(),
    environment: FirebaseConfig.environment,
    language: widget.initialLocale.languageCode,
  );
  late Locale _locale = widget.initialLocale;
  @override
  void dispose() {
    _quiz.dispose();
    super.dispose();
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    _quiz.setLanguage(locale.languageCode);
    widget.onLocaleChanged?.call(locale);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: _locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: ThemeData(
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: navy,
      ),
    ),
    home: QuizPage(
      controller: _quiz,
      locale: _locale,
      onLocaleChanged: _setLocale,
      sampleMode: widget.repository is SampleQuestionRepository,
    ),
    routes: {
      '/admin': (_) => AdminSessionBoundary(
        clearSession: FirebaseConfig.configured
            ? () => clearAdminSession(FirebaseAuth.instance.signOut)
            : () => clearAdminSession(() async {}),
        child: AdminPage(
          repository: widget.repository is QuestionAdminRepository
              ? widget.repository as QuestionAdminRepository
              : null,
          ledger: widget.ledger,
          reportingRepository: widget.reportingRepository,
        ),
      ),
    },
  );
}
