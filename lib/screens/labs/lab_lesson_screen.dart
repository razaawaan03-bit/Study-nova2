import 'package:flutter/material.dart';

import '../../models/lab_model.dart';
import '../../services/lab_service.dart';
import 'lab_quiz_screen.dart';
import 'lab_widgets.dart';

/// Reads a single Lab lesson from the bundled content.
///
/// The lesson is looked up by id through [LabService] so there is exactly one
/// source of lesson content. Completion is written back through
/// [LabService.setLessonCompleted], which also recomputes the Lab's progress.
class LabLessonScreen extends StatefulWidget {
  const LabLessonScreen({
    super.key,
    required this.labId,
    required this.lessonId,
  });

  final String? labId;
  final String? lessonId;

  @override
  State<LabLessonScreen> createState() => _LabLessonScreenState();
}

class _LabLessonScreenState extends State<LabLessonScreen> {
  final LabService _labService = LabService.instance;

  bool _saving = false;

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

  /// The lesson being read, with the current completion flag applied.
  LabLesson? _currentLesson(LabModel lab) {
    for (final lesson in lab.lessons) {
      if (lesson.id == widget.lessonId) {
        return lesson.copyWith(
          isCompleted: _labService.isLessonCompleted(lab.id, lesson.id),
        );
      }
    }
    return null;
  }

  Future<void> _toggleComplete(LabModel lab, LabLesson lesson) async {
    final wasCompleted = lesson.isCompleted;
    setState(() => _saving = true);
    await _labService.setLessonCompleted(
      lab.id,
      lesson.id,
      completed: !wasCompleted,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasCompleted
              ? 'Lesson marked as not complete.'
              : 'Lesson marked complete.',
        ),
      ),
    );
  }

  void _openLesson(String? lessonId) {
    if (lessonId == null) return;
    // Replace so Back from the last lesson returns to the Lab, not the
    // previous lesson.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            LabLessonScreen(labId: widget.labId, lessonId: lessonId),
      ),
    );
  }

  void _openQuiz(LabModel lab) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LabQuizScreen(labId: lab.id)));
  }

  @override
  Widget build(BuildContext context) {
    final lab = _labService.labById(widget.labId);
    final lesson = lab == null ? null : _currentLesson(lab);

    if (lab == null || lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson'), centerTitle: true),
        body: const Center(child: Text('This lesson could not be found.')),
      );
    }

    final accent = labCategoryColor(lab.category);
    final index = lab.lessons.indexWhere((l) => l.id == lesson.id);
    final previous = _labService.lessonBefore(lab.id, lesson.id);
    final next = _labService.lessonAfter(lab.id, lesson.id);
    final percent = _labService.progressPercentFor(lab.id);
    final isLast = index == lab.lessons.length - 1;
    final hasQuiz = lab.quizQuestions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson ${index + 1} of ${lab.lessons.length}'),
        centerTitle: true,
      ),
      body: LabPage(
        child: Column(
          children: [
            // Progress header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lab.title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LabProgressBar(percent: percent, color: accent),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  // Lesson title
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      LabBadge(
                        label: '${lesson.durationMinutes} min',
                        color: Colors.blueGrey,
                        icon: Icons.schedule,
                      ),
                      const SizedBox(width: 8),
                      LabBadge(
                        label: lab.category.label,
                        color: accent,
                        icon: labCategoryIcon(lab.category),
                      ),
                      if (lesson.isCompleted) ...[
                        const SizedBox(width: 8),
                        const LabBadge(
                          label: 'Completed',
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lesson body, paragraph by paragraph
                  ..._buildParagraphs(lesson.content),

                  // Key points
                  if (lesson.keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.06),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: accent),
                              const SizedBox(width: 8),
                              Text(
                                'Key Points',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...lesson.keyPoints.map(
                            (point) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      right: 10,
                                    ),
                                    child: Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: accent,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom action bar
            _buildActionBar(
              lab: lab,
              lesson: lesson,
              accent: accent,
              saving: _saving,
              previousId: previous?.id,
              nextId: next?.id,
              isLast: isLast,
              hasQuiz: hasQuiz,
            ),
          ],
        ),
      ),
    );
  }

  /// The bundled content stores each lesson as paragraphs separated by blank
  /// lines, so they are rendered as separate readable blocks.
  List<Widget> _buildParagraphs(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed
        .split(RegExp(r'\n\s*\n'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              paragraph.trim(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildActionBar({
    required LabModel lab,
    required LabLesson lesson,
    required Color accent,
    required bool saving,
    required String? previousId,
    required String? nextId,
    required bool isLast,
    required bool hasQuiz,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: lesson.isCompleted
                ? OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () => _toggleComplete(lab, lesson),
                    icon: const Icon(Icons.undo),
                    label: const Text('Mark as not complete'),
                  )
                : ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () => _toggleComplete(lab, lesson),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark Complete'),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: previousId == null
                      ? null
                      : () => _openLesson(previousId),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: nextId != null
                    ? ElevatedButton.icon(
                        onPressed: () => _openLesson(nextId),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next Lesson'),
                      )
                    : hasQuiz
                    ? ElevatedButton.icon(
                        onPressed: () => _openQuiz(lab),
                        icon: const Icon(Icons.quiz_outlined),
                        label: Text(isLast ? 'Take the Quiz' : 'Go to Lab'),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.done_all),
                        label: const Text('Back to Lab'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
