import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment.dart';
import '../models/course_file.dart';
import '../models/course_post.dart';
import '../models/lesson.dart';
import '../models/user_profile.dart';

class TeacherCourseService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<CoursePost>> getPosts(String courseId) async {
    final data = await _supabase
        .from('course_posts')
        .select()
        .eq('course_id', courseId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return (data as List).map((item) => CoursePost.fromMap(item)).toList();
  }

  Future<List<Lesson>> getLessons(String courseId) async {
    final data = await _supabase
        .from('lessons')
        .select()
        .eq('course_id', courseId)
        .order('position');

    return (data as List).map((item) => Lesson.fromMap(item)).toList();
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    final data = await _supabase
        .from('assignments')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return (data as List).map((item) => Assignment.fromMap(item)).toList();
  }

  Future<List<UserProfile>> getStudents(String courseId) async {
    final data = await _supabase
        .from('course_members')
        .select('''
          student:profiles!course_members_student_id_fkey(
            id,
            full_name,
            role,
            avatar_url
          )
        ''')
        .eq('course_id', courseId)
        .eq('status', 'enrolled');

    return (data as List)
        .map((item) => item['student'])
        .whereType<Map<String, dynamic>>()
        .map(UserProfile.fromMap)
        .toList();
  }

  Future<List<CourseFile>> getFiles(String courseId) async {
    final data = await _supabase
        .from('course_files')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return (data as List).map((item) => CourseFile.fromMap(item)).toList();
  }

  Future<void> createPost({
    required String courseId,
    required String title,
    required String content,
    required bool publishNow,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    await _supabase.from('course_posts').insert({
      'course_id': courseId,
      'author_id': user.id,
      'title': title.trim(),
      'content': content.trim(),
      'published_at': publishNow ? DateTime.now().toIso8601String() : null,
    });
  }

  Future<void> createLesson({
    required String courseId,
    required String title,
    required String description,
    required String content,
    required int position,
    required bool publishNow,
  }) async {
    await _supabase.from('lessons').insert({
      'course_id': courseId,
      'title': title.trim(),
      'description': description.trim(),
      'content': content.trim(),
      'position': position,
      'published_at': publishNow ? DateTime.now().toIso8601String() : null,
    });
  }

  Future<void> createAssignment({
    required String courseId,
    required String title,
    required String instructions,
    required DateTime? dueAt,
    required double maxScore,
    required bool allowLate,
    required bool publishNow,
  }) async {
    await _supabase.from('assignments').insert({
      'course_id': courseId,
      'title': title.trim(),
      'instructions': instructions.trim(),
      'due_at': dueAt?.toIso8601String(),
      'max_score': maxScore,
      'allow_late': allowLate,
      'published_at': publishNow ? DateTime.now().toIso8601String() : null,
    });
  }
}
