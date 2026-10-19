# Workout Log — iPhone App

**Implementation:** Native SwiftUI, iOS 17+, single-user, device-local.

## What this is
An installable iPhone app with bilingual (中文 / EN) exercise names and UI, exercise tutorial links, editable workout templates, quick set logging, workout history and JSON backup/restore. No server, hosted website, API key, push notifications, or developer-maintained media library.

Project location: ios/WorkoutLog/WorkoutLog.xcodeproj

## GitHub vs. workout records
GitHub is used for **source control** (app source, built-in starter exercise list, specs and CI). Each user's workout records are saved in iPhone Documents/workout-data.json **on the device** and are NOT committed to the repository. GitHub repository access and CI alone do not install an app on your phone or sync workouts.

## Install on your own iPhone

1. Use a Mac with a compatible Xcode installation (Xcode 16+ recommended).
2. Clone the repository and open ios/WorkoutLog/WorkoutLog.xcodeproj.
3. In Xcode, choose the WorkoutLog target → Signing & Capabilities → check Automatically manage signing → pick your Apple Account's Personal Team / Developer Team.
4. Connect your iPhone, trust the Mac, and enable Developer Mode on the phone if prompted (Settings → Privacy & Security → Developer Mode).
5. Select your connected iPhone as the run target and press Run (▶).
6. The Workout Log icon appears on your phone; log training offline.

**Apple signing constraint:** With a free Personal Team, development provisioning profiles expire after 7 days and you must re-build/re-install periodically. An Apple Developer Program membership supports longer-term distribution and TestFlight (subject to Apple's rules). No app link can install this private native app without a signing/distribution step.

## Change language and manage routines
- Switch 中文 / English in the Settings tab.
- Add exercises with both localized names, muscle category, alias and optional HTTPS tutorial URL.
- Templates are editable ordered exercise lists; starter routines are included.
- Start a routine; prior weights/reps automatically prefill.
- Mark sets complete and tap Finish to save into History.
- In History, open a session to adjust weights, reps or completion status.

## Data persistence and backup
- App automatically writes workout-data.json to the app's on-device Documents directory.
- Settings → Export JSON backup → Save to Files (prefer iCloud Drive for personal backup).
- Settings → Import JSON backup restores a previously exported backup after explicit overwrite confirmation.
- Deleting the app may delete the local data. Export before replacing devices/uninstalling.
- Do not commit exported workout history to the GitHub repository if you want it private.
- No remote sync or authentication is part of this MVP.

## Quality checks
- GitHub Actions: Build iOS Workout App (macos-latest, unsigned iOS Simulator build).
- The existing web prototype remains at repository root but is not required by the native app.
- GitHub Pages is intentionally not used for deployment.

## Known limitations
- iPhone only; requires iOS 17 or later.
- No multi-device sync, background cloud backups, online database, workout charts, Apple Health or Apple Watch.
- Native installation must be performed through Xcode signing or a separately configured Apple developer distribution process.
