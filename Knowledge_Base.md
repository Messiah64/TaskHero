# TaskHero — Project Knowledge Base

> **Last Updated**: February 12, 2026
> **Live URL**: [taskhero-sutd.web.app](https://taskhero-sutd.web.app)
> **Firebase Project**: `health-is-wealth-b91b2`
> **Platform**: Flutter Web (Dart 3.10.8+)
> **Repository**: `/Users/mohammedkhambhati/Desktop/flutter_application_1`

---

## 1. What Is TaskHero?

TaskHero is a **real-time campus task marketplace** built for students at the **Singapore University of Technology and Design (SUTD)**. It connects students who need help (Posters) with students willing to help (Heroes) for small tasks around campus — food delivery, tutoring, errands, tech help, and more.

### Core Concept

- A **Poster** describes what they need (voice or text). AI formats it into a structured task.
- A **Hero** browses open tasks, accepts one, picks up/delivers, then the Poster releases payment.
- Everything updates in **real-time** — both parties see live progress on a shared task detail screen.
- A **5% platform fee** is applied: heroes earn 95% of compensation.

### Target Users

SUTD students (500–1000 undergrads on a compact campus). Tasks are localized to campus buildings, hostel, canteen, and nearby malls (Changi City Point, Expo MRT).

---

## 2. Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter Web (Dart) | Single-page app, responsive (mobile + desktop) |
| **UI Library** | `shadcn_ui` v0.45.2 (by nank1ro) | ShadCN-style components (cards, buttons, badges, dialogs, tabs, toasts) |
| **Animations** | `flutter_animate` v4.5.2 | Micro-animations on load (fade, slide, scale) |
| **Icons** | `lucide_icons_flutter` (via shadcn_ui) | Modern line icons |
| **Auth** | Firebase Auth (Google Sign-In) | OAuth popup, web-optimized |
| **Database** | Cloud Firestore | Real-time NoSQL with `.snapshots()` streams |
| **AI Formatting** | OpenAI GPT-4o-mini | Converts raw task descriptions into structured JSON |
| **Speech-to-Text** | Deepgram Nova-2 | Transcribes voice recordings to text |
| **Audio Capture** | Browser MediaRecorder API | WebM/Opus mic recording |
| **Hosting** | Firebase Hosting | Deployed at `taskhero-sutd.web.app` |
| **HTTP** | `http` v1.3.0 | REST calls to OpenAI, Deepgram, Firebase Storage |

### Key Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter: sdk
  shadcn_ui: ^0.45.2
  http: ^1.3.0
  flutter_animate: ^4.5.2
  web: ^1.1.1
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  cloud_firestore: ^5.6.12
```

---

## 3. Project Structure

```
lib/
├── main.dart                    # App entry, ShadApp, AppShell (sidebar + bottom nav), routing
├── firebase_options.dart        # Auto-generated Firebase config
├── models/
│   ├── task_model.dart          # HeroTask, TaskLocation, TaskCategory, TaskStatus, TaskUrgency
│   └── user_profile.dart        # UserProfile model with Firestore serialization
├── screens/
│   ├── login_screen.dart        # Google Sign-In card
│   ├── home_screen.dart         # Dashboard: stats, active missions, recent tasks, activity chart
│   ├── browse_screen.dart       # All tasks with tab/category/sort/search filtering
│   ├── post_task_screen.dart    # Voice & manual task creation with AI formatting
│   ├── profile_screen.dart      # User profile, pillar/year editing, task history tabs
│   └── task_detail_screen.dart  # Live-updating task detail, progress tracker, payment flow
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper (Google Sign-In popup)
│   ├── firestore_service.dart   # All Firestore CRUD, streams, transactions
│   ├── api_service.dart         # OpenAI GPT-4o-mini + Deepgram STT + Firebase Storage
│   └── audio_service.dart       # Browser MediaRecorder (WebM/Opus)
├── widgets/
│   ├── task_card.dart           # Reusable task card with hover animation
│   └── stat_card.dart           # Dashboard stat metric card
└── theme/
    └── app_colors.dart          # Color palette constants
```

**Config files at project root:**

```
firestore.rules             # Firestore security rules
firestore.indexes.json      # Composite indexes for compound queries
firebase.json               # Firebase project config
Data_Flow.md                # Full data flow documentation
Knowledge_Base.md           # This file
```

---

## 4. UI Design & Color Scheme

### Theme System

- **Root widget**: `ShadApp` with `ShadThemeData`
- **Color scheme**: `ShadOrangeColorScheme` (light and dark variants)
- **Theme access**: `ShadTheme.of(context)` returns `ShadThemeData`
- **Current mode**: Light theme (dark theme configured but not toggled)

### Color Palette (`app_colors.dart`)

| Token | Hex | Usage |
|-------|-----|-------|
| `orange50` | `#FFF7ED` | Active nav item background, subtle tint |
| `orange400` | `#FB923C` | Gradient start |
| `orange500` | `#F97316` | Primary accent, mobile nav active, chart line |
| `orange600` | `#EA580C` | Gradient end, active nav text, sidebar active |
| `orangeMid` | `#FFEDD5` | Avatar fallback background |
| `green500` | `#10B981` | Success states, completed status, checkmarks |
| `green600` | `#059669` | Darker green accents |
| `blue500` | `#3B82F6` | Info/link color, task posted stat |
| `purple500` | `#8B5CF6` | In-progress status indicator |

### Gradients

| Name | Colors | Usage |
|------|--------|-------|
| `orangeGradient` | `orange400` → `orange600` | Logo, CTA buttons, AI chip, shield icon |
| `orangeSubtle` | `orange50` → `orangeMid` | Section backgrounds |

### Semantic Color Usage

| State | Color | Where |
|-------|-------|-------|
| Open task | (default theme) | Browse screen tab |
| Accepted/In-Progress | `#8B5CF6` (purple500) | Status pills, progress indicators |
| Completed | `#10B981` (green500) | Status pills, banners |
| Cancelled | `Colors.grey` | Status pill |
| Urgent/Emergency | `#DC2626` (red) | Badge with `#FEE2E2` background |
| Error/Destructive | `Colors.red` | Error toasts, cancel buttons |
| Muted text | `theme.colorScheme.mutedForeground` | Secondary text throughout |

### Typography

No custom fonts — uses Flutter's default (system fonts). Key sizes:

| Context | Size | Weight |
|---------|------|--------|
| Page headers | 22–24px | w700 |
| Section headers | 16–18px | w600 |
| Card titles | 14px | w600 |
| Body text | 13–14px | w400 |
| Muted/labels | 11–12px | w400/w500 |
| Stat card values | 28px | w700 |

### Responsive Breakpoints

| Width | Layout |
|-------|--------|
| < 768px | Mobile: bottom nav, single-column |
| ≥ 768px | Desktop: 240px sidebar + content area |
| < 900px | Post task: single column |
| ≥ 900px | Post task: two-column (form + preview) |

### ShadCN Component Usage

| Component | Where Used |
|-----------|-----------|
| `ShadButton` / `.ghost()` / `.outline()` / `.destructive()` | CTAs, nav actions, cancel |
| `ShadCard` | Stat cards, task cards, sections |
| `ShadBadge` / `.secondary()` | Category labels, status pills |
| `ShadToast` / `.destructive()` | Success/error notifications |
| `ShadDialog` | Profile edit (pillar/year dropdowns) |
| `ShadTabs` | Browse screen tabs, profile task history |
| `ShadSelect` | Category/sort dropdowns |
| `ShadAvatar` | User photos with initials fallback |
| `ShadInput` | Search bars, text fields |
| `ShadTooltip` | Icon button hints |

---

## 5. Screens Overview

### Login Screen
- Centered card with TaskHero logo (shield icon + orange gradient)
- "Sign in with Google" button → Firebase OAuth popup
- On success → creates/updates user profile in Firestore → navigates to Dashboard

### Dashboard (Home Screen)
- Greeting with user's name
- 4 stat cards: Total Earned, This Month, Tasks Completed, Tasks Posted
- "Your Active Missions" — cards for accepted/in-progress tasks
- Activity chart — area chart of completed tasks over last 7 days
- "Recent Tasks" table — open tasks with category filter pills

### Browse Screen
- Tab bar: Open / Accepted / Completed
- Category filter pills (6 categories)
- Sort dropdown: Recent / Highest Pay / Shortest Duration
- Search bar for title/description filtering
- Grid/list of TaskCards

### Post Task Screen
- Two input modes:
  - **Voice**: Hold mic → record → Deepgram transcribes → OpenAI formats
  - **Manual**: Type description, optionally select category/buildings/compensation → OpenAI formats
- AI Preview card shows formatted result
- Adjustable compensation slider
- "Post Task" button creates the Firestore document

### Profile Screen
- Avatar, name, email, pillar & year (editable)
- Stats: earned, tasks posted, tasks completed, rating, success rate
- Two-tab task history: "Tasks I Posted" / "Tasks I'm Doing"
- Sign Out button

### Task Detail Screen (Live)
- StreamBuilder wrapping entire content for real-time updates
- Role-aware: shows different actions for Poster vs Hero vs Viewer
- 4-step progress tracker: Accepted → Picked Up → Delivered → Confirmed
- Payment breakdown (compensation, 5% fee, hero earnings)
- Google Pay release payment section (poster side)
- Real-time banners for waiting/completion states

---

## 6. AI System Prompt

The following system prompt is sent to **OpenAI GPT-4o-mini** via the Chat Completions API when formatting tasks:

```
You are TaskHero AI, helping SUTD students format task requests.

SUTD Context:
- Compact campus, 5-10 min between buildings
- Canteen: Building 2, Level 2
- Buildings have 5-8 levels, Hostel separate
- Nearby: Changi City Point (10min walk), Expo MRT
- Meal prices: $3-6 SGD

Compensation (SGD):
- Food pickup 15min: $2-4
- Off-campus 30min: $5-8
- Tutoring 60min: $10-20
- Tech help 30min: $5-10
- Urgent: +$2

Categories: "Food & Supplies", "Academic Help", "Campus Errands",
            "Tech & Making", "Social & Events", "Marketplace"

Return ONLY valid JSON with this exact schema:
{
  "title": "emoji + short title (max 50 chars)",
  "description": "clear instructions",
  "category": "one of 6 categories",
  "estimated_minutes": number,
  "suggested_compensation": number,
  "urgency": "normal" or "urgent",
  "pickup": {"building": "...", "level": "...", "landmark": "..."},
  "delivery": {"building": "...", "level": "...", "landmark": "..."}
}
```

### API Configuration

```
Endpoint: POST https://api.openai.com/v1/chat/completions
Model:    gpt-4o-mini
Headers:  Authorization: Bearer <API_KEY>
          Content-Type: application/json

Body:
  messages: [system prompt, user message]
  temperature: 0.3
  max_tokens: 1024
  response_format: {"type": "json_object"}

Response: choices[0].message.content → parse as JSON
```

### Input Enrichment

Before calling the AI, manual form values are appended to the user's text:
```
"I need chicken rice from canteen"
+ "\nCategory: Food & Supplies"
+ "\nPickup: Building 2"
+ "\nDelivery: Building 1"
+ "\nBudget: $3.50"
```

---

## 7. Deepgram Speech-to-Text

```
Endpoint: POST https://api.deepgram.com/v1/listen
Model:    nova-2-general
Features: smart_format=true (auto-punctuation & capitalization)
Auth:     Token <DEEPGRAM_KEY>
Input:    WebM/Opus audio bytes from browser MediaRecorder
Output:   results.channels[0].alternatives[0].transcript
```

### Audio Recording Flow

1. User holds mic button → `WebAudioRecorder.startRecording()`
2. Browser requests microphone permission
3. `MediaRecorder` captures 250ms chunks (WebM/Opus codec)
4. User releases → `stopRecording()` combines chunks into `Uint8List`
5. Bytes sent to Deepgram → transcript returned
6. Transcript auto-sent to OpenAI for formatting

---

## 8. Firestore Database Schema

### Collection: `/users/{uid}`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `email` | string | from Google | User email |
| `displayName` | string | from Google | Full name |
| `photoURL` | string | from Google | Profile photo URL |
| `pillar` | string | `"ISTD"` | SUTD pillar (EPD/ESD/ISTD/ASD/DAI) |
| `year` | number | `1` | Academic year (1–5) |
| `totalEarned` | number | `0.0` | Lifetime hero earnings (SGD) |
| `thisMonthEarned` | number | `0.0` | Current month earnings (auto-resets) |
| `tasksCompleted` | number | `0` | Tasks completed as hero |
| `tasksPosted` | number | `0` | Tasks created as poster |
| `rating` | number | `5.0` | Average rating (1.0–5.0) |
| `totalReviews` | number | `0` | Number of ratings received |
| `createdAt` | timestamp | `now` | Account creation time |
| `lastActive` | timestamp | `now` | Last login time |

### Collection: `/tasks/{taskId}`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `title` | string | required | Task title with emoji |
| `description` | string | required | Detailed instructions |
| `category` | string | required | `food\|academic\|errands\|tech\|social\|marketplace` |
| `compensation` | number | required | Payment in SGD |
| `status` | string | `"open"` | `open\|accepted\|inProgress\|completed\|cancelled` |
| `urgency` | string | `"normal"` | `normal\|urgent\|emergency` |
| `estimatedMinutes` | number | required | Time estimate |
| `pickup` | map | required | `{building, level, landmark}` |
| `delivery` | map | required | `{building, level, landmark}` |
| `posterId` | string | auth uid | UID of task creator |
| `posterName` | string | from Auth | Creator's display name |
| `posterRating` | number | from profile | Creator's rating at post time |
| `posterAvatarUrl` | string | from Auth | Creator's photo URL |
| `heroId` | string\|null | `null` | UID of hero (set on accept) |
| `heroName` | string\|null | `null` | Hero's display name |
| `pickedUp` | boolean | `false` | Hero has picked up |
| `delivered` | boolean | `false` | Hero has delivered |
| `createdAt` | timestamp | `now` | Task creation time |
| `acceptedAt` | timestamp\|null | `null` | When hero accepted |
| `completedAt` | timestamp\|null | `null` | When poster released payment |

---

## 9. Security Rules

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

### Key Design Decisions

- **No deletes** — tasks are cancelled, never removed
- **Any auth user can update** — `completeTask` needs cross-user writes (poster completes, hero gets credited)
- **Create validation** — `posterId` must match auth uid, initial status must be `"open"`
- **Client-side guards** supplement rules: `acceptTask` uses a transaction, `cancelTask` checks poster ownership

---

## 10. Composite Indexes

| # | Fields | Used By |
|---|--------|---------|
| 1 | `status` ASC, `createdAt` DESC | `getOpenTasks()` |
| 2 | `posterId` ASC, `createdAt` DESC | `getMyPostedTasks()` |
| 3 | `heroId` ASC, `acceptedAt` DESC | `getMyAcceptedTasks()` |
| 4 | `heroId` ASC, `status` ASC | `getWeeklyCompletedTasks()` |

---

## 11. Task Lifecycle

```
                  ┌──────────┐
                  │   OPEN   │ ← createTask()
                  └────┬─────┘
                       │
            ┌──────────┴──────────┐
            │                     │
     acceptTask()           cancelTask()
            │                     │
     ┌──────┴──────┐      ┌──────┴──────┐
     │  ACCEPTED   │      │  CANCELLED  │
     └──────┬──────┘      └─────────────┘
            │
  updateTaskProgress({pickedUp: true, status: 'inProgress'})
            │
     ┌──────┴──────┐
     │ IN PROGRESS │
     └──────┬──────┘
            │
  updateTaskProgress({delivered: true})
            │
     Hero waits... Poster sees "Release Payment"
            │
     completeTask()  ← poster releases payment
            │
     ┌──────┴──────┐
     │  COMPLETED  │ → hero.totalEarned += 95%
     └─────────────┘   hero.thisMonthEarned += 95%
                       hero.tasksCompleted += 1
```

---

## 12. Real-Time Streams

All screens use Firestore `.snapshots()` for live updates:

| Stream | Source Query | Consumers |
|--------|------------|-----------|
| `getUserProfileStream()` | `/users/{uid}` doc | Sidebar, Home, Profile |
| `getOpenTasks()` | `status == 'open'`, `createdAt` DESC | Home "Recent Tasks" |
| `getAllTasks()` | all tasks, `createdAt` DESC | Browse screen |
| `getMyPostedTasks()` | `posterId == uid`, `createdAt` DESC | Profile "Tasks I Posted" |
| `getMyAcceptedTasks()` | `heroId == uid`, `acceptedAt` DESC | Home "Active Missions", Profile "Tasks I'm Doing" |
| `getTaskStream(id)` | single doc `/tasks/{id}` | TaskDetailScreen live updates |
| `getWeeklyCompletedTasks()` | `heroId == uid` + `status == 'completed'` | Home activity chart (FutureBuilder) |

---

## 13. External Service Integrations

| Service | Purpose | Endpoint |
|---------|---------|----------|
| **Firebase Auth** | Google Sign-In (popup) | Firebase SDK |
| **Cloud Firestore** | Real-time database | Firebase SDK (long polling on web) |
| **OpenAI GPT-4o-mini** | Task formatting AI | `api.openai.com/v1/chat/completions` |
| **Deepgram Nova-2** | Speech-to-text | `api.deepgram.com/v1/listen` |
| **Firebase Storage** | File uploads (via REST) | `firebasestorage.googleapis.com` |
| **Firebase Hosting** | Web app deployment | `taskhero-sutd.web.app` |

### Firestore Web Configuration

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: false,           // Avoids IndexedDB issues on web
  webExperimentalForceLongPolling: true, // Fixes channel connection errors
);
```

---

## 14. Build & Deploy

```bash
# Build
flutter build web --release

# Deploy hosting only
firebase deploy --only hosting

# Deploy Firestore rules + indexes
firebase deploy --only firestore:rules,firestore:indexes

# Deploy everything
firebase deploy
```

**Hosted at**: https://taskhero-sutd.web.app

---

## 15. ShadCN UI Notes (Gotchas)

- **App root**: `ShadApp` → `ShadThemeData` → `ShadOrangeColorScheme`
- **Theme access**: `ShadTheme.of(context)` (not `Theme.of(context)`)
- **No `variant` param** — use named constructors: `ShadButton.ghost()`, `.outline()`, `.destructive()`
- **No `ShadButtonSize.icon`** — sizes are `regular`, `sm`, `lg`
- **Icon-only buttons**: `ShadButton.ghost(size: ShadButtonSize.sm, child: Icon(...))`
- **Toast**: `ShadToaster.of(context).show(ShadToast(...))`
- **Dialog**: `showShadDialog(context: context, builder: (ctx) => ShadDialog(...))`
- **Tabs**: `ShadTabs<String>(value: 'tab1', tabs: [ShadTab(value: ..., child: ..., content: ...)])`

### LucideIcons Naming (v3.1.9)

Shape-first pattern: `circle`, `square`, `triangle` prefix the icon name.

| Want | Actual Name |
|------|-------------|
| home | `house` |
| plusCircle | `circlePlus` |
| checkCircle | `circleCheck` |
| checkSquare | `squareCheck` |
| barChart3 | `chartBar` |
| alertTriangle | `triangleAlert` |
| helpCircle | does NOT exist — use `info` |

---

## 16. Key Architectural Patterns

1. **StreamBuilder everywhere** — no manual refresh needed; Firestore changes propagate instantly
2. **Single-document stream** on TaskDetailScreen — both poster and hero see each other's actions live
3. **Firestore transaction** for `acceptTask` — prevents race conditions when two heroes accept simultaneously
4. **Atomic increments** (`FieldValue.increment`) — earnings and counters never lose writes
5. **Client-side filtering** in Browse screen — single `getAllTasks()` stream with local filter/sort/search
6. **Monthly earnings reset** — `thisMonthEarned` resets to 0 on first login of new month
7. **AI-powered input** — natural language (voice or text) → structured JSON via GPT-4o-mini
8. **Role-based UI** — `isPoster` and `isHero` booleans drive conditional rendering in TaskDetailScreen
