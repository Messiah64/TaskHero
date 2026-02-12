# 🦸 TaskHero — Campus Task Marketplace

> **Where SUTD students become each other's heroes, one task at a time!** ⚡

[![Live](https://img.shields.io/badge/🌐_Live-taskhero--sutd.web.app-orange)](https://taskhero-sutd.web.app)
[![Flutter Web](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Hosting-FFCA28?logo=firebase)](https://firebase.google.com)
[![AI Powered](https://img.shields.io/badge/AI-GPT--4o--mini%20%7C%20Deepgram-412991?logo=openai)](https://openai.com)

---

## 🤔 What is TaskHero?

TaskHero is a **real-time campus task marketplace** for students at the **Singapore University of Technology and Design (SUTD)**. Need someone to pick up lunch from the canteen? Want a quick Python tutoring session? Too lazy to collect your parcel? 📦

**Post it. A hero will grab it.** 🦸‍♂️

### 🎯 The Concept

| Role | What They Do |
|------|-------------|
| 🧑‍💼 **Poster** | Describes a task (voice or text). AI formats it beautifully. |
| 🦸 **Hero** | Browses open tasks, accepts one, completes it, gets paid. |

Everything updates in **real-time** — both parties see live progress on a shared task detail screen. No refreshing. No guessing. Just vibes. ✨

---

## 🚀 Features at a Glance

| Feature | Description |
|---------|-------------|
| 🎤 **Voice-to-Task** | Speak your task description → Deepgram transcribes → GPT-4o-mini formats it into a structured task |
| 🤖 **AI Task Formatting** | Raw "I need someone to buy me kopi from canteen" → clean title, location, compensation, category, urgency |
| 📊 **Live Dashboard** | Stats cards, active missions, recent tasks, activity chart — all streaming from Firestore |
| 🔍 **Smart Browse** | Filter by category, sort by date/price/urgency, search by keyword, tab between Available/My Tasks |
| 🏃 **Real-Time Progress** | Task status flows: `open` → `in_progress` → `arriving` → `completed` → `paid` |
| 💰 **Payment Flow** | Poster releases payment → Hero earns 95% (5% platform fee) |
| ⭐ **Rating System** | Rate your hero after task completion (1-5 stars) |
| 🎨 **Beautiful UI** | ShadCN components, orange gradient theme, hover animations, responsive design |
| 📱 **Responsive** | Mobile (bottom nav) ↔ Desktop (sidebar) — works on any screen size |

---

## 🏗️ Tech Stack

```
┌─────────────────────────────────────────────────────┐
│                    🦸 TaskHero                       │
├──────────────┬──────────────────────────────────────┤
│  Frontend    │  Flutter Web (Dart 3.10.8+)          │
│  UI Library  │  shadcn_ui v0.45.2 (ShadCN vibes)    │
│  Animations  │  flutter_animate v4.5.2              │
│  Icons       │  Lucide Icons (modern line icons)     │
├──────────────┼──────────────────────────────────────┤
│  Auth        │  Firebase Auth (Google Sign-In)       │
│  Database    │  Cloud Firestore (real-time streams)  │
│  Hosting     │  Firebase Hosting                     │
├──────────────┼──────────────────────────────────────┤
│  AI Brain    │  OpenAI GPT-4o-mini                   │
│  STT Engine  │  Deepgram Nova-2                      │
│  Audio       │  Browser MediaRecorder API            │
└──────────────┴──────────────────────────────────────┘
```

---

## 📂 Project Structure

```
lib/
├── main.dart                    # 🏠 App shell, routing, sidebar + bottom nav
├── firebase_options.dart        # 🔥 Firebase config
├── models/
│   ├── task_model.dart          # 📋 HeroTask, TaskCategory, TaskStatus, etc.
│   └── user_profile.dart        # 👤 UserProfile with Firestore serialization
├── screens/
│   ├── login_screen.dart        # 🔐 Google Sign-In
│   ├── home_screen.dart         # 📊 Dashboard with live stats
│   ├── browse_screen.dart       # 🔍 Browse & filter all tasks
│   ├── post_task_screen.dart    # ✍️ Voice/text task creation + AI formatting
│   ├── profile_screen.dart      # 👤 Profile, pillar/year, task history
│   └── task_detail_screen.dart  # 📱 Live task detail + progress tracker
├── services/
│   ├── auth_service.dart        # 🔑 Firebase Auth wrapper
│   ├── firestore_service.dart   # 🗄️ All Firestore CRUD + streams
│   ├── api_service.dart         # 🤖 OpenAI + Deepgram + Storage
│   └── audio_service.dart       # 🎙️ Browser mic recording (WebM/Opus)
├── widgets/
│   ├── task_card.dart           # 🃏 Reusable task card with hover effects
│   └── stat_card.dart           # 📈 Dashboard metric card
└── theme/
    └── app_colors.dart          # 🎨 Orange palette constants
```

---

## 🎨 The Look & Feel

TaskHero rocks a **warm orange gradient** theme built on the Tailwind orange palette:

| Color | Hex | Usage |
|-------|-----|-------|
| 🟠 Orange 400 | `#FB923C` | Gradient start, accent |
| 🟠 Orange 500 | `#F97316` | Primary brand |
| 🟠 Orange 600 | `#EA580C` | Gradient end, hover |
| 🟢 Green 500 | `#10B981` | Success states |
| 🔵 Blue 500 | `#3B82F6` | Info/links |
| 🟣 Purple 500 | `#8B5CF6` | Creative category |

**Responsive Breakpoints:**
- 📱 `< 768px` → Mobile layout with bottom navigation bar
- 🖥️ `≥ 768px` → Desktop layout with collapsible sidebar

---

## 🗄️ Database Schema

### `users` Collection
| Field | Type | Description |
|-------|------|-------------|
| `displayName` | string | User's name from Google |
| `email` | string | Google email |
| `pillar` | string | SUTD pillar (ISTD, EPD, ASD, ESD, DAI) |
| `year` | int | Academic year (1-5) |
| `totalEarned` | double | Lifetime earnings as hero |
| `rating` | double | Average star rating |
| `tasksCompleted` | int | Count of tasks done |
| `tasksPosted` | int | Count of tasks created |

### `tasks` Collection
| Field | Type | Description |
|-------|------|-------------|
| `title` | string | AI-generated task title |
| `description` | string | Full task description |
| `category` | string | One of 6 categories |
| `status` | string | `open` → `in_progress` → `arriving` → `completed` → `paid` |
| `compensation` | double | Payment amount in SGD |
| `posterUid` / `heroUid` | string | Linked user IDs |
| `location` | map | `{building, room, notes}` |
| `urgency` | string | `low` / `medium` / `high` / `urgent` |

---

## 🔄 Task Lifecycle

```
  ┌──────────┐    Hero accepts    ┌─────────────┐    Hero picks up    ┌──────────┐
  │   OPEN   │ ──────────────────►│ IN_PROGRESS  │ ──────────────────►│ ARRIVING │
  └──────────┘                    └─────────────┘                     └──────────┘
       │                                                                    │
       │ Poster cancels                                    Hero delivers    │
       ▼                                                                    ▼
  ┌──────────┐                                                       ┌───────────┐
  │ CANCELLED│                                                       │ COMPLETED │
  └──────────┘                                                       └───────────┘
                                                                           │
                                                              Poster pays  │
                                                                           ▼
                                                                     ┌──────────┐
                                                                     │   PAID   │
                                                                     └──────────┘
```

---

## 🛠️ Getting Started

### Prerequisites

- 📦 [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.8+)
- 🔥 [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- 🌐 Chrome browser (for web development)

### 1. Clone & Install

```bash
git clone <your-repo-url>
cd flutter_application_1
flutter pub get
```

### 2. Firebase Setup

The app uses Firebase project `health-is-wealth-b91b2`. You'll need:

1. **Firebase Auth** — Enable Google Sign-In provider in Firebase Console
2. **Cloud Firestore** — Create database (already has security rules in `firestore.rules`)
3. **Firebase Hosting** — Site `taskhero-sutd` already configured

> 📖 See [FIREBASE_AUTH_SETUP.md](FIREBASE_AUTH_SETUP.md) for detailed auth configuration steps.

### 3. API Keys

The app needs two API keys configured in `lib/services/api_service.dart`:

| Service | Variable | Where to Get |
|---------|----------|-------------|
| OpenAI | `_openaiApiKey` | [platform.openai.com](https://platform.openai.com/api-keys) |
| Deepgram | `_deepgramApiKey` | [console.deepgram.com](https://console.deepgram.com) |

### 4. Run Locally

```bash
flutter run -d chrome
```

### 5. Build & Deploy 🚀

```bash
flutter build web --release
firebase deploy --only hosting
```

Your app will be live at **[taskhero-sutd.web.app](https://taskhero-sutd.web.app)** 🎉

---

## 📚 Documentation

| Doc | Description |
|-----|-------------|
| 📖 [Knowledge_Base.md](Knowledge_Base.md) | Deep dive into everything — architecture, prompts, color scheme, patterns |
| 🔄 [Data_Flow.md](Data_Flow.md) | Complete data flow: UI → Services → Firestore → Streams, security rules |
| 🔥 [FIREBASE_AUTH_SETUP.md](FIREBASE_AUTH_SETUP.md) | Step-by-step Google Sign-In setup |
| 🔧 [SETUP_COMPLETE.md](SETUP_COMPLETE.md) | What's been built and how to verify everything works |
| 🌐 [URL_CHANGE_GUIDE.md](URL_CHANGE_GUIDE.md) | Guide for changing the hosting URL or adding custom domains |

---

## 🧠 The AI Behind TaskHero

### 🤖 Task Formatting (OpenAI GPT-4o-mini)

When you post a task, GPT-4o-mini transforms your casual description into a structured task:

```
Input:  "can someone buy me kopi o from canteen? i'm in building 2 room 310"
Output: {
  "title": "Buy Kopi O from Canteen",
  "description": "Purchase one Kopi O from the campus canteen...",
  "category": "Food & Delivery",
  "compensation": 3.00,
  "urgency": "medium",
  "location": { "building": "Building 2", "room": "310" }
}
```

### 🎤 Speech-to-Text (Deepgram Nova-2)

Click the mic button → speak your task → Deepgram transcribes it → AI formats it. No typing required! The browser's MediaRecorder API captures WebM/Opus audio, which gets sent to Deepgram's Nova-2 model.

---

## 📋 Task Categories

| Emoji | Category | Example |
|-------|----------|---------|
| 🍔 | Food & Delivery | "Buy me lunch from the canteen" |
| 📚 | Academic Help | "Help me debug my Python code" |
| 🏃 | Errands & Logistics | "Pick up my parcel from Building 1" |
| 💻 | Tech & Digital | "Help me set up my laptop" |
| 🎨 | Creative & Design | "Design a poster for my club event" |
| ❓ | Other | Everything else! |

---

## 🤝 How It Works (TL;DR)

```
You: "I need someone to buy me bubble tea from the canteen, I'm in hostel room 405"
         │
         ▼
    🎤 Deepgram STT (if voice)
         │
         ▼
    🤖 GPT-4o-mini formats it
         │
         ▼
    📋 Task posted to Firestore
         │
         ▼
    🦸 Hero sees it, accepts it
         │
         ▼
    🏃 Hero buys bubble tea
         │
         ▼
    🚀 Hero marks "arriving"
         │
         ▼
    ✅ Delivery done, poster confirms
         │
         ▼
    💰 Payment released (hero gets 95%)
         │
         ▼
    ⭐ Rate your hero!
```

---

## 🔒 Security

- 🔐 Firebase Auth required for all operations
- 🛡️ Firestore security rules enforce user-level access
- 🚫 Users can only edit their own tasks/profiles
- 🔑 API keys are server-side (not exposed to browser storage)
- 📝 All Firestore writes go through validated service methods

---

## 📄 License

This project was built for SUTD coursework. All rights reserved.

---

<div align="center">

**Built with 🧡 at SUTD**

*Because every campus needs its heroes* 🦸

</div>
