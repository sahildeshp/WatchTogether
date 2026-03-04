# WatchTogether

A couples iOS app for tracking movies and TV shows to watch together — built with SwiftUI, Firebase, and TMDB.

> **Vibecoded entirely with [Claude](https://claude.ai/claude-code) by Anthropic.**

---

## Features

- **Search** — Find any movie or TV show via TMDB
- **My List** — Personal watchlist with Want / Watching / Watched status tracking and 1–10 ratings
- **Our List** — Shared couple watchlist with real-time sync, nomination badges, and dual partner ratings
- **Couple Pairing** — Connect with a partner via a unique 6-digit invite code
- **Content Detail** — Full metadata including backdrop, poster, cast, genres, director/creator, runtime

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Language | Swift 6 (strict concurrency) |
| Auth | Firebase Auth (email/password + Apple Sign-In) |
| Database | Firestore (real-time sync + offline persistence) |
| Server logic | Firebase Cloud Functions |
| Image loading | Kingfisher |
| Movie/TV data | TMDB API v3 |
| Project generation | XcodeGen |

## Architecture

MVVM + Repository pattern. Each feature has a `View` and an `@Observable` `ViewModel`. Data access is abstracted behind protocol-based repositories with Firestore implementations.

```
Features/
├── Auth/          — Login, register, Apple Sign-In
├── Pairing/       — Create / join a couple
├── Search/        — TMDB search
├── MyList/        — Personal watchlist
├── CoupleList/    — Shared couple watchlist
└── ContentDetail/ — Full movie/TV metadata
```

## Getting Started

### Prerequisites

- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A [Firebase](https://firebase.google.com) project with Auth, Firestore, Functions, and Messaging enabled
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

## Development Phases

- [x] Phase 1 — Foundation (XcodeGen, SwiftData, Firebase setup)
- [x] Phase 2 — Authentication (email/password + Apple Sign-In)
- [x] Phase 3 — Couple Pairing (Cloud Functions, invite codes)
- [x] Phase 4 — TMDB Search + Content Detail
- [x] Phase 5 — My List (personal Firestore watchlist)
- [x] Phase 6 — Our List (shared couple watchlist with dual ratings)
- [ ] Phase 7 — Watch History
- [ ] Phase 8 — Polish & Testing

---

*Built with Claude Code — Anthropic's AI coding assistant.*
