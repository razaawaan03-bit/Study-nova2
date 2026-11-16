import 'course_model.dart';
import 'study_scan_model.dart';

/// Thrown when an AI response cannot be turned into a valid course.
///
/// The [message] is always safe to show to the student.
class CourseGenerationException implements Exception {
  const CourseGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return <String>[value.trim()];
  }
  return const <String>[];
}

List<CourseKeyTerm> _asKeyTerms(Object? value) {
  if (value is! List) return const <CourseKeyTerm>[];

  final terms = <CourseKeyTerm>[];
  for (final item in value) {
    if (item is Map) {
      final term = CourseKeyTerm.fromJson(Map<String, dynamic>.from(item));
      if (term.term.isNotEmpty) terms.add(term);
    } else if (item is String && item.trim().isNotEmpty) {
      terms.add(CourseKeyTerm(term: item.trim(), definition: ''));
    }
  }
  return terms;
}

List<QuizQuestion> _asQuizQuestions(Object? value) {
  if (value is! List) return const <QuizQuestion>[];

  final questions = <QuizQuestion>[];
  for (final item in value) {
    if (item is Map) {
      final question = QuizQuestion.fromJson(Map<String, dynamic>.from(item));
      if (question.question.isNotEmpty) questions.add(question);
    }
  }
  return questions;
}

/// A key term with its definition inside a topic.
class CourseKeyTerm {
  const CourseKeyTerm({required this.term, required this.definition});

  final String term;
  final String definition;

  factory CourseKeyTerm.fromJson(Map<String, dynamic> json) {
    return CourseKeyTerm(
      term: (json['term'] ?? '').toString(),
      definition: (json['definition'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'term': term, 'definition': definition};
}

/// One topic inside a course chapter.
class CourseTopic {
  const CourseTopic({
    required this.title,
    this.id,
    this.explanation = '',
    this.simpleExplanation = '',
    this.importantPoints = const <String>[],
    this.examples = const <String>[],
    this.keyTerms = const <CourseKeyTerm>[],
    this.questions = const <String>[],
    this.revisionNotes = const <String>[],
    this.order = 0,
  });

  final String? id;
  final String title;
  final String explanation;
  final String simpleExplanation;
  final List<String> importantPoints;
  final List<String> examples;
  final List<CourseKeyTerm> keyTerms;
  final List<String> questions;
  final List<String> revisionNotes;
  final int order;

  /// True when the topic carries something worth reading.
  bool get hasContent =>
      explanation.trim().isNotEmpty || simpleExplanation.trim().isNotEmpty;

  factory CourseTopic.fromJson(Map<String, dynamic> json, {int order = 0}) {
    return CourseTopic(
      id: json['id']?.toString(),
      title: (json['title'] ?? '').toString().trim(),
      explanation: (json['explanation'] ?? '').toString().trim(),
      simpleExplanation: (json['simple_explanation'] ?? '').toString().trim(),
      importantPoints: _asStringList(json['important_points']),
      examples: _asStringList(json['examples']),
      keyTerms: _asKeyTerms(json['key_terms']),
      questions: _asStringList(json['questions']),
      revisionNotes: _asStringList(json['revision_notes']),
      order: order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'explanation': explanation,
    'simple_explanation': simpleExplanation,
    'important_points': importantPoints,
    'examples': examples,
    'key_terms': keyTerms.map((term) => term.toJson()).toList(),
    'questions': questions,
    'revision_notes': revisionNotes,
    'order': order,
  };
}

/// One chapter of a generated course, with its topics.
class CourseChapter {
  const CourseChapter({
    required this.title,
    this.id,
    this.description = '',
    this.topics = const <CourseTopic>[],
    this.order = 0,
  });

  final String? id;
  final String title;
  final String description;
  final List<CourseTopic> topics;
  final int order;

  factory CourseChapter.fromJson(Map<String, dynamic> json, {int order = 0}) {
    final rawTopics = json['topics'];
    final topics = <CourseTopic>[];
    if (rawTopics is List) {
      for (var index = 0; index < rawTopics.length; index++) {
        final item = rawTopics[index];
        if (item is Map) {
          topics.add(
            CourseTopic.fromJson(Map<String, dynamic>.from(item), order: index),
          );
        }
      }
    }

    return CourseChapter(
      id: json['id']?.toString(),
      title: (json['title'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      topics: topics,
      order: order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'topics': topics.map((topic) => topic.toJson()).toList(),
    'order': order,
  };
}

/// The multiple-choice quiz belonging to one chapter.
class CourseQuiz {
  const CourseQuiz({
    required this.questions,
    this.chapterId,
    this.title = 'Chapter Quiz',
  });

  final String? chapterId;
  final String title;
  final List<QuizQuestion> questions;

  bool get isEmpty => questions.isEmpty;

  factory CourseQuiz.fromJson(Map<String, dynamic> json) {
    return CourseQuiz(
      chapterId: json['chapter_id']?.toString(),
      title: (json['title'] ?? 'Chapter Quiz').toString(),
      questions: _asQuizQuestions(json['questions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'chapter_id': chapterId,
    'title': title,
    'questions': questions.map((question) => question.toJson()).toList(),
  };
}

/// Everything the AI generated for one course: the setup plus its content.
class GeneratedCourse {
  const GeneratedCourse({
    required this.course,
    required this.chapters,
    this.quizzes = const <CourseQuiz>[],
    this.mindMapData = const <String, dynamic>{},
    this.revisionNotes = const <String>[],
  });

  /// The course setup, refined with the AI title/description.
  final CourseModel course;
  final List<CourseChapter> chapters;
  final List<CourseQuiz> quizzes;

  /// Same shape the existing MindMapWidget expects.
  final Map<String, dynamic> mindMapData;
  final List<String> revisionNotes;

  int get chapterCount => chapters.length;

  int get topicCount =>
      chapters.fold(0, (total, chapter) => total + chapter.topics.length);

  int get quizCount => quizzes.where((quiz) => !quiz.isEmpty).length;

  int get questionCount =>
      quizzes.fold(0, (total, quiz) => total + quiz.questions.length);

  /// Quiz generated for a chapter, when there is one.
  CourseQuiz? quizForChapter(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= quizzes.length) return null;
    final quiz = quizzes[chapterIndex];
    return quiz.isEmpty ? null : quiz;
  }

  GeneratedCourse copyWith({
    CourseModel? course,
    List<CourseChapter>? chapters,
    List<CourseQuiz>? quizzes,
    Map<String, dynamic>? mindMapData,
    List<String>? revisionNotes,
  }) {
    return GeneratedCourse(
      course: course ?? this.course,
      chapters: chapters ?? this.chapters,
      quizzes: quizzes ?? this.quizzes,
      mindMapData: mindMapData ?? this.mindMapData,
      revisionNotes: revisionNotes ?? this.revisionNotes,
    );
  }

  factory GeneratedCourse.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'];
    final chapters = <CourseChapter>[];
    if (rawChapters is List) {
      for (var index = 0; index < rawChapters.length; index++) {
        final item = rawChapters[index];
        if (item is Map) {
          chapters.add(
            CourseChapter.fromJson(
              Map<String, dynamic>.from(item),
              order: index,
            ),
          );
        }
      }
    }

    final rawQuizzes = json['quizzes'];
    final quizzes = <CourseQuiz>[];
    if (rawQuizzes is List) {
      for (final item in rawQuizzes) {
        if (item is Map) {
          quizzes.add(CourseQuiz.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawMindMap = json['mind_map'];

    return GeneratedCourse(
      course: CourseModel.fromJson(
        json['course'] is Map
            ? Map<String, dynamic>.from(json['course'] as Map)
            : const <String, dynamic>{},
      ),
      chapters: chapters,
      quizzes: quizzes,
      mindMapData: rawMindMap is Map
          ? Map<String, dynamic>.from(rawMindMap)
          : const <String, dynamic>{},
      revisionNotes: _asStringList(json['revision_notes']),
    );
  }

  Map<String, dynamic> toJson() => {
    'course': course.toJson(),
    'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
    'mind_map': mindMapData,
    'revision_notes': revisionNotes,
  };
}
