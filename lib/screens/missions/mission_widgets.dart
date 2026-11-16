import 'package:flutter/material.dart';

import '../../models/mission_model.dart';

/// Shared visual language for Mission Mode, matching the Study Nova look used
/// by the rest of the app (Material 3, blue seed, rounded cards, 12-16px radii).
/// Mirrors `lib/screens/labs/lab_widgets.dart`.

const Color kMissionPrimary = Colors.blue;
const Color kMissionAccent = Colors.indigo;
const Color kMissionSuccess = Colors.green;
const Color kMissionWarning = Colors.orange;

/// Centres page content so wide Windows and Web windows stay readable while
/// phone screens use the full width.
class MissionPage extends StatelessWidget {
  const MissionPage({super.key, required this.child, this.maxWidth = 900});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A small rounded badge, e.g. "Science • 14 days".
class MissionBadge extends StatelessWidget {
  const MissionBadge({
    super.key,
    required this.label,
    this.color = Colors.blue,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled progress bar with the percentage on the right.
class MissionProgressBar extends StatelessWidget {
  const MissionProgressBar({
    super.key,
    required this.percent,
    this.color = Colors.blue,
    this.height = 8,
  });

  final int percent;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              value: (percent.clamp(0, 100)) / 100,
              minHeight: height,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

/// One statistic in the mission overview / progress grid.
class MissionStatTile extends StatelessWidget {
  const MissionStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = Colors.blue,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled section inside a mission screen.
class MissionSectionHeader extends StatelessWidget {
  const MissionSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: kMissionPrimary, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// One task in a mission day: a checkbox, what it does, and a button that opens
/// the real Study Nova feature when the task points at existing content.
class MissionTaskTile extends StatelessWidget {
  const MissionTaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onStart,
    this.enabled = true,
    this.showCheckbox = true,
  });

  final MissionTask task;
  final VoidCallback onToggle;

  /// Opens the task in the existing Study Nova feature. Null for tasks that are
  /// ticked off directly (custom study tasks).
  final VoidCallback? onStart;

  final bool enabled;

  /// False on read-only lists (revision), where a disabled checkbox would be a
  /// control that looks tappable but never does anything.
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final accent = task.isCompleted ? kMissionSuccess : kMissionPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.green.shade50 : Colors.white,
        border: Border.all(
          color: task.isCompleted
              ? Colors.green.shade300
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onStart : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCheckbox) ...[
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: enabled ? (_) => onToggle() : null,
                        activeColor: kMissionSuccess,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(task.type.icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? Colors.grey.shade600
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${task.type.label} • ${task.estimatedMinutes} min'
                            '${task.topic.isEmpty ? '' : ' • ${task.topic}'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
                if (onStart != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: task.isCompleted ? null : onStart,
                        icon: Icon(task.type.icon, size: 18),
                        label: Text(task.actionLabel),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One node in the mission roadmap.
class MissionRoadmapTile extends StatelessWidget {
  const MissionRoadmapTile({
    super.key,
    required this.dayNumber,
    required this.title,
    required this.subtitle,
    required this.state,
    this.onTap,
  });

  final int dayNumber;
  final String title;
  final String subtitle;
  final MissionRoadmapState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (state) {
      MissionRoadmapState.completed => (kMissionSuccess, Icons.check_circle),
      MissionRoadmapState.current => (kMissionPrimary, Icons.play_circle_fill),
      MissionRoadmapState.available => (
        kMissionAccent,
        Icons.radio_button_unchecked,
      ),
      MissionRoadmapState.locked => (Colors.grey, Icons.lock_outline),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline rail
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: state == MissionRoadmapState.completed
                      ? Icon(Icons.check, size: 18, color: color)
                      : Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                ),
                Container(width: 2, height: 28, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(icon, size: 16, color: color),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MissionRoadmapState { completed, current, available, locked }

/// One milestone in the mission.
class MissionMilestoneTile extends StatelessWidget {
  const MissionMilestoneTile({super.key, required this.milestone});

  final MissionMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final unlocked = milestone.isUnlocked;
    final color = unlocked ? kMissionWarning : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber.shade50 : Colors.white,
        border: Border.all(
          color: unlocked ? Colors.amber.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(
              unlocked ? Icons.emoji_events : Icons.lock_outline,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Formats minutes as "2h 15m".
String formatStudyMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}
