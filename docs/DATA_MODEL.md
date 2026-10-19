# Exercise database

The application seeds 26 bilingual exercise definitions in `index.html` and stores user edits in browser localStorage under `bilingual-workout-v1`. The records are keyed by stable exercise IDs, not translated names.

Data structures: `exercises` (id, name_en, name_zh, aliases[], muscle_group, tutorial_url, notes, archived), `templates` (id, name, exercise_ids[]), `sessions` (id, name, started_at, completed_at, notes, exercises[] with sets), `draft` (unfinished session), and `lang`.

**This is a local database, not a hosted PostgreSQL/Supabase instance.** It cannot automatically sync across devices. Settings > Export / Import supports backup. For future Supabase migration, normalize templates into template_exercises and session exercises into session_exercises; keep UUID IDs and RLS by user_id.
