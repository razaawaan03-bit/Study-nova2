import 'package:flutter/material.dart';

import '../../models/lab_model.dart';
import '../../services/custom_lab_ai_service.dart';
import '../../services/custom_lab_service.dart';
import 'lab_lesson_screen.dart';
import 'lab_quiz_screen.dart';
import 'lab_widgets.dart';

class CustomLabCreatorScreen extends StatefulWidget {
  const CustomLabCreatorScreen({super.key});

  @override
  State<CustomLabCreatorScreen> createState() => _CustomLabCreatorScreenState();
}

class _CustomLabCreatorScreenState extends State<CustomLabCreatorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  final List<String> _suggestedTopics = <String>[
    'Photosynthesis',
    'Life Processes',
    'The Constitution',
    'Fractions',
    'Essay Writing',
    'Weather and Climate',
    'The Water Cycle',
    'Cell Structure',
    'World History',
  ];

  final List<String> _subjectOptions = <String>[
    'General Science',
    'General Knowledge',
    'Social Studies',
    'Mathematics',
    'English',
    'Other school subject',
  ];

  final List<String> _gradeOptions = <String>[
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
    'Other',
  ];

  final List<String> _difficultyOptions = <String>[
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final List<String> _goalOptions = <String>[
    'Understand concepts',
    'Prepare for an exam',
    'Improve weak topics',
    'Revise a chapter',
    'Practice questions',
    'Master a topic',
  ];

  final List<String> _durationOptions = <String>[
    '1 day',
    '3 days',
    '7 days',
    '14 days',
    '30 days',
  ];

  final List<String> _lessonCountOptions = <String>[
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];

  final List<String> _languageOptions = <String>[
    'English',
    'Hindi',
    'Urdu',
    'Other',
  ];

  final List<String> _studyTimeOptions = <String>[
    '10 minutes',
    '20 minutes',
    '30 minutes',
    '45 minutes',
    '60 minutes',
  ];

  final List<String> _contentOptions = <String>[
    'Short explanations',
    'Detailed lessons',
    'Examples',
    'Practice questions',
    'MCQ quizzes',
    'Revision notes',
    'Final assessment',
  ];

  String _subject = 'General Science';
  String _topic = 'Photosynthesis';
  String _grade = 'Class 10';
  String _difficulty = 'Beginner';
  String _goal = 'Understand concepts';
  String _duration = '7 days';
  String _studyTime = '30 minutes';
  String _preferredLanguage = 'English';
  String _lessonCount = '4';
  final Set<String> _selectedContent = <String>{};
  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_nameController.text.trim().isEmpty) {
      return 'Please give your lab a name.';
    }
    final topic =
        (_topicController.text.trim().isNotEmpty
                ? _topicController.text.trim()
                : _topic)
            .trim();
    if (topic.isEmpty) {
      return 'Please choose or type a topic.';
    }
    if (_selectedContent.isEmpty) {
      return 'Please select at least one type of learning content.';
    }
    return null;
  }

  Future<void> _generateAiLab() async {
    final error = _validate();
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isGenerating = true);

    final customConfig = CustomLabConfig(
      labName: _nameController.text.trim(),
      subject: _subject,
      category: LabCategory.other,
      topic: _topicController.text.trim().isNotEmpty
          ? _topicController.text.trim()
          : _topic,
      topics: <String>[
        _topicController.text.trim().isNotEmpty
            ? _topicController.text.trim()
            : _topic,
      ],
      classLevel: _grade,
      durationDays: _parseDuration(_duration),
      dailyStudyMinutes: _parseTime(_studyTime),
      difficulty: LabDifficulty.values.firstWhere(
        (item) => item.label == _difficulty,
        orElse: () => LabDifficulty.beginner,
      ),
      learningGoal: _goal,
      learningContent: _selectedContent.toList(),
      instructions: _instructionsController.text.trim(),
      preferredLanguage: _preferredLanguage.toLowerCase(),
      numberOfLessons: int.tryParse(_lessonCount) ?? 4,
    );

    try {
      final generated = await const CustomLabAiService().generateLab(
        config: customConfig,
      );
      final saved = generated.copyWith(
        id:
            generated.id ??
            'custom-ai-${DateTime.now().microsecondsSinceEpoch}',
        title: generated.title.isEmpty
            ? (customConfig.labName ?? customConfig.effectiveTopic)
            : generated.title,
        customLabConfig: generated.customLabConfig ?? customConfig,
      );
      await CustomLabService.instance.saveGeneratedLab(saved);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _CustomLabPreviewScreen(labId: saved.id!),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is CustomLabAiException
          ? error.message
          : 'AI lab generation failed. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _createLab() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isGenerating = true);
    final customConfig = CustomLabConfig(
      labName: _nameController.text.trim(),
      subject: _subject,
      category: LabCategory.other,
      topic: _topicController.text.trim().isNotEmpty
          ? _topicController.text.trim()
          : _topic,
      topics: <String>[
        _topicController.text.trim().isNotEmpty
            ? _topicController.text.trim()
            : _topic,
      ],
      classLevel: _grade,
      durationDays: _parseDuration(_duration),
      dailyStudyMinutes: _parseTime(_studyTime),
      difficulty: LabDifficulty.values.firstWhere(
        (item) => item.label == _difficulty,
        orElse: () => LabDifficulty.beginner,
      ),
      learningGoal: _goal,
      learningContent: _selectedContent.toList(),
      instructions: _instructionsController.text.trim(),
      preferredLanguage: _preferredLanguage.toLowerCase(),
      numberOfLessons: int.tryParse(_lessonCount) ?? 4,
    );

    try {
      final lab = await CustomLabService.instance.createCustomLab(customConfig);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _CustomLabPreviewScreen(labId: lab.id!),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create your lab right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  int _parseDuration(String value) {
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(digits ?? '7') ?? 7;
  }

  int _parseTime(String value) {
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(digits ?? '30') ?? 30;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Custom Lab'), centerTitle: true),
      body: LabPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Plan a custom learning lab',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildField(
              'Lab Name',
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Cell Biology Revision Lab',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSelect('Subject', _subject, _subjectOptions, (value) {
              setState(() => _subject = value ?? _subject);
            }),
            const SizedBox(height: 20),
            _buildField(
              'Topic',
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  hintText: 'Type your own topic or choose a suggestion',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedTopics.map((topic) {
                final selected =
                    (_topicController.text.trim().isEmpty && _topic == topic) ||
                    (_topicController.text.trim() == topic);
                return ChoiceChip(
                  label: Text(topic),
                  selected: selected,
                  onSelected: (_) {
                    _topicController.text = topic;
                    _topic = topic;
                    setState(() {});
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _buildSelect('Class/Grade', _grade, _gradeOptions, (value) {
              setState(() => _grade = value ?? _grade);
            }),
            const SizedBox(height: 20),
            _buildSelect('Difficulty', _difficulty, _difficultyOptions, (
              value,
            ) {
              setState(() => _difficulty = value ?? _difficulty);
            }),
            const SizedBox(height: 20),
            _buildSelect('Learning Goal', _goal, _goalOptions, (value) {
              setState(() => _goal = value ?? _goal);
            }),
            const SizedBox(height: 20),
            _buildSelect('Duration', _duration, _durationOptions, (value) {
              setState(() => _duration = value ?? _duration);
            }),
            const SizedBox(height: 20),
            _buildSelect(
              'Number of Lessons',
              _lessonCount,
              _lessonCountOptions,
              (value) {
                setState(() => _lessonCount = value ?? _lessonCount);
              },
            ),
            const SizedBox(height: 20),
            _buildSelect(
              'Preferred Language',
              _preferredLanguage,
              _languageOptions,
              (value) {
                setState(
                  () => _preferredLanguage = value ?? _preferredLanguage,
                );
              },
            ),
            const SizedBox(height: 20),
            _buildSelect('Daily Study Time', _studyTime, _studyTimeOptions, (
              value,
            ) {
              setState(() => _studyTime = value ?? _studyTime);
            }),
            const SizedBox(height: 20),
            Text(
              'Learning Content',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _contentOptions.map((content) {
                final selected = _selectedContent.contains(content);
                return FilterChip(
                  label: Text(content),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedContent.remove(content);
                      } else {
                        _selectedContent.add(content);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _buildField(
              'Optional learning instructions',
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Add anything that will help the student study better.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isGenerating ? null : _generateAiLab,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isGenerating ? 'Generating...' : 'Generate with AI',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _createLab,
                icon: const Icon(Icons.create),
                label: const Text('Create Lab Manually'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildSelect(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: options.map((option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CustomLabPreviewScreen extends StatefulWidget {
  const _CustomLabPreviewScreen({required this.labId});

  final String labId;

  @override
  State<_CustomLabPreviewScreen> createState() =>
      _CustomLabPreviewScreenState();
}

class _CustomLabPreviewScreenState extends State<_CustomLabPreviewScreen> {
  final CustomLabService _service = CustomLabService.instance;

  @override
  Widget build(BuildContext context) {
    final lab = _service.byId(widget.labId);
    if (lab == null) {
      return const Scaffold(body: Center(child: Text('Lab not found.')));
    }
    final config = lab.customLabConfig!;
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Preview'), centerTitle: true),
      body: LabPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
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
                    lab.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${config.subject} • ${config.effectiveTopic} • ${config.classLevel}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Preview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _infoRow('Subject', config.subject ?? 'General Science'),
            _infoRow('Topic', config.effectiveTopic),
            _infoRow('Grade', config.classLevel ?? 'Class 10'),
            _infoRow('Difficulty', config.difficulty?.label ?? 'Beginner'),
            _infoRow('Goal', config.learningGoal ?? 'Understand concepts'),
            _infoRow('Duration', '${config.durationDays ?? 7} days'),
            _infoRow(
              'Daily study time',
              '${config.dailyStudyMinutes ?? 30} minutes',
            ),
            const SizedBox(height: 18),
            Text(
              'Learning objectives',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...lab.lessons
                .take(3)
                .map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(lesson.title)),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => _CustomLabDetailScreen(labId: lab.id!),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Create and Open Lab'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

class _CustomLabDetailScreen extends StatefulWidget {
  const _CustomLabDetailScreen({required this.labId});

  final String labId;

  @override
  State<_CustomLabDetailScreen> createState() => _CustomLabDetailScreenState();
}

class _CustomLabDetailScreenState extends State<_CustomLabDetailScreen> {
  final CustomLabService _service = CustomLabService.instance;

  @override
  Widget build(BuildContext context) {
    final lab = _service.byId(widget.labId);
    if (lab == null) {
      return const Scaffold(
        body: Center(child: Text('This custom lab is no longer available.')),
      );
    }
    final progress = lab.progress;
    return Scaffold(
      appBar: AppBar(title: Text(lab.title), centerTitle: true),
      body: LabPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(lab.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            LabProgressBar(percent: progress, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Learning objectives',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...lab.lessons.map(
              (lesson) => ListTile(
                title: Text(lesson.title),
                subtitle: Text(lesson.content.split('\n').first),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          LabLessonScreen(labId: lab.id, lessonId: lesson.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (lab.quizQuestions.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LabQuizScreen(labId: lab.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.quiz_rounded),
                  label: const Text('Start Quiz'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
