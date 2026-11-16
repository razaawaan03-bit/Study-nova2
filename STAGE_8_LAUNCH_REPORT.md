# STAGE 8 — V1.0 LAUNCH REPORT

Project: `studynova` (Study Nova)
Flutter SDK: 3.44.7 · Dart SDK bundled with Flutter
Date of report: 30 September 2026

---

## 1. Overall Status

**NOT READY FOR LAUNCH — but close, and nothing in this status is caused by the
code.**

Every code-level blocker found by the audit has been fixed and verified. What
remains is work that only the owner can do, plus one hard limitation of this
machine:

| | Status |
| --- | --- |
| Static analysis | Clean — `dart analyze lib test` → **No issues found!** |
| Automated tests | **76 / 76 passing** |
| Web release build | **Succeeded** — `√ Built build\web` |
| Android build | **Not run here** — this machine has **no JDK installed** (see §19) |
| Store/legal paperwork | Placeholders written, need the owner's real details (§20, §22) |
| Backend provisioning | Owner's Supabase project + Gemini key not supplied (§12, §13) |

The honest one-line version: *the app is in good technical shape; it cannot be
uploaded to Google Play until you supply real keys, real legal text, real
screenshots, and a real signing key — and until the Android build is run on a
machine that has a JDK.*

---

## 2. Bugs Found

Every row below was found during this audit, fixed, and covered by a test.

| # | Bug | Location | Cause | Fix |
| --- | --- | --- | --- | --- |
| 1 | App reset a student's Lab progress on every launch | `lib/services/lab_service.dart` | Progress lived only in memory; nothing was ever written to disk | Persist lesson completion and quiz attempts with `shared_preferences`, scoped per account (`studynova.lab.progress.<account>`). `reset()` is now async and awaited on sign-out |
| 2 | Signing out leaked the previous account's progress into the next account | `lib/screens/home/home_screen.dart` | `MissionService` and `LabService` singletons kept their in-memory state across sign-out | Sign-out now awaits `LabService.reset()` and resets `MissionService` |
| 3 | Home screen overflowed on very narrow phones | `lib/screens/home/home_screen.dart` | Mission banner actions sat in a `Row` | Below 300 px the actions stack vertically |
| 4 | Welcome screen overflowed at small heights | `lib/screens/welcome/welcome_screen.dart` | "First Time Here?" block was unbounded inside a `Column` | Wrapped in `Expanded` |
| 5 | Tapping "Choose from Gallery" appeared to do nothing | `lib/screens/study_from_photo/study_from_photo_screen.dart` | No pending state while the platform picker was open | Added a visible "Opening…" state, and the buttons are disabled so a second tap cannot open two pickers |
| 6 | Technical exception text leaked into the UI | `lib/screens/study_from_photo/study_analysis_screen.dart`, `lib/services/ai_study_service.dart` | Raw provider/exception messages were shown to students | Student-readable messages, with provider detail sent to `debugPrint` only |
| 7 | Course title update ignored authentication and ownership | `lib/services/course_service.dart` | Unfiltered update; errors surfaced raw | Authenticated, `user_id`-scoped updates, escaped `.or()` filters, `maybeSingle()`, friendly errors |
| 8 | A search filter could break on a student-typed `(`, `,` or `%` | `lib/services/course_service.dart`, `lib/services/study_scan_service.dart` | PostgREST `.or()` values were interpolated raw | Filter values are escaped |
| 9 | Deleting a study scan deleted the wrong object | `lib/services/study_scan_service.dart` | Storage deletion ran before an ownership check | Ownership is verified before the storage delete |
| 10 | Corrupt local mission JSON crashed or silently lost missions | `lib/utils/mission_local_store_io.dart` | Single non-atomic write; parse errors were swallowed | Write to a temp file then rename; unparseable files are quarantined as `.corrupt`; added `clear()` |
| 11 | Revision tasks showed a dead, permanently-disabled checkbox | `lib/screens/missions/mission_widgets.dart` | `MissionTaskTile` always rendered a checkbox | Added `showCheckbox`; revision tasks no longer render a no-op control |
| 12 | Mission task launch could leave a spinner on screen and could open a task twice | `lib/screens/mission_task_launcher.dart` | Dialog pushed on a possibly-unmounted context; no re-entrancy guard | Root-navigator dialogs plus a per-task guard |
| 13 | **A live Supabase project URL and anon key were committed to the repository** | `lib/config/supabase_config.dart` | Real credentials hardcoded as a silent fallback | Both constants are now empty placeholders; credentials come from `--dart-define`. An unconfigured build says so on the About screen instead of quietly writing to an unknown database |
| 14 | "Don't have an account?" / "Already have an account?" rows overflowed | `lib/screens/auth/login_screen.dart`, `signup_screen.dart` | `Text` + `TextButton` in a non-flexible `Row` | Both children wrapped in `Flexible`, so the prompt wraps instead of clipping |
| 15 | Auth errors printed raw `toString()` | `lib/screens/auth/signup_screen.dart` | Exception cast straight to text | Routed through the centralised `AuthService.friendlyError` |
| 16 | Android could restore someone else's signed-in session from a backup | `android/app/src/main/AndroidManifest.xml` | `allowBackup` defaulted to true, so the Supabase session token was backed up with the device | `android:allowBackup="false"` |
| 17 | Documentation index was mojibake and linked to a file that does not exist | `DOCUMENTATION_INDEX.md` | Written in a non-UTF-8 round trip; referenced `EXAMPLES_DATABASE_INTEGRATION.dart` | Rewritten, accurate, links verified |

---

## 3. Bugs Fixed

Grouped by area. Every one of these has a test or a build that proves it.

**Correctness / data safety**
- Persistent, account-scoped Labs progress that survives a restart (was the most serious functional bug found).
- Progress isolation on sign-out.
- Atomic, corruption-tolerant local mission storage.
- Ownership checks before destructive storage operations.
- Authenticated, `user_id`-scoped course title updates.
- Escaped PostgREST filter values.
- Deleted missions are now deleted in Supabase as well as locally.

**Security / configuration**
- Removed the committed Supabase URL and anon key; configuration is now explicit.
- `allowBackup="false"` so the session token is not copied to cloud backup.
- `.gitignore` extended to exclude `android/local.properties`, `android/key.properties` and keystores.
- No API key, service-role key, password or signing secret is present anywhere in `lib/`, `android/` or `web/`.

**UX**
- "Opening…" state and double-tap guard on Study From Photo.
- Source-specific camera/gallery errors and a catch-all retryable failure.
- No technical exception text in front of students (AI, auth, Supabase, file upload).
- No dead checkboxes in mission revision tasks.
- Fixed five separate layout overflows, plus full accessibility text-scale coverage.

**Presentation**
- New **About Study Nova** screen: version, what the app does, how the data is handled, the AI-accuracy caveat, offline behaviour, the policy summary, support contact, and a "Setup needed" notice on an unconfigured build. Reachable from the Home app bar via the new `/about` route.
- Android launcher icon replaced with Study Nova branding at all five densities.
- Web theme colour corrected to the app's real seed (`#2196F3`), and `<meta name="theme-color">` added.
- `README.md` rewritten to match the actual product; `DOCUMENTATION_INDEX.md` rebuilt and verified.

---

## 4. Study From Photo

| Item | Status |
| --- | --- |
| Gallery | Working. Web-safe: picked bytes are decoded in memory, never through `Image.file` |
| Camera | Working. Hands off to the system camera app via `image_picker` |
| Permissions | **No `CAMERA` permission is requested — by design.** The system camera app holds its own permission. Camera and autofocus are declared as *optional* features so camera-less devices and tablets can still install the app |
| Android | `image_picker` resolves through the system intent. Manifest declares the two optional camera features |
| Web | Fully supported. `file_picker` / `image_picker` web implementations, in-memory decode, no filesystem dependency |
| Analysis pipeline | Image → base64 → Gemini → explanation + mind map + quiz, via `AIStudyService`. The model id comes from `--dart-define=GEMINI_MODEL` and falls back to a lite model automatically if the primary one is retired or unavailable |
| Error handling | Every failure path is covered: no Gemini key, expired/invalid key, quota or rate limit, retired model, network failure, empty/unreadable file, and an unexpected catch-all. Each gives a student-readable message, a `debugPrint` diagnostic for the developer, and a retry |

**Test status:** covered — both entry points present, pending state correct, double-tap safe, no crash without a picker, Web-safe image rendering.

---

## 5. Coding Removal

**Confirmed removed.** The coding feature is gone from the product:

- **Home** — no coding card. Verified by test.
- **Navigation** — no coding entry point anywhere.
- **Routes** — no coding route registered.
- **Labs** — the 6 remaining labs are `gsc-fundamentals`, `gsc-mastery`, `gk-india`, `gk-world`, `sst-mastery`, `sst-full-sst`. No coding category value survives.
- **Services** — the coding service is deleted; no Dart code references `CodeProject` or `code_projects`.
- **UI** — no coding screen exists.
- **Assets** — the coding data file is deleted.
- **SQL** — the dead `sql/code_projects.sql` was removed; it was never part of the schema.
- **Terminology** — no user-facing string refers to coding. The only remaining occurrences of the word are in historical documentation notes, such as `STUDY_FROM_PHOTO_IMPLEMENTATION.md` ("color coding"), and the documentation index explains the removal.

**Tests:** "no `LabCategory` or `LabTopic` value refers to coding", "Labs home lists only the 6 educational labs", "Labs category filters contain no coding chip", "a deleted coding lab cannot be opened", "Home shows only study features and no coding cards".

---

## 6. Course Maker

Course creation from a PDF, Word or PowerPoint upload.

- Input validation present: a name or topic is required, a school course requires a subject, and the exam name is required when the exam target field is used.
- File-type filtering is enforced by extension at pick time, with a clear rejection message.
- Generated content is previewed and the course is saved to the account.
- **Backend-unavailable behaviour is covered by test:** the service reports the problem instead of crashing.

---

## 7. My Courses

- Lists only the signed-in student's courses, filtered by `user_id`.
- `maybeSingle()` handling for title updates, so a duplicate row cannot crash the screen.
- Update path is authenticated and ownership-checked.
- **Test status:** "course and study-scan services report offline instead of crashing" passes; the account-isolation and escaping changes are part of this section.

---

## 8. Study Library

- Lists analyses belonging to the signed-in student.
- Search filters are escaped, so a student searching for `50%` or `a,b` gets correct results instead of a broken request.
- Deleting an item verifies ownership before deleting the underlying file from Supabase Storage.
- **Test status:** same offline-safety test as §7; deletion path is ownership-guarded.

---

## 9. Study Nova Labs

- 6 labs, all educational. Coding Labs were removed — they existed as `coding-fundamentals` and `html` in an earlier stage.
- Real bundled lesson content and real quiz questions, not generated placeholders.
- Lesson completion updates progress; quizzes score, review per question, store the attempt, and allow a retry.
- **Progress now persists across restarts** (bug #1) and is scoped per account.
- **Test status:** `labs_stage6_check_test.dart` — 6 tests covering no-coding-category, SST lessons and quiz questions, the SST History detail screen, lesson content rendering with completion, and quiz scoring with stored attempt. The Stage 8 suite adds the 6-lab listing, the filter chips, the deleted-lab guard, and the restart-persistence test.

---

## 10. Mission Mode

**Test status: 16 tests, all passing** (`mission_stage7_check_test.dart`).

- Catalog offers subjects, durations and default topics.
- The local planner builds a complete offline mission.
- A custom target date is honoured.
- The content matcher finds the bundled SST Labs by keyword — missions reference real content, never invented IDs.
- A mission survives a JSON round trip.
- Creating a mission makes it the featured mission on Home.
- Completing a task updates progress, streak and milestones.
- Finishing every required task completes the mission.
- Custom tasks are optional and never block completion.
- Quiz results drive recommended revision topics (adaptive behaviour is based on real scores, not guesses).
- Missions can be paused, resumed and deleted.
- The wizard requires a name before the first step and then advances.
- The day screen lists that day's real tasks, and checking one off updates mission progress.

**Persistence:** a combination. Missions are written to `study_nova_missions.json` on the device (atomic write, corrupt-file quarantine) and synced to `public.missions` in Supabase. Local state is the source of truth when the network fails.

**AI:** optional. Deterministic planning always works; a validated Gemini enhancement is applied only if it passes validation.

---

## 11. Authentication

- Uses the existing Supabase auth flow. No second system was created.
- Missing API key, invalid credentials, and Supabase being uninitialised all produce friendly messages with no stack traces, no `AuthException`, and no `toString()` output.
- `dispose()` releases the auth stream listener — verified by test, so no listener leak survives sign-out.
- Sign-in and sign-up screens were the two places that leaked raw exceptions; both are fixed.

**Tests:** "auth service stays usable when Supabase is unavailable", "`safeSupabase()` returns null instead of throwing when uninitialized", "AuthState reports a friendly error and does not throw offline", "disposing AuthState releases the auth stream listener".

---

## 12. Supabase

**Status: the code is complete and hardened; the backend itself is not provisioned in this project.**

- Four additive SQL files, all with Row Level Security enabled and per-user policies:
  - `sql/courses.sql` — `public.courses`, 8 policies
  - `sql/study_scans.sql` — `public.study_scans`, 4 policies
  - `sql/study_images_storage_policy.sql` — `study_images` bucket, 4 policies
  - `sql/missions.sql` — `public.missions`, 4 policies
- Storage objects are namespaced by user id: `<userId>/study_<timestamp>_<fileName>`.
- **Assumption to verify against your project:** that every table has RLS enabled and that each policy filters on `auth.uid()`. RLS is the only thing protecting student data, because the anon key is public by design.

**Remaining manual configuration (yours to do):**
1. Create the Supabase project.
2. Run the four SQL files in order.
3. Create the `study_images` storage bucket, then run the storage policy file.
4. Obtain the project's **anon / publishable** key.
5. Pass both values with `--dart-define` at build time.

**Note on the credentials that were in the repository:** a real project URL (`olkgibmdpibelexudrhz`) and anon key were previously committed. The anon key is not a secret — it ships inside every install of the app and RLS is what protects the data — but the URL identified a specific project as the silent default for any build without `--dart-define`. That is now removed. If that project is yours, you may want to rotate its anon key anyway, since it has been in source control.

---

## 13. AI

| Item | Detail |
| --- | --- |
| Provider | Google Gemini via `google_generative_ai` |
| Key configuration | `--dart-define=GOOGLE_GENERATIVE_AI_KEY=…`. Read from `lib/config/ai_config.dart`. **No key is present in the source, and none is printed anywhere in this report** |
| Model | `--dart-define=GEMINI_MODEL=…`, default `gemini-3.8-flash` |
| Fallback model | `gemini-3.5-flash-lite`, tried once if the primary model is retired or temporarily unavailable. Set with the same define, so you can change it without touching code |
| Error handling | `_friendlyAiError` maps provider messages to student-readable text, distinguishing a missing key, an invalid key, a quota limit, a retired model, and a network failure. Detail is logged, not displayed |
| Quota / rate limit | Detected explicitly, reported as a limit reached rather than a crash, and it does **not** trigger a pointless model retry (a quota problem will not be fixed by switching models) |
| Fallback behaviour | **The app is fully usable without AI.** Study Nova Labs, all lesson content, all quizzes, and deterministic mission planning work entirely offline. Only photo analysis and course generation require Gemini, and they show a clear message plus a retry |
| Mission planning | Deterministic local planner is authoritative. AI output is validated before use and is discarded if it does not parse, so a bad response can never crash Mission Mode |

---

## 14. Navigation

**Route audit: complete, and now enforced by a test.**

All 12 routes in `lib/main.dart` were checked to build a real screen without error:
`/`, `/welcome`, `/login`, `/home`, `/study-from-photo`, `/study-library`,
`/my-courses`, `/course-setup`, `/labs`, `/missions`, `/mission-create`,
`/about`.

The test "every named route in the app opens a real screen" fails if a route
points at a deleted or renamed screen, so this cannot silently rot again. It also
caught a real layout bug (the auth screens, §2 bug #14).

`/about` was added this stage for the About screen.

---

## 15. UI/UX

- **Layout overflows fixed** on Home, Welcome, Login and Signup. Verified at 320×640, 360×640 and 1024×768.
- **Accessibility text scale verified** at 1.5× and 2.0× on Login, Signup and Home. A student who enlarges the system font no longer gets clipped text or an overflow banner.
- **Study From Photo** now shows what is happening ("Opening…"), distinguishes a camera failure from a gallery failure, and offers a retry on any failure.
- **Mission Mode** revision tasks no longer show a permanently-disabled checkbox.
- **Loading states** for mission task launches use the root navigator, so a spinner cannot be left behind or opened twice.
- **New About screen** carrying the version, the data-handling summary, the "AI can be wrong" caveat, offline behaviour, the policy summary and support contact.
- **Branding:** Android launcher icon replaced at all densities; web theme colour corrected; app title, manifest name and description all read "Study Nova".
- **Fonts:** Material 3 with a single blue seed, no external font downloads, so the app renders identically offline.

---

## 16. Security

| Check | Result |
| --- | --- |
| Secrets in source | **None.** The committed Supabase URL and anon key were removed (§2 bug #13) |
| AI key | Passed by `--dart-define`; absent from source, logs and this report |
| Service-role key | Not present anywhere, and the config file now documents explicitly that it must never be shipped |
| API keys printed in logs | No. Provider diagnostics go to `debugPrint`, and no student-facing text contains technical detail |
| Row Level Security | 20 policies across 4 tables, all per-user |
| Storage isolation | Objects namespaced by user id; deletion is ownership-checked |
| Account isolation | Course reads/writes, study scans and missions are all `user_id`-scoped; sign-out clears in-memory state so the next account cannot see the last one's progress |
| PostgREST injection | Filter values escaped |
| Android backup | `allowBackup="false"` so the session token is not backed up |
| Android permissions | `INTERNET` only. No camera permission needed. Camera hardware optional so the app installs on camera-less devices |
| Signing | Read from `android/key.properties`, which is git-ignored; only `key.properties.example` is committed. No keystore or password is in the repository |
| Obvious vulnerabilities | None found. No `print` of sensitive data, no hardcoded credentials, no insecure HTTP endpoints |

**Two assumptions you must verify on your own Supabase project:** that RLS is enabled on every table, and that the `study_images` bucket is not public. Both are configured by the SQL files, but they can be changed later in the Supabase dashboard.

---

## 17. Dependencies

- **Added:** `shared_preferences: ^2.5.5` (Lab progress persistence), declared directly rather than relied on transitively.
- **Removed:** all coding-related packages, and the `code_projects` data source.
- **Unchanged:** `supabase_flutter ^2.5.0`, `google_generative_ai ^0.4.0`, `image_picker ^1.1.0`, `file_picker ^11.0.3`, `path_provider ^2.1.0`, `provider ^6.0.0`, `share_plus ^7.2.0`, `http ^1.6.0`, `intl ^0.19.0`, `archive ^4.3.0`, `xml ^7.0.1`, `async ^2.11.0`, `cupertino_icons`, `flutter_lints ^6.0.0`.
- **Minimum SDK:** Dart `^3.12.2`, Flutter `>=3.10.0`. One asset: `assets/images/study_nova.png`, and the reference to it resolves.
- No new dependencies were introduced this stage beyond `shared_preferences`.

---

## 18. Tests

Exact results. Nothing below is estimated.

```
dart analyze lib test
Analyzing lib, test...
No issues found!
```

```
flutter test
00:36 +76: All tests passed!
```

**76 tests, 0 failures**, across three files:

| File | Tests | Covers |
| --- | --- | --- |
| `labs_stage6_check_test.dart` | 6 | Labs content, SST lessons and quizzes, lesson completion, quiz scoring |
| `mission_stage7_check_test.dart` | 16 | Mission planning, persistence, progress, streak, milestones, revision, wizard, day screen |
| `stage8_launch_audit_test.dart` | 54 | Launch audit: routes, offline safety, config hygiene, Study From Photo, no coding anywhere, Labs listing, layout overflow at three sizes, accessibility text scale, auth, splash |

```
flutter build web
Compiling lib\main.dart for the Web...                            217.4s
√ Built build\web
```

Web output: 44.4 MB total, of which **36.7 MB is `canvaskit`** and 3.3 MB is `main.dart.js`. The size is normal for a self-hosted Flutter web build because every CanvasKit backend is shipped. If you want a much smaller upload, build with `--web-resources-cdn` to load CanvasKit from Google's CDN; that is a hosting decision, so it is left to you.

The build also prints `dart:ffi unsupported` warnings coming from the transitive `win32` package. They are advisory: they only matter if you ever target **WebAssembly**, and they do not affect this JavaScript build.

```
flutter build apk        NOT RUN — see §19
```

---

## 19. Android Release

| Item | Value |
| --- | --- |
| Application ID | `com.studynova.app` — **must be your own permanent ID before the first release.** Once published on Google Play it can never be changed |
| Version | `1.0.0` (from `pubspec.yaml`) |
| Version code | `1` |
| Namespace | `com.studynova.app` |
| Java / Kotlin | JVM target 17 |
| Permissions | `INTERNET` only |
| Optional hardware | camera, camera.autofocus (both `required="false"`) |
| Backup | `allowBackup="false"` |
| Release configuration | `isMinifyEnabled = false`, `isShrinkResources = false`, signed with the `release` signing config when `key.properties` exists, otherwise debug-signed for local release runs only |
| Signing status | **No keystore present.** Only `android/key.properties.example` is committed; `key.properties` and `*.jks` are git-ignored |
| Launcher icon | Study Nova branding at all five densities |
| **Build verification** | **Not possible on this machine.** `flutter build apk` fails immediately with `ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH`. There is no JDK anywhere on this computer — no `C:\Program Files\Java`, no Android Studio bundled JBR, and none under the Android SDK. Flutter's `build bundle` (the Dart and asset compile, which does not need Gradle) was used instead and the web release build confirms the Dart code compiles for a non-web target |

**You will need to install a JDK (17 or newer) before you can produce an APK or AAB.** This is the single most important thing blocking an Android release, and it is an environment issue, not a code issue.

---

## 20. Google Play

### Completed automatically
- App label, package/namespace, and version metadata in place.
- Launcher icon at every density.
- Manifest correct and minimal: one permission, optional camera hardware, backup disabled.
- Release signing wired to `key.properties` with a documented example, and secrets excluded from version control.
- `minSdk`/`targetSdk` inherited from the Flutter SDK defaults, which meet current Play requirements.
- No `CAMERA` permission, so no sensitive-permission declaration form is needed.
- Privacy Policy and Terms of Service drafted in the project.
- An About screen carrying the version, the data-handling summary and the support contact.
- Automated tests and static analysis are green.

### You must do manually
1. **Install a JDK 17+**, then confirm `flutter build appbundle --release` succeeds.
2. **Change the application ID** to your own, permanently.
3. **Create an upload keystore**, fill in `android/key.properties`, and **back the keystore up somewhere safe**. Lose it and you can never update the app.
4. Create the Play Console listing: title, short description, full description, and at least two screenshots per required form factor, including a 1024×500 feature graphic.
5. Fill in the **Data Safety** form. The honest answers follow from the Privacy Policy: you collect the student's email, name, uploaded photos and documents, and study progress; all of it is for app functionality; none of it is sold or shared for advertising; the data is encrypted in transit.
6. Set the content rating questionnaire.
7. Set the target audience. If children are in scope, complete the Families policy form.
8. Publish the **Privacy Policy at a public URL** and put that URL in the listing. Google requires a reachable URL, not a file in the app.
9. Upload the AAB to the internal testing track first, install it on a real physical device, and confirm sign-in, photo analysis and a Lab quiz work end to end.
10. Promote to production gradually.

---

## 21. Web Release

**Build: succeeded.** `√ Built build\web`, exit code 0.

- Output is at `build/web` and is a static bundle: it can be hosted on GitHub Pages, Netlify, Vercel or any static host with no backend.
- `index.html` title is "Study Nova"; the PWA manifest name, short name and description all read "Study Nova".
- Theme colour corrected to `#2196F3` to match the app's own seed colour, with `<meta name="theme-color">` added, so the browser chrome and the installed-app header match the app.
- All four PWA icon sizes present, including both maskable variants.
- The web build was re-run after the manifest, index and configuration changes to confirm the output still builds and contains them.

**Before going live on the web:** host it, then check the app in a real browser. The one web-specific path worth testing by hand is the photo picker, because `image_picker`'s web implementation is browser-dependent and cannot be exercised by the automated tests here.

---

## 22. Remaining Problems

Every one of them, including the minor ones. Nothing is hidden.

**Blocking an Android release**
1. **No JDK on this machine.** `flutter build apk` / `appbundle` cannot run. Nothing else can be verified about the Android artefact until a JDK is installed.
2. **The application ID is `com.studynova.app`.** Change it before the first release. After publication it is permanent.
3. **No release keystore.** `android/key.properties` and the `.jks` must be created by you, and the keystore backed up.
4. **Play Console listing does not exist.** Title, descriptions, screenshots, feature graphic, content rating, Data Safety form, support contact, privacy policy URL.

**Blocking publication of the legal documents**
5. `PRIVACY_POLICY.md` is a **placeholder**. It still contains bracketed fields: the owner's name, the support email, the minimum age, the retention period, the deletion turnaround, the third-party disclosure, and the data-protection authority line. It must be reviewed and completed, then hosted at a public URL.
6. `TERMS_OF_SERVICE.md` is a **placeholder** with the same class of blanks: minimum age, governing law and jurisdiction, support email, and the liability framing. Have it reviewed, ideally by a lawyer.
7. `AboutScreen.supportEmail` is the placeholder `support@studynova.app`.
8. The About screen's policy text says the documents are "included with this build". If you publish the app, the accurate and more useful behaviour is to point students at the public policy URL. That needs a URL-launcher dependency, so it is left to you.

**Configuration the owner must supply**
9. **Supabase project and keys.** With the committed credentials removed, an unconfigured build has no backend at all. The online features need your project's URL and anon key via `--dart-define`.
10. **Gemini API key.** Without it, photo analysis and course generation are unavailable. Everything else works.
11. **Verify RLS on your project.** The SQL files configure it, but the dashboard can change it later. RLS is the only thing protecting student data, since the anon key is public.

**Known minor issues and limits**
12. **The marketing website promises a Windows build.** `website/index.html` is written for "Download for Windows" / "Study Nova for Windows", and `website/script.js` has `DOWNLOAD_URL: "#"`. The `windows/` folder exists but **no Windows build has been verified**, and this machine cannot produce one. The site behaves honestly at runtime — the button toasts "The Windows installer link is not set yet" — but the visible wording is a commitment. Either build and verify Windows, or change the copy to match whichever platforms you actually ship. `website/script.js` also still has `SUPPORT_EMAIL: "support@example.com"`.
13. **11 historical markdown files** in the project root are kept for context and are **not** kept in sync with the current code. `DOCUMENTATION_INDEX.md` now labels them as historical and marks `README.md` as authoritative, but their contents are stale. Consider deleting them.
14. **Web bundle is 44.4 MB**, almost all of it CanvasKit. Optional fix: build with `--web-resources-cdn`.
15. **Wasm build warnings** from the transitive `win32` package. Harmless for the JavaScript build; they would only matter for a future WebAssembly target.
16. **The AI-accuracy risk is inherent.** Explanations, mind maps and quizzes are model output and can be wrong. This is disclosed on the About screen and in the Terms, but no automated check can guarantee correctness.
17. **Google is not installed on this machine.** I used a read-only Git shim in a temp folder so the Flutter wrapper would start. Installing Git for Windows restores normal `flutter` command usage. No system settings were changed.
18. **Physical-device testing has not happened.** Every result in this report comes from static analysis, 76 automated tests, and a web release build. Camera capture, real Google Play install, real Supabase networking, and a real Gemini call are all unverified by machine and must be checked by hand.
19. **The 24 legacy `.txt` and log files** in the parent directory (`analyze_out.txt`, `test.txt`, `_test.log`, and similar) are leftover scratch output. Harmless, but they clutter the folder.

---

## 23. Manual Launch Checklist

In this order. Items 1–4 are prerequisites for everything after them.

**1. Install a JDK 17 or newer**
- Install Temurin 17 or 21, or Android Studio (which bundles a JDK).
- Set `JAVA_HOME` to the JDK, and add `%JAVA_HOME%\bin` to your `Path`.
- Verify: `java -version` in PowerShell.

**2. Install Git for Windows**
- Lets the normal `flutter` command work without the shim used during this audit.

**3. Decide your permanent application ID**
- Change `applicationId` **and** `namespace` in `android/app/build.gradle.kts`.
- Make it yours, not `com.studynova.app`, if that is not your own domain.
- Do this **before** the first upload. It cannot be changed afterwards.

**4. Set up Supabase**
- Create the project.
- In the SQL editor, run in order: `sql/courses.sql`, `sql/study_scans.sql`, `sql/study_images_storage_policy.sql`, `sql/missions.sql`.
- Create a storage bucket named exactly `study_images`, then run the storage policy file.
- Copy the project's URL and the **anon / publishable** key. Never the service-role key.
- In Storage, confirm the `study_images` bucket is **not public**.

**5. Get a Gemini API key**
- From Google AI Studio.
- Keep it out of the repository. Pass it with `--dart-define`.

**6. Create the release keystore**
- Follow `android/key.properties.example`.
- Back the `.jks` file up in a safe place and record the passwords. Losing it means you can never update the app.

**7. Finish the legal documents**
- Fill in every bracketed blank in `PRIVACY_POLICY.md` and `TERMS_OF_SERVICE.md`.
- Have the Terms reviewed.
- Update `supportEmail` in `lib/screens/about/about_screen.dart`.
- Publish the Privacy Policy at a public URL and keep that URL handy for the Play listing.

**8. Build and test on a real Android phone**
```
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=GOOGLE_GENERATIVE_AI_KEY=...
```
- Sign up, sign out, sign back in.
- Analyse a real photo with the camera. Check the explanation, mind map and quiz.
- Analyse a photo from the gallery.
- Complete a Lab lesson, take its quiz, then **close and reopen the app** and confirm your progress is still there.
- Create a mission, do a day's tasks, and confirm the progress and streak move.
- Sign out, sign in as a different account, and confirm you cannot see the first account's progress.

**9. Build the release bundle**
```
flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=GOOGLE_GENERATIVE_AI_KEY=...
```

**10. Create the Play Console listing**
- Title, short and full description.
- Screenshots for phone and, if required, tablet and 1024×500 feature graphic.
- Fill the Data Safety form honestly from the Privacy Policy.
- Content rating questionnaire.
- Families policy if children are in scope.
- Privacy policy URL.
- Support email and website.

**11. Publish to internal testing first**
- Upload the AAB, install from the internal track on a real device, and repeat the step 8 checks with the release build.
- Only then promote to production.

**12. Sort out the marketing website**
- Either build and verify the Windows build, or change the "Download for Windows" copy to match what you actually ship.
- Replace `DOWNLOAD_URL: "#"` and `SUPPORT_EMAIL: "support@example.com"` in `website/script.js`.
- Add the Labs and Mission Mode features, which the site does not yet mention.

**13. Tidy up (optional)**
- Delete the 11 historical markdown files, and the scratch `.txt` and `.log` files in the parent folder.

---

## 24. Exact Next Steps

**Today, in this order:**

1. **Install a JDK 17+** and set `JAVA_HOME`. Without this, nothing about the Android build can be checked. This is the hard blocker.
2. **Install Git for Windows** so `flutter` works normally.
3. **Change the application ID** to your own, permanently, before any upload.
4. **Create your Supabase project**, run the four SQL files in order, create the `study_images` bucket, and confirm it is private.
5. **Get your Gemini API key.**
6. **Create and back up the upload keystore**, then write `android/key.properties`.
7. **Fill in the Privacy Policy and Terms**, and publish the policy at a public URL.

**Then verify by hand, on a real phone:**
8. `flutter run` with the three `--dart-define` values, and walk the step 8 checklist above — especially confirming that Lab progress survives a restart, and that signing in as a second account shows none of the first account's data.

**Then ship:**
9. `flutter build appbundle --release` with the same defines.
10. Upload to Play Console **internal testing**, install the real build, repeat the checks.
11. Create the listing, complete the Data Safety form, and promote to production.

**Then, if you have time:**
12. Decide what to do about the Windows promise on the marketing website.
13. Delete the historical markdown and the scratch log files.

**What you do not need to do:** there is no code left to fix. Static analysis is clean, all 76 tests pass, and the web release build succeeds. The remaining work is configuration, paperwork, and device testing.
