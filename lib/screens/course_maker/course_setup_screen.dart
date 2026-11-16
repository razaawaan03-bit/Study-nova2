import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import 'course_material_screen.dart';

/// Step 1 of the Course Maker: the "Create a New Course" setup screen.
///
/// Collects everything the AI needs before any study material is added, then
/// carries it forward as a draft [CourseModel].
class CourseSetupScreen extends StatefulWidget {
  const CourseSetupScreen({super.key});

  @override
  State<CourseSetupScreen> createState() => _CourseSetupScreenState();
}

class _CourseSetupScreenState extends State<CourseSetupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _examNameController = TextEditingController();
  final TextEditingController _examTargetController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  CourseType _courseType = CourseType.school;
  CourseLength _length = CourseLength.medium;
  CourseDifficulty _difficulty = CourseDifficulty.beginner;
  CourseLanguage _language = CourseLanguage.english;
  String _classLevel = 'Class 10';

  static const List<String> _classOptions = <String>[
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
    'College',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _examNameController.dispose();
    _examTargetController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  /// Combines the exam name with the optional target/topic, e.g.
  /// "NEET • Rotational Motion".
  String? _buildExamTarget() {
    final exam = _examNameController.text.trim();
    final target = _examTargetController.text.trim();
    if (exam.isEmpty && target.isEmpty) return null;
    if (exam.isEmpty) return target;
    if (target.isEmpty) return exam;
    return '$exam • $target';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _continue() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Please enter a course name or topic.');
      return;
    }

    final subject = _subjectController.text.trim();
    if (_courseType == CourseType.school && subject.isEmpty) {
      _showMessage('Please enter the subject for this school course.');
      return;
    }

    final examTarget = _buildExamTarget();
    if (_courseType == CourseType.competitiveExam &&
        (examTarget ?? '').isEmpty) {
      _showMessage('Please enter the exam name.');
      return;
    }

    final goal = _goalController.text.trim();
    final draft = CourseModel(
      title: title,
      courseType: _courseType,
      classLevel: _courseType == CourseType.school ? _classLevel : null,
      subject: subject.isEmpty ? null : subject,
      examTarget: _courseType == CourseType.competitiveExam ? examTarget : null,
      length: _length,
      difficulty: _difficulty,
      language: _language,
      learningGoal: goal.isEmpty ? null : goal,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseMaterialScreen(course: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Course'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us what you want to learn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We will build chapters, quizzes and revision notes from your own material.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: 'Course Name / Topic',
              icon: Icons.menu_book_outlined,
              children: [
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Example: Class 10 Science'),
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Course Type',
              icon: Icons.category_outlined,
              children: [
                _buildChoiceChips<CourseType>(
                  values: CourseType.values,
                  selected: _courseType,
                  labelOf: (value) => value.label,
                  onSelected: (value) => setState(() => _courseType = value),
                ),
              ],
            ),

            if (_courseType == CourseType.school)
              _buildSectionCard(
                title: 'Class & Subject',
                icon: Icons.school_outlined,
                children: [
                  _buildDropdown<String>(
                    value: _classLevel,
                    hint: 'Class / Grade',
                    options: _classOptions,
                    labelOf: (value) => value,
                    onChanged: (value) => setState(() => _classLevel = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Example: Science'),
                  ),
                ],
              ),

            if (_courseType == CourseType.competitiveExam)
              _buildSectionCard(
                title: 'Exam Details',
                icon: Icons.emoji_events_outlined,
                children: [
                  TextField(
                    controller: _examNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Exam name (Example: NEET)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Subject (Example: Biology)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _examTargetController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      'Target / Topic (Example: Human Physiology)',
                    ),
                  ),
                ],
              ),

            if (_courseType == CourseType.generalLearning)
              _buildSectionCard(
                title: 'Subject',
                icon: Icons.interests_outlined,
                children: [
                  TextField(
                    controller: _subjectController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('Optional (Example: Physics)'),
                  ),
                ],
              ),

            _buildSectionCard(
              title: 'Course Length',
              icon: Icons.format_list_numbered,
              children: [
                _buildChoiceChips<CourseLength>(
                  values: CourseLength.values,
                  selected: _length,
                  labelOf: (value) => value.label,
                  onSelected: (value) => setState(() => _length = value),
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Difficulty',
              icon: Icons.trending_up,
              children: [
                _buildChoiceChips<CourseDifficulty>(
                  values: CourseDifficulty.values,
                  selected: _difficulty,
                  labelOf: (value) => value.label,
                  onSelected: (value) => setState(() => _difficulty = value),
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Language',
              icon: Icons.translate_outlined,
              children: [
                _buildDropdown<CourseLanguage>(
                  value: _language,
                  hint: 'Language',
                  options: CourseLanguage.values,
                  labelOf: (value) => value.label,
                  onChanged: (value) => setState(() => _language = value),
                ),
              ],
            ),

            _buildSectionCard(
              title: 'Learning Goal (optional)',
              icon: Icons.flag_outlined,
              children: [
                TextField(
                  controller: _goalController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    'Example: I want to prepare this chapter for my school exam.',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _continue,
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Rounded card that groups one question of the setup form.
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(icon, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildChoiceChips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(labelOf(value)),
              selected: value == selected,
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(hint),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: options
              .map(
                (option) => DropdownMenuItem<T>(
                  value: option,
                  child: Text(labelOf(option)),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}
