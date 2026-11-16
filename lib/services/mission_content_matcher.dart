import '../data/mission_catalog.dart';
import '../models/course_content_model.dart';
import '../models/lab_model.dart';
import '../services/course_service.dart';
import '../services/lab_service.dart';
import '../utils/supabase_availability.dart';

/// A course the student already saved, referenced by a mission task.
class MissionCourseRef {
  const MissionCourseRef({
    required this.id,
    required this.title,
    this.subject = '',
    this.chapterCount = 0,
  });

  final String id;
  final String title;
  final String subject;
  final int chapterCount;
}

/// The best existing Study Nova content for one mission topic.
///
/// Every field is either null or points at content that really exists:
/// [lab] and [lesson] come from [LabService], [course] from `CourseService`.
class MissionTopicMatch {
  const MissionTopicMatch({
    required this.topic,
    this.lab,
    this.lesson,
    this.course,
    this.courseChapterIndex = 0,
  });

  final String topic;
  final LabModel? lab;
  final LabLesson? lesson;
  final MissionCourseRef? course;
  final int courseChapterIndex;

  bool get hasLab => lab != null;

  bool get hasLesson => lesson != null;

  bool get hasCourse => course != null;

  /// True when nothing in Study Nova covers this topic, so the planner must
  /// create a self-study task and say so instead of inventing an id.
  bool get hasNoContent => lab == null && course == null;
}

/// Finds existing Study Nova content for the subjects and topics a mission was
/// created from.
///
/// Only two sources are consulted, and neither stores content:
///  * [LabService] — the bundled Study Nova Labs, their lessons and quizzes.
///  * `CourseService` — courses the student has already saved in Supabase.
///
/// When Supabase is unavailable (offline, or the `courses` table is missing)
/// course matching is skipped, so the planner falls back to Lab content and
/// self-study tasks.
class MissionContentMatcher {
  MissionContentMatcher({LabService? labService})
    : _labService = labService ?? LabService.instance;

  final LabService _labService;

  /// Matches every mission topic against the existing content.
  Future<List<MissionTopicMatch>> matchTopics({
    required List<String> subjects,
    required List<String> topics,
    String customText = '',
  }) async {
    final keywords = MissionCatalog.keywordsFor(
      subjects,
      customText: customText,
    );
    final labs = matchingLabs(keywords);

    final courses = await _loadCourses();
    final courseList = courses ?? const <MissionCourseRef>[];

    return topics.map((topic) {
      final topicKeywords = <String>[
        topic.toLowerCase(),
        ..._splitTopic(topic),
      ];

      final lab = _bestLab(topicKeywords, labs);
      final lesson = lab == null ? null : _bestLesson(topicKeywords, lab);
      final course = _bestCourse(topicKeywords, courseList);
      final chapterIndex = course == null
          ? 0
          : (_splitTopic(topic).length) %
                (course.chapterCount == 0 ? 1 : course.chapterCount);

      return MissionTopicMatch(
        topic: topic,
        lab: lab,
        lesson: lesson,
        course: course,
        courseChapterIndex: chapterIndex,
      );
    }).toList();
  }

  /// Bundled Labs whose title, description, category or lesson titles mention
  /// one of the keywords. Scores higher when more keywords match.
  List<LabModel> matchingLabs(List<String> keywords) {
    if (keywords.isEmpty) return const <LabModel>[];

    final scored = <LabModel, int>{};
    for (final lab in _labService.allLabs) {
      final haystack = <String>[
        lab.title,
        lab.description,
        lab.category.label,
        for (final lesson in lab.lessons) ...[lesson.title, lesson.content],
      ].join(' ').toLowerCase();

      var score = 0;
      for (final keyword in keywords) {
        if (keyword.isEmpty) continue;
        if (lab.title.toLowerCase().contains(keyword)) score += 3;
        if (lab.category.label.toLowerCase().contains(keyword)) score += 2;
        if (haystack.contains(keyword)) score += 1;
      }
      if (score > 0) scored[lab] = score;
    }

    final matches = scored.keys.toList()
      ..sort((a, b) => (scored[b] ?? 0).compareTo(scored[a] ?? 0));
    return matches;
  }

  /// Every bundled Lab, for screens that offer a manual Lab picker.
  List<LabModel> get allLabs => _labService.allLabs;

  /// Looks up a Lab by id through the Lab registry.
  LabModel? labById(String? id) => _labService.labById(id);

  /// Loads the student's saved courses. Returns null when Supabase cannot be
  /// reached, which is a normal offline situation and never throws.
  Future<List<MissionCourseRef>?> _loadCourses() async {
    if (safeSupabase() == null) return null;
    try {
      final rows = await CourseService().getUserCourses();
      return rows
          .where((row) => (row['id']?.toString() ?? '').isNotEmpty)
          .map(
            (row) => MissionCourseRef(
              id: row['id'].toString(),
              title: (row['title'] ?? 'Untitled course').toString(),
              subject: (row['subject'] ?? '').toString(),
              chapterCount: _asInt(row['chapter_count']),
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Loads the full generated course for a course task, or null when it cannot
  /// be loaded right now.
  Future<GeneratedCourse?> loadCourse(String courseId) async {
    if (safeSupabase() == null) return null;
    try {
      return await CourseService().loadGeneratedCourse(courseId);
    } catch (_) {
      return null;
    }
  }

  LabModel? _bestLab(List<String> keywords, List<LabModel> labs) {
    if (labs.isEmpty || keywords.isEmpty) return null;

    LabModel? best;
    var bestScore = 0;
    for (final lab in labs) {
      final title = lab.title.toLowerCase();
      var score = 0;
      for (final keyword in keywords) {
        if (title.contains(keyword)) score += 3;
        for (final lesson in lab.lessons) {
          if (lesson.title.toLowerCase().contains(keyword)) score += 2;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = lab;
      }
    }
    // Fall back to the strongest overall match so a Lab is still offered.
    return best ?? labs.first;
  }

  LabLesson? _bestLesson(List<String> keywords, LabModel lab) {
    if (lab.lessons.isEmpty) return null;

    LabLesson? best;
    var bestScore = 0;
    for (final lesson in lab.lessons) {
      final title = lesson.title.toLowerCase();
      var score = 0;
      for (final keyword in keywords) {
        if (title.contains(keyword)) score += 3;
      }
      if (score > bestScore) {
        bestScore = score;
        best = lesson;
      }
    }
    return best ?? lab.lessons.first;
  }

  MissionCourseRef? _bestCourse(
    List<String> keywords,
    List<MissionCourseRef> courses,
  ) {
    if (courses.isEmpty) return null;

    MissionCourseRef? best;
    var bestScore = 0;
    for (final course in courses) {
      final haystack = '${course.title} ${course.subject}'.toLowerCase();
      var score = 0;
      for (final keyword in keywords) {
        if (haystack.contains(keyword)) score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        best = course;
      }
    }
    return best;
  }

  static List<String> _splitTopic(String topic) {
    return topic
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((part) => part.length > 3)
        .toList();
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
