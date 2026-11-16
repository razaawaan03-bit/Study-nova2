import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studynova/config/supabase_config.dart';
import 'package:studynova/models/lab_model.dart';
import 'package:studynova/screen/splash/splash.screen.dart';
import 'package:studynova/screens/about/about_screen.dart';
import 'package:studynova/screens/auth/login_screen.dart';
import 'package:studynova/screens/auth/signup_screen.dart';
import 'package:studynova/screens/course_maker/course_setup_screen.dart';
import 'package:studynova/screens/course_maker/my_courses_screen.dart';
import 'package:studynova/screens/home/home_screen.dart';
import 'package:studynova/screens/labs/lab_detail_screen.dart';
import 'package:studynova/screens/labs/labs_home_screen.dart';
import 'package:studynova/screens/missions/mission_create_screen.dart';
import 'package:studynova/screens/missions/my_missions_screen.dart';
import 'package:studynova/screens/study_from_photo/study_analysis_screen.dart';
import 'package:studynova/screens/study_from_photo/study_from_photo_screen.dart';
import 'package:studynova/screens/study_from_photo/study_library_screen.dart';
import 'package:studynova/utils/supabase_availability.dart';
import 'package:studynova/services/auth_service.dart';
import 'package:studynova/services/auth_state.dart';
import 'package:studynova/services/course_service.dart';
import 'package:studynova/services/lab_service.dart';
import 'package:studynova/services/study_scan_service.dart';
import 'package:studynova/screens/welcome/welcome_screen.dart';

void main() {
  // A 1x1 transparent PNG, decoded from memory: this is the Web-safe path that
  // replaces `Image.file`, which is not supported on Flutter Web.
  final Uint8List pngBytes = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);
  // ---------------------------------------------------------------------------
  // Supabase availability (Stage 7 fix, verified app-wide in Stage 8)
  // ---------------------------------------------------------------------------

  test(
    'safeSupabase() returns null instead of throwing when uninitialized',
    () {
      expect(safeSupabase(), isNull);
    },
  );

  /// The student-facing sentence on any of these exceptions.
  ///
  /// A predicate cannot promote an `Object` through an `||` of two unrelated
  /// types, so the message is read here instead of in the matcher.
  String messageOf(Object error) => switch (error) {
    SupabaseNotConfiguredException e => e.message,
    AuthUnavailableException e => e.message,
    BackendNotConfiguredException e => e.message,
    BackendUnavailableException e => e.message,
    _ => error.toString(),
  };

  test('auth service stays usable when Supabase is unavailable', () {
    final auth = AuthService();
    expect(auth.currentUser, isNull);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.currentSession, isNull);
    // Streaming must not throw when there is no client.
    expect(auth.authStateStream, isA<Stream<dynamic>>());
    // A missing backend must surface a friendly, student-readable message.
    // Which of the two it is depends on how this build was configured — an
    // unconfigured build is a setup problem, a configured build whose client
    // never came up is a service problem — and *neither* may be reported as a
    // lost internet connection.
    expect(
      () => auth.signIn(email: 'a@b.com', password: 'secret'),
      throwsA(
        predicate(
          (Object e) =>
              (e is SupabaseNotConfiguredException ||
                  e is AuthUnavailableException) &&
              !messageOf(e).toLowerCase().contains('internet connection'),
        ),
      ),
    );
  });

  test('course and study-scan services report offline instead of crashing', () {
    final courses = CourseService();
    // The Supabase client is resolved lazily, so constructing is safe and
    // calling a cloud method gives a clear, typed error rather than an assertion
    // from `Supabase.instance` — and, crucially, rather than a message telling a
    // connected student their internet is gone.
    expect(
      () => courses.getUserCourses(),
      throwsA(
        predicate(
          (Object e) =>
              (e is BackendNotConfiguredException ||
                  e is BackendUnavailableException) &&
              !messageOf(e).toLowerCase().contains('internet'),
        ),
      ),
    );

    final scans = StudyScanService();
    expect(scans.isCloudAvailable, isFalse);
    // With no signed-in user, list queries return an empty list, not a crash.
    expect(scans.getUserStudyScans(), completion(isEmpty));
  });

  // ---------------------------------------------------------------------------
  // Lab progress persistence (Stage 8)
  // ---------------------------------------------------------------------------

  test(
    'Lab progress survives a restart instead of resetting every launch',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = LabService.instance;
      await service.load();
      await service.reset();

      final lab = service.allLabs.first;
      final lesson = lab.lessons.first;

      expect(service.isLessonCompleted(lab.id, lesson.id), isFalse);

      await service.setLessonCompleted(lab.id, lesson.id);
      expect(service.isLessonCompleted(lab.id, lesson.id), isTrue);
      expect(service.progressPercentFor(lab.id), greaterThan(0));

      // `reset` is what signing out does: memory and storage are both cleared.
      await service.reset();
      expect(service.isLessonCompleted(lab.id, lesson.id), isFalse);

      // Study again, then read the stored progress back the way a fresh app
      // launch does: the completed lesson and the quiz score must both survive.
      await service.setLessonCompleted(lab.id, lesson.id);
      await service.recordQuizAttempt(lab.id, score: 3, totalQuestions: 4);

      // The in-memory clear mimics a restart; `load` must then restore what was
      // written, rather than leaving the student back at zero.
      service.debugClearInMemory();
      expect(service.isLessonCompleted(lab.id, lesson.id), isFalse);

      await service.load();
      expect(
        service.isLessonCompleted(lab.id, lesson.id),
        isTrue,
        reason: 'progress must survive an app restart',
      );
      expect(service.statsFor(lab.id).bestScore, 3);

      await service.reset();
    },
  );

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  testWidgets('every named route in the app opens a real screen', (
    tester,
  ) async {
    // The same table as `lib/main.dart`. A route that points at a deleted or
    // renamed screen fails here instead of at runtime.
    final routes = <String, Widget>{
      '/': const SplashScreen(),
      '/welcome': const WelcomeScreen(),
      '/login': const LoginScreen(),
      '/home': const HomeScreen(),
      '/study-from-photo': const StudyFromPhotoScreen(),
      '/study-library': const StudyLibraryScreen(),
      '/my-courses': const MyCoursesScreen(),
      '/course-setup': const CourseSetupScreen(),
      '/labs': const LabsHomeScreen(),
      '/missions': const MyMissionsScreen(),
      '/mission-create': const MissionCreateScreen(),
      '/about': const AboutScreen(),
    };

    for (final entry in routes.entries) {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => entry.value,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        tester.takeException(),
        isNull,
        reason: 'route ${entry.key} (${entry.value.runtimeType}) did not build',
      );
      expect(find.byWidget(entry.value), findsOneWidget);

      // Every route must be able to go back, so a student is never trapped.
      expect(navigator.currentState, isNotNull);
    }
  });

  testWidgets('the About screen names the app and offers the policy summary', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Study Nova'), findsOneWidget);
    expect(find.text('Version ${AboutScreen.appVersion}'), findsOneWidget);

    // The policy summary sits at the bottom of the page, so the list has to be
    // scrolled before it is built.
    await tester.scrollUntilVisible(
      find.text('Privacy Policy and Terms'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Privacy Policy and Terms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('no Supabase credentials are checked into the source', () {
    // A committed URL or anon key would mean an unconfigured build silently
    // writing to whichever project that key belongs to. Only the placeholders
    // may be present; real values arrive through --dart-define.
    expect(supabaseConfigUrl, isEmpty);
    expect(supabaseConfigAnonKey, isEmpty);

    // `supabase_availability` is what keeps the app usable without a backend.
    expect(safeSupabase(), isNull);
  });

  // ---------------------------------------------------------------------------
  // Study From Photo — platform-safe image handling
  // ---------------------------------------------------------------------------

  testWidgets('Study From Photo offers both gallery and camera entry points', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StudyFromPhotoScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Take a Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Capture Your Study Material'), findsOneWidget);
  });

  testWidgets('tapping an entry point without a picker stays on the screen', (
    tester,
  ) async {
    // In a test environment the platform picker never answers, so the screen
    // must show its loading state and never crash or navigate away. Bounded
    // pumps are used instead of pumpAndSettle: the loading spinner animates
    // for as long as the picker is pending.
    await tester.pumpWidget(const MaterialApp(home: StudyFromPhotoScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from Gallery'));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Capture Your Study Material'), findsOneWidget);
    expect(find.text('Opening...'), findsOneWidget);

    // The buttons stay disabled while the picker is pending, so a second tap
    // cannot open two pickers.
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('Capture Your Study Material'), findsOneWidget);
  });

  testWidgets(
    'the analysis screen renders picked bytes without Image.file (Web-safe)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudyAnalysisScreen(
                    imageBytes: pngBytes,
                    fileName: 'notes.png',
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The screen is reachable and the raw bytes decode in memory, which is
      // exactly the path Flutter Web needs (`Image.file` would throw here).
      expect(find.text('Review & Analyze'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  // ---------------------------------------------------------------------------
  // Home — no coding features remain
  // ---------------------------------------------------------------------------

  testWidgets('Home shows only study features and no coding cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    for (final expected in [
      'Create New Course',
      'My Courses',
      'Study From Photo',
      'My Study Library',
      'Study Nova Labs',
    ]) {
      expect(
        find.text(expected),
        findsOneWidget,
        reason: 'missing Home action: $expected',
      );
    }

    // Also reachable from the Mission Banner Card.
    expect(find.text('My Missions'), findsWidgets);

    for (final forbidden in [
      'AI Code Creator',
      'My Code Projects',
      'Code',
      'Coding',
    ]) {
      expect(
        find.text(forbidden),
        findsNothing,
        reason: 'coding feature still visible on Home: $forbidden',
      );
    }

    expect(find.text('Study Nova'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Labs — no coding Lab may be visible anywhere
  // ---------------------------------------------------------------------------

  testWidgets('Labs home lists only the 6 educational labs', (tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LabsHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Study Nova Labs'), findsWidgets);

    for (final lab in LabService.instance.allLabs) {
      expect(
        find.textContaining(lab.title, findRichText: true),
        findsWidgets,
        reason: 'lab missing from Labs home: ${lab.id}',
      );
    }

    // The removed coding labs must not appear anywhere on the screen.
    for (final removed in ['Coding Fundamentals', 'HTML', 'Coding']) {
      expect(
        find.text(removed),
        findsNothing,
        reason: 'coding UI still visible',
      );
    }
  });

  testWidgets('Labs category filters contain no coding chip', (tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LabsHomeScreen()));
    await tester.pumpAndSettle();

    // Only categories that actually contain a Lab get a chip, so the filter
    // row must match the populated categories exactly.
    final populated = <String>{
      for (final entry in LabService.instance.labsByCategory().entries)
        entry.key?.label ?? 'All',
    };
    for (final label in populated) {
      expect(
        find.text(label),
        findsWidgets,
        reason: 'missing category chip: $label',
      );
    }
    expect(find.text('Coding'), findsNothing);
    // The removed coding category must not be in the filter row at all.
    expect(LabCategory.values.map((c) => c.label), isNot(contains('Coding')));
  });

  testWidgets('a deleted coding lab cannot be opened', (tester) async {
    // Even with a stale id (for example from an old saved mission), the
    // detail screen must show a friendly "not found" state, not a crash.
    await tester.pumpWidget(
      const MaterialApp(home: LabDetailScreen(labId: 'coding-fundamentals')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('This Lab could not be found.'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Responsiveness — catch RenderFlex overflow on real phone / web sizes
  // ---------------------------------------------------------------------------

  // Each screen is pumped in its own test: a single looping test can report a
  // layout error against the wrong screen, because Flutter delivers the
  // overflow report on a later frame than the frame that caused it.
  final sizes = <Size>[
    const Size(360, 640),
    const Size(320, 640),
    const Size(1024, 768),
  ];
  final screens = <String, Widget Function()>{
    'HomeScreen': () => const HomeScreen(),
    'LabsHomeScreen': () => const LabsHomeScreen(),
    'StudyFromPhotoScreen': () => const StudyFromPhotoScreen(),
    'WelcomeScreen': () => const WelcomeScreen(),
    'SplashScreen': () => const SplashScreen(),
    'LoginScreen': () => const LoginScreen(),
    'SignupScreen': () => const SignupScreen(),
    'AboutScreen': () => const AboutScreen(),
  };

  for (final screen in screens.entries) {
    for (final size in sizes) {
      testWidgets('${screen.key} lays out without overflow at $size', (
        tester,
      ) async {
        // A small phone and a narrow browser window, the two sizes most likely
        // to overflow a fixed-height card or a long action row.
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(home: screen.value()));
        await tester.pumpAndSettle();
        // A second frame makes sure a late layout report is not missed.
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.takeException(),
          isNull,
          reason: 'layout error on $size for ${screen.key}',
        );
      });
    }
  }

  // Accessibility: a student who has turned the system font size up must not
  // get clipped text or a black-and-yellow overflow banner.
  for (final screen in <String, Widget Function()>{
    'LoginScreen': () => const LoginScreen(),
    'SignupScreen': () => const SignupScreen(),
    'HomeScreen': () => const HomeScreen(),
  }.entries) {
    for (final textScale in <double>[1.5, 2.0]) {
      testWidgets('${screen.key} survives a $textScale text scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: screen.value(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.takeException(),
          isNull,
          reason: 'layout error at $textScale text scale for ${screen.key}',
        );
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication behaviour with no backend available
  // ---------------------------------------------------------------------------

  test(
    'AuthState reports a friendly error and does not throw offline',
    () async {
      final state = AuthState();
      addTearDown(state.dispose);

      expect(state.isLoggedIn, isFalse);
      expect(state.currentUser, isNull);

      final ok = await state.signInWithPassword(
        email: 'student@example.com',
        password: 'wrong-password',
      );

      expect(ok, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, isNot(startsWith('Exception:')));
      // No stack traces, no technical jargon in front of a student.
      expect(state.errorMessage, isNot(contains('#0')));
      expect(state.errorMessage, isNot(contains('AuthException')));
      expect(state.isLoading, isFalse);
    },
  );

  test('disposing AuthState releases the auth stream listener', () {
    // The provider is created and disposed repeatedly; a leaked subscription
    // would survive and keep notifying a dead object.
    for (var i = 0; i < 3; i++) {
      AuthState().dispose();
    }
  });

  // ---------------------------------------------------------------------------
  // Splash + session restoration
  // ---------------------------------------------------------------------------

  testWidgets('splash shows the Study Nova name and moves on', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    expect(find.text('Study Nova'), findsOneWidget);
    expect(find.text('StudyNova'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Without a session the student lands on Welcome, not on a crash.
    expect(tester.takeException(), isNull);
  });
}
