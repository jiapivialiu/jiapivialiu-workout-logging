# Workout Log · 双语健身记录

**Native iPhone app (SwiftUI, iOS 17+)** for personal workout logging, with English/中文 exercise names.

## iOS app — current product

Open **[ios/WorkoutLog/WorkoutLog.xcodeproj](ios/WorkoutLog/WorkoutLog.xcodeproj)** in Xcode on a Mac. See **[iPhone installation and setup](docs/IOS_APP.md)** and **[iOS MVP specification](docs/IOS_PRODUCT_SPEC.md)**.

- 35 built-in exercises with Chinese and English names, searchable in either language.
- Add or edit exercises, aliases, muscle groups and optional external HTTPS tutorial links.
- Editable workout templates, quick sets / kg / reps logging, previous performance.
- Exercise and session history, editable historical set records.
- 中文 / EN toggle, entirely offline.
- Automatic device-local storage and manual JSON backup/restore.

**Data privacy:** Workout logs live only on the iPhone and are **never committed to GitHub**. GitHub is source control, not a workout-record database. Back up via Settings → Export JSON before replacing the phone or uninstalling.

**Installation:** A private native iPhone app cannot be opened from a repository URL. Use Xcode with an Apple Account to sign and install on your iPhone. A free Personal Team must periodically re-provision (typically every 7 days); a paid Apple Developer account allows additional distribution options. See [Apple's account documentation](https://developer.apple.com/help/account/basics/about-your-developer-account).

CI: **[Build iOS Workout App](.github/workflows/ios-build.yml)** compiles the unsigned iPhone simulator target on macOS.

## Legacy static prototype (not the current product)

The earlier mobile web proof-of-concept remains at repository root (`index.html`, `manifest.webmanifest`) for reference. It is not a backend and is not required by the iOS app. Its old GitHub Pages deployment workflow is now manual-only to avoid deployment failure notifications.

## Directory layout

- `ios/WorkoutLog/` — native SwiftUI app and Xcode project
- `docs/IOS_PRODUCT_SPEC.md` — current MVP scope
- `docs/IOS_APP.md` — install, version control and backup instructions
- `docs/SPEC.md`, `docs/DATA_MODEL.md` — previous web prototype specification
- `index.html` — previous web prototype
