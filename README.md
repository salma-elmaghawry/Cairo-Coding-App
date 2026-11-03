# Cairo Coding — Admin Dashboard & Student App

A Flutter Web admin dashboard and a mobile student app for **Cairo Coding School**, built from one codebase on Firebase.

- **Demo video:** https://youtu.be/3QkZTTSbrbQ
- **System design (Miro):** https://miro.com/app/board/uXjVEd9BKNo=/?share_link_id=122107319382

## What it does

**Admin dashboard (Flutter Web)**
- Create, edit and archive course groups (track, meeting link, location, start and end dates).
- Enroll students one by one or by pasting a list of emails. New emails get an account and a set-password email; existing accounts are just added to the group.
- Set weekly time slots and generate the group's sessions. Cancel, restore, reschedule, or add extra sessions.
- Add, edit and delete session recordings (YouTube or Google Drive links).
- Deactivate or remove students.
- Build quizzes on one page (questions, four options, points, timers, drag to reorder, preview), publish them to groups, and read per-quiz analytics.

**Student app (Android / iOS)**
- Next session with a live countdown and a one-tap "Join meeting".
- Full schedule with upcoming and past sessions, with moved, cancelled and extra sessions marked.
- Recordings, filterable by group.
- Session reminders 24 hours and 1 hour before, kept in step with schedule changes by a background sync every 6 hours.
- Quizzes: one question at a time with countdowns, automatic submit, results, and a leaderboard for their group.
- Arabic / English and light / dark / system theme.

## Technical highlights

- **One codebase, two apps.** `lib/main_admin.dart` and `lib/main_student.dart` each have their own router, so the student app never compiles admin code.
- **Riverpod** for state: Firestore reads are real-time streams exposed through `StreamProvider`s, derived state is plain `Provider`s, and `select` keeps rebuilds small.
- **go_router** with a single auth guard (splash → login → blocked / home) and shareable dashboard URLs such as `/groups/:groupId/schedule`.
- **Scheduling engine** that turns weekly slots into dated sessions in Africa/Cairo time, correct across daylight saving, and only regenerates sessions nobody has touched.
- **No server code (Firebase Spark plan).** Student accounts are created from the dashboard through a secondary Firebase app, so the admin stays signed in, and a password-reset email works as the welcome email.
- **Role-based Firestore security rules:** admins are listed in `admins/{uid}`, and students can only read their own groups while their account is active.
- **Tamper-proof quizzes without a server.** Security rules hide the answer key until an attempt is submitted, lock each answer, enforce time limits on the server's clock, and recompute every score the phone reports.
- **Offline cache** turned on to cut reads and keep the app usable on a weak connection.
- **Repository layer with swappable data sources.** Firebase in the app, an in-memory fake in tests. Errors are mapped to typed, translated messages through a sealed `Result` type.
- Arabic and English with full right-to-left layout, bundled fonts (Nunito, Cairo, JetBrains Mono), and a responsive sidebar / drawer layout.

## Tech stack

Flutter · Dart · Flutter Web · Riverpod · go_router · Firebase Auth · Cloud Firestore · Firestore Security Rules · easy_localization · timezone · flutter_animate

## Project structure

```
lib/
├── main_student.dart / main_admin.dart
├── core/      theme, fonts, assets, errors + Result, shared widgets, animations
├── data/      models, sources (Firestore / Auth), fake backend for tests, repositories
├── shared/    login, splash, blocked screen, preferences, routing guard
├── student/   student router and tabs (home, schedule, recordings, settings)
└── admin/     admin router, sidebar shell, groups, group detail tabs, settings
```

More detail in [docs/code-notes.md](docs/code-notes.md).

## Running it

```bash
flutter pub get

# Student app (pick an Android emulator or iOS simulator)
flutter run -t lib/main_student.dart

# Admin dashboard
flutter run -d chrome -t lib/main_admin.dart
```

In VS Code, use the **Student (iOS / Android)** and **Admin (Web)** launch configurations.

Admins are whoever has a document at `admins/{uid}` in Firestore. That document can only be created from the Firebase console.

## Firebase

- Project: `cairo-coding-app` (Spark plan)
- Deploy security rules: `firebase deploy --only firestore`
- Deploy the dashboard: `flutter build web -t lib/main_admin.dart && firebase deploy --only hosting`

## Tests

```bash
flutter test
```

- Auth redirect rules and the scheduling engine, including the daylight-saving change.
- End-to-end smoke tests that boot each app on the fake backend, sign in, and walk through every screen.
- Quiz scoring, ranking and analytics, plus the full student and admin quiz flows.
- Quiz security rules against the Firestore emulator: `cd tool/rules_test && npm install && npm test`. Run these after any change to `firestore.rules`.

## Status

MVP ready for Google Play. A pilot with one real group is planned for late October 2026. Store assets, listing text and the release checklist are in `store/`.
