# TaskHero - Data Flow & User Scenarios

> **Last Updated**: February 12, 2026
> **Platform**: Flutter Web
> **Live URL**: https://taskhero-sutd.web.app
> **Firebase Project**: health-is-wealth-b91b2

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Data Models](#data-models)
3. [Firestore Database Schema](#firestore-database-schema)
4. [Security Rules](#security-rules)
5. [Composite Indexes](#composite-indexes)
6. [Service Layer](#service-layer)
7. [Real-time Data Streams](#real-time-data-streams)
8. [Screen-by-Screen Data Flow](#screen-by-screen-data-flow)
9. [User Scenarios](#user-scenarios)
10. [External Integrations](#external-integrations)

---

## Architecture Overview

```
+-----------------------------------------------------------------+
|                        FLUTTER WEB APP                          |
+-----------------------------------------------------------------+
|  Screens                                                        |
|  +------------+ +----------+ +-----------+ +--------+ +-------+ |
|  |LoginScreen | |HomeScreen| |BrowseScreen| |Profile | |PostTask| |
|  +-----+------+ +----+-----+ +-----+-----+ +---+----+ +---+---+ |
|        |              |             |            |          |     |
|  +-----+--------------+-------------+------------+----------+--+ |
|  |                  TaskDetailScreen (live stream)              | |
|  +-------------------------------------------------------------+ |
+-----------------------------------------------------------------+
|                        SERVICE LAYER                            |
|  +----------+  +-----------+  +----------+  +--------+         |
|  |AuthService|  |Firestore  |  |ApiService|  | Audio  |         |
|  | (Auth)   |  | Service   |  |(OpenAI/  |  |Service |         |
|  |          |  |           |  | Deepgram)|  |        |         |
|  +----+-----+  +-----+-----+  +----+-----+  +---+----+         |
+-----------------------------------------------------------------+
|                      EXTERNAL SERVICES                          |
|  +----------+  +-----------+  +----------+  +--------+         |
|  | Firebase  |  | Firestore |  |  OpenAI  |  |Deepgram|         |
|  |   Auth    |  | Database  |  |(GPT-4o-m)|  |  STT   |         |
|  +----------+  +-----------+  +----------+  +--------+         |
+-----------------------------------------------------------------+
```

### File Structure

```
lib/
+-- main.dart                    # App entry, routing, AppShell, nav
+-- firebase_options.dart        # Firebase configuration
+-- models/
|   +-- task_model.dart          # HeroTask, TaskLocation, enums
|   +-- user_profile.dart        # UserProfile model
+-- screens/
|   +-- login_screen.dart        # Google Sign-In
|   +-- home_screen.dart         # Dashboard with stats & charts
|   +-- browse_screen.dart       # Task discovery & filtering
|   +-- post_task_screen.dart    # Voice/manual task creation
|   +-- profile_screen.dart      # User profile & task history
|   +-- task_detail_screen.dart  # Task details, progress, payment (live stream)
+-- services/
|   +-- auth_service.dart        # Firebase Auth wrapper
|   +-- firestore_service.dart   # All Firestore CRUD + streams
|   +-- api_service.dart         # OpenAI GPT-4o-mini + Deepgram STT + Storage
|   +-- audio_service.dart       # Browser MediaRecorder (WebM/Opus)
+-- widgets/
|   +-- task_card.dart           # Reusable task display card
|   +-- stat_card.dart           # Dashboard stat widget
+-- theme/
    +-- app_colors.dart          # Color palette constants
```

---

## Data Models

### UserProfile (`lib/models/user_profile.dart`)

```dart
class UserProfile {
  final String uid;              // Firebase Auth UID (document ID)
  final String email;            // User email from Google
  final String displayName;      // Full name from Google
  final String photoURL;         // Google profile photo URL
  final String pillar;           // SUTD pillar: "EPD"|"ESD"|"ISTD"|"ASD"|"DAI"
  final int year;                // Academic year (1-5)
  final double totalEarned;      // Lifetime earnings as Hero ($)
  final double thisMonthEarned;  // Current month earnings (auto-resets)
  final int tasksCompleted;      // Tasks completed as Hero
  final int tasksPosted;         // Tasks created as Poster
  final double rating;           // Average rating (1.0-5.0)
  final int totalReviews;        // Number of ratings received
  final DateTime createdAt;      // Account creation timestamp
  final DateTime lastActive;     // Last login timestamp

  // Computed
  String get initials;           // "John Tan" -> "JT"
  String get pillarYear;         // "Pillar: ISTD | Year 2"
}
```

**Default values on creation**: pillar = "ISTD", year = 1, totalEarned = 0, thisMonthEarned = 0, tasksCompleted = 0, tasksPosted = 0, rating = 5.0, totalReviews = 0

**Monthly reset**: When a user logs in and `lastActive` is in a different month/year than now, `thisMonthEarned` is reset to 0.

### HeroTask (`lib/models/task_model.dart`)

```dart
class HeroTask {
  final String? id;              // Firestore document ID (null for new unsaved tasks)
  final String title;            // Task title (often with emoji prefix)
  final String description;      // Detailed task instructions
  final TaskCategory category;   // food|academic|errands|tech|social|marketplace
  final double compensation;     // Payment amount in SGD
  final TaskStatus status;       // open|accepted|inProgress|completed|cancelled
  final TaskUrgency urgency;     // normal|urgent|emergency
  final int estimatedMinutes;    // Time estimate in minutes
  final TaskLocation pickup;     // Pickup location details
  final TaskLocation delivery;   // Delivery location details
  final String? posterId;        // UID of the task creator
  final String posterName;       // Display name of task creator
  final double posterRating;     // Creator's rating at time of posting
  final String posterAvatarUrl;  // Creator's photo URL
  final String? heroId;          // UID of the hero who accepted (null if open)
  final String? heroName;        // Display name of the hero (null if open)
  final bool pickedUp;           // Hero has picked up the item
  final bool delivered;          // Hero has delivered the item
  final DateTime createdAt;      // Task creation timestamp
  final DateTime? acceptedAt;    // When hero accepted (null if open)
  final DateTime? completedAt;   // When task was completed (null if not done)

  // Computed
  double get platformFee;        // compensation * 0.05 (5%)
  double get heroEarnings;       // compensation - platformFee (95%)
  String get timeAgo;            // "2min ago", "1h ago", "3d ago"
}
```

### TaskLocation

```dart
class TaskLocation {
  final String building;         // e.g. "Building 2"
  final String level;            // e.g. "Level 2"
  final String landmark;         // e.g. "Near Lobby C" (can be empty)

  String get short;              // "Building 2, Level 2"
  String get full;               // "Building 2, Level 2 (Near Lobby C)"
}
```

### Enums

```dart
enum TaskCategory {
  food('Food & Supplies', '....'),
  academic('Academic Help', '....'),
  errands('Campus Errands', '....'),
  tech('Tech & Making', '....'),
  social('Social & Events', '....'),
  marketplace('Marketplace', '....');
}

enum TaskStatus { open, accepted, inProgress, completed, cancelled }

enum TaskUrgency { normal, urgent, emergency }
```

---

## Firestore Database Schema

### Collection: `/users/{uid}`

| Field | Type | Description | Written By | Default |
|-------|------|-------------|-----------|---------|
| `email` | string | User email | `createOrUpdateUserProfile` | from Google |
| `displayName` | string | Full name | `createOrUpdateUserProfile` | from Google |
| `photoURL` | string | Profile photo URL | `createOrUpdateUserProfile` | from Google |
| `pillar` | string | SUTD pillar | `createOrUpdateUserProfile` / `updateUserProfile` | `"ISTD"` |
| `year` | number | Academic year (1-5) | `createOrUpdateUserProfile` / `updateUserProfile` | `1` |
| `totalEarned` | number | Lifetime hero earnings | `completeTask` (FieldValue.increment) | `0.0` |
| `thisMonthEarned` | number | Monthly hero earnings | `completeTask` / monthly reset on login | `0.0` |
| `tasksCompleted` | number | Completed as hero | `completeTask` (FieldValue.increment) | `0` |
| `tasksPosted` | number | Created as poster | `createTask` (+1) / `cancelTask` (-1) | `0` |
| `rating` | number | Average rating (1.0-5.0) | `createOrUpdateUserProfile` | `5.0` |
| `totalReviews` | number | Number of ratings | `createOrUpdateUserProfile` | `0` |
| `createdAt` | timestamp | Account creation | `createOrUpdateUserProfile` (once) | `Timestamp.now()` |
| `lastActive` | timestamp | Last login | `createOrUpdateUserProfile` (every login) | `Timestamp.now()` |

**Write operations that touch this collection:**

| Operation | Fields Modified | Triggered By |
|-----------|----------------|-------------|
| New user login | All fields (set) | `createOrUpdateUserProfile` |
| Returning user login | `lastActive`, possibly `thisMonthEarned` reset | `createOrUpdateUserProfile` |
| Edit profile | `pillar`, `year` | `updateUserProfile` |
| Post a task | `tasksPosted` (+1) | `createTask` |
| Cancel a task | `tasksPosted` (-1) | `cancelTask` |
| Complete a task | `totalEarned`, `thisMonthEarned`, `tasksCompleted` (all +increment) | `completeTask` (writes to hero's doc) |

### Collection: `/tasks/{taskId}`

| Field | Type | Description | Written By | Default |
|-------|------|-------------|-----------|---------|
| `title` | string | Task title with emoji | `createTask` | required |
| `description` | string | Detailed instructions | `createTask` | required |
| `category` | string | `"food"\|"academic"\|"errands"\|"tech"\|"social"\|"marketplace"` | `createTask` | required |
| `compensation` | number | Payment in SGD | `createTask` | required |
| `status` | string | `"open"\|"accepted"\|"inProgress"\|"completed"\|"cancelled"` | multiple methods | `"open"` |
| `urgency` | string | `"normal"\|"urgent"\|"emergency"` | `createTask` | `"normal"` |
| `estimatedMinutes` | number | Time estimate | `createTask` | required |
| `pickup` | map | `{building, level, landmark}` | `createTask` | required |
| `delivery` | map | `{building, level, landmark}` | `createTask` | required |
| `posterId` | string | UID of poster | `createTask` | `currentUserId` |
| `posterName` | string | Poster display name | `createTask` | from Auth |
| `posterRating` | number | Poster's rating at post time | `createTask` | read from user profile |
| `posterAvatarUrl` | string | Poster's photo URL | `createTask` | from Auth |
| `heroId` | string\|null | UID of hero | `acceptTask` | `null` |
| `heroName` | string\|null | Hero display name | `acceptTask` | `null` |
| `pickedUp` | boolean | Hero picked up item | `acceptTask` (init) / `updateTaskProgress` | `false` |
| `delivered` | boolean | Hero delivered item | `acceptTask` (init) / `updateTaskProgress` | `false` |
| `createdAt` | timestamp | Task creation time | `createTask` | `Timestamp.now()` |
| `acceptedAt` | timestamp\|null | When hero accepted | `acceptTask` | `null` |
| `completedAt` | timestamp\|null | When task completed | `completeTask` | `null` |

**Task status transitions and what each method writes:**

| Method | Status Change | Fields Written |
|--------|--------------|----------------|
| `createTask` | -- (new doc) | All fields, status=`"open"`, pickedUp=`false`, delivered=`false`, heroId=`null` |
| `acceptTask` | `open` -> `accepted` | status, heroId, heroName, acceptedAt, pickedUp=`false`, delivered=`false` |
| `updateTaskProgress` (pickup) | `accepted` -> `inProgress` | pickedUp=`true`, status=`"inProgress"` |
| `updateTaskProgress` (deliver) | stays `inProgress` | delivered=`true` |
| `completeTask` | `inProgress` -> `completed` | status=`"completed"`, completedAt |
| `cancelTask` | `open` -> `cancelled` | status=`"cancelled"` |

---

## Security Rules

**File**: `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read:   if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null;
      allow delete: if false;
    }

    match /tasks/{taskId} {
      allow read:   if request.auth != null;
      allow create: if request.auth != null
                     && request.resource.data.posterId == request.auth.uid
                     && request.resource.data.status == 'open';
      allow update: if request.auth != null;
      allow delete: if false;
    }
  }
}
```

**Key rules explained:**

| Collection | Operation | Rule | Reason |
|-----------|-----------|------|--------|
| users | read | any authenticated | Needed to display poster info on task cards |
| users | create | own uid only | Users can only create their own profile |
| users | update | any authenticated | `completeTask` needs to update the hero's profile (cross-user write) |
| users | delete | never | Profiles are permanent |
| tasks | read | any authenticated | All users browse all tasks |
| tasks | create | posterId must match auth uid, status must be "open" | Prevents impersonation and invalid initial status |
| tasks | update | any authenticated | Heroes update tasks they accepted; posters complete tasks they posted |
| tasks | delete | never | Tasks are never deleted, only cancelled |

**Client-side authorization guards** (in `firestore_service.dart`):
- `acceptTask`: Transaction checks `posterId != currentUserId` (can't accept own task) and `status == 'open'` (race condition protection)
- `cancelTask`: Checks `posterId == currentUserId` and `status == 'open'`
- `completeTask`: Checks caller is either `heroId` or `posterId`, and `status != 'completed'`

---

## Composite Indexes

**File**: `firestore.indexes.json` (deployed to Firebase)

| # | Collection | Fields | Used By |
|---|-----------|--------|---------|
| 1 | tasks | `status` ASC, `createdAt` DESC | `getOpenTasks()` |
| 2 | tasks | `posterId` ASC, `createdAt` DESC | `getMyPostedTasks()` |
| 3 | tasks | `heroId` ASC, `acceptedAt` DESC | `getMyAcceptedTasks()` |
| 4 | tasks | `heroId` ASC, `status` ASC | `getWeeklyCompletedTasks()` |

---

## Service Layer

### AuthService (`lib/services/auth_service.dart`)

| Method | Description | Returns |
|--------|-------------|---------|
| `signInWithGoogle()` | Google OAuth popup login | `UserCredential?` |
| `signOut()` | Clear auth session | `void` |
| `currentUser` | Get logged-in user | `User?` |
| `authStateChanges` | Auth state stream | `Stream<User?>` |

### FirestoreService (`lib/services/firestore_service.dart`)

#### User Operations

| Method | Description | Returns | Firestore Op |
|--------|-------------|---------|-------------|
| `createOrUpdateUserProfile(User)` | Create new or update existing user | `void` | set / update |
| `getUserProfile([uid])` | Get user by ID | `UserProfile?` | get |
| `getUserProfileStream()` | Real-time user profile | `Stream<UserProfile?>` | snapshots |
| `updateUserProfile(Map)` | Partial update to user doc | `void` | update |

#### Task Operations

| Method | Description | Returns | Firestore Op |
|--------|-------------|---------|-------------|
| `createTask(HeroTask)` | Create task + increment `tasksPosted` | `String` (taskId) | add + update |
| `getOpenTasks()` | Open tasks stream | `Stream<List<HeroTask>>` | where+orderBy snapshots |
| `getAllTasks()` | All tasks stream | `Stream<List<HeroTask>>` | orderBy snapshots |
| `getMyPostedTasks()` | Current user's posted tasks | `Stream<List<HeroTask>>` | where+orderBy snapshots |
| `getMyAcceptedTasks()` | Current user's accepted tasks | `Stream<List<HeroTask>>` | where+orderBy snapshots |
| `getTaskStream(taskId)` | Single task real-time stream | `Stream<HeroTask?>` | doc snapshots |
| `getWeeklyCompletedTasks()` | Last 7 days activity chart data | `Future<List<Map>>` | where+where get |
| `acceptTask(taskId)` | Accept open task (transaction) | `void` | runTransaction |
| `updateTaskProgress(taskId, Map)` | Update pickedUp/delivered | `void` | update |
| `completeTask(taskId)` | Mark complete + credit hero earnings | `void` | update x2 |
| `cancelTask(taskId)` | Cancel open task + decrement `tasksPosted` | `void` | update x2 |

### ApiService (`lib/services/api_service.dart`)

#### AIService

| Method | Description | Input | Output |
|--------|-------------|-------|--------|
| `formatTask(input)` | AI-powered task formatting | Raw text (enriched with form values) | Structured JSON |

**AI Configuration**: Model = `gpt-4o-mini` (OpenAI), temperature = 0.3, max_tokens = 1024, response_format = `{"type": "json_object"}`

**AI Output Schema**:
```json
{
  "title": "...... Canteen Food Delivery",
  "description": "Pick up chicken rice from canteen",
  "category": "Food & Supplies",
  "estimated_minutes": 15,
  "suggested_compensation": 3.50,
  "urgency": "normal",
  "pickup": {"building": "Building 2", "level": "Level 2", "landmark": "Canteen"},
  "delivery": {"building": "Building 1", "level": "Level 7", "landmark": "Near Lobby C"}
}
```

**Input enrichment**: Before sending to OpenAI, manual form values (category, pickup building, delivery building, compensation) are appended to the user's text.

#### DeepgramService

| Method | Description | Input | Output |
|--------|-------------|-------|--------|
| `transcribe(audio, mime)` | Speech-to-text | WebM audio bytes | Transcript string |

**Configuration**: Model = `nova-2-general`, smart_format = true

### WebAudioRecorder (`lib/services/audio_service.dart`)

| Method | Description | Returns |
|--------|-------------|---------|
| `startRecording()` | Begin mic capture (WebM/Opus, 250ms chunks) | `bool` (success) |
| `stopRecording()` | End capture, return audio bytes | `Uint8List?` |
| `dispose()` | Clean up media stream & resources | `void` |

---

## Real-time Data Streams

### Stream Dependencies by Screen

| Screen | Stream 1 | Stream 2 | Stream 3 |
|--------|----------|----------|----------|
| **Sidebar** (main.dart) | `getUserProfileStream()` | - | - |
| **HomeScreen** | `getUserProfileStream()` | `getMyAcceptedTasks()` | `getOpenTasks()` |
| **BrowseScreen** | `getAllTasks()` | - | - |
| **ProfileScreen** | `getUserProfileStream()` | `getMyPostedTasks()` | `getMyAcceptedTasks()` |
| **TaskDetailScreen** | `getTaskStream(taskId)` | - | - |
| **PostTaskScreen** | - (no streams) | - | - |

### Stream Flow Diagram

```
FIRESTORE REAL-TIME LISTENERS
==============================

/users/{currentUid}  .snapshots()
   |
   +---> getUserProfileStream()
   |     +---> Sidebar (name, photo in nav)
   |     +---> HomeScreen (stats: earned, completed, posted)
   |     +---> ProfileScreen (full profile + pillar/year)
   |
/tasks WHERE status == 'open'  .orderBy(createdAt DESC).snapshots()
   |
   +---> getOpenTasks()
         +---> HomeScreen ("Recent Tasks" table)

/tasks  .orderBy(createdAt DESC).snapshots()
   |
   +---> getAllTasks()
         +---> BrowseScreen (with client-side tab/category/sort/search filtering)

/tasks WHERE posterId == currentUid  .orderBy(createdAt DESC).snapshots()
   |
   +---> getMyPostedTasks()
         +---> ProfileScreen ("Tasks I Posted" tab)

/tasks WHERE heroId == currentUid  .orderBy(acceptedAt DESC).snapshots()
   |
   +---> getMyAcceptedTasks()
         +---> HomeScreen ("Your Active Missions")
         +---> ProfileScreen ("Tasks I'm Doing" tab)

/tasks/{taskId}  .snapshots()
   |
   +---> getTaskStream(taskId)
         +---> TaskDetailScreen (live progress, payment state, status changes)
```

**Important**: `TaskDetailScreen` uses a `StreamBuilder<HeroTask?>` wrapping the entire content. The initial `widget.task` is used as `initialData` for instant rendering, then live Firestore updates flow in automatically. This means:
- When hero clicks "Mark Picked Up" -> poster's screen updates instantly
- When hero clicks "Mark Delivered" -> poster sees the payment release section appear
- When poster releases payment -> hero sees "Task Complete! You earned $X" in real-time

---

## Screen-by-Screen Data Flow

### 1. Login Screen

```
User visits taskhero-sutd.web.app
    |
    v
main.dart StreamBuilder(FirebaseAuth.authStateChanges)
    |
    +-- No auth --> LoginScreen displayed
    |
    v
User clicks "Sign in with Google"
    |
    v
AuthService.signInWithGoogle()
    +-- GoogleAuthProvider with prompt='select_account'
    +-- signInWithPopup (web-optimized)
    |
    v
Firebase returns UserCredential
    |
    v
FirestoreService.createOrUpdateUserProfile(firebaseUser)
    +-- IF new user:
    |     set /users/{uid} with all default fields
    +-- IF existing user:
    |     update lastActive = Timestamp.now()
    |     IF new month: reset thisMonthEarned = 0
    |
    v
authStateChanges emits User -> AppShell rebuilds -> Dashboard
```

### 2. Home Screen (Dashboard)

```
THREE NESTED STREAM BUILDERS:

1. getUserProfileStream()
   +-> Displays: Name, greeting, stat cards (earned, completed, posted, rating)

2. getMyAcceptedTasks()
   +-> Displays: "Your Active Missions" section (accepted/inProgress tasks)

3. getOpenTasks()
   +-> Displays: "Recent Tasks" table with category filter pills

ADDITIONAL:
+-- getWeeklyCompletedTasks() -> FutureBuilder -> Activity Chart (bar chart by day)

USER ACTIONS:
+-- Click "Post Task" button -> Navigate to PostTaskScreen (page index 2)
+-- Click task row -> onTaskTap(task) -> TaskDetailScreen
+-- Click category pill -> Local filter state
```

### 3. Browse Screen

```
DATA SOURCE: getAllTasks() Stream

LOCAL FILTERING (in _filterTasks):
+-- activeTab: 'open' | 'accepted' | 'completed'
+-- activeCategory: TaskCategory enum or null
+-- sortBy: 'recent' | 'price_high' | 'duration'
+-- searchQuery: text filter on title + description

FILTER LOGIC:
tasks.where((t) =>
  matchesTab(t.status) &&
  matchesCategory(t.category) &&
  matchesSearch(t.title + t.description)
).sorted(sortBy)

USER ACTIONS:
+-- Toggle tabs (Open/Accepted/Completed) -> setState
+-- Click category pill -> Toggle filter
+-- Change sort dropdown -> Local sort
+-- Click task card -> onTaskTap(task) -> TaskDetailScreen
```

### 4. Post Task Screen

```
TWO INPUT MODES:

[VOICE MODE]
  Hold mic button -> WebAudioRecorder.startRecording()
      -> MediaRecorder captures 250ms chunks (WebM/Opus)
  Release button -> stopRecording() -> Uint8List audio
      -> DeepgramService.transcribe(audio)
      -> Transcript text returned
      -> _processWithAI(transcript)

[MANUAL MODE]
  Type description in text field
  Optionally set: category, pickup building, delivery building, compensation slider
  Click "Let AI Format & Post"
      -> Enriched input = text + manual form values appended
      -> _processWithAI(enrichedInput)

_processWithAI(input):
  +-- aiLoading = true
  +-- AIService.formatTask(input)
  +-- Returns structured JSON
  +-- aiPreview state set
  +-- Show preview card with editable compensation slider + "Post Task" button

_postTask():
  +-- Parse aiPreview -> HeroTask model
  +-- FirestoreService.createTask(task)
  |     +-- Reads poster's current rating from /users/{uid}
  |     +-- Creates doc in /tasks with all fields
  |     +-- Increments tasksPosted in /users/{uid}
  +-- Show success toast
  +-- Reset all form state (description, category, buildings, compensation, preview)
```

### 5. Profile Screen

```
DATA SOURCES:
+-- getUserProfileStream() -> User info card + stat cards
+-- getMyPostedTasks() -> "Tasks I Posted" tab
+-- getMyAcceptedTasks() -> "Tasks I'm Doing" tab

DISPLAYED INFO:
+-- Avatar (Google photo with initials fallback)
+-- Name, Email
+-- Pillar & Year (editable via pencil icon)
+-- Stats: Total Earned, This Month, Tasks Posted, Tasks Completed, Rating
+-- Two tab task history lists (each task tappable -> TaskDetailScreen)

USER ACTIONS:
+-- Click pencil icon -> ShadDialog with pillar/year dropdowns
|     -> updateUserProfile({'pillar': x, 'year': y})
+-- Click "Sign Out" -> AuthService.signOut() -> LoginScreen
+-- Click task in list -> onTaskTap(task) -> TaskDetailScreen
```

### 6. Task Detail Screen (Live Updating)

```
INPUT: HeroTask object (used as initialData)
STREAM: getTaskStream(taskId) -> StreamBuilder wraps entire content

ROLE DETECTION:
+-- isPoster = task.posterId == currentUid
+-- isHero = task.heroId == currentUid

CONDITIONAL UI:

IF status == open AND NOT poster:
  +-- Show "Accept Task" section
  |     -> acceptTask(taskId) [transaction: validates open + not own task]
  |     -> Toast "Task Accepted!" + navigate back

IF status == open AND IS poster:
  +-- Show "Cancel Task" section
  |     -> cancelTask(taskId) [validates poster + open status]
  |     -> Decrements tasksPosted
  |     -> Toast "Task Cancelled" + navigate back

IF status == accepted/inProgress/completed:
  +-- Show Progress Tracker (4 steps):
  |     [1] Task Accepted          (always done)
  |     [2] Picked Up              (button if isHero && !pickedUp && !completed)
  |           -> updateTaskProgress({pickedUp: true, status: 'inProgress'})
  |     [3] Delivered              (button if isHero && pickedUp && !delivered && !completed)
  |           -> updateTaskProgress({delivered: true})
  |           -> Toast "Waiting for poster to confirm..."
  |     [4] Poster Confirmed       (done when status == completed)
  |
  +-- IF completed (posterConfirmed):
  |     Show green banner:
  |       Hero sees: "Task Complete! You earned $X.XX"
  |       Poster sees: "Task Complete! Payment of $X.XX released."
  |
  +-- IF delivered && !completed && isHero:
  |     Show amber banner: "Waiting for [posterName] to confirm and release payment..."
  |
  +-- IF delivered && !completed && isPoster:
        Show Google Pay "Release Payment" section
          -> Simulate payment processing (2s delay)
          -> completeTask(taskId)
          |     -> status = 'completed', completedAt = now
          |     -> hero's totalEarned += heroEarnings
          |     -> hero's thisMonthEarned += heroEarnings
          |     -> hero's tasksCompleted += 1
          -> Toast "Payment Processed! Funds released to Hero."
          -> Navigate back after 2s

ALWAYS DISPLAYED:
+-- Task header (title, compensation, hero earnings, status pills)
+-- Task details (description, time estimate, delivery location, category)
+-- Pickup & Delivery location cards
+-- Payment breakdown (compensation, 5% platform fee, hero receives)
+-- Poster info (avatar, name, rating, Chat/Call buttons [coming soon])
```

---

## User Scenarios

### Scenario 1: New User Onboarding

```
1. User visits taskhero-sutd.web.app
2. LoginScreen shows (no auth session)
3. Click "Sign in with Google" -> OAuth popup
4. Select Google account
5. Firebase creates auth session
6. createOrUpdateUserProfile():
     New doc in /users/{uid}
     +-- displayName, email, photoURL from Google
     +-- pillar: "ISTD", year: 1
     +-- totalEarned: 0, thisMonthEarned: 0
     +-- tasksCompleted: 0, tasksPosted: 0
     +-- rating: 5.0, totalReviews: 0
     +-- createdAt: now, lastActive: now
7. Dashboard loads with $0 stats and empty activity chart
8. User can browse tasks (become Hero) or post tasks (become Poster)
```

### Scenario 2: Posting a Task (Voice)

```
1. Navigate to Post Task tab
2. Hold mic button -> browser requests microphone permission
3. Speak: "I need someone to pick up bubble tea from LiHo..."
4. Release button -> audio captured as WebM/Opus
5. DeepgramService.transcribe(audio) -> transcript text
6. AIService.formatTask(transcript) -> structured JSON
7. AI Preview displayed with title, category, compensation, locations
8. User adjusts compensation slider if needed
9. Click "Post Task"
10. createTask():
      +-- Reads poster's rating from /users/{uid}
      +-- Creates /tasks/{newId} with all fields, status="open"
      +-- Increments /users/{uid}.tasksPosted by 1
11. Success toast -> form resets
12. Task appears in Browse screen for all users (real-time stream)
```

### Scenario 3: Posting a Task (Manual with AI)

```
1. Navigate to Post Task tab
2. Optionally select: category, pickup building, delivery building
3. Adjust compensation slider
4. Type description: "Need someone to buy chicken rice from canteen"
5. Click "Let AI Format & Post"
6. Enriched input = description + category + buildings + budget appended
7. AIService.formatTask(enrichedInput) -> structured JSON
8. AI Preview displayed
9. Click "Post Task" -> same flow as voice step 10-12
```

### Scenario 4: Accepting a Task (Hero Flow)

```
1. Hero browses tasks on BrowseScreen or HomeScreen
2. Sees open task, clicks on it -> TaskDetailScreen
3. Sees "Ready to help? Earn $X.XX" section
4. Clicks "Accept Task"
5. acceptTask(taskId) [TRANSACTION]:
     +-- Validates: status == 'open'
     +-- Validates: posterId != currentUserId (can't accept own)
     +-- Writes: status='accepted', heroId, heroName, acceptedAt, pickedUp=false, delivered=false
6. Toast "Task Accepted! Navigate to [pickup] for pickup"
7. Navigate back
8. Task now appears in Hero's "Active Missions" on HomeScreen
9. Task removed from "Open" filter for all users (real-time)
```

### Scenario 5: Task Execution & Completion (Two-Party Flow)

```
HERO SIDE:                                POSTER SIDE:
-----------                               ------------
Opens accepted task                       Opens their posted task
Sees progress tracker (1/4)               Sees progress tracker (1/4)
    |                                         |
Clicks "Mark Picked Up"                  (sees update live: 2/4)
  -> updateTaskProgress                       |
     {pickedUp: true,                         |
      status: 'inProgress'}                   |
    |                                         |
Clicks "Mark Delivered"                   (sees update live: 3/4)
  -> updateTaskProgress                   Payment section appears:
     {delivered: true}                    "Release Payment via Google Pay"
    |                                         |
Sees amber banner:                        Clicks "Release Payment"
"Waiting for [poster]                       -> 2s payment simulation
 to confirm..."                             -> completeTask(taskId):
    |                                            status='completed'
    |                                            completedAt=now
    |                                            hero.totalEarned += earnings
    |                                            hero.thisMonthEarned += earnings
    |                                            hero.tasksCompleted += 1
    |                                         |
(sees update live: 4/4)                   Toast: "Payment Processed!"
Green banner: "Task Complete!             Green banner: "Task Complete!
You earned $X.XX"                         Payment of $X.XX released."
    |                                         |
Stats updated on Dashboard                Navigate back
(totalEarned, thisMonthEarned,
 tasksCompleted all incremented)
```

### Scenario 6: Cancelling a Task (Poster Only)

```
1. Poster opens their own task (status == open)
2. Sees "Your Task - This task is waiting for a Hero" section
3. Clicks "Cancel Task"
4. cancelTask(taskId):
     +-- Validates: posterId == currentUserId
     +-- Validates: status == 'open'
     +-- Writes: status = 'cancelled'
     +-- Decrements /users/{uid}.tasksPosted by 1
5. Toast "Task Cancelled" -> navigate back
6. Task removed from open listings (real-time)
```

### Scenario 7: Editing Profile

```
1. Navigate to Profile tab
2. StreamBuilder loads getUserProfileStream()
3. Profile displays: avatar, name, email, pillar, year, stats
4. Click pencil icon next to pillar/year
5. ShadDialog opens with pillar dropdown + year dropdown
6. Select new values, click "Save"
7. updateUserProfile({'pillar': 'ESD', 'year': 3})
8. Firestore doc updated -> StreamBuilder fires -> UI updates instantly
```

### Scenario 8: Returning User (Monthly Reset)

```
1. User logs in (hasn't logged in since last month)
2. createOrUpdateUserProfile() called
3. Checks lastActive timestamp vs current date
4. Different month/year detected
5. Updates: {lastActive: now, thisMonthEarned: 0.0}
6. Dashboard shows $0.00 for "This Month" stat
7. totalEarned (lifetime) remains unchanged
```

---

## External Integrations

### 1. Firebase Auth (Google Sign-In)

```
Provider: GoogleAuthProvider
Method: signInWithPopup (web-optimized)
Custom param: prompt = 'select_account'
Authorized domains: taskhero-sutd.web.app, localhost

Error handling:
  popup-closed-by-user -> silent fail
  popup-blocked -> silent fail (returns null)
```

### 2. Firestore Database

```
Project: health-is-wealth-b91b2
Web Settings:
  persistenceEnabled: false (avoids IndexedDB issues on web)
  webExperimentalForceLongPolling: true (fixes channel connection errors)

Real-time listeners: 7 active streams (see Stream Dependencies table)
Transactions: acceptTask uses runTransaction for race condition safety
Atomic increments: FieldValue.increment for all counter/earnings updates
```

### 3. OpenAI GPT-4o-mini (Task Formatting)

```
Model: gpt-4o-mini
Endpoint: api.openai.com/v1/chat/completions
Auth: Bearer token (Authorization header)
Temperature: 0.3 (consistent output)
Max tokens: 1024
Response format: {"type": "json_object"}

System prompt includes:
  - SUTD campus context (buildings 1-5, hostel, canteen, Changi City Point)
  - Compensation guidelines ($2-5 food, $5-15 academic, etc.)
  - Category mapping (6 categories)
  - Required JSON output schema
```

### 4. Deepgram STT (Speech-to-Text)

```
Model: nova-2-general
Endpoint: api.deepgram.com/v1/listen
Features: smart_format=true (auto punctuation + capitalization)
Audio: WebM/Opus from browser MediaRecorder (250ms chunks)
Response path: results.channels[0].alternatives[0].transcript
```

### 5. Browser MediaRecorder (Audio)

```
API: MediaRecorder + navigator.mediaDevices.getUserMedia
MIME: audio/webm;codecs=opus
Chunk interval: 250ms
Flow: getUserMedia -> MediaRecorder -> ondataavailable chunks -> stop -> combine -> Uint8List
Error handling: permission denied -> return false; empty chunks -> return null
Cleanup: dispose() stops all media stream tracks
```

---

## Summary

TaskHero is a **Flutter Web** application for SUTD students to post and complete campus tasks. Key architectural points:

- **Real-time everywhere**: All screens use Firestore `.snapshots()` streams. TaskDetailScreen streams a single document for live two-party progress updates.
- **Two-party task flow**: Poster creates -> Hero accepts (transaction) -> Hero marks progress -> Poster releases payment -> Both see completion.
- **Atomic operations**: `acceptTask` uses a Firestore transaction to prevent double-accepts. Earnings use `FieldValue.increment` for atomicity.
- **AI-powered posting**: Voice (Deepgram STT) or text input -> OpenAI GPT-4o-mini formats into structured task JSON with SUTD campus awareness.
- **5% platform fee**: `heroEarnings = compensation * 0.95`, computed client-side and applied during `completeTask`.
- **Monthly reset**: `thisMonthEarned` auto-resets on first login of a new calendar month.
- **No deletes**: Security rules block all document deletions. Tasks are cancelled, never deleted.
