import 'package:flutter/material.dart';

import '../../models/lab_model.dart';
import '../../services/custom_lab_service.dart';
import '../../services/lab_service.dart';
import 'custom_lab_creator_screen.dart';
import 'lab_detail_screen.dart';
import 'lab_widgets.dart';

/// The Study Nova Labs catalogue.
///
/// Lists every bundled Lab from [LabService], filterable by [LabCategory].
/// Requires a signed-in user; unauthenticated visitors are sent to the
/// existing login flow.
class LabsHomeScreen extends StatefulWidget {
  const LabsHomeScreen({super.key});

  @override
  State<LabsHomeScreen> createState() => _LabsHomeScreenState();
}

class _LabsHomeScreenState extends State<LabsHomeScreen> {
  final LabService _labService = LabService.instance;
  LabCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _labService.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    _labService.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  void _openLab(LabModel lab) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LabDetailScreen(labId: lab.id)));
  }

  @override
  Widget build(BuildContext context) {
    final allLabs = _labService.allLabs;
    final labs = _selectedCategory == null
        ? allLabs
        : allLabs.where((lab) => lab.category == _selectedCategory).toList();

    final startedCount = allLabs
        .where((lab) => _labService.progressPercentFor(lab.id) > 0)
        .length;
    final completedCount = allLabs
        .where((lab) => _labService.progressFor(lab.id).isCompleted)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Nova Labs'), centerTitle: true),
      body: LabPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Summary banner
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
                    'Learn by doing',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$completedCount of ${allLabs.length} Labs completed · '
                    '$startedCount in progress',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category filter
            Text(
              'Browse by subject',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'All', Icons.apps),
                  for (final category in LabCategory.values)
                    if (allLabs.any((lab) => lab.category == category))
                      _buildFilterChip(
                        category,
                        category.label,
                        labCategoryIcon(category),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build your own study plan',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a custom study lab for your subject and keep it in your personal library.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CustomLabCreatorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Custom Lab'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (CustomLabService.instance.customLabs.isNotEmpty) ...[
              Text(
                'My Custom Labs',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...CustomLabService.instance.customLabs.take(4).map((lab) {
                final accent = labCategoryColor(lab.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _openLab(lab),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lab.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lab.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Lab list
            if (labs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text('No Labs in this subject yet.')),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Two columns on wide (Windows / Web / tablet) layouts.
                  final columns = constraints.maxWidth >= 700 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      // Tall enough for the longest card (3-line description
                      // plus title, badges and progress bar) so no Lab card
                      // ever overflows its grid cell.
                      mainAxisExtent: 214,
                    ),
                    itemCount: labs.length,
                    itemBuilder: (context, index) => _buildLabCard(labs[index]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(LabCategory? category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    final color = category == null ? Colors.blue : labCategoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
        label: Text(label),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildLabCard(LabModel lab) {
    final progress = _labService.progressFor(lab.id);
    final percent = _labService.progressPercentFor(lab.id);
    final accent = labCategoryColor(lab.category);
    final stats = _labService.statsFor(lab.id);

    return InkWell(
      onTap: () => _openLab(lab),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    labCategoryIcon(lab.category),
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lab.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lab.lessons.length} lessons · '
                        '${lab.quizQuestions.length} questions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lab.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const Spacer(),
            const SizedBox(height: 10),
            Row(
              children: [
                LabBadge(
                  label: lab.difficulty.label,
                  color: labDifficultyColor(lab.difficulty),
                ),
                const SizedBox(width: 8),
                if (stats.attemptCount > 0)
                  LabBadge(
                    label: 'Best ${stats.bestPercentage}%',
                    color: Colors.teal,
                    icon: Icons.emoji_events_outlined,
                  ),
                const Spacer(),
                if (progress.isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            LabProgressBar(percent: percent, color: accent, height: 6),
          ],
        ),
      ),
    );
  }
}
