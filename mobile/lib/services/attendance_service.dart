import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_record.dart';
import '../models/attendance_session.dart';

class AttendanceService {
  SupabaseClient get _supabase =>
      Supabase.instance.client;

  Future<List<AttendanceSession>> getCourseSessions(
    String courseId,
  ) async {
    final data = await _supabase
        .from('attendance_sessions')
        .select()
        .eq('course_id', courseId)
        .order('starts_at', ascending: false);

    return (data as List<dynamic>)
        .map(
          (item) => AttendanceSession.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<AttendanceSession> createSession({
    required String courseId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    int lateAfterMinutes = 15,
  }) async {
    final data = await _supabase.rpc(
      'create_attendance_session',
      params: {
        'target_course_id': courseId,
        'session_title': title.trim(),
        'start_time': startsAt.toIso8601String(),
        'end_time': endsAt.toIso8601String(),
        'late_minutes': lateAfterMinutes,
      },
    );

    return AttendanceSession.fromMap(
      data as Map<String, dynamic>,
    );
  }

  Future<AttendanceRecord> checkIn(
    String code,
  ) async {
    final data = await _supabase.rpc(
      'check_in_attendance',
      params: {
        'attendance_code': code.trim(),
      },
    );

    return AttendanceRecord.fromMap(
      data as Map<String, dynamic>,
    );
  }

  Future<List<Map<String, dynamic>>> getSessionRecords(
    String sessionId,
  ) async {
    final data = await _supabase
        .from('attendance_records')
        .select('''
          id,
          session_id,
          student_id,
          status,
          checked_in_at,
          note,
          student:profiles!attendance_records_student_id_fkey(
            id,
            full_name,
            avatar_url
          )
        ''')
        .eq('session_id', sessionId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateRecordStatus({
    required String recordId,
    required String status,
    String note = '',
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    await _supabase
        .from('attendance_records')
        .update({
          'status': status,
          'note': note.trim(),
          'marked_by': user.id,
          'checked_in_at':
              status == 'present' || status == 'late'
                  ? DateTime.now().toIso8601String()
                  : null,
        })
        .eq('id', recordId);
  }

  Future<void> closeSession(String sessionId) async {
    await _supabase
        .from('attendance_sessions')
        .update({
          'status': 'closed',
        })
        .eq('id', sessionId);
  }
}