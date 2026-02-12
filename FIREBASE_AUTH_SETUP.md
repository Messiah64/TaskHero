# 🔥 Firebase Authentication Setup

> **Last Updated**: February 12, 2026

This guide covers setting up Google Sign-In authentication for TaskHero from scratch. If you're cloning this project or setting up a new Firebase project, follow these steps.

---

## Prerequisites

- A [Firebase project](https://console.firebase.google.com) (current: `health-is-wealth-b91b2`)
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase CLI logged in (`firebase login`)

---

## Step 1: Enable Google Sign-In Provider

1. Go to [Firebase Console → Authentication → Sign-in method](https://console.firebase.google.com/project/health-is-wealth-b91b2/authentication/providers)
2. Click **"Google"** in the providers list
3. Toggle **"Enable"** to ON
4. Enter your **support email** (e.g., your SUTD email)
5. Click **"Save"**

---

## Step 2: Get Web Client ID

After enabling Google Sign-In:

1. Click on the **Google** provider you just enabled
2. Look for the **"Web SDK configuration"** section
3. Copy the **Web client ID** (format: `563584335869-xxxxx.apps.googleusercontent.com`)
4. Update `lib/services/auth_service.dart`:

```dart
final GoogleAuthProvider _googleProvider = GoogleAuthProvider()
  ..setCustomParameters({'prompt': 'select_account'})
  ..addScope('email')
  ..addScope('profile');

// The Web client ID is configured automatically via Firebase
// If you need to set it explicitly, add it to GoogleAuthProvider
```

---

## Step 3: Configure Firebase Web App

1. Go to [Project Settings → General](https://console.firebase.google.com/project/health-is-wealth-b91b2/settings/general)
2. Scroll to **"Your apps"** section
3. If no web app exists, click **"Add app"** → choose Web (`</>`)
4. Copy the Firebase config values
5. Update `lib/firebase_options.dart` with:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'health-is-wealth-b91b2',
  authDomain: 'health-is-wealth-b91b2.firebaseapp.com',
  storageBucket: 'health-is-wealth-b91b2.firebasestorage.app',
);
```

---

## Step 4: Authorize Domains

1. Go to [Authentication → Settings → Authorized domains](https://console.firebase.google.com/project/health-is-wealth-b91b2/authentication/settings)
2. Ensure these domains are listed:

| Domain | Purpose |
|--------|---------|
| `localhost` | Local development |
| `taskhero-sutd.web.app` | Production hosting |
| `taskhero-sutd.firebaseapp.com` | Alternate Firebase domain |
| `health-is-wealth-b91b2.web.app` | Legacy default domain |

If any are missing, click **"Add domain"** and add them.

---

## Step 5: Build and Deploy

```bash
# Build the web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## How Auth Works in TaskHero

### Sign-In Flow

```
Login Screen → "Sign in with Google" button
    ↓
Firebase Auth signInWithPopup(GoogleAuthProvider)
    ↓
Google OAuth popup → user selects account
    ↓
Firebase returns User object (uid, email, displayName, photoURL)
    ↓
App checks Firestore for existing user profile
    ↓
If new user → creates UserProfile document in 'users' collection
If existing → updates lastActive timestamp
    ↓
Auth state listener redirects to Dashboard
```

### Auth State Management

The app uses `FirebaseAuth.instance.authStateChanges()` stream in `main.dart`:
- **Not signed in** → Shows `LoginScreen`
- **Signed in** → Shows `AppShell` (sidebar + main content)
- **On page refresh** → Firebase automatically restores the session (no re-login needed)

### Key Files

| File | Role |
|------|------|
| `lib/services/auth_service.dart` | `AuthService` class — wraps `signInWithPopup`, `signOut`, provides `currentUser` |
| `lib/screens/login_screen.dart` | Login UI with Google Sign-In button, animations |
| `lib/firebase_options.dart` | Firebase project configuration (apiKey, appId, etc.) |
| `lib/main.dart` | Auth state listener that switches between login/app |

---

## Troubleshooting

### "This domain is not authorized"
→ Add your domain to Firebase Console → Authentication → Settings → Authorized domains

### Google Sign-In popup closes immediately / blank popup
→ Check `Cross-Origin-Embedder-Policy` header in `firebase.json` is set to `credentialless` (not `require-corp`)

### "auth/popup-blocked" error
→ The browser is blocking the popup. Try:
- Allowing popups for your domain in browser settings
- Clicking the button directly (not programmatically triggered)

### "auth/unauthorized-domain" error
→ The domain you're accessing the app from is not in the authorized domains list. Add it in Firebase Console.

### Sign-in works locally but not on deployed site
→ Make sure `taskhero-sutd.web.app` is in the authorized domains list
→ Check that `firebase_options.dart` has the correct `authDomain`

### Browser console shows `[Auth]` errors
→ The app logs auth events with `[Auth]` prefix. Open browser DevTools (F12) → Console to see detailed error messages.

---

## Firestore User Profile (Auto-Created on Sign-In)

When a user signs in for the first time, a profile document is automatically created:

```
Collection: users
Document ID: {Firebase Auth UID}
Fields:
  - displayName: string (from Google)
  - email: string (from Google)
  - photoURL: string (from Google)
  - pillar: "ISTD" (default, user can edit)
  - year: 1 (default, user can edit)
  - totalEarned: 0.0
  - thisMonthEarned: 0.0
  - tasksCompleted: 0
  - tasksPosted: 0
  - rating: 5.0
  - totalReviews: 0
  - createdAt: Timestamp
  - lastActive: Timestamp
```

---

## Related Documentation

- [SETUP_COMPLETE.md](SETUP_COMPLETE.md) — Full feature checklist and verification steps
- [URL_CHANGE_GUIDE.md](URL_CHANGE_GUIDE.md) — How to change hosting URL or add custom domains
- [Knowledge_Base.md](Knowledge_Base.md) — Complete project knowledge base
- [Data_Flow.md](Data_Flow.md) — Full data flow documentation including Firestore schema
