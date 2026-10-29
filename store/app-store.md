# App Store Connect checklist: Cairo Coding (iOS)

Bundle ID `com.cairocodingschool.app` (same as Android), iPhone + iPad, iOS 15+.
Published from Salma's personal (Individual) Apple Developer account. Pilot goes through TestFlight first,
then the same build is submitted to App Review.

## 1. Account and signing (one time)
1. Enroll at https://developer.apple.com/programs/enroll as an **Individual** ($99/year, 2FA on the Apple ID).
   Activation usually takes 24–48 hours.
2. Xcode → Settings → Accounts → add the Apple ID. Note the **Team ID** (developer.apple.com → Membership).
3. Put the Team ID in Xcode → Runner target → Signing & Capabilities → Team (keep "Automatically manage
   signing" on). This writes `DEVELOPMENT_TEAM` into `ios/Runner.xcodeproj/project.pbxproj`.

## 2. Create the app
App Store Connect → Apps → **+** → New App:
Platform **iOS** · Name **Cairo Coding: Class Schedule** · Primary language **English (U.S.)** ·
Bundle ID **com.cairocodingschool.app** · SKU **cairocoding-ios** · User access **Full access**.

## 3. Build and upload
Bump `version:` in `pubspec.yaml` first (the build number must go up on every upload), then:
```bash
flutter build ipa --release -t lib/main_student.dart
open build/ios/archive/Runner.xcarchive   # Xcode Organizer → Distribute App → App Store Connect → Upload
```
Or drag `build/ios/ipa/*.ipa` into Apple's **Transporter** app. Processing takes 5–30 minutes; the build
then shows under TestFlight. Export compliance is already answered in `Info.plist`
(`ITSAppUsesNonExemptEncryption = NO`: the app only uses HTTPS).

## 4. TestFlight (the pilot)
1. **Internal testing** (no review, minutes): add yourself as an internal tester and install from the
   TestFlight app on your iPhone. Check sign-in, schedule, recordings, Join meeting, and that a reminder fires.
2. **Test Information** (TestFlight → Test Information):
   - Beta App Description: the first paragraph of `listing/en-full.txt`.
   - Feedback email: cairocodingschool1@gmail.com
   - Privacy Policy URL: https://cairo-coding-app.web.app/privacy/
   - Sign-in required: the review account (section 6). Notes: the App Review notes below.
3. **External testing**: create a group **Pilot students** → add the build → What to Test (below) →
   Submit for Beta App Review (usually under a day).
4. After approval: group → **Public Link** → enable (set a tester limit, e.g. 100) → send it to iPhone students.
   Students install **TestFlight** from the App Store first, then open the link. Builds expire after 90 days.

What to Test:
```
<en>
First iOS build: your next session with a live countdown, the full schedule, recordings, and reminders 24 hours and 1 hour before each session. Please report anything that looks off.
</en>
<ar>
أول نسخة للآيفون: السيشن القادمة بعداد تنازلي، الجدول كامل، التسجيلات، وتنبيه قبل كل سيشن بـ 24 ساعة وبساعة. لو في حاجة شكلها غلط ابعتهالنا.
</ar>
```

## 5. App Store listing (Distribution → App Store → iOS App 1.0.x)

| Field (limit) | English | Arabic (add the Arabic localization) |
|---|---|---|
| Name (30) | Cairo Coding: Class Schedule | `listing/ar-title.txt` |
| Subtitle (30) | Never miss a session | متفوّتش ولا سيشن |
| Promotional text (170) | `listing/en-short.txt` | `listing/ar-short.txt` |
| Description (4000) | `listing/en-full.txt` | `listing/ar-full.txt` |
| Keywords (100) | `C++,programming,course,class,timetable,reminder,recordings,student,lessons,coding school` | `برمجة,كورس,سي بلس بلس,جدول,مواعيد,تسجيلات,تنبيه,طلاب,محاضرات,مدرسة برمجة` |
| Support URL | https://cairo-coding-app.web.app/privacy/ (has the contact email) | same |

- Category **Education** · Copyright **2026 Cairo Coding School** · Price **Free**.
- Screenshots: iPhone **6.9"** and iPad **13"** sets (section 8). Apple scales them down for smaller devices.
- Keywords must not name other brands (no "Zoom", "YouTube"); words already in the name don't need repeating.
- Version release: **Manually release this version**, so you control the launch day.

## 6. App Review information
- Sign-in required: **Yes**. Use a dedicated account, e.g. `salmaelmaghawry91+applereview@gmail.com`, created
  from the dashboard in an "App Review" group that has upcoming sessions and at least one recording. Type
  the password in App Store Connect only, never in this repo. Keep the account active while reviews run.
- Contact: Salma's name, phone and email.
- Notes:
> Cairo Coding is the companion app for students enrolled at Cairo Coding School. There is no sign-up in the
> app: the school creates each student's account, and the student sets a password from the welcome email.
> Please sign in with the account above; it is enrolled in a group with upcoming sessions and recordings.
> "Join meeting" opens the class's online meeting link, and recordings open in YouTube or Google Drive.
> Reminders are local notifications 24 hours and 1 hour before each session. Settings → Delete account
> links to our account deletion page. No two-factor authentication.

If review says the app is for a "limited audience", reply asking for **Unlisted App Distribution**
(https://developer.apple.com/support/unlisted-app-distribution/) instead of changing the app.

## 7. App Privacy, age rating and the other forms

| Form | Answer |
|---|---|
| Privacy Policy URL | https://cairo-coding-app.web.app/privacy/ |
| Data collection | **Yes, we collect data** |
| Data types | Contact Info → **Name**, **Email Address**, **Phone Number**; Identifiers → **User ID** |
| For each type | Used for **App Functionality** only · **Linked** to the user's identity · **Not** used for tracking |
| Tracking | No (no ads, no analytics, no IDFA) |
| Age rating | Answer **None/No** to everything (no user-generated content, no web browsing in-app, no purchases) → 4+ |
| Content rights | Does not contain, show or access third-party content (recordings are the school's own) |
| Encryption | Already answered by `Info.plist` |
| EU Digital Services Act | Declare trader status. "Trader" shows your address, phone and email to EU users; choose based on whether this is commercial activity for you |
| Sign in with Apple | Not required: the app has no third-party or social login |

Same data list as Google Play's Data safety (`play-console.md`). Firebase Auth and Firestore add nothing to it.

## 8. Screenshots
App Store screenshots must come from iOS. The Android captures in `screenshots/raw/` show the Android
status bar, and Apple rejects screenshots that show another platform.

| Set | Simulator | Size |
|---|---|---|
| iPhone 6.9" | iPhone 16 Pro Max | 1320 × 2868 |
| iPad 13" | iPad Pro 13-inch (M4) | 2064 × 2752 |

```bash
xcrun simctl boot "iPhone 16 Pro Max" && open -a Simulator
xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
flutter run -d "iPhone 16 Pro Max" -t lib/main_student.dart    # sign in with the demo account
xcrun simctl io booted screenshot store/screenshots/raw/ios-en/01.png   # one per screen
```
Capture the same 5 screens as the Play set, in English and Arabic. The debug banner is already off.

## iOS-specific behaviour
- Reminders: background sync (workmanager) is Android-only. On iOS the reminders are rescheduled every
  time the app opens and still fire while it's closed. If a session moves and the student doesn't open the app,
  the old reminder stays until they do.
- iOS allows 64 pending notifications; the app schedules at most 40 (`ReminderPlanner.maxReminders`).
