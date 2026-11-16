import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../services/auth_state.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _authState = AuthState();
  bool _obscurePassword = true;
  bool _showOtpVerification = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _authState.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _authState.removeListener(_onAuthStateChanged);
    _authState.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_authState.isLoggedIn && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _handlePasswordLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final success = await _authState.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authState.errorMessage ?? 'Login failed')),
      );
    }
  }

  Future<void> _handleMagicLinkSignIn() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    final success = await _authState.signInWithMagicLink(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _showOtpVerification = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email for the magic link!')),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authState.errorMessage ?? 'Failed to send link'),
        ),
      );
    }
  }

  Future<void> _handleOtpVerification() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code')),
      );
      return;
    }

    final success = await _authState.verifyOTP(
      email: _emailController.text.trim(),
      token: _otpController.text,
      type: OtpType.email,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authState.errorMessage ?? 'OTP verification failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Password'),
            Tab(text: 'Magic Link'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _authState,
        builder: (context, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school,
                        size: 50,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Sign in to your StudyNova account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_authState.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _authState.errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_authState.errorMessage != null)
                      const SizedBox(height: 16),

                    // Tab view content
                    if (_tabController.index == 0)
                      Column(
                        children: [
                          // Password login
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabled: !_authState.isLoading,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabled: !_authState.isLoading,
                            ),
                            obscureText: _obscurePassword,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _authState.isLoading
                                  ? null
                                  : () {
                                      _authState.resetPassword(
                                        _emailController.text,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Password reset email sent!',
                                          ),
                                        ),
                                      );
                                    },
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _authState.isLoading
                                  ? null
                                  : _handlePasswordLogin,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: _authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          // Magic link login
                          if (!_showOtpVerification) ...[
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabled: !_authState.isLoading,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We\'ll send you a magic link to sign in',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _authState.isLoading
                                    ? null
                                    : _handleMagicLinkSignIn,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: _authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Send Magic Link'),
                              ),
                            ),
                          ] else ...[
                            // OTP verification
                            Text(
                              'Enter the OTP code sent to your email',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                labelText: 'OTP Code',
                                prefixIcon: const Icon(Icons.security),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabled: !_authState.isLoading,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _authState.isLoading
                                    ? null
                                    : _handleOtpVerification,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: _authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Verify OTP'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() => _showOtpVerification = false);
                                _otpController.clear();
                              },
                              child: const Text('Back to email'),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Sign up link
                    //
                    // `Flexible` keeps the row safe on narrow screens and at
                    // large accessibility text sizes: the prompt text wraps
                    // instead of overflowing the card.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            'Don\'t have an account?',
                            textAlign: TextAlign.end,
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: _authState.isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const SignupScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Sign Up'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
