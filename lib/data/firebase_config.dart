import 'firebase_web_setup.dart';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );
  static const enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS');
  static const analyticsDebugMode = bool.fromEnvironment(
    'ANALYTICS_DEBUG_MODE',
  );
  static String get environment => emulator
      ? 'emulator'
      : analyticsDebugMode
      ? 'development'
      : 'production';
  static const emulator = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  static bool get configured =>
      emulator || [projectId, apiKey, appId, senderId].any((v) => v.isNotEmpty);
  static Future<void> initialize() async {
    if (!emulator &&
        [projectId, apiKey, appId, senderId].any((v) => v.isEmpty)) {
      throw StateError('Incomplete Firebase configuration');
    }
    await prepareFirebaseWeb();
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: emulator ? 'demo-api-key' : apiKey,
        appId: emulator ? '1:123456789:web:demoquiz' : appId,
        messagingSenderId: emulator ? '123456789' : senderId,
        measurementId: !emulator && measurementId.isNotEmpty
            ? measurementId
            : null,
        projectId: emulator ? 'demo-quiz' : projectId,
        authDomain: emulator
            ? 'demo-quiz.firebaseapp.com'
            : authDomain.isEmpty
            ? '$projectId.firebaseapp.com'
            : authDomain,
      ),
    );
    if (emulator) {
      // Restore persisted Auth sessions against the emulator before Firestore
      // starts requesting tokens for its listeners.
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    }
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.NONE);
    }
    await FirebaseAuth.instance.signOut();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    if (emulator) {
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    }
  }
}
