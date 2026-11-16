import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/lab_content_data.dart';
import '../models/lab_model.dart';
import '../models/mission_model.dart';
import '../utils/supabase_availability.dart';
import 'custom_lab_service.dart';
import 'mission_service.dart';

/// Owns the Study Nova Labs catalogue and the signed-in user's progress.
///
/// The catalogue itself is *not* stored here: it is always the bundled
/// [LabContentData.starterLabs] content, so there is exactly one source of Lab
/// content in the app. This service only layers the user's progress on top of
/// it and notifies listeners when that progress changes.
///
/// Progress is stored on the device with `shared_preferences`, keyed per
/// account, so a student who finishes a Lab still has it finished after
/// closing the app. It is read back by [load]; a Supabase backed
/// implementation can be layered on later without touching the UI.
class LabService extends ChangeNotifier {
  LabService._internal() {
    // Fire and forget: the catalogue is usable immediately, and every screen
    // that shows progress calls `load()` itself.
    unawaited(load());
    unawaited(CustomLabService.instance.load());
    CustomLabService.instance.addListener(_onCustomLabChanged);
  }

  void _onCustomLabChanged() {
    notifyListeners();
  }

  static final LabService instance = LabService._internal();

  static const String _progressKeyPrefix = 'studynova.lab.progress.';
  static const String _attemptsKeyPrefix = 'studynova.lab.attempts.';

  bool _isLoaded = false;

  /// True once stored progress has been read back into memory.
  bool get isLoaded => _isLoaded;

  /// The bundled catalogue. Rebuilt on demand so callers can never mutate the
  /// shared list of Lab definitions.
  List<LabModel> get allLabs => List<LabModel>.unmodifiable([
    ...LabContentData.starterLabs(),
    ...CustomLabService.instance.customLabs,
  ]);

  /// Lab ids present in the bundled catalogue.
  List<String> get labIds => allLabs.map((lab) => lab.id ?? '').toList();

  /// The bundled Lab with this id, or null when it does not exist.
  LabModel? labById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final lab in allLabs) {
      if (lab.id == id) return lab;
    }
    return null;
  }

  /// Bundled Labs grouped by category, in [LabCategory] declaration order and
  /// with empty categories removed. "All" is represented by a null filter.
  Map<LabCategory?, List<LabModel>> labsByCategory({LabCategory? selected}) {
    final grouped = <LabCategory?, List<LabModel>>{};
    for (final category in LabCategory.values) {
      if (selected != null && category != selected) continue;
      final labs = allLabs
          .where((lab) => lab.category == category)
          .toList(growable: false);
      if (labs.isNotEmpty) grouped[category] = labs;
    }
    return grouped;
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  final Map<String, LabProgress> _progress = <String, LabProgress>{};
  final Map<String, List<QuizAttempt>> _attempts =
      <String, List<QuizAttempt>>{};

  /// Progress for one Lab, or an empty [LabProgress] when the user has not
  /// started it. Never null, so callers do not need null handling.
  LabProgress progressFor(String? labId) {
    if (labId == null || labId.isEmpty) {
      return const LabProgress(labId: '');
    }
    return _progress[labId] ?? LabProgress(labId: labId);
  }

  /// Whether one lesson of one Lab is done.
  bool isLessonCompleted(String? labId, String? lessonId) =>
      progressFor(labId).isLessonCompleted(lessonId);

  /// Overall completion of a Lab, 0-100.
  int progressPercentFor(String? labId) => progressFor(labId).progressPercent;

  /// Recorded quiz attempts for a Lab, oldest first.
  List<QuizAttempt> attemptsFor(String? labId) =>
      List<QuizAttempt>.unmodifiable(_attempts[labId ?? ''] ?? const []);

  /// Best-score summary for a Lab, or empty stats when never attempted.
  LabQuizStats statsFor(String? labId) =>
      LabQuizStats.fromAttempts(attemptsFor(labId));

  /// The Lab with the recorded progress, used by the Home screen summary.
  /// Returns the first started Lab that is not finished, else the most
  /// recently updated one, else null.
  LabModel? get continueLab {
    final started =
        _progress.values
            .where((progress) => progress.progressPercent > 0)
            .toList()
          ..sort((a, b) {
            if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
            final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
    if (started.isEmpty) return null;
    return labById(started.first.labId);
  }

  /// Marks a lesson complete (or incomplete) and recomputes the Lab's progress.
  ///
  /// Returns the updated [LabProgress]. Does nothing when [labId] or
  /// [lessonId] is missing, since there would be nothing to key the record on.
  Future<LabProgress> setLessonCompleted(
    String? labId,
    String? lessonId, {
    bool completed = true,
  }) async {
    if (labId == null || labId.isEmpty) {
      return const LabProgress(labId: '');
    }
    if (lessonId == null || lessonId.isEmpty) {
      return progressFor(labId);
    }

    final existing = progressFor(labId);
    final completedIds = <String>[...existing.completedLessonIds];
    if (completed) {
      if (!completedIds.contains(lessonId)) completedIds.add(lessonId);
    } else {
      completedIds.remove(lessonId);
    }

    final total = labById(labId)?.lessons.length ?? 0;
    final percent = total <= 0
        ? 0
        : ((completedIds.length / total) * 100).round().clamp(0, 100);

    final updated = existing.copyWith(
      completedLessonIds: completedIds,
      lastLessonId: lessonId,
      lastLessonIndex: _indexOfLesson(labId, lessonId),
      progressPercent: percent,
      isCompleted: total > 0 && completedIds.length >= total,
      updatedAt: DateTime.now(),
    );

    _progress[labId] = updated;
    final lab = labById(labId);
    if (lab != null) {
      final refreshed = lab.copyWith(
        progress: percent,
        isCompleted: total > 0 && completedIds.length >= total,
        lastStudiedAt: DateTime.now(),
      );
      CustomLabService.instance.saveLabProgress(refreshed);
      final missionMatches = MissionService.instance.missions.where(
        (mission) => mission.customLabId == labId,
      );
      for (final mission in missionMatches) {
        final task = mission.allTasks.firstWhere(
          (candidate) =>
              candidate.labId == labId && candidate.lessonId == lessonId,
          orElse: () => const MissionTask(
            id: '',
            missionId: '',
            dayNumber: 1,
            type: MissionTaskType.lesson,
            title: '',
          ),
        );
        if (task.id.isEmpty) continue;
        final isAlreadyDone = task.isCompleted;
        if (completed && !isAlreadyDone) {
          await MissionService.instance.setTaskCompleted(mission.id, task.id);
        } else if (!completed && isAlreadyDone) {
          await MissionService.instance.setTaskCompleted(
            mission.id,
            task.id,
            completed: false,
          );
        }
      }
    }
    await _persist();
    notifyListeners();
    return updated;
  }

  /// The first lesson of a Lab that is not yet complete, used to drive the
  /// "Continue" action. Null when the Lab is finished or has no lessons.
  LabLesson? nextLessonFor(String? labId) {
    final lab = labById(labId);
    if (lab == null) return null;
    final progress = progressFor(lab.id);
    for (final lesson in lab.lessons) {
      if (!progress.isLessonCompleted(lesson.id)) return lesson;
    }
    return null;
  }

  /// The lesson after [lessonId] in the same Lab, or null at the end.
  LabLesson? lessonAfter(String? labId, String? lessonId) {
    final lab = labById(labId);
    if (lab == null) return null;
    final index = _indexOfLesson(labId, lessonId);
    if (index < 0 || index + 1 >= lab.lessons.length) return null;
    return lab.lessons[index + 1];
  }

  /// The lesson before [lessonId] in the same Lab, or null at the start.
  LabLesson? lessonBefore(String? labId, String? lessonId) {
    final lab = labById(labId);
    if (lab == null) return null;
    final index = _indexOfLesson(labId, lessonId);
    if (index <= 0) return null;
    return lab.lessons[index - 1];
  }

  /// Stores a finished quiz run and marks the Lab complete once the user has
  /// scored full marks on every question.
  Future<QuizAttempt?> recordQuizAttempt(
    String? labId, {
    required int score,
    required int totalQuestions,
  }) async {
    if (labId == null || labId.isEmpty || totalQuestions <= 0) return null;

    final attempt = QuizAttempt(
      labId: labId,
      score: score,
      totalQuestions: totalQuestions,
      attemptedAt: DateTime.now(),
    );
    _attempts.putIfAbsent(labId, () => <QuizAttempt>[]).add(attempt);
    await _persist();
    notifyListeners();
    return attempt;
  }

  /// Drops all progress, e.g. on sign out. Does not touch Lab content.
  ///
  /// The stored progress for the account that signs out is removed as well, so
  /// the next student on a shared device starts from a clean slate. Await this
  /// before reading progress back, otherwise the in-memory clear and the stored
  /// clear can finish out of order.
  Future<void> reset() async {
    _progress.clear();
    _attempts.clear();
    _isLoaded = true;
    notifyListeners();
    await _clearStored();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Reads stored progress back into memory. Safe to call more than once.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = _storageScope();

      final progressJson = prefs.getString('$_progressKeyPrefix$scope');
      if (progressJson != null && progressJson.isNotEmpty) {
        final decoded = jsonDecode(progressJson);
        if (decoded is Map) {
          _progress.clear();
          decoded.forEach((key, value) {
            if (key is String && value is Map) {
              try {
                _progress[key] = LabProgress.fromJson(
                  Map<String, dynamic>.from(value),
                );
              } catch (_) {
                // Skip a single unreadable Lab rather than all of them.
              }
            }
          });
        }
      }

      final attemptsJson = prefs.getString('$_attemptsKeyPrefix$scope');
      if (attemptsJson != null && attemptsJson.isNotEmpty) {
        final decoded = jsonDecode(attemptsJson);
        if (decoded is Map) {
          _attempts.clear();
          decoded.forEach((key, value) {
            if (key is String && value is List) {
              _attempts[key] = value
                  .whereType<Map>()
                  .map(
                    (item) =>
                        QuizAttempt.fromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList();
            }
          });
        }
      }
    } catch (error) {
      // No platform storage (a test, or a locked preferences file): the app
      // keeps running with in-memory progress rather than failing.
      debugPrint('LabService: could not read stored Lab progress ($error)');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = _storageScope();

      await prefs.setString(
        '$_progressKeyPrefix$scope',
        jsonEncode(
          _progress.map(
            (labId, progress) => MapEntry(labId, progress.toJson()),
          ),
        ),
      );
      await prefs.setString(
        '$_attemptsKeyPrefix$scope',
        jsonEncode(
          _attempts.map(
            (labId, attempts) => MapEntry(
              labId,
              attempts.map((attempt) => attempt.toJson()).toList(),
            ),
          ),
        ),
      );
    } catch (error) {
      debugPrint('LabService: could not store Lab progress ($error)');
    }
  }

  Future<void> _clearStored() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = _storageScope();
      await prefs.remove('$_progressKeyPrefix$scope');
      await prefs.remove('$_attemptsKeyPrefix$scope');
    } catch (error) {
      debugPrint('LabService: could not clear Lab progress ($error)');
    }
  }

  /// Progress is stored per account so a shared device does not mix two
  /// students up. Unsigned-in work is kept under `guest`.
  String _storageScope() {
    final userId = safeSupabase()?.client.auth.currentUser?.id;
    return userId ?? 'guest';
  }

  /// Clears only the in-memory copies, leaving stored progress untouched.
  ///
  /// This is what an app restart looks like from the service's point of view,
  /// and it keeps the persistence path testable.
  @visibleForTesting
  void debugClearInMemory() {
    _progress.clear();
    _attempts.clear();
    _isLoaded = false;
  }

  int _indexOfLesson(String? labId, String? lessonId) {
    final lab = labById(labId);
    if (lab == null || lessonId == null) return -1;
    return lab.lessons.indexWhere((lesson) => lesson.id == lessonId);
  }
}
