import 'package:flutter/material.dart';

import '../../models/lab_model.dart';
import '../../services/lab_service.dart';
import 'lab_lesson_screen.dart';
import 'lab_quiz_screen.dart';
import 'lab_widgets.dart';

/// Detail view for a single Lab: description, progress, the ordered lesson
/// list and the quiz action.
class LabDetailScreen extends StatefulWidget {
  const LabDetailScreen({super.key, required this.labId});

  final String? labId;

  @override
  State<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen> {
  final LabService _labService = LabService.instance;

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

  void _openLesson(LabLesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LabLessonScreen(labId: widget.labId, lessonId: lesson.id),
      ),
    );
  }

  void _openQuiz() {
    final lab = _labService.labById(widget.labId);
    if (lab == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LabQuizScreen(labId: lab.id)));
  }

  @override
  Widget build(BuildContext context) {
    final lab = _labService.labById(widget.labId);

    // The Lab is bundled and always present, so this only guards against a
    // stale id arriving from an old route.
    if (lab == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lab')),
        body: const Center(child: Text('This Lab could not be found.')),
      );
    }

    final progress = _labService.progressFor(lab.id);
    final percent = _labService.progressPercentFor(lab.id);
    final stats = _labService.statsFor(lab.id);
    final nextLesson = _labService.nextLessonFor(lab.id);
    final accent = labCategoryColor(lab.category);
    final hasQuestions = lab.quizQuestions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(lab.title), centerTitle: true),
      body: LabPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        labCategoryIcon(lab.category),
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lab.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lab.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      LabBadge(
                        label: lab.category.label,
                        color: Colors.white,
                        icon: labCategoryIcon(lab.category),
                      ),
                      const SizedBox(width: 8),
                      LabBadge(
                        label: lab.difficulty.label,
                        color: Colors.white,
                        icon: Icons.signal_cellular_alt,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Progress card
            Container(
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
                      Text(
                        'Your progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (progress.isCompleted)
                        const LabBadge(
                          label: 'Completed',
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LabProgressBar(percent: percent, color: accent),
                  const SizedBox(height: 10),
                  Text(
                    '${progress.completedLessonIds.length} of '
                    '${lab.lessons.length} lessons complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (stats.attemptCount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Quiz: ${stats.attemptCount} attempt'
                      '${stats.attemptCount == 1 ? '' : 's'} · '
                      'best ${stats.bestScore}/${stats.bestPercentage}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Primary actions
            if (nextLesson != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openLesson(nextLesson),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    percent > 0 ? 'Continue Learning' : 'Start Learning',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (hasQuestions)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openQuiz,
                  icon: const Icon(Icons.quiz_outlined),
                  label: Text(
                    stats.attemptCount > 0
                        ? 'Retake Quiz'
                        : 'Start Quiz (${lab.quizQuestions.length} questions)',
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Lessons
            Text(
              'Lessons',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (lab.lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('This Lab has no lessons yet.'),
              )
            else
              ...List.generate(lab.lessons.length, (index) {
                final lesson = lab.lessons[index];
                final isDone = _labService.isLessonCompleted(lab.id, lesson.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildLessonTile(lesson, index, isDone, accent),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTile(
    LabLesson lesson,
    int index,
    bool isDone,
    Color accent,
  ) {
    return InkWell(
      onTap: () => _openLesson(lesson),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDone ? Colors.green.shade300 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDone ? Colors.green.shade50 : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? Colors.green : accent.withValues(alpha: 0.12),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (lesson.keyPoints.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.lightbulb_outline,
                          size: 13,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.keyPoints.length} key points',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
