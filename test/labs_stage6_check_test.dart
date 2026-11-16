import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studynova/data/lab_content_data.dart';
import 'package:studynova/models/lab_model.dart';
import 'package:studynova/screens/labs/lab_detail_screen.dart';
import 'package:studynova/screens/labs/lab_lesson_screen.dart';
import 'package:studynova/screens/labs/lab_quiz_screen.dart';
import 'package:studynova/services/lab_service.dart';

void main() {
  final service = LabService.instance;

  Widget wrap(Widget child) => MaterialApp(home: child);

  // A tall surface so lazily built ListView children are all present.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test(
    'all 6 educational starter labs are registered, with no coding labs',
    () {
      final labs = service.allLabs;
      expect(labs.length, 6);
      expect(labs.length, LabContentData.starterLabs().length);
      for (final id in [
        'gsc-circulatory-system',
        'gsc-fundamentals',
        'gk-fundamentals',
        'gk-current-affairs',
        'sst-fundamentals',
        'sst-history',
      ]) {
        expect(service.labById(id), isNotNull, reason: 'missing lab $id');
      }

      // Stage 8: coding labs were removed from the V1.0 product entirely.
      for (final removedId in ['coding-fundamentals', 'html']) {
        expect(
          service.labById(removedId),
          isNull,
          reason: 'coding lab $removedId',
        );
      }
      expect(
        labs.map((lab) => lab.id).toSet().intersection(<String>{
          'coding-fundamentals',
          'html',
        }),
        isEmpty,
      );
      for (final lab in labs) {
        expect(
          lab.title.toLowerCase().contains('coding'),
          isFalse,
          reason: 'coding terminology left in ${lab.id}',
        );
        expect(lab.title.toLowerCase().contains('html'), isFalse);
      }
    },
  );

  test('no LabCategory or LabTopic value refers to coding', () {
    for (final value in LabCategory.values) {
      expect(value.storageValue, isNot('coding'));
      expect(value.label.toLowerCase(), isNot('coding'));
    }
    for (final topic in LabTopic.values) {
      expect(topic.slug.toLowerCase().contains('coding'), isFalse);
      expect(topic.slug.toLowerCase(), isNot('html'));
    }
  });

  test('SST labs carry real lessons and quiz questions', () {
    for (final id in ['sst-fundamentals', 'sst-history']) {
      final lab = service.labById(id)!;
      expect(lab.title, anyOf('SST Fundamentals', 'SST History'));
      expect(lab.lessons, isNotEmpty);
      expect(lab.quizQuestions, isNotEmpty);
      expect(lab.lessons.every((l) => l.content.trim().isNotEmpty), isTrue);
    }
  });

  testWidgets('SST History detail screen lists its lessons and quiz', (
    tester,
  ) async {
    final lab = service.labById('sst-history')!;
    useTallSurface(tester);
    await tester.pumpWidget(wrap(LabDetailScreen(labId: lab.id)));
    await tester.pumpAndSettle();

    expect(find.text('SST History'), findsWidgets);
    for (final lesson in lab.lessons) {
      expect(
        find.text(lesson.title, findRichText: true),
        findsOneWidget,
        reason: 'lesson "${lesson.title}" missing from detail screen',
      );
    }
    expect(find.textContaining('Start Quiz'), findsOneWidget);
  });

  testWidgets('lesson screen shows bundled content and records completion', (
    tester,
  ) async {
    final lab = service.labById('sst-fundamentals')!;
    final lesson = lab.lessons.first;

    useTallSurface(tester);

    await tester.pumpWidget(
      wrap(LabLessonScreen(labId: lab.id, lessonId: lesson.id)),
    );
    await tester.pumpAndSettle();

    expect(find.text(lesson.title), findsOneWidget);
    // First paragraph of the real bundled content.
    final firstParagraph = lesson.content.split('\n\n').first.trim();
    expect(
      find.textContaining(firstParagraph.substring(0, 40)),
      findsOneWidget,
    );
    // Key points block
    expect(find.text('Key Points'), findsOneWidget);
    for (final point in lesson.keyPoints.take(2)) {
      expect(find.textContaining(point.substring(0, 25)), findsWidgets);
    }

    expect(service.isLessonCompleted(lab.id, lesson.id), isFalse);
    await tester.tap(find.text('Mark Complete'));
    await tester.pumpAndSettle();
    expect(service.isLessonCompleted(lab.id, lesson.id), isTrue);
    expect(service.progressPercentFor(lab.id), greaterThan(0));
  });

  testWidgets('quiz scores answers and stores the attempt', (tester) async {
    final lab = service.labById('sst-history')!;
    final questions = lab.quizQuestions;

    useTallSurface(tester);

    await tester.pumpWidget(wrap(LabQuizScreen(labId: lab.id)));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of ${questions.length}'), findsOneWidget);

    for (final question in questions) {
      await tester.tap(find.text(question.correctAnswer).first);
      await tester.pumpAndSettle();
      expect(find.text('Correct'), findsOneWidget);
      if (question != questions.last) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.text('Finish Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Quiz Results'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(
      find.text('${questions.length} of ${questions.length} correct'),
      findsOneWidget,
    );
    expect(service.statsFor(lab.id).attemptCount, 1);
    expect(service.statsFor(lab.id).bestPercentage, 100);

    // Retry resets the run.
    await tester.tap(find.text('Retry Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of ${questions.length}'), findsOneWidget);
  });
}
