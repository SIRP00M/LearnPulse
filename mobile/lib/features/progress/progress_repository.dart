import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'progress.dart';

/// Progress reads (V9). The server enforces who may see whom; both calls answer "not found" for anything else.
abstract class ProgressRepository {
  /// Teacher: one active member of an owned course.
  Future<StudentProgress> forStudent(String courseId, String studentId);

  /// Student: the signed-in student's own progress in a course.
  Future<StudentProgress> mine(String courseId);
}

class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository(this._client);
  final SupabaseClient _client;

  Future<StudentProgress> _call(String fn, Map<String, dynamic> p) async {
    try {
      return StudentProgress.fromJson(
        Map<String, dynamic>.from(await _client.rpc(fn, params: p) as Map),
      );
    } on PostgrestException catch (e) {
      throw AppError.from(e);
    }
  }

  @override
  Future<StudentProgress> forStudent(String courseId, String studentId) =>
      _call('get_student_progress', {
        'p_course_id': courseId,
        'p_student_id': studentId,
      });

  @override
  Future<StudentProgress> mine(String courseId) =>
      _call('get_my_progress', {'p_course_id': courseId});
}
