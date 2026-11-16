import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/study_scan_model.dart';
import '../utils/supabase_availability.dart';

class StudyScanService {
  static const String _tableName = 'study_scans';
  static const String _bucketName = 'study_images';

  /// Resolved lazily: `Supabase.instance` asserts before `Supabase.initialize`
  /// has run, so the Study Library must degrade gracefully when the cloud is
  /// unavailable instead of crashing the app.
  SupabaseClient get _supabase {
    final supabase = safeSupabase();
    if (supabase == null) {
      // A null client is *either* "this build has no backend" *or* "the backend
      // did not come up". Neither means the student's internet is gone.
      if (!isSupabaseConfigured) {
        throw const BackendNotConfiguredException(
          feature: 'your Study Library',
        );
      }
      throw const BackendUnavailableException();
    }
    return supabase.client;
  }

  /// True when the Study Library can talk to Supabase at all.
  bool get isCloudAvailable => safeSupabase() != null;

  /// Shown instead of a raw exception whenever an action needs a signed-in
  /// student, so the UI never has to display a technical message.
  static const String _notSignedIn =
      'Please sign in to continue using your Study Library.';

  /// Shown for every Supabase or storage failure. The provider's own message
  /// is printed to the console for the app owner and never shown to a
  /// student.
  ///
  /// This deliberately does **not** blame the student's connection: the request
  /// reached Supabase, so whatever went wrong is on the service side.
  static const String _friendlyDatabaseError =
      'Study Nova could not reach its online service right now. Please try '
      'again in a moment.';

  /// Get current user ID
  String? _getCurrentUserId() {
    return safeSupabase()?.client.auth.currentUser?.id;
  }

  /// Save a new study scan
  Future<StudyScanModel> saveStudyScan(StudyScanModel studyScan) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception(_notSignedIn);
    }

    try {
      final data = studyScan.toJson();
      data['user_id'] = userId;
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final response = await _supabase
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return StudyScanModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint(
        'StudyScanService: database error. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    } catch (e) {
      debugPrint('StudyScanService: saving study scan failed: $e');
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Get a study scan by ID
  Future<StudyScanModel?> getStudyScan(String id) async {
    final userId = _getCurrentUserId();
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return StudyScanModel.fromJson(response);
    } catch (e) {
      debugPrint('StudyScanService: fetching study scan failed: $e');
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Get all study scans for current user
  Future<List<StudyScanModel>> getUserStudyScans({
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => StudyScanModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('StudyScanService: fetching study scans failed: $e');
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Get study scans by subject
  Future<List<StudyScanModel>> getStudyScansBySubject(String subject) async {
    final userId = _getCurrentUserId();
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('subject', subject)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => StudyScanModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint(
        'StudyScanService: fetching study scans by subject failed: $e',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Search study scans by topic
  Future<List<StudyScanModel>> searchStudyScans(String query) async {
    final userId = _getCurrentUserId();
    if (userId == null) return [];

    // A search term is typed by a student, never a developer: strip the
    // characters a PostgREST `.or()` filter treats as syntax.
    final safe = query
        .replaceAll(RegExp(r'[,()%*]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (safe.isEmpty) return [];

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .or('topic.ilike.%$safe%,subject.ilike.%$safe%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => StudyScanModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('StudyScanService: searching study scans failed: $e');
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Update a study scan
  Future<StudyScanModel> updateStudyScan(StudyScanModel studyScan) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception(_notSignedIn);
    }

    if (studyScan.id == null) {
      throw Exception('Study scan must have an ID to update');
    }

    try {
      final data = studyScan.toJson();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      data.remove('created_at'); // Don't update creation time

      final response = await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', studyScan.id!)
          .eq('user_id', userId)
          .select()
          .single();

      return StudyScanModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint(
        'StudyScanService: database error. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    } catch (e) {
      debugPrint('StudyScanService: updating study scan failed: $e');
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Delete a study scan and its image
  Future<void> deleteStudyScan(String id) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception(_notSignedIn);
    }

    try {
      // Get the study scan first to find the image path
      final studyScan = await getStudyScan(id);
      if (studyScan != null && studyScan.imageUrl != null) {
        // Delete image from storage
        await deleteImage(studyScan.imageUrl!);
      }

      // Delete from database
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('StudyScanService: deleting study scan failed: $e');
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Upload an image to Supabase Storage
  Future<String> uploadImage(List<int> imageBytes, String fileName) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception(_notSignedIn);
    }

    try {
      // Create a unique path: user_id/timestamp_filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/study_${timestamp}_$fileName';

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            Uint8List.fromList(imageBytes),
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      debugPrint('StudyScanService: uploading image failed: $e');
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Delete an image from storage using URL
  Future<void> deleteImage(String imageUrl) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      // Extract the path from the URL
      // Format: https://...supabase.co/storage/v1/object/public/study_images/path
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the 'study_images' index and get everything after it
      final bucketIndex = pathSegments.indexOf('study_images');
      if (bucketIndex == -1 || bucketIndex == pathSegments.length - 1) {
        return;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Only ever delete inside the signed-in student's own folder, so a
      // crafted URL can never remove another account's photo.
      if (!filePath.startsWith('$userId/')) {
        debugPrint(
          'StudyScanService: refused to delete an image outside the signed-in '
          "student's own folder.",
        );
        return;
      }

      await _supabase.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      // Log but don't throw - image deletion failure shouldn't block operations
      debugPrint('Warning: Error deleting image: $e');
    }
  }

  /// Get storage URL for an image path
  String getImageUrl(String storagePath) {
    return _supabase.storage.from(_bucketName).getPublicUrl(storagePath);
  }

  /// Check if bucket exists and create if needed
  Future<void> initializeStorage() async {
    try {
      // Try to access the bucket
      await _supabase.storage.from(_bucketName).list(path: 'test');
    } catch (e) {
      // If bucket doesn't exist, we'll need to create it via Supabase dashboard
      debugPrint(
        'Note: Storage bucket "$_bucketName" may need to be created manually',
      );
    }
  }

  /// Get statistics for user's study scans
  Future<Map<String, int>> getStatistics() async {
    final userId = _getCurrentUserId();
    if (userId == null) return {'total': 0, 'subjects': 0, 'this_month': 0};

    try {
      // Total scans
      final allScans = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId);

      // This month
      final thisMonth = DateTime.now();
      final monthStart = DateTime(thisMonth.year, thisMonth.month, 1);
      final thisMonthScans = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', monthStart.toUtc().toIso8601String());

      return {
        'total': (allScans as List).length,
        'subjects': 0,
        'this_month': (thisMonthScans as List).length,
      };
    } catch (e) {
      return {'total': 0, 'subjects': 0, 'this_month': 0};
    }
  }
}
