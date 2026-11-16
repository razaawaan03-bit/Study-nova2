import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/mission_model.dart';
import '../utils/mission_local_store.dart';
import '../utils/supabase_availability.dart';
import 'auth_service.dart';
import 'lab_service.dart';
import 'mission_planning_service.dart';

/// Owns the student's Missions and their progress.
///
/// Mission Mode does not store learning content: it stores *references* to
/// content that already exists in Study Nova Labs or in courses the student
/// saved. This service therefore only manages missions, task completion,
/// streaks, milestones and quiz results.
///
/// Persistence is layered and always optional:
///  1. Supabase `missions` table, when Supabase is reachable and the table
///     exists (see `sql/missions.sql`);
///  2. a local JSON file on platforms that have one;
///  3. memory, so Mission Mode works with no network at all.
class MissionService extends ChangeNotifier {
  MissionService._internal();

  static final MissionService instance = MissionService._internal();

  final Map<String, MissionModel> _missions = <String, MissionModel>{};

  /// Mission ids removed on this device that still have to be deleted from the
  /// cloud, so a deleted mission cannot reappear after the next sync.
  final Set<String> _removedMissionIds = <String>{};
  final MissionLocalStore _localStore = MissionLocalStore();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoaded = false;
  bool _isSyncing = false;

  /// True when Supabase is currently usable for Mission Mode.
  bool get isCloudAvailable => safeSupabase() != null;

  /// True while the service is reading local/cloud missions.
  bool get isLoading => _isLoading;

  /// True once the first load has completed.
  bool get isLoaded => _isLoaded;

  /// True when a cloud round trip is in progress.
  bool get isSyncing => _isSyncing;

  /// The signed-in student, or `null` when nobody is signed in or Supabase is
  /// not up yet. Mission Mode never requires a signed-in account.
  String? get _currentUserId {
    try {
      return _authService.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Missions of the signed-in student, newest first.
  List<MissionModel> get missions {
    final userId = _currentUserId;
    final visible =
        _missions.values.where((mission) => mission.userId == userId).toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
    return List<MissionModel>.unmodifiable(visible);
  }

  List<MissionModel> missionsWithStatus(MissionStatus status) =>
      missions.where((mission) => mission.status == status).toList();

  List<MissionModel> get activeMissions =>
      missionsWithStatus(MissionStatus.active);

  List<MissionModel> get completedMissions =>
      missionsWithStatus(MissionStatus.completed);

  List<MissionModel> get pausedMissions =>
      missionsWithStatus(MissionStatus.paused);

  /// The mission the Home screen should continue, if any.
  MissionModel? get featuredMission {
    final active = activeMissions;
    if (active.isEmpty) return null;
    final sorted = [...active]
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime.now()).compareTo(
          a.updatedAt ?? DateTime.now(),
        ),
      );
    return sorted.first;
  }

  /// A mission by id, restricted to the missions the current account may see.
  ///
  /// A mission saved while signed out belongs to the signed-out student, so it
  /// must not open after a different account signs in on a shared device.
  MissionModel? byId(String? missionId) {
    if (missionId == null || missionId.isEmpty) return null;
    final mission = _missions[missionId];
    if (mission == null) return null;
    if (mission.userId != _currentUserId) return null;
    return mission;
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Reads missions from local storage and, when possible, from Supabase.
  /// Safe to call more than once.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final local = await _localStore.readAll();
      for (final payload in local) {
        try {
          final mission = MissionModel.fromJson(payload);
          if (mission.id.isEmpty) continue;
          _missions[mission.id] = mission;
        } catch (_) {
          // Skip anything unreadable rather than losing the whole file.
        }
      }

      await _pullFromCloud();
    } finally {
      _isLoading = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _pullFromCloud() async {
    final supabase = safeSupabase();
    if (supabase == null) return;
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final response = await supabase.client
          .from('missions')
          .select('id, data, updated_at')
          .eq('user_id', userId);

      for (final row in response) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final raw = row['data'];
        if (raw is! Map) continue;
        final payload = Map<String, dynamic>.from(raw);

        final incoming = MissionModel.fromJson(payload);

        final existing = _missions[id];
        final existingTime =
            existing?.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final incomingTime =
            incoming.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (existing == null || incomingTime.isAfter(existingTime)) {
          _missions[id] = MissionModel.fromJson({...payload, 'id': id});
        }
      }
    } catch (error) {
      // The table may not exist yet, or the device may be offline. Both are
      // expected: Mission Mode keeps running on local storage.
      debugPrint('MissionMode: cloud load skipped ($error)');
    }
  }

  // ---------------------------------------------------------------------------
  // Creating missions
  // ---------------------------------------------------------------------------

  /// Plans and stores a new mission. Never throws: if planning fails the
  /// deterministic planner result is used.
  Future<MissionPlanResult> createMission(
    MissionSetup setup, {
    bool useAi = false,
  }) async {
    final result = await MissionPlanningService.instance.createMission(
      setup,
      userId: _currentUserId,
      useAi: useAi && MissionPlanningService.instance.isAiAvailable,
    );

    _missions[result.mission.id] = result.mission;
    notifyListeners();
    await _persistAll();
    return result;
  }

  // ---------------------------------------------------------------------------
  // Task completion
  // ---------------------------------------------------------------------------

  /// Marks one mission task complete or incomplete and refreshes everything
  /// that depends on it: progress, current day, study time, streak, milestones
  /// and the mission status.
  ///
  /// When the task points at a Study Nova Lab lesson, the Lab lesson is marked
  /// complete too, so the Labs screen reflects the mission work.
  Future<MissionModel?> setTaskCompleted(
    String? missionId,
    String? taskId, {
    bool completed = true,
  }) async {
    final mission = byId(missionId);
    if (mission == null || taskId == null || taskId.isEmpty) return null;

    var changed = false;
    final updatedDays = mission.days.map((day) {
      var dayChanged = false;
      final updatedTasks = day.tasks.map((task) {
        if (task.id != taskId) return task;
        dayChanged = true;
        changed = true;
        return task.copyWith(
          isCompleted: completed,
          completedAt: completed ? DateTime.now() : null,
        );
      }).toList();
      return dayChanged ? day.copyWith(tasks: updatedTasks) : day;
    }).toList();

    if (!changed) return mission;

    var next = mission.copyWith(days: updatedDays, updatedAt: DateTime.now());

    if (completed) {
      // Keep Study Nova Labs in sync with the mission.
      final task = _findTask(next, taskId);
      if (task != null && task.hasLab && task.hasLesson) {
        await LabService.instance.setLessonCompleted(task.labId, task.lessonId);
      }
      next = _recompute(_applyActivity(next));
    } else {
      next = _recompute(next);
    }

    _missions[next.id] = next;
    notifyListeners();
    await _persistAll();
    return next;
  }

  /// Adds a student-created task to a mission day. Custom tasks are optional, so
  /// they never block mission completion.
  Future<MissionModel?> addCustomTask({
    required String missionId,
    required int dayNumber,
    required String title,
    String description = '',
  }) async {
    final mission = byId(missionId);
    if (mission == null || title.trim().isEmpty) return null;

    final day =
        mission.dayByNumber(dayNumber) ??
        (mission.days.isEmpty ? null : mission.days.first);
    if (day == null) return null;

    final task = MissionTask(
      id: '${mission.id}-d$dayNumber-custom-${DateTime.now().microsecondsSinceEpoch}',
      missionId: mission.id,
      dayNumber: dayNumber,
      type: MissionTaskType.custom,
      title: title.trim(),
      description: description.trim().isEmpty
          ? 'Your own task for this mission day.'
          : description.trim(),
      topic: day.focusTopic,
      isRequired: false,
      order: day.tasks.length,
    );

    final updatedDays = mission.days.map((candidate) {
      if (candidate.dayNumber != day.dayNumber) return candidate;
      return candidate.copyWith(tasks: [...candidate.tasks, task]);
    }).toList();

    final next = _recompute(
      mission.copyWith(days: updatedDays, updatedAt: DateTime.now()),
    );
    _missions[next.id] = next;
    notifyListeners();
    await _persistAll();
    return next;
  }

  // ---------------------------------------------------------------------------
  // Quiz results
  // ---------------------------------------------------------------------------

  /// Stores a finished mission quiz (practice, mock test or Final Challenge).
  ///
  /// The per-topic results drive the "recommended revision" hints, so
  /// suggestions are based on real answers and never on guesses.
  Future<MissionModel?> recordQuizRun(
    String? missionId, {
    required List<MissionTopicResult> results,
    bool isFinalChallenge = false,
    int percentage = 0,
  }) async {
    final mission = byId(missionId);
    if (mission == null) return null;

    final next = mission.copyWith(
      quizResults: [...results, ...mission.quizResults],
      isFinalChallengeDone: mission.isFinalChallengeDone || isFinalChallenge,
      finalChallengeBestPercentage: isFinalChallenge
          ? (percentage > mission.finalChallengeBestPercentage
                ? percentage
                : mission.finalChallengeBestPercentage)
          : mission.finalChallengeBestPercentage,
      updatedAt: DateTime.now(),
    );

    final refreshed = _recompute(next);
    _missions[refreshed.id] = refreshed;
    notifyListeners();
    await _persistAll();
    return refreshed;
  }

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  Future<MissionModel?> setStatus(
    String? missionId,
    MissionStatus status,
  ) async {
    final mission = byId(missionId);
    if (mission == null) return null;

    final next = _recompute(
      mission.copyWith(status: status, updatedAt: DateTime.now()),
    );
    _missions[next.id] = next;
    notifyListeners();
    await _persistAll();
    return next;
  }

  /// Pauses or resumes a mission.
  Future<MissionModel?> togglePause(String? missionId) async {
    final mission = byId(missionId);
    if (mission == null) return null;
    return setStatus(
      missionId,
      mission.isPaused ? MissionStatus.active : MissionStatus.paused,
    );
  }

  /// Removes a mission. Courses, Labs and lessons are never touched.
  Future<void> deleteMission(String? missionId) async {
    if (missionId == null || !_missions.containsKey(missionId)) return;
    _missions.remove(missionId);
    _removedMissionIds.add(missionId);
    notifyListeners();
    await _persistAll();
  }

  /// Clears every mission, e.g. on sign out.
  Future<void> reset() async {
    _removedMissionIds.addAll(_missions.keys);
    _missions.clear();
    _isLoaded = false;
    notifyListeners();
    await _persistAll();
  }

  // ---------------------------------------------------------------------------
  // Internal bookkeeping
  // ---------------------------------------------------------------------------

  MissionTask? _findTask(MissionModel mission, String taskId) {
    for (final day in mission.days) {
      for (final task in day.tasks) {
        if (task.id == taskId) return task;
      }
    }
    return null;
  }

  /// Recomputes derived values and unlocks any milestone that is now earned.
  MissionModel _recompute(MissionModel mission) {
    var next = mission.copyWith(
      progress: mission.computedProgress,
      currentDay: mission.suggestedDay,
    );

    next = _refreshMilestones(next);

    final finished = next.computedProgress >= 100;
    if (finished && next.status != MissionStatus.completed) {
      next = next.copyWith(
        status: MissionStatus.completed,
        updatedAt: DateTime.now(),
      );
    } else if (!finished && next.status == MissionStatus.completed) {
      // A task was unchecked, so the mission is active again.
      next = next.copyWith(
        status: MissionStatus.active,
        updatedAt: DateTime.now(),
      );
    }
    return next;
  }

  /// Records meaningful study activity: study time, the daily streak and any
  /// milestone the student just earned.
  MissionModel _applyActivity(MissionModel mission) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = mission.lastActivityDate == null
        ? null
        : DateTime(
            mission.lastActivityDate!.year,
            mission.lastActivityDate!.month,
            mission.lastActivityDate!.day,
          );

    var streak = mission.currentStreak;
    if (last == null) {
      streak = 1;
    } else if (today.difference(last).inDays == 0) {
      streak = streak == 0 ? 1 : streak;
    } else if (today.difference(last).inDays == 1) {
      streak += 1;
    } else {
      streak = 1;
    }

    final studiedMinutes = mission.days
        .expand((day) => day.tasks)
        .where((task) => task.isCompleted)
        .fold<int>(0, (sum, task) => sum + task.estimatedMinutes);

    return _refreshMilestones(
      mission.copyWith(
        currentStreak: streak,
        longestStreak: streak > mission.longestStreak
            ? streak
            : mission.longestStreak,
        lastActivityDate: now,
        studyMinutesSpent: studiedMinutes,
        updatedAt: now,
      ),
    );
  }

  MissionModel _refreshMilestones(MissionModel mission) {
    var changed = false;
    final now = DateTime.now();

    final milestones = mission.milestones.map((milestone) {
      if (milestone.isUnlocked) return milestone;
      if (!_isMilestoneEarned(mission, milestone)) return milestone;
      changed = true;
      return milestone.copyWith(isUnlocked: true, unlockedAt: now);
    }).toList();

    if (!changed) return mission;
    return mission.copyWith(milestones: milestones);
  }

  bool _isMilestoneEarned(MissionModel mission, MissionMilestone milestone) {
    switch (milestone.type) {
      case MissionMilestoneType.taskCount:
        return mission.completedRequiredTaskCount >= milestone.threshold;
      case MissionMilestoneType.taskTypeCount:
        final type = milestone.taskTypeFilter;
        if (type == null) return false;
        final completed = mission.allTasks
            .where((task) => task.type == type && task.isCompleted)
            .length;
        return completed >= milestone.threshold;
      case MissionMilestoneType.progressReached:
        return mission.computedProgress >= milestone.threshold;
      case MissionMilestoneType.streakDays:
        return mission.currentStreak >= milestone.threshold;
      case MissionMilestoneType.missionCompleted:
        return mission.computedProgress >= 100;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _persistAll() async {
    await _persistLocal();
    await _persistCloud();
  }

  Future<void> _persistLocal() async {
    try {
      await _localStore.writeAll(
        _missions.values.map((mission) => mission.toJson()).toList(),
      );
    } catch (_) {
      // Local storage is a cache; never surface a failure.
    }
  }

  Future<void> _persistCloud() async {
    final supabase = safeSupabase();
    if (supabase == null) return;
    final userId = _currentUserId;
    if (userId == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final client = supabase.client;

      // Deletions first: a mission removed on this device must not be brought
      // back to life by the next cloud pull.
      if (_removedMissionIds.isNotEmpty) {
        try {
          await client
              .from('missions')
              .delete()
              .eq('user_id', userId)
              .inFilter('id', _removedMissionIds.toList());
          _removedMissionIds.clear();
        } catch (error) {
          debugPrint('MissionMode: cloud delete failed ($error)');
        }
      }

      for (final mission in _missions.values) {
        if (mission.userId != userId) continue;
        try {
          await client.from('missions').upsert({
            'id': mission.id,
            'user_id': userId,
            'title': mission.title,
            'subject': mission.subject,
            'status': mission.status.storageValue,
            'progress': mission.computedProgress,
            'duration_days': mission.durationDays,
            'target_date': mission.targetDate?.toUtc().toIso8601String(),
            'data': jsonDecode(jsonEncode(mission.toJson())),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (error) {
          debugPrint('MissionMode: cloud save skipped ($error)');
          break;
        }
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
