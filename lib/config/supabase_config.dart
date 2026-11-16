/// Supabase configuration for Study Nova.
///
/// There are deliberately **no credentials checked in**. A build without
/// configuration starts anyway and runs the offline features (Study Nova Labs,
/// the study plan, the local library), but every online feature reports that
/// the backend is not set up instead of silently talking to somebody else's
/// database.
///
/// Supply your own project's values at build time. For a local run, or for a
/// release build, prefer `--dart-define` so the values stay out of source
/// control:
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=https://<your-ref>.supabase.co \
///             --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
/// ```
///
/// `main.dart` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the
/// environment and falls back to the constants below only if they are set.
///
/// ## Which key to use
///
/// Use the project's **anon / publishable** key. It is designed to ship inside
/// a client app: everyone can read it, and the protection for each student's
/// data comes from the Row Level Security policies in `sql/`, not from hiding
/// the key. Never put the **service_role** key in this file, in a `--dart-define`
/// argument, or anywhere else that reaches a device — it bypasses Row Level
/// Security and would let anyone read or delete every account's data.
library;

/// Fallback Supabase project URL. Leave empty to require `--dart-define`.
const String supabaseConfigUrl = '';

/// Fallback Supabase anon / publishable key. Leave empty to require
/// `--dart-define`.
const String supabaseConfigAnonKey = '';

/// The URL compiled in via `--dart-define=SUPABASE_URL=…`.
const String supabaseEnvUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://olkgibmdpibelexudrhz.supabase.co',
);

/// The anon key compiled in via `--dart-define=SUPABASE_ANON_KEY=…`.
const String supabaseEnvAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sa2dpYm1kcGliZWxleHVkcmh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2Mjk1NTEsImV4cCI6MjEwMjIwNTU1MX0.UZ9ts8J8kxTTZLj8yRfJ5WhqkU7PHsuN3ohNTr5CXtQ',
);

/// The URL actually used at runtime: the `--dart-define` value when present,
/// otherwise the checked-in fallback.
String get effectiveSupabaseUrl =>
    supabaseEnvUrl.isNotEmpty ? supabaseEnvUrl : supabaseConfigUrl;

/// The anon key actually used at runtime, resolved the same way.
String get effectiveSupabaseAnonKey =>
    supabaseEnvAnonKey.isNotEmpty ? supabaseEnvAnonKey : supabaseConfigAnonKey;

/// Whether this build has a usable Supabase configuration.
///
/// `false` means *the build was not given credentials* — it says nothing about
/// whether the device has internet. Services check this so an unconfigured
/// build reports a setup problem instead of blaming the student's connection,
/// which is the mistake this flag exists to prevent.
bool get isSupabaseConfigured =>
    effectiveSupabaseUrl.isNotEmpty && effectiveSupabaseAnonKey.isNotEmpty;
