import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/lab_service.dart';
import '../../services/mission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../course_maker/course_setup_screen.dart';
import '../course_maker/my_courses_screen.dart';
import '../labs/labs_home_screen.dart';
import '../missions/my_missions_screen.dart';
import '../study_from_photo/study_from_photo_screen.dart';
import '../study_from_photo/study_library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService().signOut();
                await MissionService.instance.reset();
                await LabService.instance.reset();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              } catch (e) {
                final message = AuthService.friendlyError(e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        message == 'Something went wrong. Please try again.'
                            ? 'Could not sign out. Please try again.'
                            : message,
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final name = user?.userMetadata?['full_name'] ?? user?.email ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => Navigator.of(context).pushNamed('/about'),
            tooltip: 'About Study Nova',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(name: name),
                  const SizedBox(height: AppSpacing.xxl),
                  _QuickActionsGrid(
                    isWide: isWide,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _StatsSection(isWide: isWide),
                  const SizedBox(height: AppSpacing.xxl),
                  _LearningOverviewSection(isWide: isWide),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  name,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your next focused study session is ready. Pick up where you left off and keep momentum going.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxl),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionItemData>[
      _ActionItemData(
        title: 'Study From Photo',
        subtitle: 'Convert material into instant explanations',
        icon: Icons.photo_camera_rounded,
        color: AppColors.primary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StudyFromPhotoScreen()),
          );
        },
      ),
      _ActionItemData(
        title: 'Course Maker',
        subtitle: 'Turn notes into structured study courses',
        icon: Icons.library_books_rounded,
        color: AppColors.accent,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CourseSetupScreen()),
          );
        },
      ),
      _ActionItemData(
        title: 'Labs',
        subtitle: 'Explore guided lessons and quizzes',
        icon: Icons.science_rounded,
        color: AppColors.info,
        onTap: () => Navigator.of(context).pushNamed('/labs'),
      ),
      _ActionItemData(
        title: 'Mission Mode',
        subtitle: 'Keep daily study momentum',
        icon: Icons.flag_rounded,
        color: AppColors.success,
        onTap: () => Navigator.of(context).pushNamed('/missions'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick access',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: isWide ? 1.15 : 1.0,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _ActionCard(item: action);
          },
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item});

  final _ActionItemData item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItemData {
  const _ActionItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final void Function() onTap;
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final stats = <_StatCardData>[
      _StatCardData(label: 'Courses', value: '0', accent: AppColors.primary),
      _StatCardData(label: 'Hours', value: '12h', accent: AppColors.accent),
      _StatCardData(label: 'Labs', value: '04', accent: AppColors.info),
      _StatCardData(label: 'Points', value: '680', accent: AppColors.success),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: stat.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Text(
                    stat.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    stat.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;
}

class _LearningOverviewSection extends StatelessWidget {
  const _LearningOverviewSection({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = <_OverviewItem>[
      _OverviewItem(
        title: 'Study Library',
        subtitle: 'Saved photo analyses and references',
        action: 'Open library',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StudyLibraryScreen()),
          );
        },
      ),
      _OverviewItem(
        title: 'My Courses',
        subtitle: 'Track and continue your classes',
        action: 'View courses',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyCoursesScreen()),
          );
        },
      ),
      _OverviewItem(
        title: 'Labs',
        subtitle: 'Guided practice and lesson check-ins',
        action: 'Explore labs',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LabsHomeScreen()),
          );
        },
      ),
      _OverviewItem(
        title: 'Missions',
        subtitle: 'Structured daily study goals',
        action: 'View missions',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyMissionsScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: isWide ? 2.8 : 1.8,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];
            return Material(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.premiumGradient.asMap().containsKey(0)
                              ? LinearGradient(
                                  colors: AppColors.premiumGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.subtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        item.action,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OverviewItem {
  const _OverviewItem({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String action;
  final void Function() onTap;
}
