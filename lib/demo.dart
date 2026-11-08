// Public static demo entrypoint: no Firebase initialization or preferences.
import 'package:flutter/material.dart';

import 'data/question_repository.dart';
import 'main.dart' show BoothApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  runApp(BoothApp(
    repository: SampleQuestionRepository(await loadSampleQuestions()),
    initialLocale: Locale(device == 'ko' ? 'ko' : 'en'),
  ));
}
