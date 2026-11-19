import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'attendance.dart';

/// Attendance access: RLS-scoped reads and the V6 RPCs only; the client never writes tables.
abstract class AttendanceRepository {
  Future<List<AttendanceSession>> listSessions(String courseId);
  Future<AttendanceSession?> getSession(String sessionId);

  /// Sessions with `from <= starts_at < to` (UTC instants), oldest first; powers the weekly grid.
  Future<List<AttendanceSession>> listSessionsBetween(
    String courseId,
    DateTime from,
    DateTime to,
  );

  /// Records of the given sessions (RLS limits a student to their own); pages through the server row cap.
  Future<List<AttendanceRecord>> listRecordsForSessions(
    List<String> sessionIds,
  );

  /// Teacher: every record of one session (RLS limits students to their own).
  Future<List<AttendanceRecord>> listRecords(String sessionId);

  /// Student: the signed-in student's records in one course, newest session first.
  Future<List<AttendanceRecord>> listMyRecords(String courseId);
  Future<List<AttendanceEvent>> listEvents(String sessionId);
  Future<AttendanceSummary> summary(String courseId);

  Future<void> createSession({
    required String courseId,
    required String requestId,
    required String title,
    required DateTime startsAt,
  });
  Future<AttendanceRecord> mark({
    required String sessionId,
    required String studentId,
    required String requestId,
    required int expectedVersion,
    required AttendanceStatus status,
    required String note,
  });
  Future<AttendanceSession> close({
    required String sessionId,
    required String requestId,
    required int expectedVersion,
  });

  /// Student: submits a scanned (or typed) classroom code to the server, which alone decides.
  Future<ScanOutcome> scan(String token);
}

class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseAttendanceRepository(this._client);

  final SupabaseClient _client;
  static const _sessionCols =
      'id, course_id, title, starts_at, status, version';
  static const _recordCols =
      'session_id, student_id, status, note, version, checked_in_at, checked_out_at, source';

  @override
  Future<List<AttendanceSession>> listSessions(String courseId) async {
    final rows = await _client
        .from('attendance_sessions')
        .select(_sessionCols)
        .eq('course_id', courseId)
        .order('starts_at', ascending: false)
        .limit(300);
    return [for (final r in rows) ?AttendanceSession.fromRow(r)];
  }

  @override
  Future<List<AttendanceSession>> listSessionsBetween(
    String courseId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _client
        .from('attendance_sessions')
        .select(_sessionCols)
        .eq('course_id', courseId)
        .gte('starts_at', from.toUtc().toIso8601String())
        .lt('starts_at', to.toUtc().toIso8601String())
        .order('starts_at', ascending: true)
        .limit(100);
    return [for (final r in rows) ?AttendanceSession.fromRow(r)];
  }

  @override
  Future<List<AttendanceRecord>> listRecordsForSessions(
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return const [];
    // The API returns at most 1000 rows per request (config max_rows); page so a big class is never truncated.
    const page = 1000;
    final all = <AttendanceRecord>[];
    for (var from = 0; from < 10 * page; from += page) {
      final rows = await _client
          .from('attendance_records')
          .select(_recordCols)
          .inFilter('session_id', sessionIds)
          .order('session_id')
          .order('student_id')
          .range(from, from + page - 1);
      all.addAll([for (final r in rows) ?AttendanceRecord.fromRow(r)]);
      if (rows.length < page) break;
    }
    return all;
  }

  @override
  Future<AttendanceSession?> getSession(String sessionId) async {
    final row = await _client
        .from('attendance_sessions')
        .select(_sessionCols)
        .eq('id', sessionId)
        .maybeSingle();
    return row == null ? null : AttendanceSession.fromRow(row);
  }

  @override
  Future<List<AttendanceRecord>> listRecords(String sessionId) async {
    final rows = await _client
        .from('attendance_records')
        .select(_recordCols)
        .eq('session_id', sessionId);
    return [for (final r in rows) ?AttendanceRecord.fromRow(r)];
  }

  @override
  Future<List<AttendanceRecord>> listMyRecords(String courseId) async {
    final rows = await _client
        .from('attendance_records')
        .select(
          '$_recordCols, '
          'attendance_sessions!inner(title, starts_at, status, course_id)',
        )
        .eq('attendance_sessions.course_id', courseId);
    final list = [for (final r in rows) ?AttendanceRecord.fromRow(r)];
    list.sort(
      (a, b) => (b.sessionStartsAt ?? DateTime(0)).compareTo(
        a.sessionStartsAt ?? DateTime(0),
      ),
    );
    return list;
  }

  @override
  Future<List<AttendanceEvent>> listEvents(String sessionId) async {
    final rows = await _client
        .from('attendance_events')
        .select('action, student_id, old_status, new_status, note, created_at')
        .eq('session_id', sessionId)
        .order('created_at', ascending: false)
        .limit(200);
    return [for (final r in rows) ?AttendanceEvent.fromRow(r)];
  }

  @override
  Future<AttendanceSummary> summary(String courseId) async =>
      AttendanceSummary.fromJson(
        await _rpc('get_attendance_summary', {'p_course_id': courseId}),
      );

  @override
  Future<void> createSession({
    required String courseId,
    required String requestId,
    required String title,
    required DateTime startsAt,
  }) async {
    await _rpc('create_attendance_session', {
      'p_course_id': courseId,
      'p_request_id': requestId,
      'p_title': title,
      'p_starts_at': startsAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<AttendanceRecord> mark({
    required String sessionId,
    required String studentId,
    required String requestId,
    required int expectedVersion,
    required AttendanceStatus status,
    required String note,
  }) async {
    final j = await _rpc('mark_attendance', {
      'p_session_id': sessionId,
      'p_student_id': studentId,
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_status': status.wire,
      'p_note': note,
    });
    return AttendanceRecord(
      sessionId: sessionId,
      studentId: studentId,
      status: AttendanceStatus.parse(j['status']) ?? status,
      note: (j['note'] as String?) ?? note,
      version: (j['version'] as num).toInt(),
    );
  }

  @override
  Future<AttendanceSession> close({
    required String sessionId,
    required String requestId,
    required int expectedVersion,
  }) async {
    await _rpc('close_attendance_session', {
      'p_session_id': sessionId,
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
    });
    final s = await getSession(sessionId);
    if (s == null) {
      throw const AppError(
        AppErrorKind.notFound,
        'Session not found.',
        AppErrorCode.sessionNotFound,
      );
    }
    return s;
  }

  @override
  Future<ScanOutcome> scan(String token) async => ScanOutcome.fromJson(
    await _rpc('scan_attendance', {'p_token': token.trim()}),
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
      throw AppError.from(e);
    }
  }
}
