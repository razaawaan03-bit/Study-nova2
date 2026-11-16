import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/course_content_model.dart';
import '../utils/supabase_availability.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();

  factory CourseService() {
    return _instance;
  }

  CourseService._internal();

  /// Shown instead of a raw exception whenever an action needs a signed-in
  /// student, so the UI never has to display a technical message.
  static const String _notSignedIn =
      'Please sign in to continue using your courses.';

  /// Shown for every Supabase/PostgREST failure. The provider's own message
  /// (table names, column names, SQL detail) is printed to the console for the
  /// app owner and never shown to a student.
  ///
  /// This deliberately does **not** blame the student's connection: a PostgREST
  /// error means the request reached Supabase, and anything below it (a missing
  /// table, a rejected row) is a backend or permissions problem.
  static const String _friendlyDatabaseError =
      'Study Nova could not reach its online service right now. Please try '
      'again in a moment.';

  /// Resolved lazily: `Supabase.instance` asserts before `Supabase.initialize`
  /// has run, and the app must still start (offline) when no backend is
  /// configured.
  SupabaseClient get _supabase {
    final supabase = safeSupabase();
    if (supabase == null) {
      // A null client is *either* "this build has no backend" *or* "the backend
      // did not come up". Neither means the student's internet is gone, so the
      // two are reported separately instead of as an offline device.
      if (!isSupabaseConfigured) {
        throw const BackendNotConfiguredException(feature: 'saved courses');
      }
      throw const BackendUnavailableException();
    }
    return supabase.client;
  }

  /// Get all courses for the current user
  Future<List<Map<String, dynamic>>> getUserCourses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      final response = await _supabase
          .from('courses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Database error failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Get a specific course by ID
  ///
  /// Scoped to the signed-in student so one account can never read another
  /// account's course.
  Future<Map<String, dynamic>> getCourseById(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      // `maybeSingle` instead of `single`: a course that is not there returns
      // null rather than throwing a StateError the student would see.
      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', courseId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception(
          'That course could not be found. It may have been deleted.',
        );
      }
      return response;
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error fetching course failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Save a generated course to Supabase
  ///
  /// This saves the complete GeneratedCourse to the courses table.
  /// The generated course JSON is stored in the content column.
  /// Returns the ID of the saved course.
  Future<String> saveGeneratedCourse(GeneratedCourse generatedCourse) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      // Save to courses table
      final response = await _supabase
          .from('courses')
          .insert({
            'user_id': userId,
            'title': generatedCourse.course.title,
            'description': generatedCourse.course.description,
            'course_type': generatedCourse.course.courseType.storageValue,
            'class_level': generatedCourse.course.classLevel,
            'subject': generatedCourse.course.subject,
            'exam_target': generatedCourse.course.examTarget,
            'length': generatedCourse.course.length.storageValue,
            'difficulty': generatedCourse.course.difficulty.storageValue,
            'language': generatedCourse.course.language.storageValue,
            'learning_goal': generatedCourse.course.learningGoal,
            'content': generatedCourse.toJson(),
            'chapter_count': generatedCourse.chapterCount,
            'topic_count': generatedCourse.topicCount,
            'progress': 0,
            'is_published': false,
          })
          .select()
          .maybeSingle();

      if (response == null) {
        debugPrint('CourseService: the insert returned no saved row.');
        throw Exception(
          'Study Nova could not save this course. Please try again.',
        );
      }
      return response['id'] as String;
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error saving course failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Load a generated course from Supabase
  ///
  /// Fetches a saved course by ID and reconstructs it as a GeneratedCourse.
  /// Returns null if the course was not found or user doesn't have access.
  Future<GeneratedCourse?> loadGeneratedCourse(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', courseId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Course not found or user doesn't have access.
        return null;
      }
      final content = response['content'] as Map<String, dynamic>? ?? {};
      return GeneratedCourse.fromJson(content);
    } on PostgrestException {
      // Course not found or user doesn't have access
      return null;
    }
  }

  /// Rename an existing course
  Future<void> updateCourseTitle(String courseId, String title) async {
    try {
      // Scoped to the signed-in student: the client must never rely on the
      // database alone to stop one account renaming another account's course.
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      await _supabase
          .from('courses')
          .update({
            'title': title,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', courseId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error renaming course failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Create a new course
  Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    String? coverImage,
    Map<String, dynamic>? content,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      final response = await _supabase.from('courses').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'cover_image': coverImage,
        'content': content ?? {},
        'is_published': false,
      }).select();

      return response.first;
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error creating course failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Update a course
  Future<Map<String, dynamic>> updateCourse({
    required String courseId,
    String? title,
    String? description,
    String? coverImage,
    Map<String, dynamic>? content,
    bool? isPublished,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (coverImage != null) updates['cover_image'] = coverImage;
      if (content != null) updates['content'] = content;
      if (isPublished != null) updates['is_published'] = isPublished;

      updates['updated_at'] = DateTime.now().toIso8601String();

      // Scoped to the owner so a course belonging to another student can
      // never be edited through this app.
      final response = await _supabase
          .from('courses')
          .update(updates)
          .eq('id', courseId)
          .eq('user_id', userId)
          .select();

      if (response.isEmpty) {
        throw Exception('This course could not be found in your account.');
      }
      return response.first;
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error updating course failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      // Scoped to the owner so one student can never delete another's course.
      await _supabase
          .from('courses')
          .delete()
          .eq('id', courseId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error deleting course failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Stream user's courses (real-time updates)
  Stream<List<Map<String, dynamic>>> streamUserCourses() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.error(_notSignedIn);
    }

    return _supabase
        .from('courses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((courses) => List<Map<String, dynamic>>.from(courses));
  }

  /// Publish/unpublish a course
  Future<void> publishCourse(String courseId, bool publish) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      // Scoped to the owner.
      await _supabase
          .from('courses')
          .update({
            'is_published': publish,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', courseId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error publishing course failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Get published courses for discovery
  Future<List<Map<String, dynamic>>> getPublishedCourses({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error fetching courses failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Search courses
  Future<List<Map<String, dynamic>>> searchCourses(
    String query, {
    int limit = 20,
  }) async {
    final safe = _escapeSearchTerm(query);
    if (safe.isEmpty) return const [];

    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('is_published', true)
          .or('title.ilike.%$safe%,description.ilike.%$safe%')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error searching courses failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Strips the characters a PostgREST `.or()` filter treats as syntax.
  ///
  /// A search term is typed by a student, never a developer, and a stray comma
  /// or bracket would otherwise change the meaning of the whole filter.
  static String _escapeSearchTerm(String term) => term
      .replaceAll(RegExp(r'[,()%*]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Enroll user in a course
  Future<void> enrollCourse(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      await _supabase.from('enrollments').insert({
        'user_id': userId,
        'course_id': courseId,
        'progress': 0,
      });
    } on PostgrestException catch (e) {
      // Ignore duplicate enrollment error
      if (!e.message.contains('duplicate key')) {
        debugPrint(
          'CourseService: Error enrolling in course failed. Supabase said: ${e.message}',
        );
        throw Exception(_friendlyDatabaseError);
      }
    }
  }

  /// Get user's enrollments
  Future<List<Map<String, dynamic>>> getUserEnrollments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      final response = await _supabase
          .from('enrollments')
          .select('*, courses(*)')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error fetching enrollments failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }

  /// Update course progress
  Future<void> updateProgress(String courseId, int progress) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception(_notSignedIn);

      await _supabase
          .from('enrollments')
          .update({'progress': progress})
          .eq('user_id', userId)
          .eq('course_id', courseId);
    } on PostgrestException catch (e) {
      debugPrint(
        'CourseService: Error updating progress failed. Supabase said: ${e.message}',
      );
      throw Exception(_friendlyDatabaseError);
    }
  }
}
