# Google Play Console checklist: Cairo Coding

Everything to upload is in this folder. The release bundle is
`build/app/outputs/bundle/release/app-release.aab` (version 1.0.2, build 3, built 2026-11-11).

**Before you send 1.0.2 for review:** deploy the Firestore rules and the website (`firebase deploy --only firestore,hosting`, after
`flutter build web -t lib/main_admin.dart`). The privacy policy online must already describe attendance, tasks and
certificates when the Data safety form below says so, and the app's Profile reads the diploma name through the new rules.

## 1. Create the app
Create app → App name **Cairo Coding** · Default language **English (United States)** · App · Free.
The package name `com.cairocodingschool.app` is permanent after the first upload.

## 2. App content (Policy → App content)

| Form | Answer |
|---|---|
| Privacy policy | https://cairo-coding-app.web.app/privacy/ |
| App access | All or some functionality is restricted → add the test student account (below) |
| Ads | No, my app does not contain ads |
| Advertising ID | No (the release manifest has no `AD_ID` permission) |
| Content rating | Category: Education/Reference. Answer **No** to violence, sexuality, language, drugs, gambling, user-generated content, sharing location, and digital purchases. Users can't chat or send each other anything; the group leaderboard only shows names and quiz scores inside a school group, so "users interact" stays **No** |
| Target audience | The real ages of your students. Never tick "under 13" (it triggers the Families policy). If some students are under 18, tick 13–15 and/or 16–17 as well |
| News app | No |
| Government app | No |
| Health | None |
| Financial features | None |
| Data safety | See below |
| Category | Education · contact email cairocodingschool1@gmail.com |

### App access instructions (paste, then fill in the account)
> Accounts are created by Cairo Coding School; there is no sign-up. Sign in with the email and password below. The account is enrolled in a group with upcoming sessions, recordings and a published quiz. No two-factor authentication.

Keep this account active and enrolled, and don't change its password, while any review is running. So the reviewer sees
every tab filled in, give the "Google Play Review" group a course (for the diploma on Profile), at least one published
quiz that is open, and one past session with attendance and a task ticked.

### Data safety
- Does your app collect or share user data? **Yes**, collects. **No** sharing.
- Encrypted in transit: **Yes**.
- Account creation: **My app does not allow users to create an account** (the school creates them).
- Users can request deletion: **Yes** → https://cairo-coding-app.web.app/delete-account/
- Data types (all **Collected**, **not shared**, processed ephemerally: **No**):
  - Personal info → **Name**, **Email address**, **Phone number**, **User IDs** (the Firebase account ID).
    Required. Purposes: **App functionality**, **Account management**.
  - App activity → **App interactions**: the app records when you join a session (attendance), which recordings you
    open, and when you last opened the app, so the school's dashboard can show them. Required.
    Purposes: **App functionality**, **Analytics**.
  - App activity → **Other user-generated content**: your quiz answers and scores. Optional (only if you take a quiz).
    Purpose: **App functionality**.
- Not collected by the app: task results and certificates (the school's staff enter those in the dashboard; the app
  only shows them), location, crash data, device IDs, photos, contacts. The app has no Analytics, Crashlytics or FCM
  SDKs, so Firebase itself adds nothing to this list. Reminders are local notifications, so they aren't data collection.
- Leaderboards show a student's name and score to the students of their own group. That is display inside the app,
  not sharing with a third party, so "shared" stays **No**.

### If asked about exact alarms
The app declares `SCHEDULE_EXACT_ALARM` (not the restricted `USE_EXACT_ALARM`). Reason: *session reminders
24 hours and 1 hour before scheduled classes, a core user-facing feature.*

## 3. Store listing (Grow users → Store presence → Main store listing)
- Title / short / full description: `listing/en-*.txt`
- App icon: `graphics/play-icon-512.png`
- Feature graphic: `graphics/feature-graphic.png`
- Phone screenshots, in this order: `screenshots/en/01.png` … `08.png` (01 + 02 are the two-part hero; keep them adjacent).
  Delete the old ones first: the October set showed the app before the redesign.
- Arabic: Manage translations → add **Arabic** → `listing/ar-*.txt`, `graphics/feature-graphic-ar.png`, `screenshots/ar/01.png` … `08.png`
- Video: optional, and YouTube links only.

## 4. Testing and release
A personal developer account created after 13 November 2023 must run a **closed test with at least 12 testers
for 14 days in a row** before it can apply for production.

1. **Internal testing** (installable within minutes, no review): Testing → Internal testing → create release →
   upload the `.aab` → testers = pilot students' Google emails → share the opt-in link. Use this for the pilot.
2. **Closed testing** (starts the 14-day clock): Testing → Closed testing → create track → add the same
   12+ pilot students → upload the same `.aab` → Send for review. Keep them opted in for 14 days.
3. After 14 days: Dashboard → Apply for production → promote the release.

Keep **Play App Signing** on when asked. The upload key stays on this Mac (see below).

### Release notes (1.0.2)
```
<en-US>
A fresh new look, plus quizzes with a leaderboard for your group, announcements from the school, and a Profile with your attendance, tasks and certificates.
</en-US>
<ar>
شكل جديد، واختبارات مع لوحة صدارة لمجموعتك، وإعلانات من المدرسة، وصفحة حسابك فيها الحضور والتاسكات والشهادات.
</ar>
```
Both are under Play's 500-character limit. If 1.0.1 was never uploaded, this is the first release and the notes still
read fine.

## Upload key (back this up)
- Keystore: `~/.android-keystores/cairo_coding/upload-keystore.jks`, alias `cairocoding-upload`
- Passwords: only in `android/key.properties` (git-ignored)
- Copy both into your password manager or a private drive. If they're lost, the upload key can only be reset
  through Play support.

## Next upload
Bump `version:` in `pubspec.yaml` (for example `1.0.3+4`; the build number must go up), then:
```bash
flutter build appbundle --release -t lib/main_student.dart
```
