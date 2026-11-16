import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/ai_config.dart';
import '../models/course_content_model.dart';
import '../models/course_model.dart';
import '../models/processed_material_model.dart';
import '../models/study_scan_model.dart';
import 'study_photo_service.dart';

/// The two AI features in Study Nova, and how each one reaches its model:
///
/// * **Study From Photo** goes through the `study-from-photo` Supabase Edge
///   Function. The Gemini key stays on the server as `STUDY_PHOTO_GEMINI_KEY`
///   and is never present in the app, so this path needs no [apiKey].
/// * **Course Maker** still calls Gemini directly from the device, which is
///   why [apiKey] is still part of this service.
///
/// Only the Study From Photo methods were moved. [generateCourse] is unchanged.
class AIStudyService {
  /// Retries after the first attempt of the primary model, so at most 3
  /// requests are sent to it before the fallback model is considered.
  static const int _maxRetries = 2;

  /// First backoff step; every retry doubles it (2s, then 4s).
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  /// The fallback model only gets a single retry, so a full outage cannot
  /// keep the user waiting for long.
  static const int _fallbackMaxRetries = 1;

  /// Image-capable fallback, used only when the primary model keeps returning
  /// HTTP 503 / UNAVAILABLE. Gemini 3.5 Flash-Lite accepts Text, Image, Video,
  /// Audio and PDF input:
  /// https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite
  static const String _defaultFallbackModel = 'gemini-3.5-flash-lite';

  /// Shown to the user when every attempt fails with a temporary outage.
  static const String _temporarilyBusyMessage =
      'Gemini is temporarily busy. Please try again in a few minutes.';

  /// Only Gemini Flash/Pro variants are multimodal, i.e. accept images.
  static final RegExp _multimodalModelPattern = RegExp(
    r'^gemini-(\d+(\.\d+)?-)?(flash|pro)(-lite)?$',
  );

  late final GenerativeModel _model;
  GenerativeModel? _fallbackModelInstance;

  /// Gemini key for the Course Maker path only.
  ///
  /// Empty for Study From Photo, which never sends a key anywhere: it calls the
  /// `study-from-photo` Edge Function and the key stays on the server.
  final String apiKey;

  /// Transport used by the Study From Photo path.
  final StudyPhotoService _studyPhoto;

  /// The Gemini model used for image analysis.
  ///
  /// Defaults to [geminiModel] so the model can be changed with
  /// `--dart-define=GEMINI_MODEL=<model-id>` when Google retires it.
  final String model;

  /// Model tried once the primary [model] keeps returning 503 / UNAVAILABLE.
  final String fallbackModel;

  bool _initialized = false;

  AIStudyService({
    this.apiKey = '',
    String? model,
    String? fallbackModel,
    StudyPhotoService? studyPhoto,
  }) : _studyPhoto = studyPhoto ?? const StudyPhotoService(),
       model = (model != null && model.trim().isNotEmpty)
           ? model.trim()
           : geminiModel,
       fallbackModel =
           (fallbackModel != null && fallbackModel.trim().isNotEmpty)
           ? fallbackModel.trim()
           : _defaultFallbackModel {
    _initializeModel();
  }

  void _initializeModel() {
    _model = GenerativeModel(model: model, apiKey: apiKey);
    _initialized = true;
  }

  /// Builds the fallback model lazily, and only when it can accept images.
  ///
  /// Returns null when there is no usable fallback, in which case the caller
  /// reports the friendly "temporarily busy" message instead.
  GenerativeModel? _fallbackModelOrNull() {
    final name = fallbackModel;
    if (name.isEmpty || name == model) {
      return null;
    }
    if (!_supportsImageInput(name)) {
      return null;
    }
    return _fallbackModelInstance ??= GenerativeModel(
      model: name,
      apiKey: apiKey,
    );
  }

  /// True when [model] is a multimodal Gemini Flash/Pro variant, which is
  /// required before image parts may be sent to it.
  static bool _supportsImageInput(String model) =>
      _multimodalModelPattern.hasMatch(model.trim().toLowerCase());

  /// Analyzes an image from raw bytes and returns the app's structured
  /// explanation.
  ///
  /// Bytes are used instead of a [File] because `dart:io` / `File` is not
  /// supported on Flutter Web, while image bytes are. The [fileName] is only
  /// used to determine the correct MIME type for the request.
  ///
  /// The request goes to the `study-from-photo` Supabase Edge Function, so no
  /// Gemini key is involved and none is needed. Everything after the text comes
  /// back — the JSON parsing, the mind map and the quiz questions — is the
  /// original Study From Photo logic, unchanged.
  Future<Map<String, dynamic>> analyzeImage(
    Uint8List imageBytes, {
    String fileName = 'study_image.jpg',
    String explanationLevel = 'normal',
  }) async {
    if (imageBytes.isEmpty) {
      throw Exception('The selected image is empty and cannot be analyzed.');
    }

    final mimeType = _getMimeType(_extensionOf(fileName));
    final prompt = _createAnalysisPrompt(explanationLevel);

    final String text;
    try {
      text = await _studyPhoto.requestExplanation(
        prompt: prompt,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
    } on StudyPhotoException catch (e) {
      // Already a student-readable sentence.
      throw Exception(e.message);
    } catch (e) {
      debugPrint('AIStudyService: unexpected image analysis failure: $e');
      throw Exception(
        'Something went wrong while analysing your photo. Please try again.',
      );
    }

    return _parseAIResponse(text, explanationLevel);
  }

  /// Runs the primary model with retries, then the image-capable fallback.
  ///
  /// Only temporary 503 / UNAVAILABLE failures are retried or handed over to
  /// the fallback; every other error is rethrown so the existing handling of
  /// retired models, invalid keys and quota limits stays unchanged.
  Future<Map<String, dynamic>> _analyzeWithFallback(
    List<Content> content,
    String explanationLevel, {
    Map<String, dynamic> Function(String text)? parse,
  }) async {
    try {
      return await _analyzeWithRetries(
        _model,
        model,
        content,
        explanationLevel,
        parse: parse,
      );
    } on _TransientUnavailable {
      final fallback = _fallbackModelOrNull();
      if (fallback == null) {
        // No usable fallback - let `analyzeImage` report the friendly message.
        rethrow;
      }

      // One last attempt on the fallback model.
      return _analyzeWithRetries(
        fallback,
        fallbackModel,
        content,
        explanationLevel,
        maxRetries: _fallbackMaxRetries,
        parse: parse,
      );
    }
  }

  /// Sends one Gemini request, retrying temporary 503 / UNAVAILABLE errors with
  /// exponential backoff. The loop is strictly bounded by [maxRetries].
  Future<Map<String, dynamic>> _analyzeWithRetries(
    GenerativeModel activeModel,
    String activeModelName,
    List<Content> content,
    String explanationLevel, {
    int maxRetries = _maxRetries,
    Map<String, dynamic> Function(String text)? parse,
  }) async {
    var delay = _baseRetryDelay;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await activeModel.generateContent(content);

        if (response.text == null || response.text!.isEmpty) {
          throw Exception('No response from AI service');
        }

        // Course generation supplies its own parser; image analysis keeps the
        // existing one, so Study From Photo behaves exactly as before.
        final parser = parse;
        if (parser != null) {
          return parser(response.text!);
        }
        return _parseAIResponse(response.text!, explanationLevel);
      } on GenerativeAIException catch (e) {
        if (!_isTransientUnavailable(e.message)) {
          // Not a temporary outage (retired model, invalid key, quota, ...).
          rethrow;
        }

        if (attempt >= maxRetries) {
          throw const _TransientUnavailable();
        }

        // Bounded exponential backoff: 2s, then 4s. Only the model name,
        // attempt counter and delay are logged - never the API key or the
        // request body.
        debugPrint(
          'AIStudyService: $activeModelName unavailable (503), retrying in '
          '${delay.inSeconds}s (retry ${attempt + 1}/$maxRetries)',
        );
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }

    // Unreachable: the loop above always returns or throws.
    throw const _TransientUnavailable();
  }

  /// Detects Gemini's temporary, retryable outages.
  ///
  /// The SDK converts any `statusCode >= 500` into
  /// `GenerativeAIException('Server Error [<code>]: <body>')` before parsing
  /// the body, so a 503 arrives as e.g.
  /// `Server Error [503]: {"error":{"code":503,"message":"This model is
  /// currently experiencing high demand...","status":"UNAVAILABLE"}}`.
  static bool _isTransientUnavailable(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('unavailable') ||
        lower.contains('high demand') ||
        lower.contains('overloaded') ||
        lower.contains('try again later')) {
      return true;
    }
    // The SDK buckets every 5xx response together; all of them are transient.
    return RegExp(r'server error \[5\d\d\]').hasMatch(lower);
  }

  /// Turns a raw Gemini API error message into a student-readable one.
  ///
  /// The technical hint (model id, dart-define, provider status code) is
  /// printed to the console for the app owner and is deliberately kept out of
  /// the message the student reads.
  String _friendlyAiError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('not found for api version') ||
        lower.contains('not supported for generatecontent')) {
      debugPrint(
        'AIStudyService: the configured model "$model" is not available for '
        'this key. Set a current image-capable model with '
        '--dart-define=GEMINI_MODEL=<model-id>. Provider said: $message',
      );
      return 'Study Nova is having trouble reaching its AI right now. '
          'Please try again in a few minutes.';
    }

    if (lower.contains('api key not valid') ||
        lower.contains('api_key_invalid') ||
        lower.contains('api key expired')) {
      debugPrint(
        'AIStudyService: the Generative AI key is missing or invalid. Provide '
        'it with --dart-define=GOOGLE_GENERATIVE_AI_KEY=<key>.',
      );
      return 'Study Nova is not connected to its AI service yet. Please try '
          'again later.';
    }

    if (lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('resource_exhausted')) {
      debugPrint(
        'AIStudyService: quota/rate limit reached. Provider said: '
        '$message',
      );
      return 'You have reached the AI usage limit for now. Please wait a few '
          'minutes and try again.';
    }

    debugPrint(
      'AIStudyService: unexpected AI failure. Provider said: $message',
    );
    return 'Something went wrong while preparing your explanation. '
        'Please try again.';
  }

  /// Extracts the lowercase extension (without the dot) from a file name.
  ///
  /// Works for plain names ("notes.jpg"), paths ("/tmp/a/notes.PNG") and
  /// web blob URLs ("blob:http://localhost/uuid"). Returns an empty string
  /// when no usable extension is present.
  String _extensionOf(String fileName) {
    final cleaned = fileName.split('?').first.split('#').first;
    final lastDot = cleaned.lastIndexOf('.');
    final lastSeparator = cleaned.lastIndexOf(RegExp(r'[/\\]'));
    if (lastDot <= lastSeparator + 1 || lastDot == cleaned.length - 1) {
      return '';
    }
    return cleaned.substring(lastDot + 1).toLowerCase();
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _createAnalysisPrompt(String explanationLevel) {
    final basePrompt =
        '''
You are an expert educational tutor. Analyze this image of educational material and provide:

1. **Topic**: The main topic/title of what is shown (e.g., "Photosynthesis", "Quadratic Equations")
2. **Subject**: The subject area (e.g., "Biology", "Mathematics", "Chemistry")
3. **Summary**: A brief 1-2 line overview (50 words max)
4. **Explanation**: A full explanation appropriate for the requested level

Instructions:
- If the image is unclear or blurry, state this clearly
- If you cannot read text in the image, say so rather than guessing
- Only explain what you can actually see
- Use accurate information only
- For diagrams, describe what they show and explain the concepts
- Identify any formulas, equations, or technical terms and explain them

Based on the "$explanationLevel" level requested:
- "easy": Use simple words, avoid jargon, explain basics clearly, include analogies
- "normal": Standard explanation with some technical terms, balanced detail
- "detailed": Comprehensive explanation with technical depth, include derivations if applicable

Provide response as valid JSON with this structure:
{
  "topic": "string",
  "subject": "string", 
  "summary": "string",
  "explanation": "string",
  "important_concepts": ["string"],
  "key_definitions": [{"term": "string", "definition": "string"}],
  "examples": ["string"],
  "formulas": ["string"],
  "common_mistakes": ["string"],
  "quick_revision_points": ["string"],
  "mind_map_structure": {
    "root": "string",
    "branches": [
      {
        "name": "string",
        "children": ["string"]
      }
    ]
  }
}

IMPORTANT: Return ONLY valid JSON, no additional text.
''';
    return basePrompt;
  }

  Map<String, dynamic> _parseAIResponse(
    String response,
    String explanationLevel,
  ) {
    try {
      // Clean response of any markdown code blocks
      String cleaned = response.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      // The model may wrap the JSON in commentary (or reasoning) text, so
      // locate the JSON object instead of assuming the text is pure JSON.
      final json = _decodeJsonObject(cleaned);

      // Validate and clean response
      final topic = _getString(json, 'topic', 'Unknown Topic');
      final subject = _getString(json, 'subject', 'General Studies');
      final summary = _getString(json, 'summary', '');
      final explanation = _getString(json, 'explanation', '');
      final concepts = _getStringList(json, 'important_concepts');
      final mistakes = _getStringList(json, 'common_mistakes');

      if (topic.isEmpty || explanation.isEmpty) {
        throw Exception(
          'Invalid response: missing required fields (topic or explanation)',
        );
      }

      // Generate key points
      final keyPoints = explanation
          .split('\n')
          .where((line) => line.trim().isNotEmpty && line.length > 20)
          .take(5)
          .toList();

      // Build mind map data
      final mindMapStructure =
          json['mind_map_structure'] as Map<String, dynamic>? ?? {};
      final mindMapData = _buildMindMapData(topic, mindMapStructure);

      // Generate quiz questions
      final quizQuestions = _generateQuizQuestions(
        topic,
        explanation,
        json['key_definitions'] as List? ?? [],
        json['examples'] as List? ?? [],
      );

      return {
        'topic': topic,
        'subject': subject,
        'summary': summary,
        'explanation': explanation,
        'important_concepts': concepts,
        'common_mistakes': mistakes,
        'key_points': keyPoints,
        'mind_map_data': mindMapData,
        'quiz_questions': quizQuestions,
        'explanation_level': explanationLevel,
      };
    } catch (e) {
      // The model answered in prose instead of the requested JSON. That is
      // still a usable explanation for a student, so it is turned into the
      // same shape rather than thrown away. Only genuinely unusable text
      // (empty, or nothing but markup) fails here.
      debugPrint('AIStudyService: no JSON in the AI response ($e).');
      final prose = _parseProseResponse(response, explanationLevel);
      if (prose == null) {
        throw Exception(
          'Study Nova could not read the AI response. Please try again.',
        );
      }
      return prose;
    }
  }

  /// Builds the same result shape from a plain-text explanation.
  ///
  /// Used when the model answers in prose rather than JSON, which keeps the
  /// explanation → mind map → quiz flow working instead of ending in an error.
  /// Returns null when there is no real text to work with.
  Map<String, dynamic>? _parseProseResponse(
    String response,
    String explanationLevel,
  ) {
    final text = response.trim();
    if (text.isEmpty) return null;

    // Markdown headings are the most reliable topic label when they exist.
    String topic = '';
    final heading = RegExp(
      r'^#{1,6}\s*(.+)$',
      multiLine: true,
    ).firstMatch(text);
    if (heading != null) {
      topic = _stripMarkdown(heading.group(1) ?? '');
    }
    if (topic.isEmpty) {
      // Otherwise use the first bolded phrase, then the first sentence.
      final bold = RegExp(r'\*\*(.+?)\*\*').firstMatch(text);
      topic = bold != null
          ? _stripMarkdown(bold.group(1) ?? '')
          : _firstSentence(text);
    }
    if (topic.isEmpty || topic.length > 120) {
      topic = 'Your Study Material';
    }

    final explanation = text;
    final summary = _firstSentence(text);

    final keyPoints = explanation
        .split('\n')
        .map(_stripMarkdown)
        .where((line) => line.trim().isNotEmpty && line.length > 20)
        .take(5)
        .toList();

    return {
      'topic': topic,
      'subject': 'General Studies',
      'summary': summary,
      'explanation': explanation,
      'important_concepts': const <String>[],
      'common_mistakes': const <String>[],
      'key_points': keyPoints,
      'mind_map_data': _buildMindMapData(topic, const {}),
      'quiz_questions': _generateQuizQuestions(topic, explanation, [], []),
      'explanation_level': explanationLevel,
    };
  }

  /// Removes Markdown emphasis and list bullets from a line of prose.
  static String _stripMarkdown(String line) {
    return line
        .replaceAll(RegExp(r'[*_`#>]'), '')
        .replaceAll(RegExp(r'^\s*[-+\u2022]\s+'), '')
        .trim();
  }

  /// The first sentence of [text], trimmed to something a summary can show.
  static String _firstSentence(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.isEmpty) return '';
    final stop = flat.indexOf(RegExp(r'[.!?]'));
    final sentence = stop > 20 ? flat.substring(0, stop + 1) : flat;
    return sentence.length > 300
        ? '${sentence.substring(0, 300)}...'
        : sentence;
  }

  /// Decodes the JSON object out of an AI response.
  ///
  /// Tries the whole text first, then falls back to the outermost `{...}`
  /// block so leading/trailing commentary in the response cannot break the
  /// explanation flow.
  Map<String, dynamic> _decodeJsonObject(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      decoded = null;
    }

    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      final candidate = jsonDecode(text.substring(start, end + 1));
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) return Map<String, dynamic>.from(candidate);
    }

    throw const FormatException('No JSON object found in the AI response');
  }

  String _getString(
    Map<String, dynamic> json,
    String key,
    String defaultValue,
  ) {
    final value = json[key];
    if (value is String) return value;
    return defaultValue;
  }

  List<String> _getStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> _buildMindMapData(
    String topic,
    Map<String, dynamic> structure,
  ) {
    if (structure.isEmpty) {
      return {
        'root': topic,
        'branches': [
          {'name': 'Definition', 'children': []},
          {'name': 'Key Concepts', 'children': []},
          {'name': 'Examples', 'children': []},
          {'name': 'Applications', 'children': []},
        ],
      };
    }

    return {
      'root': structure['root'] ?? topic,
      'branches': structure['branches'] ?? [],
    };
  }

  List<QuizQuestion> _generateQuizQuestions(
    String topic,
    String explanation,
    List keyDefinitions,
    List examples,
  ) {
    final questions = <QuizQuestion>[];

    // Multiple choice question about main topic
    if (explanation.isNotEmpty) {
      questions.add(
        QuizQuestion(
          id: '${DateTime.now().millisecondsSinceEpoch}_1',
          question: 'What is the main topic of this material?',
          options: [
            topic,
            'Related concept',
            'Different topic',
            'Not specified',
          ],
          correctAnswer: topic,
          explanation: 'This was the main topic of the image content.',
          type: 'multiple_choice',
        ),
      );
    }

    // Definition questions
    if (keyDefinitions.isNotEmpty) {
      for (var i = 0; i < keyDefinitions.length && questions.length < 10; i++) {
        final def = keyDefinitions[i] as Map<String, dynamic>?;
        if (def != null) {
          final term = def['term'] as String? ?? '';
          final definition = def['definition'] as String? ?? '';
          if (term.isNotEmpty && definition.isNotEmpty) {
            questions.add(
              QuizQuestion(
                id: '${DateTime.now().millisecondsSinceEpoch}_${i + 2}',
                question: 'What is "$term"?',
                options: [
                  definition,
                  'A related concept',
                  'An application',
                  'A common mistake',
                ],
                correctAnswer: definition,
                explanation:
                    'This is the correct definition of $term based on the material.',
                type: 'multiple_choice',
              ),
            );
          }
        }
      }
    }

    // True/False questions
    if (explanation.length > 100 && questions.length < 10) {
      questions.add(
        QuizQuestion(
          id: '${DateTime.now().millisecondsSinceEpoch}_${questions.length + 1}',
          question: 'Understanding $topic is important for this subject area.',
          options: ['True', 'False'],
          correctAnswer: 'True',
          explanation: 'This topic is part of the core material.',
          type: 'true_false',
        ),
      );
    }

    return questions;
  }

  /// Answers a student's follow-up question about the material they analysed.
  ///
  /// Part of Study From Photo, so it also goes through the `study-from-photo`
  /// Edge Function with no image attached — the function accepts a
  /// text-only request.
  Future<String> askFollowUpQuestion({
    required String topic,
    required String explanation,
    required String question,
  }) async {
    if (question.trim().isEmpty) {
      throw Exception('Please enter a question.');
    }

    // The material is trimmed so a long explanation cannot crowd out the
    // student's actual question.
    final material = explanation.length > 4000
        ? explanation.substring(0, 4000)
        : explanation;

    final prompt =
        '''
Topic: $topic
Material: $material

Student question: $question

Answer clearly and keep it friendly and relevant to the topic and material above. Do not use JSON. Be concise but informative.
''';

    try {
      final text = await _studyPhoto.requestExplanation(prompt: prompt);
      return text.trim().isEmpty
          ? 'Study Nova could not answer that question. Please try rephrasing it.'
          : text.trim();
    } on StudyPhotoException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      debugPrint('AIStudyService: unexpected follow-up failure: $e');
      throw Exception(
        'Study Nova could not answer that question. Please try again.',
      );
    }
  }

  /// Gemini accepts roughly 20 MB of inline data per request; keep a margin so
  /// the prompt and several files still fit.
  static const int _maxInlineBytes = 16 * 1024 * 1024;

  /// Generates a complete structured course from processed study material.
  ///
  /// Text material is folded into the prompt and every ready PDF / image is
  /// attached as inline data, so Gemini works from the student's own material.
  /// Requests reuse the same 503 retry / fallback path as [analyzeImage].
  Future<GeneratedCourse> generateCourse(
    List<ProcessedMaterial> material, {
    required CourseModel course,
  }) async {
    if (!_initialized) {
      throw Exception('AI Service not initialized. Provide API key.');
    }

    final ready = material.where((item) => item.isReady).toList();
    if (ready.isEmpty) {
      throw Exception(
        'Your study material could not be read. Please check it and try again.',
      );
    }

    final content = _buildCourseContent(course, ready);

    try {
      final json = await _analyzeWithFallback(
        content,
        'course',
        parse: _decodeJsonObject,
      );
      return _parseGeneratedCourse(json, course);
    } on _TransientUnavailable {
      // Same friendly message the Study From Photo flow uses.
      throw Exception(_temporarilyBusyMessage);
    } on CourseGenerationException catch (e) {
      throw Exception(e.message);
    } on GenerativeAIException catch (e) {
      throw Exception(_friendlyAiError(e.message));
    } catch (_) {
      // Never surface a raw exception to the student.
      throw Exception('Course generation failed. Please try again.');
    }
  }

  /// Builds the multimodal request: one prompt plus inline PDF/image parts.
  List<Content> _buildCourseContent(
    CourseModel course,
    List<ProcessedMaterial> ready,
  ) {
    final textMaterial = ready.where((item) => item.hasText).toList();
    final binary = <ProcessedMaterial>[];
    var skippedForSize = 0;
    var remaining = _maxInlineBytes;

    for (final item in ready) {
      final bytes = item.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      if (bytes.length > remaining) {
        skippedForSize++;
        continue;
      }
      remaining -= bytes.length;
      binary.add(item);
    }

    final prompt = _createCoursePrompt(
      course,
      textMaterial,
      attachmentCount: binary.length,
      skippedForSize: skippedForSize,
    );

    final parts = <Part>[TextPart(prompt)];
    for (final item in binary) {
      parts.add(
        DataPart(item.mimeType ?? 'application/octet-stream', item.bytes!),
      );
    }

    return <Content>[Content.multi(parts)];
  }

  /// Prompt that turns the course setup plus the supplied material into a
  /// strict JSON course.
  String _createCoursePrompt(
    CourseModel course,
    List<ProcessedMaterial> textMaterial, {
    required int attachmentCount,
    required int skippedForSize,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      'You are an expert teacher. Build a complete, structured study course '
      'for a student, using mainly the material provided below.',
    );
    buffer.writeln();
    buffer.writeln('COURSE REQUEST');
    buffer.writeln('- Course name / topic: ${course.title}');
    buffer.writeln('- Course type: ${course.courseType.label}');
    if ((course.classLevel ?? '').trim().isNotEmpty) {
      buffer.writeln('- Class / grade: ${course.classLevel}');
    }
    if ((course.subject ?? '').trim().isNotEmpty) {
      buffer.writeln('- Subject: ${course.subject}');
    }
    if ((course.examTarget ?? '').trim().isNotEmpty) {
      buffer.writeln('- Exam / target: ${course.examTarget}');
    }
    buffer.writeln('- Course length: ${course.length.label}');
    buffer.writeln('- Difficulty: ${course.difficulty.label}');
    buffer.writeln(
      '- Write every generated string in this language: ${course.language.label}.',
    );
    if ((course.learningGoal ?? '').trim().isNotEmpty) {
      buffer.writeln('- Student goal: ${course.learningGoal}');
    }

    buffer.writeln();
    buffer.writeln('HOW MUCH TO GENERATE');
    buffer.writeln('- Short: 2 to 3 chapters with 2 to 3 topics each.');
    buffer.writeln('- Medium: 3 to 5 chapters with 3 to 4 topics each.');
    buffer.writeln('- Detailed: 5 to 8 chapters with 4 to 6 topics each.');
    buffer.writeln(
      '- Add one quiz of 5 to 10 multiple-choice questions per chapter, but '
      'only where the material really supports them.',
    );

    if (textMaterial.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('STUDY MATERIAL PROVIDED BY THE STUDENT');
      for (final item in textMaterial) {
        buffer.writeln('--- ${item.name} ---');
        buffer.writeln(item.text!.trim());
        buffer.writeln();
      }
    }

    if (attachmentCount > 0) {
      buffer.writeln(
        'The student also attached $attachmentCount file(s) to this request. '
        'Read them directly and treat their content as part of the material.',
      );
    }
    if (skippedForSize > 0) {
      buffer.writeln(
        '$skippedForSize attached file(s) were too large to send and could not '
        'be read. Do not invent their content - mention this gap if it matters.',
      );
    }

    buffer.writeln();
    buffer.writeln('RULES');
    buffer.writeln(
      '- Base the course mainly on the supplied material. Do not invent facts.',
    );
    buffer.writeln(
      '- If the material is not enough for a topic, say so inside that topic '
      'instead of guessing.',
    );
    buffer.writeln('- Keep the language simple and student friendly.');
    buffer.writeln(
      '- Give each quiz in the same order as the chapters it belongs to.',
    );
    buffer.writeln(
      '- Return ONLY valid JSON. No markdown fences, no commentary.',
    );

    buffer.writeln();
    buffer.writeln('RETURN THIS EXACT JSON SHAPE');
    buffer.write(_courseJsonShape);

    return buffer.toString();
  }

  static const String _courseJsonShape = '''
{
  "title": "course title",
  "description": "one or two sentence course description",
  "chapters": [
    {
      "title": "chapter title",
      "description": "what this chapter covers",
      "topics": [
        {
          "title": "topic title",
          "explanation": "detailed explanation",
          "simple_explanation": "very simple explanation for a school student",
          "important_points": ["point"],
          "examples": ["example"],
          "key_terms": [{"term": "term", "definition": "definition"}],
          "questions": ["practice question"],
          "revision_notes": ["short revision note"]
        }
      ]
    }
  ],
  "quizzes": [
    {
      "title": "Chapter 1 Quiz",
      "questions": [
        {
          "question": "question text",
          "options": ["option A", "option B", "option C", "option D"],
          "correct_answer": "exact text of the correct option",
          "explanation": "why that answer is correct"
        }
      ]
    }
  ],
  "mind_map": {
    "root": "main topic",
    "branches": [{"name": "concept", "children": ["sub-concept", "key point"]}]
  },
  "revision_notes": ["course level revision note"]
}''';

  /// Validates the AI JSON and turns it into a [GeneratedCourse].
  ///
  /// Invalid or empty structures raise [CourseGenerationException] so no
  /// corrupted course data can ever reach the preview.
  GeneratedCourse _parseGeneratedCourse(
    Map<String, dynamic> json,
    CourseModel draft,
  ) {
    const invalidMessage =
        'The course could not be created from this material. '
        'Please try again.';

    final parsed = GeneratedCourse.fromJson(json);

    final chapters = parsed.chapters
        .where(
          (chapter) => chapter.title.isNotEmpty && chapter.topics.isNotEmpty,
        )
        .toList();
    if (chapters.isEmpty) {
      throw const CourseGenerationException(invalidMessage);
    }

    final aiTitle = parsed.course.title.trim();
    final aiDescription = parsed.course.description.trim();

    return GeneratedCourse(
      course: draft.copyWith(
        title: aiTitle.isEmpty ? draft.title : aiTitle,
        description: aiDescription.isEmpty ? draft.description : aiDescription,
        chapterCount: chapters.length,
        topicCount: chapters.fold<int>(
          0,
          (total, chapter) => total + chapter.topics.length,
        ),
        updatedAt: DateTime.now(),
      ),
      chapters: chapters,
      quizzes: parsed.quizzes,
      mindMapData: parsed.mindMapData,
      revisionNotes: parsed.revisionNotes,
    );
  }
}

/// Internal marker for a temporary Gemini outage (HTTP 503 / UNAVAILABLE).
///
/// It deliberately carries no data so that no raw API response (and never the
/// API key) can leak into logs or the UI.
class _TransientUnavailable implements Exception {
  const _TransientUnavailable();
}
