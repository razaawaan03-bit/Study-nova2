import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns the Supabase instance, or `null` when Supabase is not initialized.
///
/// `Supabase.instance` throws an assertion error before `Supabase.initialize`
/// has finished (and whenever the app runs without Supabase at all), so every
/// optional online feature — Missions, courses, study library — asks through
/// this helper instead. Offline is the normal case, not an error.
Supabase? safeSupabase() {
  try {
    final supabase = Supabase.instance;
    return supabase.isInitialized ? supabase : null;
  } catch (_) {
    return null;
  }
}

/// Thrown when this build was never given Supabase credentials at all.
///
/// This is a **setup** problem, not a network problem: the student's internet is
/// working fine, the app simply has no backend to talk to. It is deliberately
/// distinct from [BackendUnavailableException] so that a connected Windows
/// machine is never told it is offline.
class BackendNotConfiguredException implements Exception {
  const BackendNotConfiguredException({this.feature = 'this feature'});

  /// Plain-language name of the feature the student was trying to use, used to
  /// make the message read naturally.
  final String feature;

  String get message =>
      'Study Nova was built without its online service, so $feature cannot be '
      'used. Rebuild with --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=... to enable it.';

  @override
  String toString() => message;
}

/// Thrown when an online feature is used while Supabase is not initialized,
/// even though this build *is* configured.
///
/// The backend failed to come up. That is not proof of a lost connection — a
/// wrong URL, a blocked host or a TLS problem produce exactly the same null
/// client — so the message never claims the student's internet is gone.
class BackendUnavailableException implements Exception {
  const BackendUnavailableException();

  String get message =>
      'Study Nova could not reach its online service right now. Please try '
      'again in a moment.';

  @override
  String toString() => message;
}

/// Exception type names produced by `dart:io` and `package:http` when a request
/// never reaches the server. Matched by name so this file stays free of a
/// `dart:io` import, which would break the Web build.
const List<String> _transportErrorTypeNames = <String>[
  'SocketException',
  'HttpException',
  'HandshakeException',
  'TlsException',
  'ClientException',
];

/// Classifies any error produced by an online feature into one of the four
/// situations a student can actually act on.
///
/// The four cases are kept strictly separate on purpose:
///  * **missing configuration** — a build/setup problem;
///  * **timeout** — the request started but never finished;
///  * **transport failure** — the request never reached the server;
///  * **authentication failure** — the server answered, the credentials did
///    not work.
///
/// Anything else keeps its own message only when that message came from the
/// server and is safe to read. A raw technical exception is never shown to a
/// student.
String friendlyBackendError(Object error) {
  debugPrint(
    'StudyNova: online request failed '
    '(${error.runtimeType}): ${_debugDetail(error)}',
  );

  // A. Missing configuration.
  if (error is BackendNotConfiguredException) return error.message;

  // C. Backend failed to start / initialize.
  if (error is BackendUnavailableException) return error.message;

  // D. Authentication failures are *not* network failures: the server replied,
  // so the connection was fine.
  if (error is AuthException) return _friendlyAuthError(error);

  // B. Timeout: the request was attempted but never completed.
  if (error is TimeoutException) {
    return 'Connection timed out. Please check your internet connection and '
        'try again.';
  }

  // Transport failure: DNS, TLS or a dropped socket. This is the only case that
  // legitimately mentions the student's connection.
  final typeName = error.runtimeType.toString();
  if (_transportErrorTypeNames.any(typeName.contains)) {
    return 'Study Nova could not reach its online service. Please check your '
        'connection and try again.';
  }

  // PostgREST wraps *everything*, including a missing table or a rejected row,
  // in one exception. That is a backend problem, not proof of a lost
  // connection.
  if (error is PostgrestException) {
    return 'Study Nova could not reach its online service right now. Please '
        'try again in a moment.';
  }

  return 'Something went wrong. Please try again.';
}

/// Maps a Supabase `AuthException` to a message a student can act on.
String _friendlyAuthError(AuthException error) {
  final lower = error.message.toLowerCase();
  if (lower.contains('invalid login credentials')) {
    return 'That email and password do not match. Please try again.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Please confirm your email address before signing in.';
  }
  if (lower.contains('rate limit') || lower.contains('too many')) {
    return 'Too many attempts. Please wait a minute and try again.';
  }
  if (lower.contains('user already registered')) {
    return 'An account with this email already exists. Try signing in.';
  }
  if (lower.contains('password should be')) {
    return 'Please choose a stronger password (at least 6 characters).';
  }

  // An expired or revoked session is an auth problem, not a network problem.
  if (lower.contains('refresh token') ||
      lower.contains('invalid jwt') ||
      lower.contains('session missing') ||
      lower.contains('session not found')) {
    return 'Your session has expired. Please sign in again.';
  }

  // GoTrue wraps every transport failure in `AuthRetryableFetchException`,
  // whose message is the *stringified* underlying error. A socket, DNS or TLS
  // failure therefore arrives here as plain text with no type information,
  // which is why these are matched by substring.
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('connection closed') ||
      lower.contains('handshake') ||
      lower.contains('certificate') ||
      lower.contains('tls')) {
    return 'Study Nova could not reach its online service. Please check your '
        'connection and try again.';
  }

  // `package:http`'s own wrapper, and a genuinely timed-out request that GoTrue
  // turned into an exception.
  if (lower.contains('clientexception') ||
      lower.contains('failed to fetch') ||
      lower.contains('network') ||
      lower.contains('timed out') ||
      lower.contains('timeout')) {
    return 'Study Nova could not reach its online service. Please check your '
        'connection and try again.';
  }

  // The server answered with a real, human-readable message (validation errors,
  // captcha requirements, ...). Safe to show.
  return error.message;
}

/// The technical detail, for the app owner's console only. Deliberately not
/// part of any student-facing message.
///
/// For an unrecognised error type only the *type* is logged: its `toString()`
/// could in principle carry a URL or a credential fragment, and this log is the
/// one place that never needs the full text to be useful.
String _debugDetail(Object error) {
  if (error is PostgrestException) return error.message;
  if (error is AuthException) return error.message;
  return '(details withheld; see the provider log above)';
}
