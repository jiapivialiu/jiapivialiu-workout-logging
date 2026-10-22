# Workout Log — Native iOS MVP Product Specification

**Status:** Implementation in progress  
**Version:** 1.0  
**Target:** iPhone, iOS 17+, SwiftUI.  
**Audience:** One person; private, low-maintenance training log.

## Product definition
An offline, bilingual workout tracking app. It is not part of a portfolio website and requires no published frontend/server. Source code is versioned in the existing `jiapivialiu/jiapivialiu-workout-logging` repo.

## MVP features

### Workout (训练)
- Start a blank workout or pick one of four seeded templates (Lower Body, Back & Biceps, Chest & Shoulders, Full Body).
- Session includes a name, timestamp and ordered exercise entries.
- Add or remove session exercises; each exercise can have arbitrary sets.
- For a set: decimal weight (kg), nonnegative integer repetitions, completion toggle.
- Add/remove sets and edit recorded metrics. Added sets copy previous weight/reps; the first set pre-fills the last completed historical value when available.
- Show previous completed performance inline.
- Leave the app mid-workout and resume the active workout after restart.
- Finish a session only after one set is marked complete; discard requires confirmation.

### Exercises (动作库)
- 49 built-in bilingual exercises covering lower body, upper body, activation and core stability.
- Store stable ID, English and Simplified Chinese names, muscle group, aliases, notes and HTTPS tutorial URL. No images/media are produced or hosted.
- Group and filter the exercise library and exercise picker by one primary muscle group per exercise.
- Keep direction-specific variations as separate exercises with explicit bilingual qualifiers such as Front-Facing / Side-Facing or Hip Internal Rotation / Hip External Rotation.
- App updates append only missing built-in exercises by stable ID or bilingual name; they never replace user-created or user-edited exercises.
- Add/update/archive exercises; archived exercises remain resolvable in previous sessions.
- Search both languages and aliases regardless of selected UI language.
- Open a saved tutorial externally (e.g. YouTube, Bilibili, Xiaohongshu).

### History (历史)
- Saved workouts listed newest first with date.
- Open past sessions, append missed exercises at the end, reorder their exercises, edit their names and per-set weights/repetitions/completion, remove sets or add sets.
- Swipe to delete past sessions.
- No additional calendar or charts in MVP.

### Settings (设置)
- Toggle 中文 / English; localize labels and primary exercise name without changing stored records.
- Export the complete personal database as JSON to Files/iCloud Drive.
- Import a backup only after a destructive-overwrite confirmation.
- Explain device-local persistence and lack of account/cross-device sync.

## Data storage
- `TrackerData` Codable object is stored atomically at app sandbox Documents/workout-data.json.
- Exercises, templates, saved sessions and the current active session all persist on device.
- No live API, database host, password, sign-in or cloud service is provisioned.
- User workout records must never be committed to GitHub.
- GitHub tracks product documentation, seeds, app code, automated build status only.

## UX constraints
- Native SwiftUI with one screen per tab: Workout, Exercises, History, Settings.
- Prominent set completion controls and numeric keyboards.
- Minimal navigation depth, no external media embedding or brand-new image assets.
- iPhone form factor and small-screen readability.

## Deployment / build
- Xcode project committed under `ios/WorkoutLog/WorkoutLog.xcodeproj`.
- GitHub Actions unsigned Simulator build verifies compilation.
- Physical iPhone installation requires code signing under the user's Apple Account or an explicitly configured distribution method. Free personal provisioning profiles expire periodically (Apple documents seven days).
- GitHub Pages and personal portfolio updates are not part of distribution.

## Acceptance criteria
- [ ] Project builds with current Xcode for the iPhone simulator.
- [ ] iPhone user can install a signed development build.
- [ ] Bilingual exercise names and cross-language search work.
- [ ] Exercises and tutorial URLs are editable.
- [ ] Templates can be edited and used to start a session.
- [ ] Weight, reps, set completion, previous performance, autosave and history work.
- [ ] App relaunch preserves unfinished and saved sessions.
- [ ] Language switch does not change records.
- [ ] JSON backup export and confirmed restore work.
- [ ] No need to deploy a website or manually push training data.

## Not in MVP
Apple Health, Apple Watch, Apple Calendar sync, workout calendar, advanced analytics, AI training, nutrition, sign-in, remote cloud database, cross-device sync, TestFlight publishing automation, App Store public release.
