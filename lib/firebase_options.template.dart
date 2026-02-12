import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// ─── FIREBASE OPTIONS TEMPLATE ────────────────────────────────
/// Copy this file to `firebase_options.dart` (same directory) and
/// fill in your real Firebase config values.
///
///   cp lib/firebase_options.template.dart lib/firebase_options.dart
///
/// You can find these values in the Firebase Console:
///   Project Settings → General → Your apps → Web app → Config
///
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
    measurementId: 'YOUR_MEASUREMENT_ID',
  );
}
