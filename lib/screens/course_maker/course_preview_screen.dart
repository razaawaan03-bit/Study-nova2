import "package:flutter/material.dart";

import "../../models/course_content_model.dart";
import "../../models/course_model.dart";
import "../../services/course_service.dart";

/// Shows the structured course the AI generated, before anything is saved.
class CoursePreviewScreen extends StatefulWidget {
  const CoursePreviewScreen({
    super.key,
    required this.course,
    this.onRegenerate,
  });

  final GeneratedCourse course;

  /// Re-runs course generation. Returns null when it failed, in which case the
  /// caller has already shown a friendly message.
  final Future<GeneratedCourse?> Function()? onRegenerate;

  @override
  State<CoursePreviewScreen> createState() => _CoursePreviewScreenState();
}

class _CoursePreviewScreenState extends State<CoursePreviewScreen> {
  late GeneratedCourse _course = widget.course;
  bool _isRegenerating = false;
  bool _isSaving = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _regenerate() async {
    final regenerate = widget.onRegenerate;
    if (regenerate == null || _isRegenerating) {
      _showMessage("Regenerating is not available right now.");
      return;
    }

    setState(() => _isRegenerating = true);
    try {
      final regenerated = await regenerate();
      if (!mounted) return;
      if (regenerated != null) {
        setState(() => _course = regenerated);
        _showMessage("Course regenerated.");
      }
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _course.course.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Course title"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: "Course title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (newTitle == null || newTitle.isEmpty) return;
    setState(() {
      _course = _course.copyWith(
        course: _course.course.copyWith(title: newTitle),
      );
    });
  }

  Future<void> _saveCourse() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final courseService = CourseService();
      await courseService.saveGeneratedCourse(_course);

      if (!mounted) return;

      _showMessage("Course saved successfully!");

      // Navigate to My Courses
      Navigator.of(context).pushNamed("/my-courses");
    } catch (e) {
      if (!mounted) return;
      _showMessage("Could not save your course. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = _course.course;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Preview"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isRegenerating ? null : _editTitle,
            tooltip: "Edit title",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isRegenerating || widget.onRegenerate == null)
                ? null
                : _regenerate,
            tooltip: "Regenerate",
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(course),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveCourse,
        icon: const Icon(Icons.save),
        label: const Text("Save course"),
      ),
    );
  }

  Widget _buildBody(CourseModel course) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (course.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(course.description),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        "Chapters",
                        _course.chapterCount.toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildStat(
                        "Topics",
                        _course.topicCount.toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildStat(
                        "Quizzes",
                        _course.quizCount.toString(),
                      ),
                    ),
                  ],
                ),
                if (_course.questionCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    "${_course.questionCount} questions in total",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List<Widget>.generate(_course.chapters.length, (index) {
          return _buildChapter(_course.chapters[index], index);
        }),
        if (_course.revisionNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Revision notes",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._course.revisionNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("- $note"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChapter(CourseChapter chapter, int chapterIndex) {
    final quiz = _course.quizForChapter(chapterIndex);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(chapter.title),
        subtitle: Text(
          quiz == null
              ? "${chapter.topics.length} topics"
              : "${chapter.topics.length} topics • ${quiz.questions.length} questions",
        ),
        children: [
          if (chapter.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(chapter.description),
              ),
            ),
          ...chapter.topics.map((topic) => _buildTopic(topic)),
        ],
      ),
    );
  }

  Widget _buildTopic(CourseTopic topic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topic.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (topic.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(topic.explanation),
          ],
          if (topic.simpleExplanation.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              topic.simpleExplanation,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          if (topic.importantPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...topic.importantPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text("- $point"),
              ),
            ),
          ],
          if (topic.examples.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Examples", style: Theme.of(context).textTheme.labelLarge),
            ...topic.examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(example),
              ),
            ),
          ],
          if (topic.keyTerms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: topic.keyTerms
                  .map(
                    (term) => Chip(
                      label: Text(
                        term.definition.isEmpty
                            ? term.term
                            : "${term.term}: ${term.definition}",
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (topic.questions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Practice", style: Theme.of(context).textTheme.labelLarge),
            ...topic.questions.map(
              (question) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text("Q: $question"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
