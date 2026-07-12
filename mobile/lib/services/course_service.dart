import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course.dart';

class CourseService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<Course>> getMyCourses() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final data = await _supabase
        .from('courses')
        .select('''
          id,
          teacher_id,
          title,
          course_code,
          description,
          overview,
          cover_url,
          status,
          created_at,
          teacher:profiles!courses_teacher_id_fkey(
            full_name
          )
        ''')
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => Course.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Course>> getTeacherCourses() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final data = await _supabase
        .from('courses')
        .select('''
          id,
          teacher_id,
          title,
          course_code,
          description,
          overview,
          cover_url,
          status,
          created_at,
          teacher:profiles!courses_teacher_id_fkey(
            full_name
          )
        ''')
        .eq('teacher_id', user.id)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => Course.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Course> createCourse({
    required String title,
    required String description,
    required String overview,
    required String status,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final data = await _supabase
        .from('courses')
        .insert({
          'teacher_id': user.id,
          'title': title.trim(),
          'description': description.trim(),
          'overview': overview.trim(),
          'status': status,
        })
        .select('''
          id,
          teacher_id,
          title,
          course_code,
          description,
          overview,
          cover_url,
          status,
          created_at,
          teacher:profiles!courses_teacher_id_fkey(
            full_name
          )
        ''')
        .single();

    return Course.fromMap(data);
  }

  Future<String> joinCourseByCode(String courseCode) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final result = await _supabase.rpc(
      'join_course_by_code',
      params: {'join_code': courseCode.trim().toUpperCase()},
    );

    if (result == null) {
      throw StateError('Unable to join this course.');
    }

    return result.toString();
  }
}
