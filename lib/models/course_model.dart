/// Domain model for a Study Nova course created with the Course Maker.
///
/// JSON keys use snake_case so the model maps directly onto the Supabase
/// tables used by CourseService (see `sql/courses.sql`).
library;

/// The kind of learning the course is meant for.
enum CourseType {
  school('School', 'school'),
  competitiveExam('Competitive Exam', 'competitive_exam'),
  generalLearning('General Learning', 'general_learning');

  const CourseType(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static CourseType fromStorage(String? value) {
    for (final type in CourseType.values) {
      if (type.storageValue == value) return type;
    }
    return CourseType.generalLearning;
  }
}

/// How detailed the generated course should be.
enum CourseLength {
  short('Short', 'short'),
  medium('Medium', 'medium'),
  detailed('Detailed', 'detailed');

  const CourseLength(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static CourseLength fromStorage(String? value) {
    for (final length in CourseLength.values) {
      if (length.storageValue == value) return length;
    }
    return CourseLength.medium;
  }
}

/// Difficulty level of the generated course.
enum CourseDifficulty {
  beginner('Beginner', 'beginner'),
  intermediate('Intermediate', 'intermediate'),
  advanced('Advanced', 'advanced');

  const CourseDifficulty(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static CourseDifficulty fromStorage(String? value) {
    for (final difficulty in CourseDifficulty.values) {
      if (difficulty.storageValue == value) return difficulty;
    }
    return CourseDifficulty.beginner;
  }
}

/// Languages the Course Maker can generate the course in.
enum CourseLanguage {
  english('English', 'en'),
  hindi('Hindi', 'hi'),
  hinglish('Hinglish', 'hinglish'),
  other('Other', 'other');

  const CourseLanguage(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static CourseLanguage fromStorage(String? value) {
    for (final language in CourseLanguage.values) {
      if (language.storageValue == value) return language;
    }
    return CourseLanguage.english;
  }
}

/// A course the student is creating (draft) or has already saved.
///
/// Inside the Course Maker wizard the course has no [id]/[userId] yet; it is
/// the draft that is carried from step to step.
class CourseModel {
  const CourseModel({
    this.id,
    this.userId,
    required this.title,
    this.courseType = CourseType.generalLearning,
    this.classLevel,
    this.subject,
    this.examTarget,
    this.length = CourseLength.medium,
    this.difficulty = CourseDifficulty.beginner,
    this.language = CourseLanguage.english,
    this.learningGoal,
    this.description = '',
    this.chapterCount = 0,
    this.topicCount = 0,
    this.progress = 0,
    this.createdAt,
    this.updatedAt,
    this.lastStudiedAt,
  });

  final String? id;
  final String? userId;
  final String title;
  final CourseType courseType;

  /// School only, e.g. "Class 10".
  final String? classLevel;

  /// e.g. "Science".
  final String? subject;

  /// Competitive exam only, e.g. "NEET".
  final String? examTarget;

  final CourseLength length;
  final CourseDifficulty difficulty;
  final CourseLanguage language;

  /// Optional learning goal written by the student.
  final String? learningGoal;

  final String description;

  /// Number of chapters generated for this course.
  final int chapterCount;

  /// Number of topics generated for this course.
  final int topicCount;

  /// Completion percentage (0-100).
  final int progress;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastStudiedAt;

  /// Completion as a 0.0-1.0 fraction, for progress indicators.
  double get progressFraction => progress.clamp(0, 100) / 100;

  /// One-line summary for course cards, e.g. "School • Class 10 • Science".
  String get subtitle {
    final parts = <String>[
      courseType.label,
      if ((classLevel ?? '').trim().isNotEmpty) classLevel!.trim(),
      if ((examTarget ?? '').trim().isNotEmpty) examTarget!.trim(),
      if ((subject ?? '').trim().isNotEmpty) subject!.trim(),
    ];
    return parts.join(' • ');
  }

  CourseModel copyWith({
    String? id,
    String? userId,
    String? title,
    CourseType? courseType,
    String? classLevel,
    String? subject,
    String? examTarget,
    CourseLength? length,
    CourseDifficulty? difficulty,
    CourseLanguage? language,
    String? learningGoal,
    String? description,
    int? chapterCount,
    int? topicCount,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastStudiedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      courseType: courseType ?? this.courseType,
      classLevel: classLevel ?? this.classLevel,
      subject: subject ?? this.subject,
      examTarget: examTarget ?? this.examTarget,
      length: length ?? this.length,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      learningGoal: learningGoal ?? this.learningGoal,
      description: description ?? this.description,
      chapterCount: chapterCount ?? this.chapterCount,
      topicCount: topicCount ?? this.topicCount,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      courseType: CourseType.fromStorage(json['course_type']?.toString()),
      classLevel: json['class_level']?.toString(),
      subject: json['subject']?.toString(),
      examTarget: json['exam_target']?.toString(),
      length: CourseLength.fromStorage(json['length']?.toString()),
      difficulty: CourseDifficulty.fromStorage(json['difficulty']?.toString()),
      language: CourseLanguage.fromStorage(json['language']?.toString()),
      learningGoal: json['learning_goal']?.toString(),
      description: (json['description'] ?? '').toString(),
      chapterCount: _asInt(json['chapter_count']),
      topicCount: _asInt(json['topic_count']),
      progress: _asInt(json['progress']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      lastStudiedAt: _asDate(json['last_studied_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'course_type': courseType.storageValue,
      'class_level': classLevel,
      'subject': subject,
      'exam_target': examTarget,
      'length': length.storageValue,
      'difficulty': difficulty.storageValue,
      'language': language.storageValue,
      'learning_goal': learningGoal,
      'description': description,
      'chapter_count': chapterCount,
      'topic_count': topicCount,
      'progress': progress,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'last_studied_at': lastStudiedAt?.toUtc().toIso8601String(),
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
