import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studynova/services/study_photo_service.dart';

/// Builds a [StudyPhotoService] whose *attempt* is recorded rather than sent.
///
/// The seam is deliberately one layer below the service: the real
/// `requestExplanation` still builds the request body (including the base64
/// encoding) and the real `_invokeWithRetries` still decides what to retry. Only
/// the network call is replaced, so what these tests prove is the production
/// behaviour rather than a copy of it.
class RecordingStudyPhotoService {
  RecordingStudyPhotoService({this.queuedBodies, this.httpStatus});

  /// Bodies to return, in order. The final entry repeats if more calls arrive,
  /// which keeps a retry test readable.
  final List<Object?>? queuedBodies;

  /// When set, every attempt fails with this HTTP status, exactly as the real
  /// SDK does for a non-2xx response: it throws instead of returning a body.
  final int? httpStatus;

  /// Bodies received by the app, one per attempt.
  final List<Map<String, dynamic>> receivedBodies = <Map<String, dynamic>>[];

  /// The body of the most recent attempt.
  Map<String, dynamic>? get lastBody =>
      receivedBodies.isEmpty ? null : receivedBodies.last;

  /// Number of attempts the app made.
  int get calls => receivedBodies.length;

  /// The service to hand to `AIStudyService`.
  StudyPhotoService get service => StudyPhotoService.withAttempt(_attempt);

  Future<Object?> _attempt(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    receivedBodies.add(Map<String, dynamic>.from(body));

    final status = httpStatus;
    if (status != null) {
      throw FunctionException(
        status: status,
        details: <String, dynamic>{'error': 'recorded failure'},
        reasonPhrase: 'recorded',
      );
    }

    final queue = queuedBodies;
    if (queue == null || queue.isEmpty) {
      throw StateError(
        'RecordingStudyPhotoService had no recorded body to return.',
      );
    }
    return queue.length == 1 ? queue.first : queue[receivedBodies.length - 1];
  }
}
