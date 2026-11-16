import 'package:flutter/material.dart';

import '../../models/mission_model.dart';
import '../../services/auth_service.dart';
import '../../services/mission_service.dart';
import 'mission_detail_screen.dart';
import 'mission_widgets.dart';

/// "My Missions": the student's learning journeys, grouped by status.
class MyMissionsScreen extends StatefulWidget {
  const MyMissionsScreen({super.key});

  @override
  State<MyMissionsScreen> createState() => _MyMissionsScreenState();
}

class _MyMissionsScreenState extends State<MyMissionsScreen> {
  final MissionService _missionService = MissionService.instance;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _missionService.addListener(_onMissionsChanged);
    if (!_missionService.isLoaded) {
      _missionService.load();
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Missions'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/mission-create'),
        icon: const Icon(Icons.add),
        label: const Text('New Mission'),
      ),
      body: !_authService.isLoggedIn ? _buildSignInGate() : _buildBody(),
    );
  }

  Widget _buildSignInGate() {
    return MissionPage(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: Colors.blue.shade300),
              const SizedBox(height: 16),
              Text(
                'Sign in to open Mission Mode',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your missions belong to your account.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/login');
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_missionService.isLoading && !_missionService.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final active = _missionService.activeMissions;
    final paused = _missionService.pausedMissions;
    final completed = _missionService.completedMissions;
    final total = active.length + paused.length + completed.length;

    if (total == 0) {
      return _buildEmptyState();
    }

    return MissionPage(
      child: RefreshIndicator(
        onRefresh: _missionService.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            if (!_missionService.isCloudAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline mode: your missions are saved on this device.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (active.isNotEmpty) ...[
              const MissionSectionHeader(
                title: 'Active',
                icon: Icons.play_circle_outline,
              ),
              ...active.map(
                (mission) => _MissionCard(
                  mission: mission,
                  onOpen: () => _open(mission),
                  onPause: () => _missionService.togglePause(mission.id),
                  onDelete: () => _delete(mission),
                  actionLabel: 'Continue',
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (paused.isNotEmpty) ...[
              const MissionSectionHeader(
                title: 'Paused',
                icon: Icons.pause_circle_outline,
              ),
              ...paused.map(
                (mission) => _MissionCard(
                  mission: mission,
                  onOpen: () => _open(mission),
                  onPause: () => _missionService.togglePause(mission.id),
                  onDelete: () => _delete(mission),
                  actionLabel: 'Resume',
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (completed.isNotEmpty) ...[
              const MissionSectionHeader(
                title: 'Completed',
                icon: Icons.emoji_events_outlined,
              ),
              ...completed.map(
                (mission) => _MissionCard(
                  mission: mission,
                  onOpen: () => _open(mission),
                  onPause: null,
                  onDelete: () => _delete(mission),
                  actionLabel: 'View results',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return MissionPage(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag_circle_outlined,
                size: 64,
                color: Colors.blue.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No missions yet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell Study Nova what you want to achieve and it will build the '
                'daily journey for you.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/mission-create'),
                icon: const Icon(Icons.add),
                label: const Text('Create Your Mission'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(MissionModel mission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionDetailScreen(missionId: mission.id),
      ),
    );
  }

  Future<void> _delete(MissionModel mission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this mission?'),
        content: Text(
          '"${mission.title}" will be removed from Mission Mode. Your courses, '
          'Labs and lessons are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _missionService.deleteMission(mission.id);
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.onOpen,
    required this.onPause,
    required this.onDelete,
    required this.actionLabel,
  });

  final MissionModel mission;
  final VoidCallback onOpen;
  final VoidCallback? onPause;
  final VoidCallback? onDelete;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final completed = mission.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'pause') onPause?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      if (onPause != null)
                        PopupMenuItem(
                          value: 'pause',
                          child: Text(mission.isPaused ? 'Resume' : 'Pause'),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                mission.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              MissionProgressBar(
                percent: mission.computedProgress,
                color: completed ? Colors.green : Colors.blue,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  MissionBadge(
                    label:
                        'Day ${mission.suggestedDay} of ${mission.durationDays}',
                    color: mission.isPaused ? Colors.orange : Colors.blue,
                    icon: Icons.today,
                  ),
                  const SizedBox(width: 8),
                  if (mission.currentStreak > 0)
                    MissionBadge(
                      label: '${mission.currentStreak} day streak',
                      color: Colors.deepOrange,
                      icon: Icons.local_fire_department,
                    ),
                  const Spacer(),
                  if (mission.status == MissionStatus.paused)
                    const MissionBadge(
                      label: 'Paused',
                      color: Colors.orange,
                      icon: Icons.pause,
                    )
                  else if (completed)
                    const MissionBadge(
                      label: 'Completed',
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
