import 'package:flutter/material.dart';

import '../../models/lab_model.dart';

/// Shared visual language for the Labs screens: category colours, difficulty
/// chips and progress bars. Kept here so Labs looks consistent with the rest
/// of the app (Material 3, blue seed, 12-16px radii).

/// Icon for each [LabCategory].
IconData labCategoryIcon(LabCategory category) {
  switch (category) {
    case LabCategory.gsc:
      return Icons.biotech;
    case LabCategory.gk:
      return Icons.public;
    case LabCategory.sst:
      return Icons.account_balance;
    case LabCategory.other:
      return Icons.school;
  }
}

/// Accent colour for each [LabCategory].
Color labCategoryColor(LabCategory category) {
  switch (category) {
    case LabCategory.gsc:
      return Colors.teal;
    case LabCategory.gk:
      return Colors.deepOrange;
    case LabCategory.sst:
      return Colors.indigo;
    case LabCategory.other:
      return Colors.blueGrey;
  }
}

/// Colour used for the [LabDifficulty] badge.
Color labDifficultyColor(LabDifficulty difficulty) {
  switch (difficulty) {
    case LabDifficulty.beginner:
      return Colors.green;
    case LabDifficulty.intermediate:
      return Colors.orange;
    case LabDifficulty.advanced:
      return Colors.red;
  }
}

/// A small rounded "Category · Difficulty" style badge.
class LabBadge extends StatelessWidget {
  const LabBadge({
    super.key,
    required this.label,
    required this.color,
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

/// A labelled progress bar with an optional trailing percentage.
class LabProgressBar extends StatelessWidget {
  const LabProgressBar({
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
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

/// Wraps page content in a centred, max-width column so the Labs screens stay
/// readable on wide Windows and Web windows while filling phone screens.
class LabPage extends StatelessWidget {
  const LabPage({super.key, required this.child, this.maxWidth = 900});

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
