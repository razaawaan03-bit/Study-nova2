import 'package:flutter/material.dart';

import '../course_maker/course_setup_screen.dart';
import '../study_from_photo/study_from_photo_screen.dart';
import '../study_from_photo/study_library_screen.dart';
import '../course_maker/my_courses_screen.dart';
import '../missions/mission_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../services/lab_service.dart';
import '../../services/mission_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService().signOut();
                // A shared device: the next student must not inherit the
                // previous account's missions or Lab progress.
                await MissionService.instance.reset();
                await LabService.instance.reset();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              } catch (e) {
                // Classified, so a misconfigured backend is not reported as a
                // lost connection and no raw exception reaches the student.
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
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Nova'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).pushNamed('/about'),
            tooltip: 'About Study Nova',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.userMetadata?['full_name'] ?? user?.email ?? 'User',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My Learning Mission (Stage 7 — Mission Mode)
            _buildMissionCard(context),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Create Course Button
            _buildActionCard(
              context,
              icon: Icons.add_circle,
              title: 'Create New Course',
              description: 'Start building an AI-powered course',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CourseSetupScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // My Courses Button
            _buildActionCard(
              context,
              icon: Icons.library_books,
              title: 'My Courses',
              description: 'View and manage your courses',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyCoursesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Study From Photo Button (NEW)
            _buildActionCard(
              context,
              icon: Icons.photo_camera,
              title: 'Study From Photo',
              description: 'Take a photo and understand it instantly',
              isPrimary: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StudyFromPhotoScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // My Study Library Button (NEW)
            _buildActionCard(
              context,
              icon: Icons.bookmark,
              title: 'My Study Library',
              description: 'View your saved photo analyses',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StudyLibraryScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Study Nova Labs Button (Stage 6)
            _buildActionCard(
              context,
              icon: Icons.science,
              title: 'Study Nova Labs',
              description: 'Explore guided Labs, lessons and quizzes',
              onTap: () {
                Navigator.of(context).pushNamed('/labs');
              },
            ),
            const SizedBox(height: 12),

            // My Missions Button
            _buildActionCard(
              context,
              icon: Icons.flag_circle_outlined,
              title: 'My Missions',
              description: 'Every mission, its progress and milestones',
              onTap: () {
                Navigator.of(context).pushNamed('/missions');
              },
            ),
            const SizedBox(height: 32),

            // Statistics Section
            Text(
              'Your Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                // Two columns on a phone, four on a wide/browser layout, so
                // the stats never overflow a narrow screen.
                final columns = constraints.maxWidth > 560 ? 4 : 2;
                const items = <(String, String)>[
                  ('0', 'Courses Created'),
                  ('0', 'Hours Learned'),
                  ('0', 'Certificates'),
                  ('0', 'Points'),
                ];

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final (value, label) in items)
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns,
                        child: _buildStatCard(context, value, label),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context) {
    return const _MissionBannerCard();
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPrimary ? Colors.blue.shade300 : Colors.grey.shade300,
            width: isPrimary ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isPrimary ? Colors.blue.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.blue.shade200 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.blue.shade800 : Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.blue.shade700 : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // The trailing chevron is decorative; on a very narrow screen the
            // title/description column takes priority.
            if (MediaQuery.sizeOf(context).width > 340)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPrimary ? Colors.blue.shade400 : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// "My Learning Mission" card for the Home screen (Stage 7 • Mission Mode).
///
/// Shows the active mission with its day and progress, or prompts the student
/// to create one. It listens to `MissionService`, so it updates as soon as a
/// mission task is completed.
class _MissionBannerCard extends StatefulWidget {
  const _MissionBannerCard();

  @override
  State<_MissionBannerCard> createState() => _MissionBannerCardState();
}

class _MissionBannerCardState extends State<_MissionBannerCard> {
  final MissionService _missionService = MissionService.instance;

  @override
  void initState() {
    super.initState();
    _missionService.addListener(_onMissionsChanged);
    if (!_missionService.isLoaded) _missionService.load();
  }

  @override
  void dispose() {
    _missionService.removeListener(_onMissionsChanged);
    super.dispose();
  }

  void _onMissionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mission = _missionService.featuredMission;

    if (mission == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Learning Mission',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell Study Nova what you want to achieve and it will build the '
              'daily journey for you.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _bannerActions(
              context,
              primaryLabel: 'Create Your Mission',
              primaryIcon: Icons.add,
              onPrimary: () =>
                  Navigator.of(context).pushNamed('/mission-create'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Learning Mission',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mission.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Day ${mission.suggestedDay} of ${mission.durationDays}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: mission.progressFraction,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${mission.computedProgress}% • '
            '${mission.completedRequiredTaskCount}/${mission.requiredTaskCount} tasks',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _bannerActions(
            context,
            primaryLabel: 'Continue Mission',
            primaryIcon: Icons.play_arrow,
            onPrimary: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MissionDetailScreen(missionId: mission.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The banner buttons.
  ///
  /// A Material button never shrinks below its label, so on a narrow screen
  /// (a small phone, or a narrow browser window) the two buttons are stacked
  /// full-width instead of sitting next to each other and overflowing.
  Widget _bannerActions(
    BuildContext context, {
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback onPrimary,
  }) {
    final create = FilledButton.icon(
      onPressed: onPrimary,
      icon: Icon(primaryIcon),
      label: Text(primaryLabel),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
      ),
    );
    final list = TextButton(
      onPressed: () => Navigator.of(context).pushNamed('/missions'),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: const Text('My Missions'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[create, const SizedBox(height: 8), list],
          );
        }
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[create, list],
        );
      },
    );
  }
}
