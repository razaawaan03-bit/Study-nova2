library;

import 'study_scan_model.dart';

// Re-exported so Lab content files only need to import lab_model.dart.
// CustomLabConfig is defined locally in this file, so it is not re-exported.
export 'study_scan_model.dart' show QuizQuestion;

/// One lesson inside a Study Nova Lab.
class LabLesson {
  const LabLesson({
    this.id,
    required this.title,
    this.content = '',
    this.keyPoints = const <String>[],
    this.order = 0,
    this.durationMinutes = 0,
    this.isCompleted = false,
  });

  final String? id;
  final String title;
  final String content;

  /// Short, memorable takeaways shown in the "Key Points" block.
  final List<String> keyPoints;
  final int order;
  final int durationMinutes;
  final bool isCompleted;

  LabLesson copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? keyPoints,
    int? order,
    int? durationMinutes,
    bool? isCompleted,
  }) {
    return LabLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      keyPoints: keyPoints ?? this.keyPoints,
      order: order ?? this.order,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory LabLesson.fromJson(Map<String, dynamic> json) {
    return LabLesson(
      id: json['id']?.toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      keyPoints: _asStringList(json['key_points']),
      order: _asInt(json['order_index'] ?? json['order']),
      durationMinutes: _asInt(json['duration_minutes']),
      isCompleted: _asBool(json['is_completed']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'key_points': keyPoints,
    'order_index': order,
    'order': order,
    'duration_minutes': durationMinutes,
    'is_completed': isCompleted,
  };
}

/// The user-chosen configuration of a custom ("Build your own") Lab.
class CustomLabConfig {
  const CustomLabConfig({
    this.labName,
    this.subject,
    this.category,
    this.topic,
    this.topics = const <String>[],
    this.classLevel,
    this.durationDays,
    this.dailyStudyMinutes,
    this.difficulty,
    this.learningGoal,
    this.learningContent = const <String>[],
    this.instructions = '',
    this.preferredLanguage,
    this.numberOfLessons,
  });

  final String? labName;
  final String? subject;
  final LabCategory? category;
  final String? topic;
  final List<String> topics;
  final String? classLevel;
  final int? durationDays;
  final int? dailyStudyMinutes;
  final LabDifficulty? difficulty;
  final String? learningGoal;
  final List<String> learningContent;
  final String? instructions;
  final String? preferredLanguage;
  final int? numberOfLessons;

  String get effectiveTopic => topic?.trim().isNotEmpty == true
      ? topic!.trim()
      : (topics.isNotEmpty ? topics.first.trim() : 'General study');

  CustomLabConfig copyWith({
    String? labName,
    String? subject,
    LabCategory? category,
    String? topic,
    List<String>? topics,
    String? classLevel,
    int? durationDays,
    int? dailyStudyMinutes,
    LabDifficulty? difficulty,
    String? learningGoal,
    List<String>? learningContent,
    String? instructions,
    String? preferredLanguage,
    int? numberOfLessons,
  }) {
    return CustomLabConfig(
      labName: labName ?? this.labName,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      topic: topic ?? this.topic,
      topics: topics ?? this.topics,
      classLevel: classLevel ?? this.classLevel,
      durationDays: durationDays ?? this.durationDays,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      difficulty: difficulty ?? this.difficulty,
      learningGoal: learningGoal ?? this.learningGoal,
      learningContent: learningContent ?? this.learningContent,
      instructions: instructions ?? this.instructions,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      numberOfLessons: numberOfLessons ?? this.numberOfLessons,
    );
  }

  factory CustomLabConfig.fromJson(Map<String, dynamic> json) {
    return CustomLabConfig(
      labName: json['lab_name']?.toString(),
      subject: json['subject']?.toString(),
      category: json['category'] == null
          ? null
          : LabCategory.fromStorage(json['category'].toString()),
      topic: json['topic']?.toString(),
      topics: _asStringList(json['topics']),
      classLevel: json['class_level']?.toString(),
      durationDays: json['duration_days'] == null
          ? null
          : _asInt(json['duration_days']),
      dailyStudyMinutes: json['daily_study_minutes'] == null
          ? null
          : _asInt(json['daily_study_minutes']),
      difficulty: json['difficulty'] == null
          ? null
          : LabDifficulty.fromStorage(json['difficulty'].toString()),
      learningGoal: json['learning_goal']?.toString(),
      learningContent: _asStringList(json['learning_content']),
      instructions: json['instructions']?.toString(),
      preferredLanguage: json['preferred_language']?.toString(),
      numberOfLessons: json['number_of_lessons'] == null
          ? null
          : _asInt(json['number_of_lessons']),
    );
  }

  Map<String, dynamic> toJson() => {
    'lab_name': labName,
    'subject': subject,
    'category': category?.storageValue,
    'topic': topic,
    'topics': topics,
    'class_level': classLevel,
    'duration_days': durationDays,
    'daily_study_minutes': dailyStudyMinutes,
    'difficulty': difficulty?.storageValue,
    'learning_goal': learningGoal,
    'learning_content': learningContent,
    'instructions': instructions,
    'preferred_language': preferredLanguage,
    'number_of_lessons': numberOfLessons,
  };
}

/// A user's progress through a single Lab. Persisted per (user, lab).
class LabProgress {
  const LabProgress({
    required this.labId,
    this.userId,
    this.lastLessonId,
    this.lastLessonIndex = 0,
    this.completedLessonIds = const <String>[],
    this.progressPercent = 0,
    this.isCompleted = false,
    this.updatedAt,
  });

  final String labId;
  final String? userId;
  final String? lastLessonId;
  final int lastLessonIndex;
  final List<String> completedLessonIds;

  /// 0-100 overall Lab progress.
  final int progressPercent;
  final bool isCompleted;
  final DateTime? updatedAt;

  bool isLessonCompleted(String? lessonId) {
    if (lessonId == null || lessonId.isEmpty) return false;
    return completedLessonIds.contains(lessonId);
  }

  LabProgress copyWith({
    String? labId,
    String? userId,
    String? lastLessonId,
    int? lastLessonIndex,
    List<String>? completedLessonIds,
    int? progressPercent,
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return LabProgress(
      labId: labId ?? this.labId,
      userId: userId ?? this.userId,
      lastLessonId: lastLessonId ?? this.lastLessonId,
      lastLessonIndex: lastLessonIndex ?? this.lastLessonIndex,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      progressPercent: progressPercent ?? this.progressPercent,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LabProgress.fromJson(Map<String, dynamic> json) {
    return LabProgress(
      labId: (json['lab_id'] ?? '').toString(),
      userId: json['user_id']?.toString(),
      lastLessonId: json['last_lesson_id']?.toString(),
      lastLessonIndex: _asInt(json['last_lesson_index']),
      completedLessonIds: _asStringList(json['completed_lesson_ids']),
      progressPercent: _asInt(json['progress_percent'] ?? json['progress']),
      isCompleted: _asBool(json['is_completed']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'lab_id': labId,
    'user_id': userId,
    'last_lesson_id': lastLessonId,
    'last_lesson_index': lastLessonIndex,
    'completed_lesson_ids': completedLessonIds,
    'progress_percent': progressPercent,
    'progress': progressPercent,
    'is_completed': isCompleted,
    'updated_at': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

/// One completed run of a Lab quiz.
class QuizAttempt {
  const QuizAttempt({
    this.id,
    required this.labId,
    this.userId,
    required this.score,
    required this.totalQuestions,
    this.attemptedAt,
  });

  final String? id;
  final String labId;
  final String? userId;
  final int score;
  final int totalQuestions;
  final DateTime? attemptedAt;

  /// Score as a percentage, 0-100.
  int get percentage =>
      totalQuestions <= 0 ? 0 : ((score / totalQuestions) * 100).round();

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id']?.toString(),
      labId: (json['lab_id'] ?? '').toString(),
      userId: json['user_id']?.toString(),
      score: _asInt(json['score']),
      totalQuestions: _asInt(json['total_questions']),
      attemptedAt: _asDate(json['attempted_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lab_id': labId,
    'user_id': userId,
    'score': score,
    'total_questions': totalQuestions,
    'attempted_at': (attemptedAt ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

/// Aggregated quiz statistics for one Lab.
class LabQuizStats {
  const LabQuizStats({
    this.attemptCount = 0,
    this.bestScore = 0,
    this.bestPercentage = 0,
  });

  final int attemptCount;
  final int bestScore;
  final int bestPercentage;

  factory LabQuizStats.fromAttempts(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) return const LabQuizStats();
    var best = attempts.first;
    for (final attempt in attempts) {
      if (attempt.percentage > best.percentage) best = attempt;
    }
    return LabQuizStats(
      attemptCount: attempts.length,
      bestScore: best.score,
      bestPercentage: best.percentage,
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Reads a boolean that may arrive as true/false, 1/0 or "true"/"false".
bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return false;
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Maps a JSON list of objects to models, skipping anything malformed.
List<T> _asModelList<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return <T>[];
  final result = <T>[];
  for (final item in value) {
    if (item is Map) {
      result.add(parse(Map<String, dynamic>.from(item)));
    }
  }
  return result;
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const <String>[];
}

enum LabCategory {
  gsc('GSC', 'gsc'),
  gk('GK', 'gk'),
  sst('SST', 'sst'),
  other('Other', 'other');

  const LabCategory(this.label, this.storageValue);
  final String label;
  final String storageValue;

  static LabCategory fromStorage(String? value) {
    for (final c in values) {
      if (c.storageValue == value) return c;
    }
    return LabCategory.other;
  }
}

enum LabTopic {
  gscCirculatory(
    'Circulatory System',
    'gsc-circulatory-system',
    LabCategory.gsc,
  ),
  gscFundamentals('Fundamentals', 'gsc-fundamentals', LabCategory.gsc),
  gkFundamentals('Fundamentals', 'gk-fundamentals', LabCategory.gk),
  gkCurrentAffairs('Current Affairs', 'gk-current-affairs', LabCategory.gk),
  sstFundamentals('Fundamentals', 'sst-fundamentals', LabCategory.sst),
  sstHistory('History', 'sst-history', LabCategory.sst);

  const LabTopic(this.label, this.slug, this.category);
  final String label;
  final String slug;
  final LabCategory category;
}

enum LabDifficulty {
  beginner('Beginner', 'beginner'),
  intermediate('Intermediate', 'intermediate'),
  advanced('Advanced', 'advanced');

  const LabDifficulty(this.label, this.storageValue);
  final String label;
  final String storageValue;

  static LabDifficulty fromStorage(String? value) {
    for (final d in values) {
      if (d.storageValue == value) return d;
    }
    return LabDifficulty.beginner;
  }
}

enum LearningGoal {
  learnFundamentals('Learn Fundamentals', 'learn_fundamentals'),
  examPreparation('Exam Preparation', 'exam_preparation'),
  practice('Practice', 'practice'),
  revision('Revision', 'revision');

  const LearningGoal(this.label, this.storageValue);
  final String label;
  final String storageValue;

  static LearningGoal fromStorage(String? value) {
    for (final g in values) {
      if (g.storageValue == value) return g;
    }
    return LearningGoal.learnFundamentals;
  }
}

enum CourseLengthOption {
  days7('7 Days', '7_days'),
  days14('14 Days', '14_days'),
  days30('30 Days', '30_days'),
  custom('Custom', 'custom');

  const CourseLengthOption(this.label, this.storageValue);
  final String label;
  final String storageValue;

  static CourseLengthOption fromStorage(String? value) {
    for (final o in values) {
      if (o.storageValue == value) return o;
    }
    return CourseLengthOption.days7;
  }
}

enum LearningPreference {
  lessons('Lessons', 'lessons'),
  quizzes('Quizzes', 'quizzes'),
  practiceQuestions('Practice Questions', 'practice_questions'),
  mindMaps('Mind Maps', 'mind_maps'),
  notes('Notes', 'notes');

  const LearningPreference(this.label, this.storageValue);
  final String label;
  final String storageValue;

  static List<LearningPreference> fromStringList(List<String> values) {
    final result = <LearningPreference>[];
    for (final value in values) {
      for (final pref in LearningPreference.values) {
        if (pref.storageValue == value) {
          result.add(pref);
          break;
        }
      }
    }
    return result;
  }

  static List<String> toStringList(List<LearningPreference> preferences) {
    return preferences.map((p) => p.storageValue).toList();
  }
}

class LabModel {
  const LabModel({
    this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.difficulty = LabDifficulty.beginner,
    this.lessons = const <LabLesson>[],
    this.quizQuestions = const <QuizQuestion>[],
    this.progress = 0,
    this.isCompleted = false,
    this.isCustomLab = false,
    this.customLabConfig,
    this.createdAt,
    this.userId,
    this.lastStudiedAt,
  });

  final String? id;
  final String title;
  final LabCategory category;
  final String description;
  final LabDifficulty difficulty;
  final List<LabLesson> lessons;
  final List<QuizQuestion> quizQuestions;
  final int progress;
  final bool isCompleted;
  final bool isCustomLab;
  final CustomLabConfig? customLabConfig;
  final DateTime? createdAt;
  final String? userId;
  final DateTime? lastStudiedAt;

  /// Number of lessons marked complete for this Lab.
  int get completedLessonCount =>
      lessons.where((lesson) => lesson.isCompleted).length;

  /// The next lesson the user should study (first incomplete one), or null.
  LabLesson? get nextLesson {
    for (final lesson in lessons) {
      if (!lesson.isCompleted) return lesson;
    }
    return null;
  }

  /// Lessons plus their progress flags, ready for the detail screen.
  List<LabLesson> lessonsWithCompletion(LabProgress? progress) {
    return lessons
        .map(
          (lesson) => lesson.copyWith(
            isCompleted:
                lesson.isCompleted ||
                (progress != null && progress.isLessonCompleted(lesson.id)),
          ),
        )
        .toList();
  }

  LabModel copyWith({
    String? id,
    String? title,
    LabCategory? category,
    String? description,
    LabDifficulty? difficulty,
    List<LabLesson>? lessons,
    List<QuizQuestion>? quizQuestions,
    int? progress,
    bool? isCompleted,
    bool? isCustomLab,
    CustomLabConfig? customLabConfig,
    DateTime? createdAt,
    String? userId,
    DateTime? lastStudiedAt,
  }) {
    return LabModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      lessons: lessons ?? this.lessons,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isCustomLab: isCustomLab ?? this.isCustomLab,
      customLabConfig: customLabConfig ?? this.customLabConfig,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }

  factory LabModel.fromJson(Map<String, dynamic> json) {
    return LabModel(
      id: json['id']?.toString(),
      title: (json['title'] ?? '').toString(),
      category: LabCategory.fromStorage(json['category']?.toString()),
      description: (json['description'] ?? '').toString(),
      difficulty: LabDifficulty.fromStorage(json['difficulty']?.toString()),
      lessons: _asModelList(json['lessons'], LabLesson.fromJson),
      quizQuestions: _asModelList(
        json['quiz_questions'],
        QuizQuestion.fromJson,
      ),
      progress: _asInt(json['progress']),
      isCompleted: _asBool(json['is_completed']),
      isCustomLab: _asBool(json['is_custom_lab']),
      customLabConfig: json['custom_lab_config'] is Map
          ? CustomLabConfig.fromJson(
              Map<String, dynamic>.from(json['custom_lab_config'] as Map),
            )
          : null,
      createdAt: _asDate(json['created_at']),
      userId: json['user_id']?.toString(),
      lastStudiedAt: _asDate(json['last_studied_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.storageValue,
      'description': description,
      'difficulty': difficulty.storageValue,
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'quiz_questions': quizQuestions.map((q) => q.toJson()).toList(),
      'progress': progress,
      'is_completed': isCompleted,
      'is_custom_lab': isCustomLab,
      'custom_lab_config': customLabConfig?.toJson(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'user_id': userId,
      'last_studied_at': lastStudiedAt?.toUtc().toIso8601String(),
    };
  }
}
