import 'dart:convert';

import '../config/supabase_config.dart';
import '../models/lab_model.dart';
import '../utils/supabase_availability.dart';

class CustomLabAiException implements Exception {
  const CustomLabAiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CustomLabAiService {
  const CustomLabAiService();

  static const String functionName = 'customized-lab-ai';
  static const String defaultPrimaryModel = 'gemini-3.8-flash';
  static const String defaultFallbackModel = 'gemini-3.5-flash-lite';
  static const List<String> supportedModels = <String>[
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
  ];
  static const Duration _requestTimeout = Duration(seconds: 90);

  static String normalizeModelName(String? value, {required String fallback}) {
    final candidate = (value ?? '').trim().toLowerCase();
    if (candidate.isEmpty) {
      return fallback;
    }
    if (!candidate.startsWith('gemini-')) {
      return fallback;
    }
    if (!supportedModels.contains(candidate)) {
      return fallback;
    }
    return candidate;
  }

  static List<String> resolveGeminiModels({
    String? primaryModel,
    String? fallbackModel,
  }) {
    final primary = normalizeModelName(
      primaryModel,
      fallback: defaultPrimaryModel,
    );
    final fallback = normalizeModelName(
      fallbackModel,
      fallback: defaultFallbackModel,
    );

    if (primary == fallback) {
      return <String>[primary];
    }
    return <String>[primary, fallback];
  }

  static bool shouldUseFallbackForGeminiError({int? statusCode, String? code}) {
    if (code == 'upstream_unavailable') {
      return true;
    }
    if (statusCode == null) {
      return false;
    }
    return <int>[429, 500, 502, 503, 504].contains(statusCode);
  }

  static String? selectModelForAttempt({
    required List<String> orderedModels,
    required int attemptIndex,
  }) {
    if (orderedModels.isEmpty) {
      return null;
    }
    if (attemptIndex < orderedModels.length) {
      return orderedModels[attemptIndex];
    }
    return orderedModels.last;
  }

  static int getTotalAllowedAttempts({required List<String> orderedModels}) {
    if (orderedModels.isEmpty) {
      return 0;
    }
    if (orderedModels.length == 1) {
      return 3;
    }
    return 3;
  }

  Future<LabModel> generateLab({required CustomLabConfig config}) async {
    final supabase = safeSupabase();
    if (supabase == null) {
      throw CustomLabAiException(
        isSupabaseConfigured
            ? 'The AI lab generator is busy right now. Please try again in a few minutes.'
            : 'AI lab generation is not connected yet for this build. Please try again later.',
      );
    }

    final body = <String, dynamic>{
      'title': (config.labName ?? config.effectiveTopic).trim(),
      'topic': config.effectiveTopic,
      'subject': config.subject ?? config.category?.label ?? 'General Science',
      'classLevel': config.classLevel ?? 'Class 10',
      'difficulty': (config.difficulty ?? LabDifficulty.beginner).storageValue,
      'numberOfLessons': (config.numberOfLessons ?? 4).clamp(2, 8),
      'duration': '${config.durationDays ?? 7} days',
      'learningObjectives': config.learningGoal ?? 'Understand concepts',
      'preferredLanguage': (config.preferredLanguage ?? 'en').trim().isNotEmpty
          ? config.preferredLanguage!.trim()
          : 'en',
      'learningContent': config.learningContent,
      'instructions': config.instructions ?? '',
    };

    final response = await supabase.client.functions
        .invoke(functionName, body: body)
        .timeout(_requestTimeout);

    final parsed = _parseEnvelope(response.data);
    final labJson = Map<String, dynamic>.from(parsed['lab'] as Map? ?? parsed);
    final generated = LabModel.fromJson(labJson);

    return generated.copyWith(
      id: generated.id ?? 'custom-ai-${DateTime.now().microsecondsSinceEpoch}',
      isCustomLab: true,
      createdAt: generated.createdAt ?? DateTime.now(),
      userId: supabase.client.auth.currentUser?.id,
      lastStudiedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _parseEnvelope(Object? data) {
    final decoded = _unwrapObject(data);
    if (decoded is! Map) {
      throw const CustomLabAiException(
        'The AI lab generator returned an unexpected response.',
      );
    }

    final envelope = Map<String, dynamic>.from(decoded);
    final status = envelope['status'];
    if (status is int && status != 200) {
      final result = envelope['result'];
      if (result is Map) {
        final error = result['error'];
        if (error is Map) {
          throw CustomLabAiException(
            (error['message'] ?? 'The AI lab generator failed.').toString(),
            statusCode: status,
          );
        }
      }
      throw CustomLabAiException(
        'The AI lab generator failed.',
        statusCode: status,
      );
    }

    final result = envelope['result'];
    if (result is Map) {
      final lab = result['lab'];
      if (lab is Map) {
        return Map<String, dynamic>.from(lab);
      }
      if (result.containsKey('course')) {
        return Map<String, dynamic>.from(result['course'] as Map);
      }
    }

    throw const CustomLabAiException(
      'The AI lab generator did not return a valid lab.',
    );
  }

  Object? _unwrapObject(Object? data) {
    if (data == null || data == '') {
      throw const CustomLabAiException(
        'The AI lab generator returned no data.',
      );
    }

    Object? decoded = data;
    if (data is String) {
      try {
        decoded = jsonDecode(data);
      } on FormatException {
        throw const CustomLabAiException(
          'The AI lab generator returned unreadable data.',
        );
      }
    }

    return decoded;
  }
}
