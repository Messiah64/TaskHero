import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google (Web-optimized)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('[Auth] Starting Google Sign-In with popup...');
      print('[Auth] Current domain: ${Uri.base.host}');
      
      // Create Google provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Optional: Add custom parameters
      googleProvider.setCustomParameters({
        'prompt': 'select_account',  // Always show account selection
      });

      print('[Auth] Calling signInWithPopup...');
      
      // Sign in with popup
      final UserCredential userCredential = 
          await _auth.signInWithPopup(googleProvider);

      print('[Auth] Successfully signed in: ${userCredential.user?.email}');
      print('[Auth] User ID: ${userCredential.user?.uid}');
      
      // Create or update user profile in Firestore
      if (userCredential.user != null) {
        try {
          await _firestoreService.createOrUpdateUserProfile(userCredential.user!);
        } catch (e) {
          print('[Auth] Warning: Failed to create/update profile, but sign-in succeeded. Error: $e');
          // We continue anyway so the user can use the app
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[Auth] FirebaseAuthException: ${e.code} - ${e.message}');
      
      if (e.code == 'popup-closed-by-user') {
        print('[Auth] User closed the popup');
      } else if (e.code == 'popup-blocked') {
        print('[Auth] Popup was blocked by browser');
      }
      
      return null;
    } catch (e, stackTrace) {
      print('[Auth] ERROR: $e');
      print('[Auth] Stack trace: $stackTrace');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('[Auth] User signed out');
    } catch (e) {
      print('[Auth] Sign out error: $e');
    }
  }
}
