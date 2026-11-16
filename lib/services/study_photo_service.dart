import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/supabase_availability.dart';

/// A Study From Photo failure that already carries a student-readable message.
///
/// Nothing technical is attached to it, so throwing this can never leak a URL, a
/// provider payload or a credential into the UI. The provider detail goes to
/// the console with [debugPrint] only.
class StudyPhotoException implements Exception {
  const StudyPhotoException(this.message, {this.status});

  /// What the student reads.
  final String message;

  /// The status behind this failure, when there was one.
  ///
  /// Kept for the retry decision only — it is never shown to a student.
  final int? status;

  @override
  String toString() => message;
}

/// Performs **one** attempt at the function call and returns the decoded
/// response body.
///
/// Production delegates to the Supabase client. A substitute must behave the
/// same way: return the body on success, and throw [FunctionException] for a
/// non-2xx response, exactly as the real SDK does. Injecting the attempt — not
/// the finished text — is what lets the real request body, the real response
/// parsing and the real retry policy all be exercised by tests with no network.
typedef StudyPhotoAttempt =
    Future<Object?> Function(String functionName, Map<String, dynamic> body);

/// Calls the `study-from-photo` Supabase Edge Function for Study From Photo.
///
/// ## Why this exists
///
/// The Gemini API key lives **only** in the Edge Function's server-side secret
/// (`STUDY_PHOTO_GEMINI_KEY`). It is never present in the Flutter app, is never
/// sent from a device, and cannot be read out of an installed APK or a loaded
/// web bundle. The app calls this function instead, using the Supabase client
/// it is already signed in with.
///
/// ## Authentication
///
/// No header is built by hand. The Supabase client attaches the `apikey` header
/// and the signed-in student's JWT to every function call, and the function
/// verifies that JWT — an unauthenticated call returns HTTP 401. Nothing in
/// this file can weaken that.
///
/// ## Response shape
///
/// The function answers with HTTP 200 and the real outcome in the body:
///
/// ```json
/// { "status": 200,
///   "result": { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] } }
/// ```
///
/// A failure keeps the same envelope and puts the upstream status in `status`,
/// for example `{"status":503,"result":{"error":{...}}}`. Both are handled
/// below, as are non-2xx HTTP responses and transport failures.
class StudyPhotoService {
  const StudyPhotoService() : _attempt = null;

  /// Test seam: supplies one attempt at the call, so the request body, the
  /// response parsing and the retry policy can be verified offline.
  @visibleForTesting
  const StudyPhotoService.withAttempt(StudyPhotoAttempt attempt)
    : _attempt = attempt;

  final StudyPhotoAttempt? _attempt;

  /// Name of the deployed Supabase Edge Function.
  static const String functionName = 'study-from-photo';

  /// Total attempts for a transient failure, including the first one.
  static const int maxAttempts = 3;

  /// Backoff between attempts: 2s, then 4s.
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  /// Ceiling for a single attempt. An image upload plus a structured answer is
  /// genuinely slow, so this is generous — it only exists so a silently hung
  /// request cannot leave the student staring at a spinner forever.
  static const Duration _attemptTimeout = Duration(seconds: 60);

  /// Student-readable messages, kept together so every failure path is visible
  /// in one place.
  static const String notConfigured =
      'Study Nova is not connected to its AI service on this build yet. '
      'Please try again later.';
  static const String temporarilyBusy =
      'The AI service is busy right now. Please try again in a few minutes.';
  static const String unreachable =
      'Study Nova could not reach its AI service. Please check your connection '
      'and try again.';
  static const String noText =
      'The AI service did not return an explanation. Please try again.';
  static const String unreadable =
      'Study Nova could not read the AI response. Please try again.';

  /// Asks the Edge Function for an explanation of [imageBytes].
  ///
  /// [imageBytes] is sent as raw base64 **without** a `data:` prefix, because
  /// that is what the function expects; the MIME type travels beside it in
  /// [mimeType]. Leaving [imageBytes] null sends a text-only request, which is
  /// how the "Ask AI" follow-up question reuses this same endpoint.
  ///
  /// Returns the generated text exactly as the model produced it. Turning that
  /// text into the app's structured explanation stays in `AIStudyService`, so
  /// the parsing logic the rest of the app depends on is untouched.
  Future<String> requestExplanation({
    required String prompt,
    List<int>? imageBytes,
    String? mimeType,
  }) async {
    final body = <String, dynamic>{'prompt': prompt};
    if (imageBytes != null && imageBytes.isNotEmpty) {
      // Raw base64, deliberately no `data:image/jpeg;base64,` prefix.
      body['imageBase64'] = base64Encode(imageBytes);
      final type = mimeType?.trim();
      body['mimeType'] = (type == null || type.isEmpty) ? 'image/jpeg' : type;
    }

    final substitute = _attempt;
    Supabase? supabase;
    if (substitute == null) {
      supabase = safeSupabase();
      if (supabase == null) {
        // A null client is either "this build has no backend" or "the backend
        // did not come up". Neither is evidence that the student is offline, so
        // the message stays about the service rather than their connection.
        debugPrint(
          'StudyPhotoService: no Supabase client, so $functionName cannot be '
          'called.',
        );
        throw StudyPhotoException(
          isSupabaseConfigured ? temporarilyBusy : notConfigured,
        );
      }
    }

    return _invokeWithRetries(body, (name, requestBody) async {
      final replacement = substitute;
      if (replacement != null) return replacement(name, requestBody);
      final response = await supabase!.client.functions
          .invoke(name, body: requestBody)
          .timeout(_attemptTimeout);
      return response.data;
    });
  }

  /// Sends [body] to the function, retrying only a transient outage.
  ///
  /// Retrying is deliberate: the function reports upstream capacity problems as
  /// `status: 503 / UNAVAILABLE`, which clears within seconds. A retry loop with
  /// backoff turns most of those into a normal successful analysis, while the
  /// bound keeps a real outage from hanging the UI.
  Future<String> _invokeWithRetries(
    Map<String, dynamic> body,
    Future<Object?> Function(String name, Map<String, dynamic> requestBody)
    send,
  ) async {
    var delay = _baseRetryDelay;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return parseResponseBody(await send(functionName, body));
      } on StudyPhotoException catch (error) {
        if (!isTransientStatus(error.status) || attempt >= maxAttempts) {
          rethrow;
        }
        _logRetry(attempt, delay, 'a temporary problem');
      } on FunctionException catch (error) {
        // The function answered with a non-2xx status.
        debugPrint(
          'StudyPhotoService: HTTP ${error.status} from $functionName.',
        );
        debugPrintDetail(error.details);
        final mapped = friendlyMessageForStatus(error.status);
        if (!isTransientStatus(error.status) || attempt >= maxAttempts) {
          throw mapped;
        }
        _logRetry(attempt, delay, 'a server outage');
      } on TimeoutException {
        debugPrint('StudyPhotoService: attempt $attempt timed out.');
        if (attempt >= maxAttempts) {
          throw const StudyPhotoException(temporarilyBusy);
        }
      } catch (error) {
        // Transport failures (DNS, TLS, a dropped socket) and anything else.
        // `friendlyBackendError` already maps those to a sentence a student can
        // act on, and never reveals a URL or a credential.
        debugPrint(
          'StudyPhotoService: could not complete the call to $functionName '
          '(${error.runtimeType}).',
        );
        throw StudyPhotoException(friendlyBackendError(error));
      }

      await Future<void>.delayed(delay);
      delay *= 2;
    }

    // Unreachable: the loop above always returns or throws.
    throw const StudyPhotoException(temporarilyBusy);
  }

  void _logRetry(int attempt, Duration delay, String what) {
    debugPrint(
      'StudyPhotoService: attempt $attempt/$maxAttempts hit $what, retrying '
      'in ${delay.inSeconds}s.',
    );
  }

  /// Reads the function's JSON envelope and returns the generated text.
  ///
  /// Handles a malformed body, a missing `result`, a candidate without any
  /// part, and an empty text — none of which may crash the flow.
  static String parseResponseBody(Object? data) {
    if (data == null || data == '') {
      debugPrint('StudyPhotoService: the function returned an empty body.');
      throw const StudyPhotoException(noText);
    }

    // The SDK hands back decoded JSON when the content type says so, and raw
    // text otherwise. Accept a String body too, so an unexpected content type
    // cannot break the flow.
    Object? decoded = data;
    if (data is String) {
      try {
        decoded = jsonDecode(data);
      } on FormatException {
        debugPrint('StudyPhotoService: the function body was not JSON.');
        throw const StudyPhotoException(unreadable);
      }
    }

    if (decoded is! Map) {
      debugPrint('StudyPhotoService: unexpected function response type.');
      throw const StudyPhotoException(unreadable);
    }
    final envelope = Map<String, dynamic>.from(decoded);

    // The real outcome sits in `status`, even on an HTTP 200.
    final status = _intOrNull(envelope['status']);
    if (status != null && status != 200) {
      debugPrint(
        'StudyPhotoService: the function reported status $status. '
        'Error: ${_errorSummary(envelope['result'])}',
      );
      throw friendlyMessageForStatus(status);
    }

    final result = envelope['result'];
    if (result is! Map) {
      debugPrint('StudyPhotoService: no `result` object in the response.');
      throw const StudyPhotoException(noText);
    }

    final text = _extractText(Map<String, dynamic>.from(result));
    if (text == null || text.trim().isEmpty) {
      debugPrint('StudyPhotoService: the response carried no generated text.');
      throw const StudyPhotoException(noText);
    }
    return text;
  }

  /// Pulls `result.candidates[0].content.parts[*].text` out of a Gemini body.
  ///
  /// Every step is checked defensively, and all text parts are joined, so an
  /// answer split across parts still reads correctly.
  static String? _extractText(Map<String, dynamic> result) {
    final candidates = result['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final first = candidates.first;
    if (first is! Map) return null;

    final content = first['content'];
    if (content is! Map) return null;

    final parts = content['parts'];
    if (parts is! List) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      final String? text;
      if (part is Map) {
        text = part['text'] is String ? part['text'] as String : null;
      } else if (part is String) {
        text = part;
      } else {
        text = null;
      }
      if (text != null && text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(text);
      }
    }

    final text = buffer.toString();
    return text.isEmpty ? null : text;
  }

  /// True when a status is worth retrying.
  ///
  /// Only capacity problems qualify. A bad key, a missing function or a bad
  /// request would fail again identically, and retrying would just make the
  /// student wait longer for the same error.
  static bool isTransientStatus(int? status) => status != null && status >= 500;

  /// Maps a status code to the message a student can act on.
  static StudyPhotoException friendlyMessageForStatus(int status) {
    switch (status) {
      case 400:
        return const StudyPhotoException(
          'Study Nova could not read the image. Please choose a different '
          'photo or one that is clearer.',
          status: 400,
        );
      case 401:
      case 403:
        return const StudyPhotoException(
          'Please sign in again to use the AI explanation.',
          status: 401,
        );
      case 404:
        return const StudyPhotoException(notConfigured, status: 404);
      case 429:
        return const StudyPhotoException(
          'You have reached the AI usage limit for now. Please wait a few '
          'minutes and try again.',
          status: 429,
        );
    }
    if (isTransientStatus(status)) {
      return StudyPhotoException(temporarilyBusy, status: status);
    }
    return StudyPhotoException(
      'Study Nova could not reach its AI service right now. Please try again '
      'in a moment.',
      status: status,
    );
  }

  /// A short, safe summary of the function's error object, for the console.
  static String _errorSummary(Object? result) {
    if (result is Map) {
      final error = result['error'];
      if (error is Map) {
        return 'status=${error['status']} message=${error['message']}';
      }
    }
    return '(no detail)';
  }

  static int? _intOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Logs provider detail without ever logging the request body.
///
/// The body holds the student's photo as base64, so it is deliberately never
/// printed.
@visibleForTesting
void debugPrintDetail(Object? details) {
  if (details == null) return;
  final text = details.toString();
  const limit = 400;
  debugPrint(
    'StudyPhotoService: response detail '
    '${text.length <= limit ? text : '${text.substring(0, limit)}...'}',
  );
}
