# WatchTogether

A couples iOS app for tracking movies and TV shows to watch together — built with SwiftUI, Firebase, and TMDB.

> **Vibecoded with [Claude](https://claude.ai/claude-code) by Anthropic.**

---

## Features

- **Search** — Find any movie or TV show via TMDB
- **My List** — Personal watchlist with Want / Watching / Watched status and 1–10 ratings
- **Our List** — Shared couple watchlist with real-time sync, nomination badges, and dual partner ratings
- **Watch History** — Unified chronological log of everything watched from both lists, grouped by month with All / Movies / TV filtering
- **Couple Pairing** — Connect with a partner via a unique 6-digit invite code; works standalone without a partner
- **Profile** — Avatar upload, partner status, dark mode toggle, leave couple
- **Content Detail** — Full metadata: backdrop, poster, cast, genres, director/creator, runtime
- **Push Notifications** — Partner gets notified when you join using their invite code
- **Dark Mode** — Per-app toggle that overrides the system setting
- **Offline Support** — Firestore offline persistence keeps your lists available without a connection

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Language | Swift 6 (strict concurrency) |
| Auth | Firebase Auth (email/password + Apple Sign-In) |
| Database | Firestore (real-time sync + offline persistence) |
| Storage | Firebase Storage (profile photos) |
| Push | Firebase Cloud Messaging |
| Server logic | Firebase Cloud Functions (Node.js) |
| Image loading | Kingfisher |
| Movie/TV data | TMDB API v3 |
| Project generation | XcodeGen |

## Architecture

MVVM + Repository pattern. Each feature has a `View` and an `@Observable` `ViewModel`. Data access is abstracted behind protocol-based repositories with Firestore implementations injected at the call site — making ViewModels fully unit-testable with mock repositories.

```
Features/
├── Auth/          — Login, register, Apple Sign-In
├── Pairing/       — Create / join a couple (sheet from Profile)
├── Search/        — TMDB search with debounced query
├── MyList/        — Personal watchlist
├── CoupleList/    — Shared couple watchlist
├── ContentDetail/ — Full movie/TV metadata
├── WatchHistory/  — Aggregated watch log
└── Profile/       — Account, photo, partner, appearance
```

## Getting Started

### Prerequisites

- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A [Firebase](https://firebase.google.com) project with Auth, Firestore, Storage, Functions, and Messaging enabled
- A [TMDB API key](https://www.themoviedb.org/settings/api)

### Setup

1. Clone the repo
2. Add `WatchTogether/Resources/GoogleService-Info.plist` from your Firebase Console
3. Create `WatchTogether/Configuration/Debug.xcconfig` with your TMDB key:
   ```
   TMDB_API_KEY = your_key_here
   ```
4. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
5. Open `WatchTogether.xcodeproj` and run

### Deploy backend

```bash
# Cloud Functions (pairing logic + FCM notifications)
firebase deploy --only functions

# Firestore security rules
firebase deploy --only firestore:rules
```

## Firestore Security Rules

- Users can only read/write their own `users/{userId}` document and personal watchlist
- Couple documents are write-locked to the server (Cloud Functions only)
- Couple watchlists are restricted to the couple's `memberIds`

## Development Phases

- [x] Phase 1 — Foundation (XcodeGen, SwiftData, Firebase setup)
- [x] Phase 2 — Authentication (email/password + Apple Sign-In)
- [x] Phase 3 — Couple Pairing (Cloud Functions, invite codes)
- [x] Phase 4 — TMDB Search + Content Detail
- [x] Phase 5 — My List (personal Firestore watchlist)
- [x] Phase 6 — Our List (shared couple watchlist with dual ratings)
- [x] Phase 7 — Watch History (unified log, month grouping, media filter)
- [x] Phase 8 — Polish & Testing (security rules, profile photo, accessibility, unit + UI tests)

---
