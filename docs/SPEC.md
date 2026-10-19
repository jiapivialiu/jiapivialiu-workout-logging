# Workout Tracker — MVP Specification
Version: 1.0 | Platform: mobile-first static PWA | Languages: zh-CN / en

## Purpose
A lightweight strength-training journal. No images or hosted tutorials, subscriptions, AI coaching, or social features.

## Product flows
1. **Exercises**: add/edit/archive exercise with English name, Chinese name, bilingual-search aliases, primary muscle group, and optional external HTTPS tutorial link. Seed with common exercises; each exercise has a stable unique ID.
2. **Templates**: create, rename, copy and remove ordered lists of exercise IDs. Predefined example templates are editable.
3. **Workout**: start blank or from a template; add/remove exercises; log arbitrary sets of weight (kg, decimal allowed) and integer reps; mark sets completed; prefill from previous set or historical values; save completed workout. Keep unfinished session across refresh.
4. **History**: list newest-first sessions; inspect/edit or delete a session. Exercise view surfaces its most recent completed performance.
5. **Bilingual UI**: toggle 中文 / EN instantly without changing workout data or interrupting forms. Name and muscle group respond to language selection; search matches both names and aliases, independent of UI language. User-authored template names are not translated.
6. **Tutorials**: open the saved external URL safely in a separate tab. No media uploaded, embedded or generated.
7. **Data portability**: export/import JSON backups (import replaces local data after confirmation).

## Data model
- Exercise: id, name_en, name_zh, aliases[], muscle_group, tutorial_url?, notes?, archived?
- Template: id, name, exercise_ids[] (ordered)
- Session: id, name, template_id?, started_at, completed_at?, notes?, exercises: [{exercise_id, sets:[{id,weight_kg,reps,completed}]}]
- Preferences: language

## Constraints and persistence
- Personal, single-browser MVP. Browser localStorage persists all records and unfinished workout, no cloud database/authentication or cross-device sync. Static seed data is bundled in source; app-maintained exercise records live in localStorage. Export data frequently.
- Validate weight >=0, finite; reps >=0, integer. Trim names, require both language fields, validate tutorial HTTPS URLs.
- Archived exercises retained for history. Template edits do not mutate saved sessions.
- No remote media, no embedded tutorial content.

## Out of scope
Cloud sync/Supabase, sign-in, nutrition, wearables, analytics dashboards, AI trainer, reminders, rest timer, photos or exercise videos.

## Acceptance criteria
- [ ] Switch interface language and exercise names with no data loss.
- [ ] Search by Chinese, English or alias.
- [ ] Add/edit/archive exercises, including tutorial URL.
- [ ] Create/edit/copy/delete templates, add/remove/reorder exercises.
- [ ] Start template or ad hoc session; add exercises and sets; edit/complete sets.
- [ ] Restore draft on refresh; show previous exercise values.
- [ ] Save session, inspect history, edit and delete sessions.
- [ ] Persist locally and support export/import backup.
- [ ] Usable on phone and desktop.

## Deployment
Static host like GitHub Pages. Repo owner must enable Pages in repository settings. GitHub repository access alone does not constitute an active website.
