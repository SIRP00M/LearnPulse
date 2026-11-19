import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'course.dart';

/// All course access goes through RLS-scoped reads and the V0/V2 RPCs; the client never writes tables.
abstract class CourseRepository {
  Future<List<Course>> listCourses();
  Future<NewCourse> createCourse({
    required String title,
    String description = '',
  });
  Future<JoinResult> joinByCode(String code);
  Future<String> joinCode(String courseId);
  Future<void> updateCourse(
    String courseId, {
    String? title,
    String? description,
    CourseStatus? status,
  });
  Future<List<RosterEntry>> roster(String courseId);
  Future<void> removeMember(String courseId, String studentId);
}

class SupabaseCourseRepository implements CourseRepository {
  SupabaseCourseRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Course>> listCourses() async {
    final rows = await _client
        .from('courses')
        .select(
          'id, owner_id, title, description, status, created_at, '
          'owner:profiles!courses_owner_id_fkey(full_name)',
        )
        .order('created_at', ascending: false);
    return [for (final r in rows) ?Course.fromRow(r)];
  }

  @override
  Future<NewCourse> createCourse({
    required String title,
    String description = '',
  }) async {
    final json = await _rpc('create_course', {
      'p_title': title,
      'p_description': description,
    });
    return NewCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      joinCode: json['join_code'] as String,
    );
  }

  @override
  Future<JoinResult> joinByCode(String code) async =>
      JoinResult.fromJson(await _rpc('join_course_by_code', {'p_code': code}));

  @override
  Future<String> joinCode(String courseId) async {
    try {
      return await _client.rpc(
            'get_course_join_code',
            params: {'p_course_id': courseId},
          )
          as String;
    } on PostgrestException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> updateCourse(
    String courseId, {
    String? title,
    String? description,
    CourseStatus? status,
  }) async {
    await _rpc('update_course', {
      'p_course_id': courseId,
      'p_title': ?title,
      'p_description': ?description,
      'p_status': ?status?.name,
    });
  }

  @override
  Future<List<RosterEntry>> roster(String courseId) async {
    final rows = await _client
        .from('course_members')
        .select(
          'student_id, status, joined_at, student:profiles!course_members_student_id_fkey(full_name)',
        )
        .eq('course_id', courseId)
        .order('joined_at', ascending: true);
    return [for (final r in rows) ?RosterEntry.fromRow(r)];
  }

  @override
  Future<void> removeMember(String courseId, String studentId) => _rpc(
    'remove_course_member',
    {'p_course_id': courseId, 'p_student_id': studentId},
  );

  Future<Map<String, dynamic>> _rpc(
    String fn,
    Map<String, dynamic> params,
  ) async {
    try {
      return Map<String, dynamic>.from(
        await _client.rpc(fn, params: params) as Map,
      );
    } on PostgrestException catch (e) {
      throw _map(e);
    }
  }

  AppError _map(PostgrestException e) => AppError.from(e);
}
