import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../auth/login_screen.dart';
import 'features_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;
    final logoSize = isWide ? 180.0 : 150.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.huge,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _HeroPanel(
                                logoSize: logoSize,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.huge),
                            SizedBox(
                              width: 430,
                              child: _ActionCard(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _HeroPanel(logoSize: logoSize),
                            const SizedBox(height: AppSpacing.huge),
                            _ActionCard(),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.logoSize});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.huge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/study_nova.png',
                width: logoSize * 0.7,
                height: logoSize * 0.7,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.school_rounded,
                    size: logoSize * 0.45,
                    color: AppColors.white,
                  );
                },
              ),
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
            'Build smarter study habits with AI-powered learning, guided labs, and personalized missions.',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _Pill(label: 'AI course creation'),
              _Pill(label: 'Photo study'),
              _Pill(label: 'Mission mode'),
              _Pill(label: 'Labs'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
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
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Learn with confidence.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Create a study flow that fits your pace, your goals, and your course style.',
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FeaturesScreen()),
              );
            },
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Explore features'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.login_rounded),
            label: const Text('Sign in'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'New to StudyNova? Create your account and take your first study session in minutes.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.deepNavy,
                    ),
                  ),
                ),
              ],
            ),
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
