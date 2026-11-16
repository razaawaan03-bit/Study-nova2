import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mission_model.dart';
import '../screens/course_maker/course_preview_screen.dart';
import '../screens/labs/lab_detail_screen.dart';
import '../screens/labs/lab_lesson_screen.dart';
import '../screens/labs/lab_quiz_screen.dart';
import '../screens/missions/mission_quiz_screen.dart';
import '../screens/missions/mission_revision_screen.dart';
import '../screens/study_from_photo/study_from_photo_screen.dart';
import '../screens/study_from_photo/study_library_screen.dart';
import 'lab_service.dart';
import 'mission_content_matcher.dart';
import 'mission_service.dart';

/// Opens a mission task in the Study Nova feature that already does the work.
///
/// Mission Mode never re-implements a learning feature. Every task type is
/// routed to the real screen, and when the content a task points at cannot be
/// reached the student is told exactly why instead of being sent to an empty
/// screen.
class MissionTaskLauncher {
  const MissionTaskLauncher._();

  /// Whether tapping the task should open another screen. Custom study tasks
  /// are ticked off directly in the mission day.
  static bool canOpen(MissionTask task) => task.type != MissionTaskType.custom;

  static Future<void> open(BuildContext context, MissionTask task) async {
    switch (task.type) {
      case MissionTaskType.lesson:
        await _openLesson(context, task);
        break;
      case MissionTaskType.lab:
        await _openLab(context, task);
        break;
      case MissionTaskType.quiz:
        await _openQuiz(context, task);
        break;
      case MissionTaskType.course:
        await _openCourse(context, task);
        break;
      case MissionTaskType.studyFromPhoto:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StudyFromPhotoScreen()));
        break;
      case MissionTaskType.studyLibrary:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StudyLibraryScreen()));
        break;
      case MissionTaskType.revision:
        await _openRevision(context, task);
        break;
      case MissionTaskType.practice:
        await _openMissionQuiz(context, task, MissionQuizMode.practice);
        break;
      case MissionTaskType.mockTest:
        await _openMissionQuiz(context, task, MissionQuizMode.mockTest);
        break;
      case MissionTaskType.finalChallenge:
        await _openMissionQuiz(context, task, MissionQuizMode.finalChallenge);
        break;
      case MissionTaskType.custom:
        break;
    }
  }

  static Future<void> _openLesson(
    BuildContext context,
    MissionTask task,
  ) async {
    final lab = LabService.instance.labById(task.labId);
    if (lab == null) {
      _showMissingContent(
        context,
        'This Study Nova Lab is not available any more. The task is kept so '
        'you can tick it off or add your own task.',
      );
      return;
    }

    final lessonExists = lab.lessons.any(
      (lesson) => lesson.id == task.lessonId,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => lessonExists
            ? LabLessonScreen(labId: lab.id, lessonId: task.lessonId)
            : LabDetailScreen(labId: lab.id),
      ),
    );
  }

  static Future<void> _openLab(BuildContext context, MissionTask task) async {
    final lab = LabService.instance.labById(task.labId);
    if (lab == null) {
      _showMissingContent(
        context,
        'This Study Nova Lab is not available any more. Open Study Nova Labs '
        'to choose another Lab.',
      );
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LabDetailScreen(labId: lab.id)));
  }

  static Future<void> _openQuiz(BuildContext context, MissionTask task) async {
    final lab = LabService.instance.labById(task.labId);
    if (lab != null && lab.quizQuestions.isNotEmpty) {
      // The Lab already owns a quiz, so use it instead of a copy.
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LabQuizScreen(labId: lab.id)));
      return;
    }
    await _openMissionQuiz(context, task, MissionQuizMode.practice);
  }

  static Future<void> _openCourse(
    BuildContext context,
    MissionTask task,
  ) async {
    if (!task.hasCourse) {
      _showMissingContent(
        context,
        'This mission task is not linked to a saved course. Open My Courses to '
        'pick one, or mark the task as done after you study the topic.',
      );
      return;
    }

    // The dialog is pushed on the root navigator, so it must be dismissed on
    // the root navigator too: popping the default navigator would close the
    // course screen underneath instead of the dialog.
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Loading your course...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final course = await MissionContentMatcher().loadCourse(task.courseId!);
    if (!context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();

    if (course == null) {
      _showMissingContent(
        context,
        'This course could not be loaded. It may be offline, or the course '
        'was deleted. Open My Courses to check, or add your own task instead.',
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CoursePreviewScreen(course: course)),
    );
  }

  static Future<void> _openRevision(
    BuildContext context,
    MissionTask task,
  ) async {
    if (!_missionStillExists(task)) {
      _showMissingMission(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MissionRevisionScreen(missionId: task.missionId, topic: task.topic),
      ),
    );
  }

  static Future<void> _openMissionQuiz(
    BuildContext context,
    MissionTask task,
    MissionQuizMode mode,
  ) async {
    if (!_missionStillExists(task)) {
      _showMissingMission(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionQuizScreen(
          missionId: task.missionId,
          mode: mode,
          topic: mode == MissionQuizMode.practice ? task.topic : null,
        ),
      ),
    );
  }

  /// True when the mission a task belongs to is still available to this
  /// student, so the task can be opened rather than landing on a dead screen.
  static bool _missionStillExists(MissionTask task) =>
      MissionService.instance.byId(task.missionId) != null;

  static void _showMissingMission(BuildContext context) {
    _showMissingContent(
      context,
      'This mission is no longer available. Open My Missions to pick another '
      'mission, or create a new one.',
    );
  }

  static void _showMissingContent(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Labs',
          onPressed: () => Navigator.of(context).pushNamed('/labs'),
        ),
      ),
    );
  }
}
