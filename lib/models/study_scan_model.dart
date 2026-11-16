class StudyScanModel {
  final String? id;
  final String userId;
  final String topic;
  final String subject;
  final String? imageUrl;
  final String explanation;
  final List<String> keyPoints;
  final Map<String, dynamic> mindMapData;
  final List<QuizQuestion> quizData;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String explanationLevel; // 'easy', 'normal', 'detailed'
  final List<String> importantConcepts;
  final List<String> commonMistakes;

  StudyScanModel({
    this.id,
    required this.userId,
    required this.topic,
    required this.subject,
    this.imageUrl,
    required this.explanation,
    required this.keyPoints,
    required this.mindMapData,
    required this.quizData,
    this.createdAt,
    this.updatedAt,
    this.explanationLevel = 'normal',
    this.importantConcepts = const [],
    this.commonMistakes = const [],
  });

  factory StudyScanModel.fromJson(Map<String, dynamic> json) {
    return StudyScanModel(
      id: json['id'] as String?,
      userId: (json['user_id'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      imageUrl: json['image_url'] as String?,
      explanation: (json['explanation'] ?? '').toString(),
      keyPoints: List<String>.from(json['key_points'] ?? []),
      mindMapData: json['mind_map_data'] ?? {},
      quizData:
          (json['quiz_data'] as List?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      explanationLevel: (json['explanation_level'] ?? 'normal').toString(),
      importantConcepts: List<String>.from(json['important_concepts'] ?? []),
      commonMistakes: List<String>.from(json['common_mistakes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'topic': topic,
      'subject': subject,
      'image_url': imageUrl,
      'explanation': explanation,
      'key_points': keyPoints,
      'mind_map_data': mindMapData,
      'quiz_data': quizData.map((q) => q.toJson()).toList(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'explanation_level': explanationLevel,
      'important_concepts': importantConcepts,
      'common_mistakes': commonMistakes,
    };
  }

  StudyScanModel copyWith({
    String? id,
    String? userId,
    String? topic,
    String? subject,
    String? imageUrl,
    String? explanation,
    List<String>? keyPoints,
    Map<String, dynamic>? mindMapData,
    List<QuizQuestion>? quizData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? explanationLevel,
    List<String>? importantConcepts,
    List<String>? commonMistakes,
  }) {
    return StudyScanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      imageUrl: imageUrl ?? this.imageUrl,
      explanation: explanation ?? this.explanation,
      keyPoints: keyPoints ?? this.keyPoints,
      mindMapData: mindMapData ?? this.mindMapData,
      quizData: quizData ?? this.quizData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      explanationLevel: explanationLevel ?? this.explanationLevel,
      importantConcepts: importantConcepts ?? this.importantConcepts,
      commonMistakes: commonMistakes ?? this.commonMistakes,
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String type; // 'multiple_choice', 'true_false', 'short_answer'

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.type,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: (json['correct_answer'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      type: (json['type'] ?? 'multiple_choice').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'type': type,
    };
  }
}
