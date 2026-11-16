import 'package:flutter/material.dart';

import '../../services/course_service.dart';
import 'course_preview_screen.dart';

/// Displays the courses the current user has saved to Supabase.
class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final CourseService _courseService = CourseService();
  List<Map<String, dynamic>> _courses = <Map<String, dynamic>>[];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final courses = await _courseService.getUserCourses();
      if (!mounted) return;
      setState(() => _courses = courses);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteCourse(String courseId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text('Delete "$title"? This cannot be undone.'),
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

    try {
      await _courseService.deleteCourse(courseId);
      if (!mounted) return;
      _showMessage('Course deleted.');
      _loadCourses();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not delete the course. Please try again.');
    }
  }

  Future<void> _openCourse(Map<String, dynamic> courseRow) async {
    final courseId = courseRow['id']?.toString();
    if (courseId == null) return;

    _showMessage('Loading your course...');
    try {
      final generatedCourse = await _courseService.loadGeneratedCourse(
        courseId,
      );
      if (!mounted) return;
      if (generatedCourse == null) {
        _showMessage('Could not load this course.');
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CoursePreviewScreen(course: generatedCourse, onRegenerate: null),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not open this course. Please try again.');
    }
  }

  String _progressLabel(int progress) => '$progress%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final signedOut = _error!.toLowerCase().contains('sign in');
      // The service already decided *why* the load failed (not configured,
      // backend unreachable, signed out, ...). Repeating a fixed "check your
      // internet connection" line here used to blame the student's connection
      // for problems that have nothing to do with it, so the real, already
      // friendly message is shown instead.
      final detail = signedOut
          ? 'Your saved courses are stored securely in your account.'
          : _error!;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                signedOut ? Icons.lock_outline : Icons.cloud_off,
                size: 56,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 16),
              Text(
                signedOut
                    ? 'Sign in to see your courses'
                    : 'Could not load your courses',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (signedOut)
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _loadCourses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
            ],
          ),
        ),
      );
    }
    if (_courses.isEmpty) {
      return _buildEmptyState();
    }
    return _buildCourseList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "You haven't created any courses yet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/course-setup'),
              icon: const Icon(Icons.add),
              label: const Text('Create New Course'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = (course['title'] ?? 'Untitled').toString();
    final subject = (course['subject'] ?? '').toString();
    final courseType = (course['course_type'] ?? '').toString();
    final chapterCount = _asInt(course['chapter_count']);
    final topicCount = _asInt(course['topic_count']);
    final progress = _asInt(course['progress']);
    final updatedAt = course['updated_at'] != null
        ? DateTime.tryParse(course['updated_at'].toString())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openCourse(course),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameCourse(course['id']?.toString() ?? '', title);
                      } else if (value == 'delete') {
                        _deleteCourse(course['id']?.toString() ?? '', title);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              if (subject.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subject, style: TextStyle(color: Colors.blue.shade700)),
              ],
              if (courseType.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  courseType.replaceAll('_', ' '),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStat('📖', '$chapterCount chapters'),
                  const SizedBox(width: 12),
                  _buildStat('📝', '$topicCount topics'),
                  const SizedBox(width: 12),
                  _buildStat('📊', _progressLabel(progress)),
                ],
              ),
              if (updatedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last studied ${_formatDate(updatedAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Open →',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String icon, String label) {
    return Row(
      children: [
        Text(icon),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      ],
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return ' days ago';
    return '//';
  }

  Future<void> _renameCourse(String courseId, String currentTitle) async {
    if (courseId.isEmpty) return;
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename course'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Course title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) {
      return;
    }
    try {
      await _courseService.updateCourseTitle(courseId, newTitle);
      if (!mounted) return;
      _showMessage('Course renamed.');
      _loadCourses();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not rename the course. Please try again.');
    }
  }
}
