import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lab_model.dart';
import '../services/mission_service.dart';
import 'auth_service.dart';

class CustomLabService extends ChangeNotifier {
  CustomLabService._internal();

  static final CustomLabService instance = CustomLabService._internal();

  static const String _storageKeyPrefix = 'studynova.custom_labs.';

  final Map<String, LabModel> _labs = <String, LabModel>{};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  String? get _currentUserId {
    try {
      return AuthService().currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  List<LabModel> get customLabs {
    final userId = _currentUserId;
    final labs = _labs.values
        .where(
          (lab) => userId == null
              ? lab.userId == null || lab.userId!.isEmpty
              : lab.userId == userId,
        )
        .toList();
    labs.sort((a, b) {
      final aTime =
          a.lastStudiedAt ??
          a.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.lastStudiedAt ??
          b.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return List<LabModel>.unmodifiable(labs);
  }

  LabModel? byId(String? labId) {
    if (labId == null || labId.isEmpty) return null;
    final lab = _labs[labId];
    if (lab == null) return null;
    final userId = _currentUserId;
    if (userId == null) {
      return lab.userId == null || lab.userId!.isEmpty ? lab : null;
    }
    return lab.userId == userId ? lab : null;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = _storageScope();
      final raw = prefs.getString('$_storageKeyPrefix$scope');
      if (raw == null || raw.trim().isEmpty) {
        _isLoaded = true;
        notifyListeners();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _isLoaded = true;
        notifyListeners();
        return;
      }
      final next = <String, LabModel>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final lab = LabModel.fromJson(Map<String, dynamic>.from(item));
          if (lab.id == null || lab.id!.isEmpty) continue;
          next[lab.id!] = lab;
        } catch (_) {
          // Skip malformed custom labs instead of crashing the whole library.
        }
      }
      _labs
        ..clear()
        ..addAll(next);
    } catch (error) {
      debugPrint('CustomLabService: could not read saved custom labs ($error)');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<LabModel> createCustomLab(CustomLabConfig config) async {
    final cleaned = _normalizeConfig(config);
    final labId = _newLabId();
    final now = DateTime.now();
    final subjectValue =
        (cleaned.subject ?? cleaned.category?.label ?? 'General Science')
            .trim();
    final lab = LabModel(
      id: labId,
      title: (cleaned.labName ?? '${cleaned.effectiveTopic} Lab').trim().isEmpty
          ? '${cleaned.effectiveTopic} Lab'
          : (cleaned.labName ?? '${cleaned.effectiveTopic} Lab').trim(),
      category: _categoryForSubject(subjectValue),
      description: _buildDescription(cleaned),
      difficulty: cleaned.difficulty ?? LabDifficulty.beginner,
      lessons: _buildLessons(cleaned),
      quizQuestions: _buildQuizQuestions(cleaned),
      isCustomLab: true,
      customLabConfig: cleaned,
      createdAt: now,
      userId: _currentUserId,
      lastStudiedAt: now,
    );

    _labs[lab.id!] = lab;
    notifyListeners();
    await _persist();
    return lab;
  }

  Future<void> saveGeneratedLab(LabModel lab) async {
    if (lab.id == null || lab.id!.isEmpty) return;
    final next = lab.copyWith(
      isCustomLab: true,
      userId: lab.userId ?? _currentUserId,
      createdAt: lab.createdAt ?? DateTime.now(),
      lastStudiedAt: lab.lastStudiedAt ?? DateTime.now(),
    );
    _labs[next.id!] = next;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteCustomLab(String? labId) async {
    if (labId == null || labId.isEmpty || !_labs.containsKey(labId)) return;
    _labs.remove(labId);
    final missions = MissionService.instance.missions
        .where((mission) => mission.customLabId == labId)
        .toList();
    for (final mission in missions) {
      await MissionService.instance.deleteMission(mission.id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> saveLabProgress(LabModel lab) async {
    if (lab.id == null || lab.id!.isEmpty) return;
    final updated = lab.copyWith(lastStudiedAt: DateTime.now());
    _labs[lab.id!] = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> reset() async {
    _labs.clear();
    _isLoaded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final scope = _storageScope();
    await prefs.remove('$_storageKeyPrefix$scope');
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = _storageScope();
      final payload = customLabs.map((lab) => lab.toJson()).toList();
      await prefs.setString('$_storageKeyPrefix$scope', jsonEncode(payload));
    } catch (error) {
      debugPrint('CustomLabService: could not persist custom labs ($error)');
    }
  }

  String _storageScope() {
    return AuthService().currentUser?.id ?? 'guest';
  }

  static String _newLabId() =>
      'custom-lab-${DateTime.now().microsecondsSinceEpoch}';

  CustomLabConfig _normalizeConfig(CustomLabConfig config) {
    final topic = (config.topic ?? config.effectiveTopic).trim();
    final subject =
        (config.subject ?? config.category?.label ?? 'General Science').trim();
    final learningContent = config.learningContent.isNotEmpty
        ? config.learningContent
              .map((entry) => entry.trim())
              .where((entry) => entry.isNotEmpty)
              .toList()
        : const <String>['Short explanations', 'Practice questions'];
    return config.copyWith(
      labName: (config.labName ?? '$topic Lab').trim(),
      subject: subject,
      topic: topic,
      topics: config.topics.isEmpty ? <String>[topic] : config.topics,
      learningContent: learningContent,
      instructions: (config.instructions ?? '').trim(),
    );
  }

  String _buildDescription(CustomLabConfig config) {
    final goal = (config.learningGoal ?? 'Understand concepts').trim();
    final duration = config.durationDays ?? 7;
    final study = config.dailyStudyMinutes ?? 30;
    final classLevel = config.classLevel ?? 'Class 10';
    return '$goal • $classLevel • $duration-day plan • $study min/day';
  }

  List<LabLesson> _buildLessons(CustomLabConfig config) {
    final topic = config.effectiveTopic;
    final list = <LabLesson>[];
    final lessonCount = (config.durationDays ?? 7).clamp(3, 8);
    final sections = <String>[
      'Introduction to $topic',
      'Key ideas and concepts',
      'Examples and applications',
      'Practice and review',
      'Revision and consolidation',
      'Final check and reflection',
    ];

    for (var i = 0; i < lessonCount; i++) {
      final section = i < sections.length
          ? sections[i]
          : 'Review lesson ${i + 1}';
      final explanation = _lessonBody(topic, section, config);
      list.add(
        LabLesson(
          id: 'custom-lesson-${i + 1}',
          title: section,
          content: explanation,
          keyPoints: _keyPoints(topic, section),
          order: i,
          durationMinutes: (config.dailyStudyMinutes ?? 30).clamp(10, 60),
        ),
      );
    }
    return list;
  }

  String _lessonBody(String topic, String section, CustomLabConfig config) {
    final goal = (config.learningGoal ?? 'Understand concepts').trim();
    final difficulty = (config.difficulty ?? LabDifficulty.beginner).label;
    return 'This lesson focuses on $topic in a ${difficulty.toLowerCase()} way. '
        'The goal is to $goal.\n\n'
        'Start by understanding the main idea of $section. Then look at a few everyday examples and try to explain the concept in your own words.\n\n'
        'When you finish, check the key points and answer the short practice questions. '
        'This helps you remember what matters and build confidence with the topic.';
  }

  List<String> _keyPoints(String topic, String section) {
    return <String>[
      'Understand the main idea of $topic.',
      'Use $section to connect the theory to real learning.',
      'Review examples before moving to practice questions.',
    ];
  }

  List<QuizQuestion> _buildQuizQuestions(CustomLabConfig config) {
    final topic = config.effectiveTopic;
    return <QuizQuestion>[
      QuizQuestion(
        id: 'custom-q-1',
        question: 'What is the main focus of this lab on $topic?',
        options: const <String>[
          'To learn the key concept clearly',
          'To skip explanations',
          'To avoid examples',
          'To replace revision',
        ],
        correctAnswer: 'To learn the key concept clearly',
        explanation:
            'A strong lab starts with a clear idea, examples, and practice so the topic becomes easier to remember.',
        type: 'multiple_choice',
      ),
      QuizQuestion(
        id: 'custom-q-2',
        question: 'Why is practicing questions helpful for $topic?',
        options: const <String>[
          'It makes the topic harder',
          'It checks understanding and builds confidence',
          'It skips the lesson',
          'It replaces revision',
        ],
        correctAnswer: 'It checks understanding and builds confidence',
        explanation:
            'Practice questions show what is clear and what still needs revision.',
        type: 'multiple_choice',
      ),
      QuizQuestion(
        id: 'custom-q-3',
        question: 'What is best after learning a new topic?',
        options: const <String>[
          'Ignore it',
          'Revise the key points and try a quick quiz',
          'Forget all examples',
          'Stop studying',
        ],
        correctAnswer: 'Revise the key points and try a quick quiz',
        explanation:
            'Reviewing helps the ideas stay in memory and makes the next practice easier.',
        type: 'multiple_choice',
      ),
    ];
  }

  LabCategory _categoryForSubject(String subject) {
    final normalized = subject.toLowerCase();
    if (normalized.contains('science')) return LabCategory.gsc;
    if (normalized.contains('knowledge')) return LabCategory.gk;
    if (normalized.contains('social') ||
        normalized.contains('history') ||
        normalized.contains('geography')) {
      return LabCategory.sst;
    }
    return LabCategory.other;
  }
}
