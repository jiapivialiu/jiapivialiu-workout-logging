# Workout Log / 训练记录

Mobile-first bilingual strength workout logger. No account required; records are kept in this browser (localStorage), with JSON export/import for backup. See `docs/SPEC.md` for features and data model.

## Run

Open `index.html` in a browser, or run `python3 -m http.server 8000` and visit `http://localhost:8000`.

## Deployment

Static web app suitable for GitHub Pages. GitHub repository > Settings > Pages > Deploy from a branch > `main` / `(root)`. Then check `https://jiapivialiu.github.io/jiapivialiu-workout-logging/`. A live Pages URL is not guaranteed until Pages is enabled and deployment succeeds.

## Privacy and backup

Records are stored **only on the device/browser** you use; they do not sync automatically. Export JSON regularly using Settings > Export, and import it on other devices. Clearing browser data deletes local records unless exported.
