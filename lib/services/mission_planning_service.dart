import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/ai_config.dart';
import '../data/mission_catalog.dart';
import '../models/mission_model.dart';
import 'mission_content_matcher.dart';

/// The outcome of planning a mission.
class MissionPlanResult {
  const MissionPlanResult({
    required this.mission,
    this.usedAi = false,
    this.notes = const <String>[],
  });

  final MissionModel mission;

  /// True when the plan was written by the optional AI planner. The AI can only
  /// choose wording and ordering — every content id still comes from the
  /// deterministic matcher.
  final bool usedAi;

  /// Student-facing notes, e.g. a topic with no matching Study Nova content.
  final List<String> notes;
}

/// Turns a mission setup into a complete learning journey.
///
/// Every implementation must:
///  * only reference content that exists (Labs from `LabService`, courses the
///    student saved);
///  * produce a runnable plan when there is no network and no AI quota;
///  * never throw.
abstract class MissionPlanner {
  Future<MissionPlanResult?> plan(
    MissionSetup setup, {
    required String missionId,
    String? userId,
  });
}

/// Deterministic planner. This is the default and the safety net: it works
/// offline, without any AI key, and always produces the same plan for the same
/// setup.
class LocalMissionPlanner implements MissionPlanner {
  LocalMissionPlanner({MissionContentMatcher? matcher})
    : _matcher = matcher ?? MissionContentMatcher();

  final MissionContentMatcher _matcher;

  /// Shared milestone definitions, so every mission teaches the same
  /// achievement vocabulary.
  ///
  /// Thresholds scale with the mission, so a short mission never shows a badge
  /// the student has no way to earn.
  static List<MissionMilestone> buildMilestones({
    required int totalTasks,
    required int durationDays,
  }) {
    int atMost(int value, int days) => value < days ? value : days;

    final milestones = <MissionMilestone>[
      MissionMilestone(
        id: 'm-first-steps',
        title: 'First Milestone',
        description: 'Complete your first 3 mission tasks.',
        type: MissionMilestoneType.taskCount,
        threshold: atMost(3, totalTasks),
      ),
      MissionMilestone(
        id: 'm-halfway',
        title: 'Halfway There',
        description: 'Reach 50% mission progress.',
        type: MissionMilestoneType.progressReached,
        threshold: 50,
      ),
      MissionMilestone(
        id: 'm-knowledge-builder',
        title: 'Knowledge Builder',
        description: 'Complete 5 lesson or Lab tasks.',
        type: MissionMilestoneType.taskTypeCount,
        threshold: atMost(5, durationDays),
        taskTypeFilter: MissionTaskType.lesson,
      ),
      MissionMilestone(
        id: 'm-quiz-master',
        title: 'Quiz Master',
        description: 'Complete 4 quiz, practice or mock test tasks.',
        type: MissionMilestoneType.taskTypeCount,
        threshold: _half(durationDays),
        taskTypeFilter: MissionTaskType.quiz,
      ),
      MissionMilestone(
        id: 'm-streak',
        title: 'Consistent Learner',
        description: 'Study on 5 consecutive days.',
        type: MissionMilestoneType.streakDays,
        threshold: _half(durationDays),
      ),
    ];

    if (durationDays >= 10) {
      milestones.insert(
        1,
        MissionMilestone(
          id: 'm-momentum',
          title: 'Momentum',
          description: 'Complete 10 mission tasks.',
          type: MissionMilestoneType.taskCount,
          threshold: atMost(10, totalTasks),
        ),
      );
    }
    if (totalTasks >= totalTasksForFinalMilestone(durationDays)) {
      milestones.add(
        MissionMilestone(
          id: 'm-mission-complete',
          title: 'Mission Complete',
          description: 'Finish every required task in this mission.',
          type: MissionMilestoneType.missionCompleted,
          threshold: 1,
        ),
      );
    }
    return milestones;
  }

  /// A threshold that halves with the mission length, never below one, so a
  /// three-day mission is still winnable.
  static int _half(int durationDays) {
    if (durationDays <= 1) return 1;
    final half = durationDays ~/ 2;
    return half < 1 ? 1 : half;
  }

  static int totalTasksForFinalMilestone(int durationDays) =>
      (durationDays * 2).clamp(6, 1000000);

  @override
  Future<MissionPlanResult> plan(
    MissionSetup setup, {
    required String missionId,
    String? userId,
  }) async {
    final notes = <String>[];

    final topics = _resolveTopics(setup, notes);
    final durationDays = setup.resolvedDurationDays.clamp(1, 120);
    final matches = await _matcher.matchTopics(
      subjects: setup.subjects,
      topics: topics,
    );

    final days = <MissionDay>[];
    for (var dayNumber = 1; dayNumber <= durationDays; dayNumber++) {
      days.add(
        _buildDay(
          setup: setup,
          topics: topics,
          matches: matches,
          dayNumber: dayNumber,
          durationDays: durationDays,
          missionId: missionId,
          notes: notes,
        ),
      );
    }

    final totalTasks = days.fold<int>(
      0,
      (total, day) => total + day.tasks.length,
    );

    final now = DateTime.now();
    final mission = MissionModel(
      id: missionId,
      userId: userId,
      title: _resolveTitle(setup),
      goal: setup.goal,
      subject: setup.primarySubject,
      subjects: setup.subjects,
      topics: topics,
      targetDate: setup.resolvedTargetDate,
      durationDays: durationDays,
      dailyStudyMinutes: setup.dailyStudyMinutes,
      level: setup.level,
      preference: setup.preference,
      examTarget: setup.examTarget,
      customExamTarget: setup.customExamTarget,
      status: MissionStatus.active,
      currentDay: 1,
      days: days,
      milestones: buildMilestones(
        totalTasks: totalTasks,
        durationDays: durationDays,
      ),
      createdAt: now,
      updatedAt: now,
    );

    return MissionPlanResult(mission: mission, notes: notes);
  }

  List<String> _resolveTopics(MissionSetup setup, List<String> notes) {
    final chosen = setup.topics
        .map((topic) => topic.trim())
        .where((topic) => topic.isNotEmpty)
        .toList();
    if (chosen.isNotEmpty) return chosen;

    final defaults = MissionCatalog.defaultTopicsFor(setup.subjects);
    if (defaults.isNotEmpty) return defaults;

    notes.add(
      'No subject topics were found, so the mission uses general study tasks. '
      'Add topics in Mission Mode to get a tailored plan.',
    );
    return const <String>['Core concepts'];
  }

  String _resolveTitle(MissionSetup setup) {
    final trimmed = setup.title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final subject = setup.primarySubject;
    return subject.isEmpty
        ? 'My Learning Mission'
        : '$subject Learning Mission';
  }

  MissionDay _buildDay({
    required MissionSetup setup,
    required List<String> topics,
    required List<MissionTopicMatch> matches,
    required int dayNumber,
    required int durationDays,
    required String missionId,
    required List<String> notes,
  }) {
    final topicIndex = (dayNumber - 1) % topics.length;
    final topic = topics[topicIndex];
    final match = matches[topicIndex];

    final tasks = <MissionTask>[];
    var taskIndex = 0;
    void add(MissionTask task) {
      tasks.add(
        task.copyWith(
          order: taskIndex,
          id: '$missionId-d$dayNumber-t$taskIndex',
        ),
      );
      taskIndex++;
    }

    // 1. The main study task, linked to real content whenever it exists.
    add(
      _buildStudyTask(
        setup: setup,
        match: match,
        topic: topic,
        dayNumber: dayNumber,
        missionId: missionId,
        notes: notes,
      ),
    );

    // 2. A Lab task every third day, when a bundled Lab matched.
    if (match.hasLab &&
        dayNumber % 3 == 0 &&
        !tasks.any((task) => task.lessonId != null)) {
      add(
        _task(
          missionId: missionId,
          dayNumber: dayNumber,
          type: MissionTaskType.lab,
          title: 'Work through ${match.lab!.title}',
          description:
              'Open the Study Nova Lab and continue where you stopped. '
              'Progress here is tracked in Study Nova Labs too.',
          topic: topic,
          labId: match.lab!.id,
        ),
      );
    }

    // 3. Quiz / practice, chosen from the Lab's own quiz questions when the
    //    Lab has any, otherwise the mission practice bank.
    final wantsQuiz =
        _prefers(setup.preference, MissionPreference.quizzes) ||
        dayNumber % 2 == 0;
    if (wantsQuiz) {
      add(
        _task(
          missionId: missionId,
          dayNumber: dayNumber,
          type: MissionTaskType.quiz,
          title: match.hasLab && match.lab!.quizQuestions.isNotEmpty
              ? 'Quiz on ${match.lab!.title}'
              : 'Practice questions on $topic',
          description: match.hasLab && match.lab!.quizQuestions.isNotEmpty
              ? 'Answer the ${match.lab!.quizQuestions.length} questions that '
                    'ship with ${match.lab!.title}.'
              : 'Answer practice questions on $topic and review the '
                    'explanations.',
          topic: topic,
          labId: match.hasLab && match.lab!.quizQuestions.isNotEmpty
              ? match.lab!.id
              : null,
        ),
      );
    }

    // 4. Study From Photo, on day one and then every fourth day.
    if (dayNumber == 1 || dayNumber % 4 == 0) {
      add(
        _task(
          missionId: missionId,
          dayNumber: dayNumber,
          type: MissionTaskType.studyFromPhoto,
          title: 'Study From Photo: $topic',
          description:
              'Photograph your notes or a textbook page for $topic and read '
              'the explanation Study Nova generates.',
          topic: topic,
        ),
      );
    }

    // 5. Revision every third day; the Study Library is used once the student
    //    has saved at least one photo analysis.
    if (dayNumber > 1 && dayNumber % 3 == 0) {
      add(
        _task(
          missionId: missionId,
          dayNumber: dayNumber,
          type: dayNumber % 6 == 0
              ? MissionTaskType.studyLibrary
              : MissionTaskType.revision,
          title: 'Revise ${topics[(dayNumber - 2) % topics.length]}',
          description: dayNumber % 6 == 0
              ? 'Reopen your saved photo analyses in the Study Library and '
                    're-read the explanations.'
              : 'Revisit the key points you marked earlier and write down '
                    'anything you still cannot explain.',
          topic: topics[(dayNumber - 2) % topics.length],
        ),
      );
    }

    // 6. Mock tests towards the end, more of them for competitive exams.
    if (_isMockTestDay(dayNumber, durationDays, setup.examTarget)) {
      add(
        _task(
          missionId: missionId,
          dayNumber: dayNumber,
          type: MissionTaskType.mockTest,
          title: 'Mock test on $topic',
          description:
              'A longer mixed test covering the mission so far. Review every '
              'mistake afterwards.',
          topic: topic,
        ),
      );
    }

    // 7. The Final Challenge closes the mission.
    if (dayNumber == durationDays) {
      add(
        _task(
          missionId: missionId,
          dayNumber: dayNumber,
          type: MissionTaskType.finalChallenge,
          title: 'Final Challenge',
          description:
              'A mixed test over everything covered by this mission, with a '
              'topic-by-topic breakdown.',
          topic: topic,
        ),
      );
    }

    final planned = _distributeMinutes(tasks, setup.dailyStudyMinutes);

    final isRevisionDay = dayNumber > 1 && dayNumber % 3 == 0;
    return MissionDay(
      dayNumber: dayNumber,
      title: isRevisionDay
          ? 'Day $dayNumber · Revision & Practice'
          : 'Day $dayNumber · $topic',
      focusTopic: topic,
      tasks: planned,
      estimatedMinutes: planned.fold<int>(
        0,
        (sum, task) => sum + task.estimatedMinutes,
      ),
    );
  }

  MissionTask _buildStudyTask({
    required MissionSetup setup,
    required MissionTopicMatch match,
    required String topic,
    required int dayNumber,
    required String missionId,
    required List<String> notes,
  }) {
    if (match.hasLesson && match.lab != null) {
      return _task(
        missionId: missionId,
        dayNumber: dayNumber,
        type: MissionTaskType.lesson,
        title: 'Study $topic',
        description:
            'Read "${match.lesson!.title}" inside the '
            '${match.lab!.title} Lab, then mark the lesson complete.',
        topic: topic,
        labId: match.lab!.id,
        lessonId: match.lesson!.id,
      );
    }

    if (match.hasCourse) {
      return _task(
        missionId: missionId,
        dayNumber: dayNumber,
        type: MissionTaskType.course,
        title: 'Study $topic',
        description:
            'Open your saved course and work through the chapter for $topic.',
        topic: topic,
        courseId: match.course!.id,
        courseChapterIndex: match.courseChapterIndex,
      );
    }

    if (match.hasLab) {
      // The Lab matched the subject but has no lesson for this topic, so the
      // student still works inside Study Nova Labs rather than off-app.
      return _task(
        missionId: missionId,
        dayNumber: dayNumber,
        type: MissionTaskType.lab,
        title: 'Study $topic in the ${match.lab!.title} Lab',
        description:
            'Open the ${match.lab!.title} Lab and work through the material on '
            '$topic. Progress here is tracked in Study Nova Labs too.',
        topic: topic,
        labId: match.lab!.id,
      );
    }

    if (!notes.contains(_noContentNote)) notes.add(_noContentNote);
    return _task(
      missionId: missionId,
      dayNumber: dayNumber,
      type: MissionTaskType.custom,
      title: 'Study $topic',
      description:
          'No matching Study Nova content found for "$topic" yet. Read your '
          'notes or a textbook chapter on it, and use Study From Photo if the '
          'page is hard to follow.',
      topic: topic,
    );
  }

  static const String _noContentNote =
      'Some topics have no matching Study Nova content yet, so they became '
      'self-study tasks. Create a course for them, or take a photo of your '
      'notes in Study From Photo.';

  bool _isMockTestDay(
    int dayNumber,
    int durationDays,
    MissionExamTarget examTarget,
  ) {
    if (durationDays < 5) return false;
    final competitive = examTarget.isCompetitive;
    if (competitive) {
      return dayNumber == ((durationDays * 0.6).round()) ||
          dayNumber == ((durationDays * 0.85).round());
    }
    return dayNumber == durationDays - 1 && durationDays >= 7;
  }

  bool _prefers(MissionPreference missionPreference, MissionPreference other) {
    if (missionPreference == MissionPreference.mixed) return true;
    return missionPreference == other;
  }

  /// Spreads the student's daily study time across the day's tasks so the day
  /// adds up to roughly what they committed to.
  List<MissionTask> _distributeMinutes(
    List<MissionTask> tasks,
    int dailyMinutes,
  ) {
    if (tasks.isEmpty) return tasks;

    final weights = <double>[for (final task in tasks) _weightFor(task.type)];
    final totalWeight = weights.fold<double>(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) return tasks;

    final budget = dailyMinutes < 10 ? 10 : dailyMinutes;
    var used = 0;
    return List<MissionTask>.generate(tasks.length, (index) {
      var share = ((weights[index] / totalWeight) * budget).round().clamp(
        5,
        180,
      );
      // Give any rounding remainder to the last task so the day adds up to
      // exactly the student's daily study time.
      if (index == tasks.length - 1) {
        share = (budget - used).clamp(5, 180);
      } else {
        used += share;
      }
      return tasks[index].copyWith(estimatedMinutes: share);
    });
  }

  double _weightFor(MissionTaskType type) {
    switch (type) {
      case MissionTaskType.course:
      case MissionTaskType.lab:
      case MissionTaskType.lesson:
        return 4;
      case MissionTaskType.finalChallenge:
      case MissionTaskType.mockTest:
        return 3;
      case MissionTaskType.quiz:
      case MissionTaskType.practice:
        return 2;
      case MissionTaskType.studyFromPhoto:
      case MissionTaskType.studyLibrary:
      case MissionTaskType.revision:
        return 1.5;
      case MissionTaskType.custom:
        return 3;
    }
  }

  MissionTask _task({
    required String missionId,
    required int dayNumber,
    required MissionTaskType type,
    required String title,
    required String description,
    required String topic,
    String? labId,
    String? lessonId,
    String? courseId,
    int? courseChapterIndex,
  }) {
    return MissionTask(
      id: '$missionId-d$dayNumber-t0',
      missionId: missionId,
      dayNumber: dayNumber,
      type: type,
      title: title,
      description: description,
      topic: topic,
      labId: labId,
      lessonId: lessonId,
      courseId: courseId,
      courseChapterIndex: courseChapterIndex,
    );
  }
}

/// Optional AI planner.
///
/// The AI may only choose wording and ordering. It never supplies content ids:
/// every task is matched to real Study Nova content by [LocalMissionPlanner]
/// afterwards, and any answer that fails validation is discarded so the
/// deterministic planner is used instead.
class AiMissionPlanner implements MissionPlanner {
  AiMissionPlanner({required this.apiKey, String? model})
    : model = (model != null && model.trim().isNotEmpty)
          ? model.trim()
          : geminiModel;

  final String apiKey;
  final String model;

  /// True when an AI key is configured for this build.
  static bool get isConfigured => googleGenerativeAIKey.isNotEmpty;

  @override
  Future<MissionPlanResult?> plan(
    MissionSetup setup, {
    required String missionId,
    String? userId,
  }) async {
    if (!isConfigured) return null;

    try {
      final model_ = GenerativeModel(model: model, apiKey: apiKey);
      final response = await model_.generateContent([
        Content.multi([TextPart(_buildPrompt(setup))]),
      ]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) return null;

      final parsed = _validate(jsonDecode(_stripCodeFence(text)));
      if (parsed == null) return null;

      // Only the wording is taken from the AI; the structure and every content
      // reference are produced locally.
      final local = await LocalMissionPlanner().plan(
        setup,
        missionId: missionId,
        userId: userId,
      );
      return MissionPlanResult(
        mission: _applyWording(local.mission, parsed),
        usedAi: true,
        notes: local.notes,
      );
    } catch (error) {
      debugPrint('MissionMode: AI planning unavailable ($error)');
      return null;
    }
  }

  /// Keeps only safe, bounded strings from the AI response. Anything else is
  /// treated as invalid and the local plan is used.
  static Map<String, dynamic>? _validate(Object? decoded) {
    if (decoded is! Map) return null;
    final rawDays = decoded['days'];
    if (rawDays is! List || rawDays.isEmpty || rawDays.length > 120) {
      return null;
    }

    final days = <Map<String, dynamic>>[];
    for (final day in rawDays) {
      if (day is! Map) return null;
      final title = (day['title'] ?? '').toString().trim();
      if (title.isEmpty || title.length > 120) return null;
      final rawTasks = day['tasks'];
      if (rawTasks is! List) return null;
      final tasks = <Map<String, dynamic>>[];
      for (final task in rawTasks) {
        if (task is! Map) return null;
        final taskTitle = (task['title'] ?? '').toString().trim();
        if (taskTitle.isEmpty || taskTitle.length > 160) return null;
        tasks.add(<String, dynamic>{
          'title': taskTitle,
          'description': (task['description'] ?? '')
              .toString()
              .trim()
              .substring(
                0,
                (task['description'] ?? '').toString().trim().length.clamp(
                  0,
                  400,
                ),
              ),
          'type': (task['type'] ?? '').toString().trim(),
        });
        if (tasks.length > 8) return null;
      }
      days.add(<String, dynamic>{'title': title, 'tasks': tasks});
    }

    return <String, dynamic>{'days': days};
  }

  /// Copies AI wording onto the locally generated structure by day index.
  static MissionModel _applyWording(
    MissionModel mission,
    Map<String, dynamic> aiPlan,
  ) {
    final aiDays = (aiPlan['days'] as List).cast<Map<String, dynamic>>();

    final updatedDays = mission.days.map((day) {
      if (day.dayNumber - 1 >= aiDays.length) return day;
      final aiDay = aiDays[day.dayNumber - 1];
      final aiTasks = (aiDay['tasks'] as List).cast<Map<String, dynamic>>();

      final updatedTasks = day.tasks.asMap().entries.map((entry) {
        final index = entry.key;
        if (index >= aiTasks.length) return entry.value;
        final aiTask = aiTasks[index];
        final title = (aiTask['title'] ?? '').toString().trim();
        final description = (aiTask['description'] ?? '').toString().trim();
        return entry.value.copyWith(
          title: title.isEmpty ? entry.value.title : title,
          description: description.isEmpty
              ? entry.value.description
              : description,
        );
      }).toList();

      return day.copyWith(
        title: (aiDay['title'] ?? '').toString().trim().isEmpty
            ? day.title
            : aiDay['title'].toString().trim(),
        tasks: updatedTasks,
      );
    }).toList();

    return mission.copyWith(days: updatedDays);
  }

  static String _stripCodeFence(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'```\s*$'), '');
    }
    return cleaned.trim();
  }

  static String _buildPrompt(MissionSetup setup) {
    final buffer = StringBuffer()
      ..writeln(
        'You plan short daily study missions for the Study Nova learning app.',
      )
      ..writeln(
        'Reply with JSON only: {"days":[{"title":"...","tasks":'
        '[{"title":"...","description":"...","type":"lesson|lab|quiz|'
        'studyFromPhoto|revision|practice|mockTest"}]}]}',
      )
      ..writeln(
        'Mission title: ${setup.title.isEmpty ? 'Learning mission' : setup.title}',
      )
      ..writeln('Goal: ${setup.goal.label}')
      ..writeln('Subjects: ${setup.subjects.join(', ')}')
      ..writeln('Topics: ${setup.topics.join(', ')}')
      ..writeln('Days: ${setup.resolvedDurationDays}')
      ..writeln('Minutes per day: ${setup.dailyStudyMinutes}')
      ..writeln('Level: ${setup.level.label}')
      ..writeln('Preference: ${setup.preference.label}')
      ..writeln('Exam target: ${setup.examTarget.label}')
      ..writeln(
        'Create exactly ${setup.resolvedDurationDays} days, 2 to 5 tasks per '
        'day, in the order the topics should be learned. Be concise.',
      );
    return buffer.toString();
  }
}

/// Entry point used by the Mission Mode screens.
///
/// Default behaviour is fully local and offline. The AI planner is only tried
/// when the student explicitly asks for it *and* a key is configured, and any
/// failure falls back to the deterministic plan.
class MissionPlanningService {
  MissionPlanningService._();

  static final MissionPlanningService instance = MissionPlanningService._();

  static int _idCounter = 0;

  /// Whether AI planning can even be attempted in this build.
  bool get isAiAvailable => AiMissionPlanner.isConfigured;

  /// Creates a mission id that is unique on the device, so missions exist even
  /// before Supabase ever sees them.
  static String newMissionId() {
    _idCounter++;
    return 'mission-${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  Future<MissionPlanResult> createMission(
    MissionSetup setup, {
    String? userId,
    String? missionId,
    bool useAi = false,
  }) async {
    final id = missionId ?? newMissionId();

    if (useAi && isAiAvailable) {
      final ai = await AiMissionPlanner(
        apiKey: googleGenerativeAIKey,
      ).plan(setup, missionId: id, userId: userId);
      if (ai != null) return ai;
    }

    return LocalMissionPlanner().plan(setup, missionId: id, userId: userId);
  }
}
