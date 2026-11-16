import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../services/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.huge,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _BrandPanel()),
                            const SizedBox(width: AppSpacing.huge),
                            SizedBox(
                              width: 440,
                              child: _AuthCard(
                                tabController: _tabController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                otpController: _otpController,
                                authState: _authState,
                                obscurePassword: _obscurePassword,
                                showOtpVerification: _showOtpVerification,
                                onTogglePassword: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                onPasswordLogin: _handlePasswordLogin,
                                onMagicLinkSignIn: _handleMagicLinkSignIn,
                                onOtpVerification: _handleOtpVerification,
                                onShowOtpVerificationChanged: (value) => setState(
                                  () => _showOtpVerification = value,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _AuthCard(
                          tabController: _tabController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          otpController: _otpController,
                          authState: _authState,
                          obscurePassword: _obscurePassword,
                          showOtpVerification: _showOtpVerification,
                          onTogglePassword: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onPasswordLogin: _handlePasswordLogin,
                          onMagicLinkSignIn: _handleMagicLinkSignIn,
                          onOtpVerification: _handleOtpVerification,
                          onShowOtpVerificationChanged: (value) => setState(
                            () => _showOtpVerification = value,
                          ),
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.huge),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'StudyNova',
            style: textTheme.displaySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A premium platform for focused study sessions, custom courses, and guided learning.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _Pill(label: 'Course builder'),
              _Pill(label: 'Study from photo'),
              _Pill(label: 'Mission mode'),
              _Pill(label: 'Labs'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.tabController,
    required this.emailController,
    required this.passwordController,
    required this.otpController,
    required this.authState,
    required this.obscurePassword,
    required this.showOtpVerification,
    required this.onTogglePassword,
    required this.onPasswordLogin,
    required this.onMagicLinkSignIn,
    required this.onOtpVerification,
    required this.onShowOtpVerificationChanged,
  });

  final TabController tabController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController otpController;
  final AuthState authState;
  final bool obscurePassword;
  final bool showOtpVerification;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onPasswordLogin;
  final Future<void> Function() onMagicLinkSignIn;
  final Future<void> Function() onOtpVerification;
  final ValueChanged<bool> onShowOtpVerificationChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: authState,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to continue studying smarter.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.whiteSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: TabBar(
                  controller: tabController,
                  tabs: const [
                    Tab(text: 'Password'),
                    Tab(text: 'Magic Link'),
                  ],
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (authState.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (authState.errorMessage != null)
                const SizedBox(height: AppSpacing.lg),
              Builder(
                builder: (context) {
                  if (tabController.index == 0) {
                    return Column(
                      children: [
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_rounded),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          enabled: !authState.isLoading,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: onTogglePassword,
                            ),
                          ),
                          obscureText: obscurePassword,
                          enabled: !authState.isLoading,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : () {
                                    authState.resetPassword(emailController.text);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset email sent!'),
                                      ),
                                    );
                                  },
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: authState.isLoading ? null : onPasswordLogin,
                          icon: authState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.2),
                                )
                              : const Icon(Icons.login_rounded),
                          label: const Text('Sign in'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_rounded),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !authState.isLoading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (showOtpVerification) ...[
                        TextField(
                          controller: otpController,
                          decoration: InputDecoration(
                            labelText: 'Verification code',
                            prefixIcon: const Icon(Icons.verified_rounded),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: !authState.isLoading,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      FilledButton.icon(
                        onPressed: authState.isLoading
                            ? null
                            : showOtpVerification
                                ? onOtpVerification
                                : onMagicLinkSignIn,
                        icon: authState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : Icon(
                                showOtpVerification
                                    ? Icons.verified_rounded
                                    : Icons.link_rounded,
                              ),
                        label: Text(
                          showOtpVerification ? 'Verify code' : 'Send magic link',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => onShowOtpVerificationChanged(!showOtpVerification),
                        child: Text(
                          showOtpVerification
                              ? 'I need a new magic link'
                              : 'I already have a code',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New to StudyNova?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
