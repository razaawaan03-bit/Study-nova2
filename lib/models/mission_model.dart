/// Domain models for Study Nova Mission Mode.
///
/// Mission Mode does not own any learning content. A mission only *points at*
/// existing Study Nova content: courses saved by the student, bundled Study
/// Nova Labs, their lessons and their quiz questions. Ids stored on
/// [MissionTask] are therefore always ids that already exist in
/// `CourseService` / `LabService`.
///
/// JSON keys use snake_case so the models map directly onto the optional
/// Supabase `missions` table (see `sql/missions.sql`). Persistence must never be
/// required: the models are complete on their own and the app falls back to
/// local storage.
library;

import 'package:flutter/material.dart';

import 'lab_model.dart';

enum MissionStatus {
  active('Active', 'active'),
  paused('Paused', 'paused'),
  completed('Completed', 'completed'),
  archived('Archived', 'archived');

  const MissionStatus(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static MissionStatus fromStorage(String? value) {
    for (final status in values) {
      if (status.storageValue == value) return status;
    }
    return MissionStatus.active;
  }
}

/// What the student said they want to achieve.
enum MissionGoal {
  prepareExam('Prepare for an exam', 'prepare_exam'),
  learnSubject('Learn a subject', 'learn_subject'),
  masterTopic('Master a topic', 'master_topic'),
  completeCourse('Complete a course', 'complete_course'),
  improveWeakAreas('Improve weak subjects', 'improve_weak_areas'),
  buildKnowledge('Build knowledge', 'build_knowledge'),
  practiceTest('Practice for a test', 'practice_test');

  const MissionGoal(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static MissionGoal fromStorage(String? value) {
    for (final goal in values) {
      if (goal.storageValue == value) return goal;
    }
    return MissionGoal.learnSubject;
  }
}

/// How the student prefers to learn. Maps onto the existing
/// [LearningPreference] values when a Lab task is generated.
enum MissionPreference {
  reading('Reading', 'reading', <LearningPreference>[
    LearningPreference.lessons,
  ]),
  practice('Practice', 'practice', <LearningPreference>[
    LearningPreference.practiceQuestions,
    LearningPreference.lessons,
  ]),
  quizzes('Quizzes', 'quizzes', <LearningPreference>[
    LearningPreference.quizzes,
  ]),
  visual('Visual learning', 'visual', <LearningPreference>[
    LearningPreference.mindMaps,
  ]),
  mixed('Mixed', 'mixed', <LearningPreference>[
    LearningPreference.lessons,
    LearningPreference.quizzes,
    LearningPreference.practiceQuestions,
  ]);

  const MissionPreference(this.label, this.storageValue, this.labPreferences);

  final String label;
  final String storageValue;

  /// The Study Nova Labs preferences this mission preference implies.
  final List<LearningPreference> labPreferences;

  static MissionPreference fromStorage(String? value) {
    for (final preference in values) {
      if (preference.storageValue == value) return preference;
    }
    return MissionPreference.mixed;
  }
}

/// Optional exam target. It only shapes the plan (more mock tests, more
/// revision) — it never adds exam content of its own.
enum MissionExamTarget {
  none('No specific exam', 'none'),
  schoolExam('School exam', 'school_exam'),
  classExam('Class exam', 'class_exam'),
  neet('NEET', 'neet'),
  jee('JEE', 'jee'),
  upsc('UPSC', 'upsc'),
  general('General', 'general'),
  custom('Other', 'custom');

  const MissionExamTarget(this.label, this.storageValue);

  final String label;
  final String storageValue;

  /// True when the target is a real exam worth practising against.
  bool get isCompetitive =>
      this != MissionExamTarget.none && this != MissionExamTarget.general;

  static MissionExamTarget fromStorage(String? value) {
    for (final target in values) {
      if (target.storageValue == value) return target;
    }
    return MissionExamTarget.none;
  }
}

/// What a mission task actually does. Every value maps to a real Study Nova
/// destination, except [custom] which is a self-study task the student ticks
/// off themselves.
enum MissionTaskType {
  course('Course', 'course', Icons.menu_book),
  lab('Lab', 'lab', Icons.science),
  lesson('Lesson', 'lesson', Icons.auto_stories),
  quiz('Quiz', 'quiz', Icons.quiz_outlined),
  studyFromPhoto('Study From Photo', 'study_from_photo', Icons.photo_camera),
  studyLibrary('Study Library', 'study_library', Icons.bookmark),
  revision('Revision', 'revision', Icons.refresh),
  practice('Practice', 'practice', Icons.edit_note),
  mockTest('Mock Test', 'mock_test', Icons.assignment),
  custom('Custom', 'custom', Icons.flag),
  finalChallenge('Final Challenge', 'final_challenge', Icons.emoji_events);

  const MissionTaskType(this.label, this.storageValue, this.icon);

  final String label;
  final String storageValue;
  final IconData icon;

  /// True when starting the task opens another Study Nova screen.
  bool get opensExistingFeature => this != MissionTaskType.custom;

  static MissionTaskType fromStorage(String? value) {
    for (final type in values) {
      if (type.storageValue == value) return type;
    }
    return MissionTaskType.custom;
  }
}

/// How a milestone is earned.
enum MissionMilestoneType {
  taskCount('Tasks completed', 'task_count'),
  taskTypeCount('A kind of task completed', 'task_type_count'),
  progressReached('Progress reached', 'progress_reached'),
  streakDays('Day streak', 'streak_days'),
  missionCompleted('Mission completed', 'mission_completed');

  const MissionMilestoneType(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static MissionMilestoneType fromStorage(String? value) {
    for (final type in values) {
      if (type.storageValue == value) return type;
    }
    return MissionMilestoneType.taskCount;
  }
}

/// One action inside a mission day.
///
/// [labId], [lessonId] and [courseId] are only set when the matching content
/// already exists in Study Nova. When nothing matched, the task is created as
/// [MissionTaskType.custom] with a clear explanation instead of an invented id.
class MissionTask {
  const MissionTask({
    required this.id,
    required this.missionId,
    required this.dayNumber,
    required this.type,
    required this.title,
    this.description = '',
    this.topic = '',
    this.estimatedMinutes = 10,
    this.isRequired = true,
    this.isCompleted = false,
    this.completedAt,
    this.labId,
    this.lessonId,
    this.courseId,
    this.courseChapterIndex,
    this.order = 0,
  });

  final String id;
  final String missionId;
  final int dayNumber;
  final MissionTaskType type;
  final String title;
  final String description;

  /// The mission topic this task covers, used for the final challenge
  /// breakdown and for revision suggestions.
  final String topic;

  final int estimatedMinutes;

  /// Custom tasks are optional: they never block mission completion.
  final bool isRequired;

  final bool isCompleted;
  final DateTime? completedAt;

  /// Existing Study Nova Lab this task opens, when one matched.
  final String? labId;

  /// Lesson inside [labId], for lesson tasks.
  final String? lessonId;

  /// Saved course this task opens, when the student has one.
  final String? courseId;

  /// Chapter inside the saved course.
  final int? courseChapterIndex;

  final int order;

  bool get hasLab => labId != null && labId!.isNotEmpty;

  bool get hasLesson => lessonId != null && lessonId!.isNotEmpty;

  bool get hasCourse => courseId != null && courseId!.isNotEmpty;

  /// Whether this task can be opened in another Study Nova screen. Custom
  /// tasks are ticked off directly in the mission day screen.
  bool get isActionable => type.opensExistingFeature && (hasLab || hasCourse);

  /// Label for the button that starts the task.
  String get actionLabel {
    switch (type) {
      case MissionTaskType.course:
        return 'Open course';
      case MissionTaskType.lab:
        return 'Open Lab';
      case MissionTaskType.lesson:
        return 'Read lesson';
      case MissionTaskType.quiz:
        return 'Start quiz';
      case MissionTaskType.studyFromPhoto:
        return 'Study From Photo';
      case MissionTaskType.studyLibrary:
        return 'Open Study Library';
      case MissionTaskType.revision:
        return 'Review now';
      case MissionTaskType.practice:
        return 'Start practice';
      case MissionTaskType.mockTest:
        return 'Start mock test';
      case MissionTaskType.custom:
        return 'Mark as done';
      case MissionTaskType.finalChallenge:
        return 'Take Final Challenge';
    }
  }

  MissionTask copyWith({
    String? id,
    String? missionId,
    int? dayNumber,
    MissionTaskType? type,
    String? title,
    String? description,
    String? topic,
    int? estimatedMinutes,
    bool? isRequired,
    bool? isCompleted,
    DateTime? completedAt,
    String? labId,
    String? lessonId,
    String? courseId,
    int? courseChapterIndex,
    int? order,
  }) {
    return MissionTask(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      dayNumber: dayNumber ?? this.dayNumber,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      topic: topic ?? this.topic,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isRequired: isRequired ?? this.isRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      labId: labId ?? this.labId,
      lessonId: lessonId ?? this.lessonId,
      courseId: courseId ?? this.courseId,
      courseChapterIndex: courseChapterIndex ?? this.courseChapterIndex,
      order: order ?? this.order,
    );
  }

  factory MissionTask.fromJson(Map<String, dynamic> json) {
    return MissionTask(
      id: (json['id'] ?? '').toString(),
      missionId: (json['mission_id'] ?? '').toString(),
      dayNumber: _asInt(json['day_number']),
      type: MissionTaskType.fromStorage(json['type']?.toString()),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      estimatedMinutes: _asInt(json['estimated_minutes']),
      isRequired: json['is_required'] == null
          ? true
          : _asBool(json['is_required']),
      isCompleted: _asBool(json['is_completed']),
      completedAt: _asDate(json['completed_at']),
      labId: _nullableString(json['lab_id']),
      lessonId: _nullableString(json['lesson_id']),
      courseId: _nullableString(json['course_id']),
      courseChapterIndex: json['course_chapter_index'] == null
          ? null
          : _asInt(json['course_chapter_index']),
      order: _asInt(json['order']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mission_id': missionId,
    'day_number': dayNumber,
    'type': type.storageValue,
    'title': title,
    'description': description,
    'topic': topic,
    'estimated_minutes': estimatedMinutes,
    'is_required': isRequired,
    'is_completed': isCompleted,
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'lab_id': labId,
    'lesson_id': lessonId,
    'course_id': courseId,
    'course_chapter_index': courseChapterIndex,
    'order': order,
  };
}

/// One day of a mission: a small set of tasks that fit the student's daily
/// study time.
class MissionDay {
  const MissionDay({
    required this.dayNumber,
    required this.title,
    this.focusTopic = '',
    this.tasks = const <MissionTask>[],
    this.estimatedMinutes = 0,
  });

  /// 1-based day number.
  final int dayNumber;

  final String title;
  final String focusTopic;
  final List<MissionTask> tasks;

  /// Planned study minutes, derived from the tasks when not supplied.
  final int estimatedMinutes;

  int get totalTasks => tasks.length;

  int get completedTasks => tasks.where((task) => task.isCompleted).length;

  int get requiredTasks => tasks.where((task) => task.isRequired).length;

  int get completedRequiredTasks =>
      tasks.where((task) => task.isRequired && task.isCompleted).length;

  bool get isComplete =>
      requiredTasks > 0 && completedRequiredTasks == requiredTasks;

  bool get isStarted => completedTasks > 0;

  /// 0-100 for this day.
  int get progressPercent => requiredTasks <= 0
      ? 0
      : ((completedRequiredTasks / requiredTasks) * 100).round().clamp(0, 100);

  MissionDay copyWith({
    int? dayNumber,
    String? title,
    String? focusTopic,
    List<MissionTask>? tasks,
    int? estimatedMinutes,
  }) {
    return MissionDay(
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      focusTopic: focusTopic ?? this.focusTopic,
      tasks: tasks ?? this.tasks,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  factory MissionDay.fromJson(Map<String, dynamic> json) {
    final tasks = <MissionTask>[];
    final rawTasks = json['tasks'];
    if (rawTasks is List) {
      for (final item in rawTasks) {
        if (item is Map) {
          tasks.add(MissionTask.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return MissionDay(
      dayNumber: _asInt(json['day_number']),
      title: (json['title'] ?? '').toString(),
      focusTopic: (json['focus_topic'] ?? '').toString(),
      tasks: tasks,
      estimatedMinutes: _asInt(json['estimated_minutes']),
    );
  }

  Map<String, dynamic> toJson() => {
    'day_number': dayNumber,
    'title': title,
    'focus_topic': focusTopic,
    'estimated_minutes': estimatedMinutes,
    'tasks': tasks.map((task) => task.toJson()).toList(),
  };
}

/// An achievement inside a mission.
class MissionMilestone {
  const MissionMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.threshold,
    this.taskTypeFilter,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final MissionMilestoneType type;

  /// The value the student has to reach, e.g. 3 completed tasks or 50%.
  final int threshold;

  /// For [MissionMilestoneType.taskTypeCount]: which task type must be done.
  final MissionTaskType? taskTypeFilter;

  final bool isUnlocked;
  final DateTime? unlockedAt;

  MissionMilestone copyWith({
    String? id,
    String? title,
    String? description,
    MissionMilestoneType? type,
    int? threshold,
    MissionTaskType? taskTypeFilter,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return MissionMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      taskTypeFilter: taskTypeFilter ?? this.taskTypeFilter,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  factory MissionMilestone.fromJson(Map<String, dynamic> json) {
    return MissionMilestone(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: MissionMilestoneType.fromStorage(json['type']?.toString()),
      threshold: _asInt(json['threshold']),
      taskTypeFilter: json['task_type_filter'] == null
          ? null
          : MissionTaskType.fromStorage(json['task_type_filter'].toString()),
      isUnlocked: _asBool(json['is_unlocked']),
      unlockedAt: _asDate(json['unlocked_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.storageValue,
    'threshold': threshold,
    'task_type_filter': taskTypeFilter?.storageValue,
    'is_unlocked': isUnlocked,
    'unlocked_at': unlockedAt?.toUtc().toIso8601String(),
  };
}

/// The result of one mission quiz run, kept per topic so Mission Mode can
/// suggest revision where it is actually needed.
class MissionTopicResult {
  const MissionTopicResult({
    required this.topic,
    required this.correct,
    required this.total,
    required this.attemptedAt,
  });

  final String topic;
  final int correct;
  final int total;
  final DateTime attemptedAt;

  int get percentage => total <= 0 ? 0 : ((correct / total) * 100).round();

  bool get needsRevision => total > 0 && percentage < 50;

  factory MissionTopicResult.fromJson(Map<String, dynamic> json) {
    return MissionTopicResult(
      topic: (json['topic'] ?? '').toString(),
      correct: _asInt(json['correct']),
      total: _asInt(json['total']),
      attemptedAt:
          _asDate(json['attempted_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'correct': correct,
    'total': total,
    'attempted_at': attemptedAt.toUtc().toIso8601String(),
  };
}

/// A complete learning journey: setup, roadmap, daily tasks and milestones.
class MissionModel {
  const MissionModel({
    required this.id,
    this.userId,
    required this.title,
    this.goal = MissionGoal.learnSubject,
    this.subject = '',
    this.subjects = const <String>[],
    this.topics = const <String>[],
    this.customLabId,
    this.targetDate,
    this.durationDays = 7,
    this.dailyStudyMinutes = 30,
    this.level = LabDifficulty.beginner,
    this.preference = MissionPreference.mixed,
    this.examTarget = MissionExamTarget.none,
    this.customExamTarget = '',
    this.status = MissionStatus.active,
    this.progress = 0,
    this.currentDay = 1,
    this.days = const <MissionDay>[],
    this.milestones = const <MissionMilestone>[],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.studyMinutesSpent = 0,
    this.quizResults = const <MissionTopicResult>[],
    this.isFinalChallengeDone = false,
    this.finalChallengeBestPercentage = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String title;
  final MissionGoal goal;

  /// Primary subject, e.g. "Science".
  final String subject;

  /// Every subject the student selected. [subject] is always the first entry.
  final List<String> subjects;

  final List<String> topics;
  final String? customLabId;
  final DateTime? targetDate;
  final int durationDays;
  final int dailyStudyMinutes;

  /// Reuses the existing [LabDifficulty] used across Study Nova.
  final LabDifficulty level;

  final MissionPreference preference;
  final MissionExamTarget examTarget;

  /// Free-text exam name when [examTarget] is
  /// [MissionExamTarget.custom].
  final String customExamTarget;

  final MissionStatus status;

  /// Overall 0-100 progress across the required tasks.
  final int progress;

  /// 1-based day the student should be on.
  final int currentDay;

  final List<MissionDay> days;
  final List<MissionMilestone> milestones;

  final int currentStreak;
  final int longestStreak;

  /// Day of the last meaningful activity (a completed task).
  final DateTime? lastActivityDate;

  final int studyMinutesSpent;

  /// Per-topic quiz results, newest first.
  final List<MissionTopicResult> quizResults;

  final bool isFinalChallengeDone;
  final int finalChallengeBestPercentage;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<MissionTask> get allTasks =>
      days.expand((day) => day.tasks).toList(growable: false);

  List<MissionTask> get requiredTasks =>
      allTasks.where((task) => task.isRequired).toList(growable: false);

  int get totalTaskCount => allTasks.length;

  int get completedTaskCount =>
      allTasks.where((task) => task.isCompleted).length;

  int get requiredTaskCount => requiredTasks.length;

  int get completedRequiredTaskCount =>
      requiredTasks.where((task) => task.isCompleted).length;

  /// Tasks that open an existing Study Nova feature, e.g. a Lab lesson.
  int get linkedTaskCount => allTasks.where((task) => task.isActionable).length;

  int get lessonTaskCount =>
      _countTotal(MissionTaskType.lesson) + _countTotal(MissionTaskType.lab);

  int get completedLessonCount =>
      _countCompleted(MissionTaskType.lesson) +
      _countCompleted(MissionTaskType.lab);

  int get quizTaskCount =>
      _countTotal(MissionTaskType.quiz) +
      _countTotal(MissionTaskType.practice) +
      _countTotal(MissionTaskType.mockTest) +
      _countTotal(MissionTaskType.finalChallenge);

  int get completedQuizCount =>
      _countCompleted(MissionTaskType.quiz) +
      _countCompleted(MissionTaskType.practice) +
      _countCompleted(MissionTaskType.mockTest) +
      _countCompleted(MissionTaskType.finalChallenge);

  int get mockTestCount => _countTotal(MissionTaskType.mockTest);

  int get revisionCount =>
      _countTotal(MissionTaskType.revision) +
      _countTotal(MissionTaskType.studyLibrary);

  bool get isCompleted => status == MissionStatus.completed;

  bool get isPaused => status == MissionStatus.paused;

  double get progressFraction => progress.clamp(0, 100) / 100;

  /// Recomputed from the required tasks so the stored value can never drift.
  int get computedProgress => requiredTaskCount <= 0
      ? 0
      : ((completedRequiredTaskCount / requiredTaskCount) * 100).round().clamp(
          0,
          100,
        );

  MissionDay? dayByNumber(int dayNumber) {
    for (final day in days) {
      if (day.dayNumber == dayNumber) return day;
    }
    return null;
  }

  /// The day the student should work on: the first day with unfinished
  /// required tasks, otherwise the last day.
  int get suggestedDay {
    for (final day in days) {
      if (!day.isComplete) return day.dayNumber;
    }
    return days.isEmpty ? 1 : days.last.dayNumber;
  }

  /// Days unlock one after another so the roadmap shows a real journey.
  bool isDayUnlocked(int dayNumber) {
    if (dayNumber <= 1) return true;
    for (final day in days) {
      if (day.dayNumber < dayNumber && !day.isComplete) return false;
    }
    return true;
  }

  /// The Final Challenge task, when the mission has one.
  MissionTask? get finalChallengeTask {
    for (final task in allTasks) {
      if (task.type == MissionTaskType.finalChallenge) return task;
    }
    return null;
  }

  /// Topics the student is weakest on, based on recorded quiz results.
  List<MissionTopicResult> get revisionSuggestions {
    final latest = <String, MissionTopicResult>{};
    for (final result in quizResults) {
      latest.putIfAbsent(result.topic, () => result);
    }
    return latest.values.where((result) => result.needsRevision).toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage));
  }

  /// One-line summary, e.g. "Science • 14 days • Beginner".
  String get subtitle {
    final parts = <String>[
      if (subject.trim().isNotEmpty) subject.trim(),
      if (goal != MissionGoal.buildKnowledge) goal.label,
      '$durationDays day${durationDays == 1 ? '' : 's'}',
      level.label,
    ];
    return parts.join(' • ');
  }

  MissionModel copyWith({
    String? id,
    String? userId,
    String? title,
    MissionGoal? goal,
    String? subject,
    List<String>? subjects,
    List<String>? topics,
    String? customLabId,
    DateTime? targetDate,
    int? durationDays,
    int? dailyStudyMinutes,
    LabDifficulty? level,
    MissionPreference? preference,
    MissionExamTarget? examTarget,
    String? customExamTarget,
    MissionStatus? status,
    int? progress,
    int? currentDay,
    List<MissionDay>? days,
    List<MissionMilestone>? milestones,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? studyMinutesSpent,
    List<MissionTopicResult>? quizResults,
    bool? isFinalChallengeDone,
    int? finalChallengeBestPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      goal: goal ?? this.goal,
      subject: subject ?? this.subject,
      subjects: subjects ?? this.subjects,
      topics: topics ?? this.topics,
      customLabId: customLabId ?? this.customLabId,
      targetDate: targetDate ?? this.targetDate,
      durationDays: durationDays ?? this.durationDays,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      level: level ?? this.level,
      preference: preference ?? this.preference,
      examTarget: examTarget ?? this.examTarget,
      customExamTarget: customExamTarget ?? this.customExamTarget,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentDay: currentDay ?? this.currentDay,
      days: days ?? this.days,
      milestones: milestones ?? this.milestones,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      studyMinutesSpent: studyMinutesSpent ?? this.studyMinutesSpent,
      quizResults: quizResults ?? this.quizResults,
      isFinalChallengeDone: isFinalChallengeDone ?? this.isFinalChallengeDone,
      finalChallengeBestPercentage:
          finalChallengeBestPercentage ?? this.finalChallengeBestPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    final days = <MissionDay>[];
    final rawDays = json['days'];
    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is Map) {
          days.add(MissionDay.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final milestones = <MissionMilestone>[];
    final rawMilestones = json['milestones'];
    if (rawMilestones is List) {
      for (final item in rawMilestones) {
        if (item is Map) {
          milestones.add(
            MissionMilestone.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final quizResults = <MissionTopicResult>[];
    final rawResults = json['quiz_results'];
    if (rawResults is List) {
      for (final item in rawResults) {
        if (item is Map) {
          quizResults.add(
            MissionTopicResult.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return MissionModel(
      id: (json['id'] ?? '').toString(),
      userId: _nullableString(json['user_id']),
      title: (json['title'] ?? '').toString(),
      goal: MissionGoal.fromStorage(json['goal']?.toString()),
      subject: (json['subject'] ?? '').toString(),
      subjects: _asStringList(json['subjects']),
      topics: _asStringList(json['topics']),
      customLabId: _nullableString(
        json['custom_lab_id'] ?? json['customLabId'],
      ),
      targetDate: _asDate(json['target_date']),
      durationDays: _asInt(json['duration_days']) == 0
          ? 7
          : _asInt(json['duration_days']),
      dailyStudyMinutes: _asInt(json['daily_study_minutes']),
      level: LabDifficulty.fromStorage(json['level']?.toString()),
      preference: MissionPreference.fromStorage(json['preference']?.toString()),
      examTarget: MissionExamTarget.fromStorage(
        json['exam_target']?.toString(),
      ),
      customExamTarget: (json['custom_exam_target'] ?? '').toString(),
      status: MissionStatus.fromStorage(json['status']?.toString()),
      progress: _asInt(json['progress']),
      currentDay: _asInt(json['current_day']),
      days: days,
      milestones: milestones,
      currentStreak: _asInt(json['current_streak']),
      longestStreak: _asInt(json['longest_streak']),
      lastActivityDate: _asDate(json['last_activity_date']),
      studyMinutesSpent: _asInt(json['study_minutes_spent']),
      quizResults: quizResults,
      isFinalChallengeDone: _asBool(json['is_final_challenge_done']),
      finalChallengeBestPercentage: _asInt(
        json['final_challenge_best_percentage'],
      ),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'goal': goal.storageValue,
    'subject': subject,
    'subjects': subjects,
    'topics': topics,
    'custom_lab_id': customLabId,
    'customLabId': customLabId,
    'target_date': targetDate?.toUtc().toIso8601String(),
    'duration_days': durationDays,
    'daily_study_minutes': dailyStudyMinutes,
    'level': level.storageValue,
    'preference': preference.storageValue,
    'exam_target': examTarget.storageValue,
    'custom_exam_target': customExamTarget,
    'status': status.storageValue,
    'progress': computedProgress,
    'current_day': suggestedDay,
    'days': days.map((day) => day.toJson()).toList(),
    'milestones': milestones.map((milestone) => milestone.toJson()).toList(),
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'last_activity_date': lastActivityDate?.toUtc().toIso8601String(),
    'study_minutes_spent': studyMinutesSpent,
    'quiz_results': quizResults.map((result) => result.toJson()).toList(),
    'is_final_challenge_done': isFinalChallengeDone,
    'final_challenge_best_percentage': finalChallengeBestPercentage,
    'created_at': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
    'updated_at': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
  };

  int _countTotal(MissionTaskType type) =>
      allTasks.where((task) => task.type == type).length;

  int _countCompleted(MissionTaskType type) =>
      allTasks.where((task) => task.type == type && task.isCompleted).length;
}

/// The answer the student gives the wizard before a mission exists.
class MissionSetup {
  const MissionSetup({
    this.title = '',
    this.goal = MissionGoal.learnSubject,
    this.subjects = const <String>[],
    this.topics = const <String>[],
    this.durationDays = 7,
    this.customTargetDate,
    this.dailyStudyMinutes = 30,
    this.level = LabDifficulty.beginner,
    this.preference = MissionPreference.mixed,
    this.examTarget = MissionExamTarget.none,
    this.customExamTarget = '',
  });

  final String title;
  final MissionGoal goal;
  final List<String> subjects;
  final List<String> topics;
  final int durationDays;
  final DateTime? customTargetDate;
  final int dailyStudyMinutes;
  final LabDifficulty level;
  final MissionPreference preference;
  final MissionExamTarget examTarget;
  final String customExamTarget;

  String get primarySubject => subjects.isEmpty ? '' : subjects.first;

  /// How long the mission runs: either the chosen number of days or the span
  /// to a custom target date, never below one day.
  ///
  /// A custom target date counts inclusively, so a mission due in 5 days is a
  /// 5-day mission: today is day one and the target date is the last day.
  int get resolvedDurationDays {
    if (customTargetDate == null) return durationDays < 1 ? 1 : durationDays;
    final days = customTargetDate!
        .difference(DateTime.now())
        .inDays
        .clamp(0, 364);
    return days + 1;
  }

  DateTime get resolvedTargetDate =>
      customTargetDate ??
      DateTime.now().add(Duration(days: resolvedDurationDays));

  MissionSetup copyWith({
    String? title,
    MissionGoal? goal,
    List<String>? subjects,
    List<String>? topics,
    int? durationDays,
    DateTime? customTargetDate,
    bool clearCustomTargetDate = false,
    int? dailyStudyMinutes,
    LabDifficulty? level,
    MissionPreference? preference,
    MissionExamTarget? examTarget,
    String? customExamTarget,
  }) {
    return MissionSetup(
      title: title ?? this.title,
      goal: goal ?? this.goal,
      subjects: subjects ?? this.subjects,
      topics: topics ?? this.topics,
      durationDays: durationDays ?? this.durationDays,
      customTargetDate: clearCustomTargetDate
          ? null
          : (customTargetDate ?? this.customTargetDate),
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      level: level ?? this.level,
      preference: preference ?? this.preference,
      examTarget: examTarget ?? this.examTarget,
      customExamTarget: customExamTarget ?? this.customExamTarget,
    );
  }
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

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

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const <String>[];
}
