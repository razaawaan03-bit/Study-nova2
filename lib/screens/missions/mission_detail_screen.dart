import 'package:flutter/material.dart';

import '../../models/mission_model.dart';
import '../../services/mission_service.dart';
import 'mission_completion_screen.dart';
import 'mission_day_screen.dart';
import 'mission_quiz_screen.dart';
import 'mission_widgets.dart';

/// The mission overview: what the mission is, how far it has come, the roadmap
/// of mission days, the milestones and the Final Challenge.
class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({super.key, required this.missionId});

  final String? missionId;

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionService _missionService = MissionService.instance;

  @override
  Widget build(BuildContext context) {
    final mission = _missionService.byId(widget.missionId);
    if (mission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mission'), centerTitle: true),
        body: const Center(child: Text('This mission could not be found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Mode'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _onMenu(value, mission),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: mission.isPaused ? 'resume' : 'pause',
                child: Text(
                  mission.isPaused ? 'Resume mission' : 'Pause mission',
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete mission',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: MissionPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildOverview(mission),
            const SizedBox(height: 16),
            _buildPrimaryActions(mission),
            const SizedBox(height: 24),
            _buildProgress(mission),
            const SizedBox(height: 24),
            _buildRoadmap(mission),
            const SizedBox(height: 24),
            _buildMilestones(mission),
            const SizedBox(height: 24),
            _buildFinalChallenge(mission),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(MissionModel mission) {
    final remaining = mission.targetDate?.difference(DateTime.now()).inDays;

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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mission.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MissionBadge(
                label: '${mission.durationDays} day mission',
                color: Colors.white,
                icon: Icons.calendar_today,
              ),
              MissionBadge(
                label: '${formatStudyMinutes(mission.dailyStudyMinutes)} / day',
                color: Colors.white,
                icon: Icons.schedule,
              ),
              MissionBadge(
                label: mission.level.label,
                color: Colors.white,
                icon: Icons.signal_cellular_alt,
              ),
              if (mission.examTarget != MissionExamTarget.none)
                MissionBadge(
                  label: mission.examTarget == MissionExamTarget.custom
                      ? (mission.customExamTarget.isEmpty
                            ? 'Exam'
                            : mission.customExamTarget)
                      : mission.examTarget.label,
                  color: Colors.white,
                  icon: Icons.flag,
                ),
            ],
          ),
          if (mission.topics.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Topics: ${mission.topics.take(6).join(', ')}'
              '${mission.topics.length > 6 ? ' +${mission.topics.length - 6} more' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (remaining != null) ...[
            const SizedBox(height: 6),
            Text(
              remaining < 0
                  ? 'Target date has passed'
                  : '$remaining day${remaining == 1 ? '' : 's'} to your target date',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(MissionModel mission) {
    if (mission.isPaused) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _missionService.togglePause(mission.id),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Resume this mission'),
        ),
      );
    }

    if (mission.isCompleted) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MissionCompletionScreen(missionId: mission.id),
            ),
          ),
          icon: const Icon(Icons.emoji_events),
          label: const Text('View mission results'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openDay(mission, mission.suggestedDay),
            icon: const Icon(Icons.play_arrow),
            label: Text(
              mission.completedRequiredTaskCount == 0
                  ? 'Start Day 1'
                  : 'Continue Day ${mission.suggestedDay}',
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openDay(mission, 1),
            icon: const Icon(Icons.list_alt),
            label: const Text('See all mission days'),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(MissionModel mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MissionSectionHeader(
          title: 'Mission Progress',
          icon: Icons.insights,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${mission.computedProgress}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 10),
              MissionProgressBar(percent: mission.computedProgress),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 560 ? 2 : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.4,
                    children: [
                      MissionStatTile(
                        icon: Icons.check_circle_outline,
                        value:
                            '${mission.completedRequiredTaskCount}/${mission.requiredTaskCount}',
                        label: 'Tasks',
                      ),
                      MissionStatTile(
                        icon: Icons.menu_book,
                        value:
                            '${mission.completedLessonCount}/${mission.lessonTaskCount}',
                        label: 'Lessons',
                        color: kMissionAccent,
                      ),
                      MissionStatTile(
                        icon: Icons.quiz_outlined,
                        value:
                            '${mission.completedQuizCount}/${mission.quizTaskCount}',
                        label: 'Quizzes',
                        color: Colors.teal,
                      ),
                      MissionStatTile(
                        icon: Icons.schedule,
                        value: formatStudyMinutes(mission.studyMinutesSpent),
                        label: 'Study time',
                        color: Colors.orange,
                      ),
                      MissionStatTile(
                        icon: Icons.local_fire_department,
                        value: '${mission.currentStreak} days',
                        label: 'Streak (best ${mission.longestStreak})',
                        color: Colors.deepOrange,
                      ),
                      MissionStatTile(
                        icon: Icons.assignment,
                        value: '${mission.revisionCount}',
                        label: 'Revision sessions',
                        color: Colors.purple,
                      ),
                    ],
                  );
                },
              ),
              if (mission.linkedTaskCount < mission.requiredTaskCount) ...[
                const SizedBox(height: 12),
                Text(
                  '${mission.linkedTaskCount} of your tasks open existing Study '
                  'Nova content. The rest are self-study tasks, because no '
                  'matching course or Lab was found.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmap(MissionModel mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MissionSectionHeader(
          title: 'Mission Roadmap',
          icon: Icons.route,
          subtitle: 'Start at the beginning and unlock each mission day.',
        ),
        ...mission.days.map((day) {
          final unlocked = mission.isDayUnlocked(day.dayNumber);
          final state = day.isComplete
              ? MissionRoadmapState.completed
              : day.dayNumber == mission.suggestedDay
              ? MissionRoadmapState.current
              : unlocked
              ? MissionRoadmapState.available
              : MissionRoadmapState.locked;

          return MissionRoadmapTile(
            dayNumber: day.dayNumber,
            title: day.title,
            subtitle:
                '${day.completedTasks}/${day.totalTasks} tasks • '
                '${formatStudyMinutes(day.estimatedMinutes)} • '
                '${day.progressPercent}%',
            state: state,
            onTap: unlocked ? () => _openDay(mission, day.dayNumber) : null,
          );
        }),
      ],
    );
  }

  Widget _buildMilestones(MissionModel mission) {
    if (mission.milestones.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MissionSectionHeader(
          title: 'Milestones',
          icon: Icons.military_tech,
        ),
        ...mission.milestones.map(
          (milestone) => MissionMilestoneTile(milestone: milestone),
        ),
      ],
    );
  }

  Widget _buildFinalChallenge(MissionModel mission) {
    final task = mission.finalChallengeTask;
    if (task == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MissionSectionHeader(
          title: 'Final Challenge',
          icon: Icons.emoji_events,
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test everything you covered in ${mission.title}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (mission.finalChallengeBestPercentage > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Best score so far: ${mission.finalChallengeBestPercentage}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MissionQuizScreen(
                      missionId: mission.id,
                      mode: MissionQuizMode.finalChallenge,
                    ),
                  ),
                ),
                icon: const Icon(Icons.emoji_events),
                label: Text(
                  task.isCompleted
                      ? 'Retake Final Challenge'
                      : 'Take Final Challenge',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDay(MissionModel mission, int dayNumber) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MissionDayScreen(missionId: mission.id, dayNumber: dayNumber),
      ),
    );
  }

  Future<void> _onMenu(String value, MissionModel mission) async {
    switch (value) {
      case 'pause':
      case 'resume':
        await _missionService.togglePause(mission.id);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete this mission?'),
            content: const Text(
              'Only the mission is removed. Your courses, Labs and lessons stay '
              'in Study Nova.',
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
        if (!mounted) return;
        Navigator.of(context).pop();
        break;
    }
  }
}
