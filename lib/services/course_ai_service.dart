import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/course_content_model.dart';
import '../models/course_model.dart';
import '../models/processed_material_model.dart';
import '../utils/supabase_availability.dart';

/// Calls the deployed `course-maker-ai` Supabase Edge Function.
///
/// This keeps the Gemini API key inside the Supabase server, matching the
/// security requirement of the app. The app sends only the student’s material
/// and metadata.
class CourseAiService {
  const CourseAiService();

  static const String functionName = 'course-maker-ai';
  static const int _maxAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _attemptTimeout = Duration(seconds: 90);

  static const String notConfigured =
      'Course generation is not connected yet. Please try again later.';
  static const String temporarilyBusy =
      'The AI course generator is busy right now. Please try again in a few minutes.';
  static const String unreachable =
      'Study Nova could not reach its AI course generator. Please check your connection and try again.';

  Future<GeneratedCourse> generateCourse({
    required CourseModel course,
    required List<ProcessedMaterial> material,
  }) async {
    final supabase = safeSupabase();
    if (supabase == null) {
      throw Exception(isSupabaseConfigured ? temporarilyBusy : notConfigured);
    }

    final payload = _buildPayload(course: course, material: material);
    final body = <String, dynamic>{'course': payload};

    final resp = await _invokeWithRetries(body, (requestBody) async {
      final response = await supabase.client.functions
          .invoke(functionName, body: requestBody)
          .timeout(_attemptTimeout);
      return response.data;
    });

    return _parseGeneratedCourse(resp, course);
  }

  Map<String, dynamic> _buildPayload({
    required CourseModel course,
    required List<ProcessedMaterial> material,
  }) {
    final textParts = <String>[];
    final attachments = <Map<String, dynamic>>[];

    for (final item in material) {
      if (item.hasText && (item.text ?? '').trim().isNotEmpty) {
        textParts.add('--- ${item.name} ---\n${item.text!.trim()}');
      }

      if (item.hasBytes && item.bytes != null) {
        attachments.add({
          'name': item.name,
          'mimeType': item.mimeType ?? 'application/octet-stream',
          'data': base64Encode(item.bytes!),
        });
      }
    }

    return {
      'title': course.title,
      'courseType': course.courseType.storageValue,
      'classLevel': course.classLevel ?? '',
      'subject': course.subject ?? '',
      'examTarget': course.examTarget ?? '',
      'length': course.length.storageValue,
      'difficulty': course.difficulty.storageValue,
      'language': course.language.storageValue,
      'learningGoal': course.learningGoal ?? '',
      'description': course.description,
      'materialText': textParts.join('\n\n'),
      'attachments': attachments,
    };
  }

  Future<Map<String, dynamic>> _invokeWithRetries(
    Map<String, dynamic> body,
    Future<Object?> Function(Map<String, dynamic> requestBody) send,
  ) async {
    var delay = _baseRetryDelay;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return _parseResponseBody(await send(body));
      } on CourseAiException catch (_) {
        rethrow;
      } on FunctionException catch (error) {
        debugPrint('CourseAiService: HTTP ${error.status} from $functionName.');
        debugPrint(error.details.toString());
        if (error.status == 404 || error.status == 400) {
          throw const CourseAiException(notConfigured);
        }
        if (error.status >= 500 && attempt < _maxAttempts) {
          debugPrint('CourseAiService: retrying in ${delay.inSeconds}s.');
          await Future<void>.delayed(delay);
          delay *= 2;
          continue;
        }
        throw CourseAiException(
          error.status >= 500 ? temporarilyBusy : unreachable,
        );
      } on TimeoutException catch (_) {
        if (attempt >= _maxAttempts) {
          throw const CourseAiException(temporarilyBusy);
        }
        debugPrint(
          'CourseAiService: timeout, retrying in ${delay.inSeconds}s.',
        );
        await Future<void>.delayed(delay);
        delay *= 2;
      } catch (error) {
        debugPrint('CourseAiService: unexpected failure: $error');
        throw CourseAiException(friendlyBackendError(error));
      }
    }

    throw const CourseAiException(temporarilyBusy);
  }

  static Map<String, dynamic> _parseResponseBody(Object? data) {
    if (data == null || data == '') {
      throw const CourseAiException(
        'The AI course generator returned no data.',
      );
    }

    Object? decoded = data;
    if (data is String) {
      try {
        decoded = jsonDecode(data);
      } on FormatException {
        throw const CourseAiException(
          'The AI course generator returned unreadable data.',
        );
      }
    }

    if (decoded is! Map) {
      throw const CourseAiException(
        'The AI course generator returned an unexpected response.',
      );
    }

    final envelope = Map<String, dynamic>.from(decoded);
    final status = envelope['status'];
    if (status is int && status != 200) {
      final result = envelope['result'];
      if (result is Map) {
        final error = result['error'];
        if (error is Map) {
          throw CourseAiException(
            (error['message'] ?? 'The AI course generator failed.').toString(),
          );
        }
      }
      throw CourseAiException('The AI course generator failed.');
    }

    final result = envelope['result'];
    if (result is Map && result.containsKey('course')) {
      return Map<String, dynamic>.from(result['course'] as Map);
    }

    if (result is Map && result.containsKey('text')) {
      final text = result['text'];
      if (text is String && text.trim().isNotEmpty) {
        return jsonDecode(text);
      }
    }

    if (result is Map && result.containsKey('content')) {
      final content = result['content'];
      if (content is Map) {
        return Map<String, dynamic>.from(content);
      }
    }

    if (result is Map && result.containsKey('candidate')) {
      final candidate = result['candidate'];
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate);
      }
    }

    throw const CourseAiException(
      'The AI course generator did not return a valid course.',
    );
  }

  GeneratedCourse _parseGeneratedCourse(
    Map<String, dynamic> json,
    CourseModel draft,
  ) {
    final parsed = GeneratedCourse.fromJson(json);

    final chapters = parsed.chapters
        .where(
          (chapter) => chapter.title.isNotEmpty && chapter.topics.isNotEmpty,
        )
        .toList();
    if (chapters.isEmpty) {
      throw const CourseAiException(
        'The AI course generator did not return usable course content.',
      );
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

class CourseAiException implements Exception {
  const CourseAiException(this.message);

  final String message;

  @override
  String toString() => message;
}
