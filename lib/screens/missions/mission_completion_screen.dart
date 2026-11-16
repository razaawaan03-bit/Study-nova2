import 'package:flutter/material.dart';

import '../../services/mission_service.dart';
import 'mission_detail_screen.dart';
import 'mission_widgets.dart';

/// Celebration screen shown when every required task of a mission is done.
class MissionCompletionScreen extends StatelessWidget {
  const MissionCompletionScreen({super.key, required this.missionId});

  final String? missionId;

  @override
  Widget build(BuildContext context) {
    final mission = MissionService.instance.byId(missionId);
    if (mission == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mission Complete'),
          centerTitle: true,
        ),
        body: const Center(child: Text('This mission could not be found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Complete'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MissionPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const Center(child: Text('🎉', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 12),
            Text(
              'MISSION COMPLETE!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mission.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${mission.computedProgress}%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Mission progress',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const MissionSectionHeader(
              title: 'What you completed',
              icon: Icons.checklist,
            ),
            ...mission.days.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Day ${entry.key + 1} — ${entry.value.title}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value.totalTasks} tasks',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 560 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3.2,
                  children: [
                    MissionStatTile(
                      icon: Icons.calendar_today,
                      value: '${mission.durationDays} days',
                      label: 'Mission length',
                    ),
                    MissionStatTile(
                      icon: Icons.check_circle_outline,
                      value: '${mission.completedRequiredTaskCount}',
                      label: 'Tasks completed',
                      color: Colors.green,
                    ),
                    MissionStatTile(
                      icon: Icons.menu_book,
                      value: '${mission.completedLessonCount}',
                      label: 'Lessons studied',
                      color: kMissionAccent,
                    ),
                    MissionStatTile(
                      icon: Icons.quiz_outlined,
                      value: '${mission.completedQuizCount}',
                      label: 'Quizzes taken',
                      color: Colors.teal,
                    ),
                    MissionStatTile(
                      icon: Icons.assignment,
                      value: '${mission.mockTestCount}',
                      label: 'Mock tests',
                      color: Colors.purple,
                    ),
                    MissionStatTile(
                      icon: Icons.emoji_events,
                      value: mission.finalChallengeBestPercentage == 0
                          ? 'Done'
                          : '${mission.finalChallengeBestPercentage}%',
                      label: 'Final Challenge',
                      color: Colors.amber,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            if (mission.milestones.isNotEmpty) ...[
              const MissionSectionHeader(
                title: 'Milestones earned',
                icon: Icons.military_tech,
              ),
              ...mission.milestones
                  .where((milestone) => milestone.isUnlocked)
                  .map(
                    (milestone) => MissionMilestoneTile(milestone: milestone),
                  ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MissionDetailScreen(missionId: mission.id),
                  ),
                ),
                icon: const Icon(Icons.replay),
                label: const Text('Review Mission'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushNamed('/mission-create');
                },
                icon: const Icon(Icons.flag),
                label: const Text('Start Another Mission'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
