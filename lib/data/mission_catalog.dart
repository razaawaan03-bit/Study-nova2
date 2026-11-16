/// Subject and topic choices offered by the Mission Mode wizard.
///
/// This file deliberately contains **no learning content**. It is a list of
/// what the student can pick plus the keywords used to look for *existing*
/// Study Nova content (courses and bundled Labs) that matches the choice. The
/// planner never invents lessons, questions or ids: it only references what
/// `LabService` and `CourseService` already contain.
library;

import '../models/lab_model.dart';

class MissionSubjectOption {
  const MissionSubjectOption({
    required this.name,
    required this.keywords,
    this.defaultTopics = const <String>[],
    this.category,
  });

  final String name;

  /// Lower-case keywords matched against Lab titles, descriptions, lesson
  /// titles and course titles/subjects.
  final List<String> keywords;

  /// Topics used when the student does not pick any.
  final List<String> defaultTopics;

  /// The Study Nova Lab category this subject usually belongs to, if any.
  final LabCategory? category;
}

/// Subjects offered by the wizard, plus a custom-text escape hatch.
class MissionCatalog {
  const MissionCatalog._();

  static const List<MissionSubjectOption> subjects = <MissionSubjectOption>[
    MissionSubjectOption(
      name: 'Science',
      keywords: <String>[
        'science',
        'biology',
        'physics',
        'chemistry',
        'gsc',
        'circulatory',
        'life processes',
      ],
      defaultTopics: <String>[
        'Life Processes',
        'Control and Coordination',
        'Reproduction',
        'Heredity and Evolution',
        'Chemical Reactions',
        'Periodic Classification',
        'Electricity',
        'Our Environment',
      ],
      category: LabCategory.gsc,
    ),
    MissionSubjectOption(
      name: 'Mathematics',
      keywords: <String>[
        'math',
        'mathematics',
        'algebra',
        'geometry',
        'number',
      ],
      defaultTopics: <String>[
        'Number Systems',
        'Algebra',
        'Linear Equations',
        'Geometry',
        'Trigonometry',
        'Statistics',
        'Mensuration',
      ],
    ),
    MissionSubjectOption(
      name: 'History',
      keywords: <String>['history', 'sst', 'ancient', 'medieval', 'modern'],
      defaultTopics: <String>[
        'Ancient Civilisations',
        'Medieval India',
        'The Sultanate and the Mughal Period',
        'The British Raj',
        'Modern India',
        'World Wars',
        'Indian Independence',
      ],
      category: LabCategory.sst,
    ),
    MissionSubjectOption(
      name: 'Geography',
      keywords: <String>['geography', 'sst', 'climate', 'rivers', 'landform'],
      defaultTopics: <String>[
        'Land, Water and Climate',
        'Indian Rivers',
        'Soils and Natural Vegetation',
        'Natural Disasters',
        'Resources and Economy',
        'Population',
      ],
      category: LabCategory.sst,
    ),
    MissionSubjectOption(
      name: 'Indian Polity',
      keywords: <String>[
        'polity',
        'constitution',
        'sst',
        'civics',
        'government',
      ],
      defaultTopics: <String>[
        'The Constitution',
        'Fundamental Rights and Duties',
        'The Three Pillars of Government',
        'Parliament',
        'The Judiciary',
        'Local Government',
      ],
      category: LabCategory.sst,
    ),
    MissionSubjectOption(
      name: 'English',
      keywords: <String>['english', 'grammar', 'literature', 'vocabulary'],
      defaultTopics: <String>[
        'Grammar Basics',
        'Tenses',
        'Vocabulary',
        'Reading Comprehension',
        'Writing Skills',
      ],
    ),
    MissionSubjectOption(
      name: 'General Knowledge',
      keywords: <String>['gk', 'general knowledge', 'current affairs', 'india'],
      defaultTopics: <String>[
        'Indian Polity Basics',
        'Geography Basics',
        'Science Facts',
        'Current Affairs',
        'History Basics',
      ],
      category: LabCategory.gk,
    ),
  ];

  /// Everyday durations offered in the wizard.
  static const List<int> durationOptions = <int>[3, 7, 14, 20, 30, 60];

  /// Daily study time options, in minutes.
  static const List<int> dailyStudyOptions = <int>[15, 30, 45, 60, 120];

  static MissionSubjectOption? byName(String name) {
    for (final subject in subjects) {
      if (subject.name.toLowerCase() == name.trim().toLowerCase()) {
        return subject;
      }
    }
    return null;
  }

  /// All keywords for the selected subjects, including a free-text subject.
  static List<String> keywordsFor(List<String> subjects, {String? customText}) {
    final keywords = <String>[];
    for (final name in subjects) {
      final option = byName(name);
      if (option == null) {
        keywords.add(name.toLowerCase());
        continue;
      }
      keywords.addAll(option.keywords);
      final category = option.category;
      if (category != null) keywords.add(category.label.toLowerCase());
    }
    final custom = (customText ?? '').trim().toLowerCase();
    if (custom.isNotEmpty) keywords.addAll(_splitKeywords(custom));
    return keywords;
  }

  /// Default topics for the selected subjects, de-duplicated and in order.
  static List<String> defaultTopicsFor(List<String> subjects) {
    final topics = <String>[];
    for (final name in subjects) {
      final option = byName(name);
      if (option == null) continue;
      for (final topic in option.defaultTopics) {
        if (!topics.contains(topic)) topics.add(topic);
      }
    }
    return topics;
  }

  /// Splits a custom subject or topic line into usable keywords, e.g.
  /// "Class 10 Science, Physics" becomes ["class 10 science", "physics"].
  static List<String> _splitKeywords(String text) {
    return text
        .split(RegExp(r'[,\n/]'))
        .map((part) => part.trim().toLowerCase())
        .where((part) => part.isNotEmpty)
        .toList();
  }
}
