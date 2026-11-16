import 'package:flutter/material.dart';

import '../../models/mission_model.dart';
import '../../services/mission_service.dart';
import '../../services/mission_task_launcher.dart';
import 'mission_widgets.dart';

/// Revision view for a mission.
///
/// Shows what the student has already completed in this mission — real lessons,
/// Labs and quizzes — so revising means re-opening the same Study Nova content,
/// not reading a summary invented here.
class MissionRevisionScreen extends StatelessWidget {
  const MissionRevisionScreen({super.key, required this.missionId, this.topic});

  final String? missionId;

  /// When set, the list is limited to this mission topic.
  final String? topic;

  @override
  Widget build(BuildContext context) {
    final mission = MissionService.instance.byId(missionId);
    if (mission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revision'), centerTitle: true),
        body: const Center(child: Text('This mission could not be found.')),
      );
    }

    final completed =
        mission.allTasks
            .where(
              (task) =>
                  task.isCompleted &&
                  task.type != MissionTaskType.custom &&
                  (topic == null || topic!.isEmpty || task.topic == topic),
            )
            .toList()
          ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          topic == null || topic!.isEmpty
              ? 'Revise ${mission.title}'
              : 'Revise $topic',
        ),
        centerTitle: true,
      ),
      body: MissionPage(
        child: completed.isEmpty
            ? _buildEmpty(context, mission)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Text(
                    'Everything you finished in this mission, ready to open '
                    'again.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...completed.map(
                    (task) => MissionTaskTile(
                      task: task,
                      onToggle: () {},
                      // Revision is a read-only review list: everything here is
                      // already finished, so there is nothing to tick.
                      showCheckbox: false,
                      onStart: () => MissionTaskLauncher.open(context, task),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, MissionModel mission) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.replay, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nothing to revise yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a few mission days and the lessons, Labs and quizzes you '
              'finished will appear here for a quick revision.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to my day'),
            ),
          ],
        ),
      ),
    );
  }
}
