import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// This file declares its own `AuthState` (a ChangeNotifier), so the Supabase
// event type is imported under an alias to keep the two apart.
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'auth_service.dart';

/// Real-time auth state provider with listener support
class AuthState extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  Session? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMagicLinkSent = false;

  /// Subscription to the Supabase auth stream. Held so it can be released in
  /// [dispose] instead of leaking a listener for the lifetime of the app.
  StreamSubscription<supabase.AuthState>? _authSubscription;

  // Getters
  User? get currentUser => _currentUser;
  Session? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isMagicLinkSent => _isMagicLinkSent;

  AuthState() {
    _initializeAuthState();
  }

  /// Initialize auth state listening, and seed the current session so a
  /// returning student is recognised without signing in again.
  void _initializeAuthState() {
    _currentUser = _authService.currentUser;
    _currentSession = _authService.currentSession;

    _authSubscription = _authService.authStateStream.listen((authState) {
      _currentUser = authState.session?.user;
      _currentSession = authState.session;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Turns any failure into a message a student can act on.
  ///
  /// The mapping lives on [AuthService] so the login and sign-up screens,
  /// which talk to the service directly, produce exactly the same wording.
  String _friendlyError(Object error) => AuthService.friendlyError(error);

  /// Sign in with email and password
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.signIn(email: email, password: password);
      _currentUser = _authService.currentUser;
      _currentSession = _authService.currentSession;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with magic link
  Future<bool> signInWithMagicLink(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _isMagicLinkSent = false;
      notifyListeners();

      await _authService.signInWithMagicLink(email);
      _isMagicLinkSent = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP token
  Future<bool> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.verifyOTP(email: email, token: token, type: type);
      _currentUser = _authService.currentUser;
      _currentSession = _authService.currentSession;
      _isMagicLinkSent = false;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      _currentUser = _authService.currentUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _currentUser = null;
      _currentSession = null;
      _isMagicLinkSent = false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
