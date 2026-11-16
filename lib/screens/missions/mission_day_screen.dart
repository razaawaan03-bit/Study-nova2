import 'package:flutter/material.dart';

import '../../models/mission_model.dart';
import '../../services/mission_service.dart';
import '../../services/mission_task_launcher.dart';
import 'mission_completion_screen.dart';
import 'mission_revision_screen.dart';
import 'mission_widgets.dart';

/// One day of a mission: the tasks for today, with buttons that open the real
/// Study Nova feature each task belongs to.
class MissionDayScreen extends StatefulWidget {
  const MissionDayScreen({
    super.key,
    required this.missionId,
    required this.dayNumber,
  });

  final String? missionId;
  final int dayNumber;

  @override
  State<MissionDayScreen> createState() => _MissionDayScreenState();
}

class _MissionDayScreenState extends State<MissionDayScreen> {
  final MissionService _missionService = MissionService.instance;

  @override
  Widget build(BuildContext context) {
    final mission = _missionService.byId(widget.missionId);
    if (mission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mission day'), centerTitle: true),
        body: const Center(child: Text('This mission could not be found.')),
      );
    }

    final day = mission.dayByNumber(widget.dayNumber);
    if (day == null) {
      return Scaffold(
        appBar: AppBar(title: Text(mission.title), centerTitle: true),
        body: const Center(child: Text('This mission day is not available.')),
      );
    }

    final isUnlocked = mission.isDayUnlocked(day.dayNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${day.dayNumber} of ${mission.durationDays}'),
        centerTitle: true,
      ),
      body: MissionPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildHeader(mission, day),
            const SizedBox(height: 16),
            if (mission.currentStreak > 0) ...[
              _buildStreak(mission),
              const SizedBox(height: 16),
            ],
            if (mission.revisionSuggestions.isNotEmpty) ...[
              _buildRevisionSuggestion(mission),
              const SizedBox(height: 16),
            ],
            const MissionSectionHeader(
              title: "Today's Mission",
              icon: Icons.checklist,
            ),
            if (!isUnlocked)
              _buildLocked(day)
            else
              ...day.tasks.map(
                (task) => MissionTaskTile(
                  task: task,
                  onToggle: () =>
                      _missionService.setTaskCompleted(mission.id, task.id),
                  onStart: MissionTaskLauncher.canOpen(task)
                      ? () => MissionTaskLauncher.open(context, task)
                      : null,
                ),
              ),
            if (isUnlocked) ...[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _addCustomTask(mission, day),
                icon: const Icon(Icons.add),
                label: const Text('Add your own task'),
              ),
            ],
            const SizedBox(height: 24),
            _buildDayNavigation(mission, day),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MissionModel mission, MissionDay day) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mission.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${day.completedRequiredTasks} / ${day.requiredTasks} completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${formatStudyMinutes(day.estimatedMinutes)} planned',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: day.progressPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreak(MissionModel mission) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${mission.currentStreak} day mission streak • best '
              '${mission.longestStreak}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionSuggestion(MissionModel mission) {
    final topics = mission.revisionSuggestions
        .map((result) => result.topic)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.replay, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommended revision',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your last quiz was weak on $topics. Review it before you move on.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MissionRevisionScreen(
                  missionId: mission.id,
                  topic: mission.revisionSuggestions.first.topic,
                ),
              ),
            ),
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Review this topic'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocked(MissionDay day) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Finish the earlier mission days to unlock Day ${day.dayNumber}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNavigation(MissionModel mission, MissionDay day) {
    final previous = day.dayNumber > 1 ? day.dayNumber - 1 : null;
    final next = day.dayNumber < mission.days.length ? day.dayNumber + 1 : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: previous == null
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MissionDayScreen(
                            missionId: mission.id,
                            dayNumber: previous,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: next == null
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MissionDayScreen(
                            missionId: mission.id,
                            dayNumber: next,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ),
          ],
        ),
        if (next == null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: mission.isCompleted
                ? FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MissionCompletionScreen(missionId: mission.id),
                      ),
                    ),
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('Mission Complete — View results'),
                  )
                : OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.flag),
                    label: const Text('Finish mission day'),
                  ),
          ),
        ],
      ],
    );
  }

  Future<void> _addCustomTask(MissionModel mission, MissionDay day) async {
    final controller = TextEditingController();
    final descriptionController = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add your own task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task',
                hintText: 'e.g. Read page 42 and make notes',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Add task'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (title == null || title.trim().isEmpty) return;

    await _missionService.addCustomTask(
      missionId: mission.id,
      dayNumber: day.dayNumber,
      title: title,
      description: descriptionController.text,
    );
  }
}
