/// Shared helpers for building bundled Lab content in a compact, readable way.
library;

import '../../models/lab_model.dart';

LabLesson lessonOf(
  String id,
  String title,
  String content,
  List<String> keyPoints, {
  int durationMinutes = 8,
}) {
  return LabLesson(
    id: id,
    title: title,
    content: content,
    keyPoints: keyPoints,
    durationMinutes: durationMinutes,
  );
}

QuizQuestion questionOf(
  String id,
  String question,
  List<String> options,
  String correctAnswer,
  String explanation,
) {
  return QuizQuestion(
    id: id,
    question: question,
    options: options,
    correctAnswer: correctAnswer,
    explanation: explanation,
    type: 'multiple_choice',
  );
}

/// Builds a standard (non-custom) Lab.
LabModel labOf({
  required String id,
  required String title,
  required String description,
  required LabCategory category,
  List<LabLesson> lessons = const <LabLesson>[],
  List<QuizQuestion> questions = const <QuizQuestion>[],
  LabDifficulty difficulty = LabDifficulty.beginner,
}) {
  return LabModel(
    id: id,
    title: title,
    description: description,
    category: category,
    difficulty: difficulty,
    lessons: lessons,
    quizQuestions: questions,
  );
}
