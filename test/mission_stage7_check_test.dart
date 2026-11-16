import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studynova/data/mission_catalog.dart';
import 'package:studynova/models/mission_model.dart';
import 'package:studynova/screens/missions/mission_create_screen.dart';
import 'package:studynova/screens/missions/mission_day_screen.dart';
import 'package:studynova/services/lab_service.dart';
import 'package:studynova/services/mission_content_matcher.dart';
import 'package:studynova/services/mission_planning_service.dart';
import 'package:studynova/services/mission_service.dart';

void main() {
  final missionService = MissionService.instance;
  final labService = LabService.instance;

  const sstSetup = MissionSetup(
    title: 'Class 10 Indian Polity Mastery',
    goal: MissionGoal.learnSubject,
    subjects: <String>['Indian Polity'],
    topics: <String>['The Constitution', 'Fundamental Rights and Duties'],
    durationDays: 7,
    dailyStudyMinutes: 30,
  );

  setUp(() async {
    await missionService.reset();
    await missionService.load();
    labService.reset();
  });

  Widget wrap(Widget child) => MaterialApp(home: child);

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // ---------------------------------------------------------------------------
  // Catalog
  // ---------------------------------------------------------------------------

  test('catalog offers subjects, durations and default topics', () {
    expect(MissionCatalog.subjects.length, 7);
    expect(MissionCatalog.byName('Indian Polity'), isNotNull);
    expect(MissionCatalog.byName('Not A Subject'), isNull);
    expect(MissionCatalog.durationOptions, containsAll(<int>[3, 7, 14, 30]));
    expect(MissionCatalog.dailyStudyOptions, contains(30));

    // Stage 8: coding subjects were removed from the wizard.
    for (final removed in ['Coding', 'HTML', 'Computer Science']) {
      expect(
        MissionCatalog.byName(removed),
        isNull,
        reason: 'removed $removed',
      );
    }
    for (final subject in MissionCatalog.subjects) {
      expect(
        subject.category?.storageValue,
        isNot('coding'),
        reason: 'coding subject left in the wizard: ${subject.name}',
      );
    }

    final topics = MissionCatalog.defaultTopicsFor(<String>['Indian Polity']);
    expect(topics, isNotEmpty);
    expect(
      MissionCatalog.keywordsFor(<String>['Indian Polity']),
      contains('constitution'),
    );
  });

  // ---------------------------------------------------------------------------
  // Offline planning
  // ---------------------------------------------------------------------------

  test('local planner builds a complete offline mission', () async {
    final plan = await MissionPlanningService.instance.createMission(sstSetup);

    final mission = plan.mission;
    expect(plan.usedAi, isFalse, reason: 'no AI is configured in tests');
    expect(mission.title, 'Class 10 Indian Polity Mastery');
    expect(mission.durationDays, 7);
    expect(mission.days.length, 7);
    expect(mission.status, MissionStatus.active);
    expect(mission.computedProgress, 0);
    expect(mission.topics, isNotEmpty);

    for (final day in mission.days) {
      expect(day.tasks, isNotEmpty, reason: 'day ${day.dayNumber} is empty');
      expect(day.progressPercent, 0);
      expect(
        day.tasks.every((task) => task.dayNumber == day.dayNumber),
        isTrue,
      );
    }

    // The Final Challenge closes the mission.
    expect(mission.finalChallengeTask, isNotNull);
    expect(mission.finalChallengeTask!.dayNumber, mission.durationDays);

    // Every referenced Lab really exists in Study Nova Labs.
    for (final task in mission.allTasks) {
      if (task.hasLab) {
        expect(
          labService.labById(task.labId),
          isNotNull,
          reason: 'task ${task.id} points at missing lab ${task.labId}',
        );
      }
    }

    // The plan points at real content for the chosen subject.
    expect(
      mission.allTasks.where((task) => task.hasLab).isNotEmpty,
      isTrue,
      reason: 'an SST mission should link to the bundled SST Labs',
    );

    // Daily study time is respected, not exceeded wildly.
    for (final day in mission.days) {
      final total = day.tasks.fold<int>(
        0,
        (sum, task) => sum + task.estimatedMinutes,
      );
      expect(total, greaterThan(0));
      expect(total, lessThanOrEqualTo(30 * 3));
    }

    // Milestones start locked.
    expect(mission.milestones, isNotEmpty);
    expect(mission.milestones.every((m) => !m.isUnlocked), isTrue);
  });

  test('missions created from a custom target date honour the date', () async {
    final target = DateTime.now().add(const Duration(days: 5));
    final setup = sstSetup.copyWith(durationDays: 30, customTargetDate: target);
    final plan = await MissionPlanningService.instance.createMission(setup);
    expect(plan.mission.targetDate, target);
    // Today is day one and the target date is the last day of the mission.
    expect(plan.mission.days.length, plan.mission.durationDays);
    expect(plan.mission.days.length, inInclusiveRange(4, 6));
    expect(plan.mission.days.last.dayNumber, plan.mission.durationDays);
  });

  test('content matcher finds the bundled SST Labs by keyword', () async {
    final matcher = MissionContentMatcher();
    final matches = await matcher.matchTopics(
      subjects: const <String>['Indian Polity'],
      topics: const <String>['Indian Constitution'],
    );
    expect(matches, isNotEmpty);
    expect(matches.first.hasLab, isTrue);
    expect(labService.labById(matches.first.lab!.id), isNotNull);
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  test('a mission survives a JSON round trip', () async {
    final plan = await MissionPlanningService.instance.createMission(sstSetup);
    final original = plan.mission;
    final restored = MissionModel.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.durationDays, original.durationDays);
    expect(restored.dailyStudyMinutes, original.dailyStudyMinutes);
    expect(restored.days.length, original.days.length);
    expect(restored.allTasks.length, original.allTasks.length);
    expect(restored.milestones.length, original.milestones.length);
    expect(restored.computedProgress, original.computedProgress);
    expect(
      restored.days.last.tasks.last.title,
      original.days.last.tasks.last.title,
    );
  });

  // ---------------------------------------------------------------------------
  // MissionService
  // ---------------------------------------------------------------------------

  test('creating a mission makes it the featured mission on Home', () async {
    final result = await missionService.createMission(sstSetup);
    expect(missionService.missions.length, 1);
    expect(missionService.featuredMission?.id, result.mission.id);
    expect(missionService.activeMissions.length, 1);
    expect(missionService.byId(result.mission.id), isNotNull);
  });

  test('completing a task updates progress, streak and milestones', () async {
    final result = await missionService.createMission(sstSetup);
    final id = result.mission.id;
    final task = result.mission.days.first.tasks.first;
    expect(task.isCompleted, isFalse);
    expect(result.mission.currentStreak, 0);

    var mission = (await missionService.setTaskCompleted(id, task.id))!;
    expect(mission.progress, greaterThan(0));
    expect(mission.computedProgress, mission.progress);
    expect(mission.completedRequiredTaskCount, 1);
    expect(mission.currentStreak, 1);
    expect(mission.longestStreak, 1);
    expect(mission.studyMinutesSpent, task.estimatedMinutes);

    // The first milestone is earned after three tasks.
    final firstThree = result.mission.requiredTasks.take(3).toList();
    for (final required in firstThree.skip(1)) {
      mission = (await missionService.setTaskCompleted(id, required.id))!;
    }
    expect(mission.completedRequiredTaskCount, 3);
    final firstMilestone = mission.milestones.firstWhere(
      (m) => m.id == 'm-first-steps',
    );
    expect(firstMilestone.isUnlocked, isTrue);
    expect(firstMilestone.unlockedAt, isNotNull);

    // Unchecking puts the progress back.
    mission = (await missionService.setTaskCompleted(
      id,
      task.id,
      completed: false,
    ))!;
    expect(mission.completedRequiredTaskCount, 2);
    expect(mission.progress, lessThan(100));
  });

  test(
    'a mission task that links to a Lab lesson syncs Study Nova Labs',
    () async {
      final result = await missionService.createMission(
        sstSetup.copyWith(
          durationDays: 3,
          preference: MissionPreference.reading,
        ),
      );
      final mission = result.mission;
      final lessonTask = mission.allTasks.firstWhere(
        (task) => task.hasLab && task.hasLesson,
        orElse: () =>
            throw StateError('planner produced no lesson-linked task'),
      );
      final lab = labService.labById(lessonTask.labId)!;
      final lessonId = lessonTask.lessonId!;
      expect(labService.isLessonCompleted(lab.id, lessonId), isFalse);

      await missionService.setTaskCompleted(mission.id, lessonTask.id);

      expect(labService.isLessonCompleted(lab.id, lessonId), isTrue);
      expect(labService.progressPercentFor(lab.id), greaterThan(0));
    },
  );

  test('finishing every required task completes the mission', () async {
    final result = await missionService.createMission(sstSetup);
    final id = result.mission.id;
    final requiredIds = result.mission.requiredTasks.map((t) => t.id).toList();

    MissionModel? mission;
    for (final taskId in requiredIds) {
      mission = await missionService.setTaskCompleted(id, taskId);
    }
    expect(mission, isNotNull);
    expect(mission!.computedProgress, 100);
    expect(mission.status, MissionStatus.completed);
    expect(mission.isCompleted, isTrue);
    expect(
      mission.milestones
          .firstWhere((m) => m.id == 'm-mission-complete')
          .isUnlocked,
      isTrue,
    );
    expect(
      mission.milestones.firstWhere((m) => m.id == 'm-halfway').isUnlocked,
      isTrue,
    );
    expect(missionService.completedMissions.length, 1);
    expect(missionService.featuredMission, isNull);
  });

  test('custom tasks are optional and never block completion', () async {
    final result = await missionService.createMission(sstSetup);
    final id = result.mission.id;

    final withCustom = await missionService.addCustomTask(
      missionId: id,
      dayNumber: 1,
      title: 'Revise my class notes',
    );
    expect(withCustom, isNotNull);
    final custom = withCustom!.allTasks.firstWhere(
      (t) => t.type == MissionTaskType.custom,
    );
    expect(custom.isRequired, isFalse);

    for (final taskId in result.mission.requiredTasks.map((t) => t.id)) {
      await missionService.setTaskCompleted(id, taskId);
    }
    final finished = missionService.byId(id)!;
    expect(finished.progress, 100);
    expect(
      finished.allTasks.firstWhere((t) => t.id == custom.id).isCompleted,
      isFalse,
    );
  });

  test('quiz results drive the recommended revision topics', () async {
    final result = await missionService.createMission(sstSetup);
    final id = result.mission.id;
    final topic = result.mission.topics.first;

    final updated = await missionService.recordQuizRun(
      id,
      results: <MissionTopicResult>[
        MissionTopicResult(
          topic: topic,
          correct: 1,
          total: 5,
          attemptedAt: DateTime.now(),
        ),
      ],
      percentage: 20,
    );
    expect(updated, isNotNull);
    expect(updated!.quizResults.length, 1);
    expect(updated.quizResults.first.percentage, 20);
    expect(updated.quizResults.first.needsRevision, isTrue);
    expect(updated.revisionSuggestions.map((r) => r.topic), contains(topic));

    final challenge = await missionService.recordQuizRun(
      id,
      results: const <MissionTopicResult>[],
      isFinalChallenge: true,
      percentage: 80,
    );
    expect(challenge!.isFinalChallengeDone, isTrue);
    expect(challenge.finalChallengeBestPercentage, 80);
  });

  test('missions can be paused, resumed and deleted', () async {
    final result = await missionService.createMission(sstSetup);
    final id = result.mission.id;

    final paused = await missionService.togglePause(id);
    expect(paused!.status, MissionStatus.paused);
    expect(missionService.pausedMissions.length, 1);
    expect(missionService.featuredMission, isNull);

    final resumed = await missionService.togglePause(id);
    expect(resumed!.status, MissionStatus.active);
    expect(missionService.activeMissions.length, 1);

    await missionService.deleteMission(id);
    expect(missionService.missions, isEmpty);
    expect(missionService.byId(id), isNull);
  });

  // ---------------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------------

  testWidgets('the creation wizard asks for a name before the first step', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap(const MissionCreateScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Create New Mission'), findsOneWidget);
    expect(find.text('Step 1 of 8 · Mission name'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(
      find.textContaining('Give your mission a name'),
      findsOneWidget,
      reason: 'the wizard must ask for a name before moving on',
    );
    expect(find.text('Step 1 of 8 · Mission name'), findsOneWidget);
  });

  testWidgets('the creation wizard advances once the mission is named', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap(const MissionCreateScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'My Polity Mission');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 8 · Learning goal'), findsOneWidget);
  });

  testWidgets('the day screen lists the real tasks of that day', (
    tester,
  ) async {
    // Mission planning does real async work (local persistence), which must run
    // outside the fake-async zone widget tests use.
    final result = await tester.runAsync(
      () => missionService.createMission(sstSetup),
    );
    final mission = result!.mission;
    final day = mission.days.first;

    useTallSurface(tester);
    await tester.pumpWidget(
      wrap(MissionDayScreen(missionId: mission.id, dayNumber: day.dayNumber)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Day 1 of 7'), findsOneWidget);
    for (final task in day.tasks) {
      expect(
        find.text(task.title, findRichText: true),
        findsOneWidget,
        reason: 'task "${task.title}" missing from the day screen',
      );
    }
    expect(find.text('Add your own task'), findsOneWidget);
  });

  testWidgets('checking a task off the day screen updates mission progress', (
    tester,
  ) async {
    final result = await tester.runAsync(
      () => missionService.createMission(sstSetup),
    );
    final mission = result!.mission;
    final day = mission.days.first;
    final task = day.tasks.first;

    useTallSurface(tester);
    await tester.pumpWidget(
      wrap(MissionDayScreen(missionId: mission.id, dayNumber: day.dayNumber)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    // Let the real async work (Labs sync + persistence) finish.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    final updated = missionService.byId(mission.id)!;
    expect(updated.completedRequiredTaskCount, 1);
    expect(
      updated.allTasks.firstWhere((t) => t.id == task.id).isCompleted,
      isTrue,
    );
  });
}
