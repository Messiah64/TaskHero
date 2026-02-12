/// ─── API KEYS TEMPLATE ────────────────────────────────────────
/// Copy this file to `api_keys.dart` in the same directory and
/// fill in your real keys. The real file is gitignored.
///
///   cp lib/config/api_keys.template.dart lib/config/api_keys.dart
///
class ApiKeys {
  static const openaiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const deepgramKey = 'YOUR_DEEPGRAM_API_KEY_HERE';
  static const firebaseProject = 'YOUR_FIREBASE_PROJECT_ID';
  static const storageBucket = '$firebaseProject.firebasestorage.app';
}
