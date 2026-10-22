# Workout Log — iPhone App

**Implementation:** Native SwiftUI, iOS 17+, single-user, device-local.

## What this is
An installable iPhone app with bilingual (中文 / EN) exercise names and UI, exercise tutorial links, editable workout templates, quick set logging, workout history and JSON backup/restore. No server, hosted website, API key, push notifications, or developer-maintained media library.

Workout weights default to pounds (lb). Change the global weight unit between lb and kg from the weight-column menu during a workout or from Settings; existing and historical values are converted automatically for display.

Project location: ios/WorkoutLog/WorkoutLog.xcodeproj

## GitHub vs. workout records
GitHub is used for **source control** (app source, built-in starter exercise list, specs and CI). Each user's workout records are saved in iPhone Documents/workout-data.json **on the device** and are NOT committed to the repository. GitHub repository access and CI alone do not install an app on your phone or sync workouts.

## Install on your own iPhone

1. Use a Mac with Xcode 15.4 or later and an iOS 17+ SDK (Xcode 16+ recommended).
2. From the repository directory, run `open ios/WorkoutLog/WorkoutLog.xcodeproj`.
3. In Xcode, choose the WorkoutLog target → Signing & Capabilities → check Automatically manage signing → pick your Apple Account's Personal Team / Developer Team.
4. Connect your iPhone, trust the Mac, and enable Developer Mode on the phone if prompted (Settings → Privacy & Security → Developer Mode).
5. Select your connected iPhone as the run target and press Run (▶).
6. The Workout Log icon appears on your phone; log training offline.

**Apple signing constraint:** With a free Personal Team, development provisioning profiles expire after 7 days and you must re-build/re-install periodically. An Apple Developer Program membership supports longer-term distribution and TestFlight (subject to Apple's rules). No app link can install this private native app without a signing/distribution step.

## Change language and manage routines
- Switch 中文 / English in the Settings tab.
- Add exercises with both localized names, muscle category, alias and optional HTTPS tutorial URL.
- Browse or filter both the exercise library and exercise chooser by primary muscle group.
- Direction-specific movements remain separate entries and use explicit name qualifiers, such as （正面）/ (Front-Facing), （侧面）/ (Side-Facing), （髋内旋）/ (Hip Internal Rotation), and （髋外旋）/ (Hip External Rotation).
- New app versions append missing built-in exercises without replacing custom exercises or edits.
- Templates are editable ordered exercise lists with reliable up/down controls. The built-in routines include three full-body plans ordered as activation, compound lifts and unilateral/stability finishers; app updates append these plans without replacing personal templates.
- Start a routine; prior weights/reps automatically prefill.
- Choose the workout date and start time; optionally set an end time or record it automatically when finishing.
- Mark sets complete and tap Finish to save into History.
- Add an overall workout review before finishing; it is saved with the session and previewed in History.
- In History, open a session to append a missed exercise, reorder exercises, or adjust its date/time, weights, reps, completion status or workout review.

## Data persistence and backup
- App automatically writes workout-data.json to the app's on-device Documents directory.
- Settings → Export JSON backup → Save to Files (prefer iCloud Drive for personal backup).
- Settings → Import JSON backup restores a previously exported backup after explicit overwrite confirmation.
- Deleting the app may delete the local data. Export before replacing devices/uninstalling.
- Do not commit exported workout history to the GitHub repository if you want it private.
- No remote sync or authentication is part of this MVP.

## Quality checks
- GitHub Actions: Build iOS Workout App (macos-latest, unsigned iOS Simulator build).
- The repository includes a shared `WorkoutLog` scheme, so Xcode and `xcodebuild` use the same checked-in build definition.
- Local unsigned Simulator check: `xcodebuild -project ios/WorkoutLog/WorkoutLog.xcodeproj -scheme WorkoutLog -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.
- The existing web prototype remains at repository root but is not required by the native app.
- GitHub Pages is intentionally not used for deployment.

## Known limitations
- iPhone only; requires iOS 17 or later.
- No multi-device sync, background cloud backups, online database, workout charts, Apple Health or Apple Watch.
- Native installation must be performed through Xcode signing or a separately configured Apple developer distribution process.
