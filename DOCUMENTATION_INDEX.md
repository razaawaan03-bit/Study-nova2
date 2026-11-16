# Study Nova Documentation Index

> **The authoritative document is [README.md](README.md).** Everything else in
> this list is either a setup guide, a historical implementation record, or a
> publication document. If the two ever disagree, README.md wins.

## 1. Start here

| I want to... | Read |
| --- | --- |
| Install, configure and run the app | [README.md](README.md) |
| Get running in five minutes | [QUICK_START.md](QUICK_START.md) |
| Understand how the app is put together | [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) |
| Create and configure the Supabase backend | [SUPABASE_SETUP.md](SUPABASE_SETUP.md) |
| Check off what is finished before launch | [COMPLETION_CHECKLIST.md](COMPLETION_CHECKLIST.md) |
| Read the launch audit and its findings | [STAGE_8_LAUNCH_REPORT.md](STAGE_8_LAUNCH_REPORT.md) |

## 2. Publication documents

These are required by Google Play and by the web build. Both are **placeholders
that must be completed before publishing**.

| Document | Purpose |
| --- | --- |
| [PRIVACY_POLICY.md](PRIVACY_POLICY.md) | What data Study Nova collects, where it goes, and the student's rights |
| [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md) | The agreement the student accepts when using the app |

## 3. Historical implementation records

These were written while a stage of the project was being built. They are kept
for context and for anyone tracing a decision. They are not kept in sync with
the current code, so treat details in them as a starting point rather than
fact.

| Document | Stage it records |
| --- | --- |
| [IMPLEMENTATION_COMPLETE.md](IMPLEMENTATION_COMPLETE.md) | Initial feature build |
| [IMPLEMENTATION_REPORT.md](IMPLEMENTATION_REPORT.md) | Initial feature build |
| [README_IMPLEMENTATION.md](README_IMPLEMENTATION.md) | Initial feature build |
| [STUDY_FROM_PHOTO_IMPLEMENTATION.md](STUDY_FROM_PHOTO_IMPLEMENTATION.md) | Study From Photo build |
| [START_HERE.md](START_HERE.md) | Early orientation |
| [VISUAL_OVERVIEW.md](VISUAL_OVERVIEW.md) | Early architecture diagrams |

## 4. What is in the project

```
studynova/
├── lib/
│   ├── main.dart               route table for every screen
│   ├── config/                 Supabase and AI configuration
│   ├── models/                 data classes
│   ├── screens/                one folder per feature
│   │   ├── about/              About Study Nova (version, policies, support)
│   │   ├── auth/               sign up, sign in
│   │   ├── course_maker/       build a course from your own documents
│   │   ├── home/               the main menu
│   │   ├── labs/               the six bundled study Labs
│   │   ├── missions/           day-by-day study planning
│   │   ├── study_from_photo/   photo → explanation, mind map, quiz
│   │   └── welcome/            first launch
│   ├── services/               Supabase, Gemini, storage, progress
│   ├── screen/                 splash
│   └── utils/                  local file storage
├── test/                       the automated checks
├── sql/                        run these in the Supabase SQL editor
├── android/                    Android app, launcher icon, signing setup
├── PRIVACY_POLICY.md           publication document (placeholder)
└── TERMS_OF_SERVICE.md         publication document (placeholder)
```

## 5. A note on the old coding feature

Earlier stages of this project included a coding playground. It has been
removed: there are no coding screens, routes, services or assets left in `lib/`,
and no coding Labs. The six Labs that remain are `gsc-fundamentals`,
`gsc-mastery`, `gk-india`, `gk-world`, `sst-mastery` and `sst-full-sst`.
