import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/supabase_availability.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  SupabaseClient get _client {
    final supabase = safeSupabase();
    if (supabase == null) {
      // A null client has two very different causes, and telling them apart is
      // what stops a connected device being told it has no internet.
      if (!isSupabaseConfigured) {
        throw const SupabaseNotConfiguredException(feature: 'accounts');
      }
      throw const AuthUnavailableException();
    }
    return supabase.client;
  }

  // Get current user
  User? get currentUser => safeSupabase()?.client.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => safeSupabase()?.client.auth.currentUser != null;

  // Stream of auth state changes
  Stream<AuthState> get authStateStream =>
      safeSupabase()?.client.auth.onAuthStateChange ?? const Stream.empty();

  /// Turns any authentication failure into a message a student can act on.
  ///
  /// Supabase `AuthException`s are technical, so the common cases (wrong
  /// password, unknown email, too many attempts, duplicate account) are
  /// translated here instead of being shown verbatim. Every screen that signs
  /// a student in or up uses this one mapper, so no screen ever renders a raw
  /// `AuthException.toString()`.
  static String friendlyError(Object error) {
    // Missing build configuration is a setup problem, not a network problem.
    // It must never be reported as "check your internet connection".
    if (error is SupabaseNotConfiguredException) return error.message;

    if (error is AuthUnavailableException) return error.message;

    // Everything else — wrong password, expired session, DNS/TLS failure,
    // timeout, server error — is classified by the shared mapper, so the login
    // screens and the online services cannot drift apart again.
    return friendlyBackendError(error);
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return response;
    } on AuthException {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException {
      rethrow;
    }
  }

  /// Reset password with email
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException {
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({required String fullName}) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    } on AuthException {
      rethrow;
    }
  }

  /// Sign in with magic link (email only)
  Future<void> signInWithMagicLink(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.studynova://login-callback/',
      );
    } on AuthException {
      rethrow;
    }
  }

  /// Verify OTP token sent via email
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      return response;
    } on AuthException {
      rethrow;
    }
  }

  /// Listen to real-time auth state changes
  void onAuthStateChanged(Function(AuthState) callback) {
    safeSupabase()?.client.auth.onAuthStateChange.listen(callback);
  }

  /// Get current session
  Session? get currentSession => safeSupabase()?.client.auth.currentSession;
}

/// Thrown when this build has no Supabase credentials at all.
///
/// This is deliberately distinct from [AuthUnavailableException]: the network is
/// working fine, the app simply was never given a backend to talk to.
class SupabaseNotConfiguredException extends BackendNotConfiguredException {
  const SupabaseNotConfiguredException({super.feature = 'accounts'});
}

/// Thrown when an auth action is attempted while Supabase is not initialized.
///
/// It carries a student-friendly message so screens never have to surface a
/// raw `StateError` or an assertion from `Supabase.instance`.
class AuthUnavailableException extends BackendUnavailableException {
  const AuthUnavailableException();
}
