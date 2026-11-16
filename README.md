# Study Nova

Study Nova is a Flutter study app for students. It turns a photo of a textbook
page, handwritten notes or a diagram into a clear explanation, builds
course-style study material from your own PDFs and images, and gives you a
guided day-by-day learning plan.

The app targets **Android** and **Web**.

## What is in the app

| Area | What it does |
| --- | --- |
| Course Maker | Pick PDFs, documents and images, and let AI turn them into a structured course you can save and reopen. |
| My Courses | Every saved course, with progress you can pick up again. |
| Study From Photo | Take a photo or choose one from the gallery, get an explanation, key points, a mind map and a quiz. |
| Study Library | Your saved photo analyses, stored per student account. |
| Study Nova Labs | Bundled, offline lessons and quizzes (Science, General Knowledge, Social Science) that need no AI. |
| Mission Mode | Set a goal, a subject and a daily study time; Study Nova plans the days, tasks, milestones and a Final Challenge. |
| Authentication | Email/password sign-up and sign-in with Supabase, with session restore on launch. |

Study Nova is a **studying** app. It contains no code editor, no programming
tools and no developer tooling.

## Project structure

```
lib/
  main.dart                     app entry point and named routes
  config/                       Supabase and AI configuration (build-time)
  data/                         bundled Lab content, mission catalog
  models/                       course, lab, mission and study-scan models
  screen/splash/                splash screen
  screens/
    auth/                       login and sign-up
    welcome/                    welcome and feature tour
    home/                       home dashboard
    course_maker/               course setup, materials, preview, my courses
    study_from_photo/           photo analysis, explanation, quiz, library
    labs/                       Labs home, lab detail, lesson, quiz
    missions/                   mission creation, roadmap, day, quiz, results
  services/                     auth, course, lab, mission, study scan, AI
  utils/                        file reading, local storage, Supabase guards
  widgets/                      shared widgets
sql/                            Supabase tables, RLS policies, storage policies
test/                           automated tests
```

## Configuration

**No credentials are checked into this repository.** Pass everything at build
time with `--dart-define`:

```powershell
# Supabase — required for accounts, saved courses and synced missions
--dart-define=SUPABASE_URL=https://<project>.supabase.co
--dart-define=SUPABASE_ANON_KEY=<anon-key>

# Google Gemini, required for AI features
--dart-define=GOOGLE_GENERATIVE_AI_KEY=<your-key>
--dart-define=GEMINI_MODEL=gemini-3.8-flash
```

Use the Supabase **anon / publishable** key. It is designed to ship inside a
client app: everyone can read it, and each student's data is protected by the
Row Level Security policies in `sql/`, not by hiding the key. Never put a
**service-role** key in the app or in a `--dart-define` argument — it bypasses
Row Level Security and would let anyone read or delete every account's data.

Running without Supabase configured is supported, not a failure: the app opens,
Study Nova Labs and the study plan work fully offline, and the online features
explain that setup is missing. **About Study Nova** shows a "Setup needed"
notice on such a build, so a misconfigured build is obvious immediately.

## Database setup

Run the SQL files in `sql/` in the Supabase SQL editor, in this order:

1. `sql/courses.sql`
2. `sql/study_scans.sql`
3. `sql/study_images_storage_policy.sql`
4. `sql/missions.sql`

## Running, testing and building

```powershell
# Run on a device or the web
flutter run
flutter run -d chrome

# Static analysis and tests
dart analyze lib
flutter test

# Release builds
flutter build web --release
flutter build appbundle --release
```

Release signing for Android is described in `android/key.properties.example`.
Never commit `android/key.properties` or a keystore.

## Offline behaviour

Labs, mission planning, lesson content and quizzes work without a network and
without an AI key. AI features (photo analysis, course generation) need the
Gemini key and show a friendly message plus a retry when the service is
unavailable.

## Privacy and terms

`PRIVACY_POLICY.md` and `TERMS_OF_SERVICE.md` hold the publication documents.
Both are placeholders: fill in the owner details, the contact address, the
retention period and the governing law, then host the privacy policy at a public
URL and put that URL in the Google Play listing.

Study Nova stores the study material a student uploads (photos, documents) in
the student's own Supabase account, scoped per user by Row Level Security. The
app sets `allowBackup="false"` so the session token is not copied into Android's
cloud backup. See the launch audit in `STAGE_8_LAUNCH_REPORT.md` for the full
list of what is finished and what is left for the owner.
