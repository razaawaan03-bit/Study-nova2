import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/ai_config.dart';
import 'config/supabase_config.dart';
import 'navigation/study_nova_shell.dart';
import 'screen/splash/splash.screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/study_from_photo/study_library_screen.dart';
import 'screens/course_maker/course_setup_screen.dart';
import 'screens/missions/mission_create_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final effectiveUrl = effectiveSupabaseUrl;
  final effectiveAnonKey = effectiveSupabaseAnonKey;

  debugPrint(
    'StudyNova configuration: '
    'SUPABASE_URL configured: ${effectiveUrl.isNotEmpty}, '
    'SUPABASE_ANON_KEY configured: ${effectiveAnonKey.isNotEmpty}, '
    'GEMINI key configured: ${googleGenerativeAIKey.isNotEmpty}',
  );

  if (isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: effectiveUrl,
        publishableKey: effectiveAnonKey,
      );
    } catch (error, stackTrace) {
      debugPrint('StudyNova: Supabase initialization failed.');
      debugPrintStack(stackTrace: stackTrace, label: 'Supabase.initialize');
    }
  } else {
    debugPrint(
      'Study Nova: no Supabase configuration. Online features (accounts, '
      'saved courses, synced missions) are unavailable. Pass '
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
      'to enable them.',
    );
  }

  runApp(const StudyNovaApp());
}

class StudyNovaApp extends StatelessWidget {
  const StudyNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Nova',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const StudyNovaShell(initialIndex: 0),
        '/study-from-photo': (context) => const StudyNovaShell(initialIndex: 3),
        '/study-library': (context) => const StudyLibraryScreen(),
        '/my-courses': (context) => const StudyNovaShell(initialIndex: 2),
        '/course-setup': (context) => const CourseSetupScreen(),
        '/labs': (context) => const StudyNovaShell(initialIndex: 1),
        '/missions': (context) => const StudyNovaShell(initialIndex: 4),
        '/mission-create': (context) => const MissionCreateScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
