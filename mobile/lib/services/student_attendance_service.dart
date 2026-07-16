import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAttendanceService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<StudentAttendanceSession>> getCourseSessions(
    String courseId,
  ) async {
    final data = await _supabase.rpc(
      'get_student_attendance_sessions',
      params: {
        'target_course_id': courseId,
      },
    );

    return _normalizeRows(data)
        .map(StudentAttendanceSession.fromMap)
        .toList();
  }

  Future<List<StudentAttendanceEntry>> getMyAttendance(
    String courseId,
  ) async {
    final data = await _supabase.rpc(
      'get_my_course_attendance',
      params: {
        'target_course_id': courseId,
      },
    );

    return _normalizeRows(data)
        .map(StudentAttendanceEntry.fromMap)
        .toList();
  }

  Future<StudentCheckInResult> checkIn(
    String attendanceCode,
  ) async {
    final code = attendanceCode.trim().toUpperCase();

    if (code.isEmpty) {
      throw ArgumentError(
        'Attendance code is required.',
      );
    }

    final data = await _supabase.rpc(
      'check_in_attendance',
      params: {
        'attendance_code': code,
      },
    );

    final rows = _normalizeRows(data);

    if (rows.isEmpty) {
      throw StateError(
        'Attendance check-in did not return a result.',
      );
    }

    return StudentCheckInResult.fromMap(
      rows.first,
    );
  }

  List<Map<String, dynamic>> _normalizeRows(
    dynamic data,
  ) {
    if (data is Map) {
      return [
        Map<String, dynamic>.from(data),
      ];
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    return const [];
  }
}

class StudentAttendanceSession {
  final String id;
  final String courseId;
  final String title;
  final DateTime sessionDate;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final int lateAfterMinutes;

  const StudentAttendanceSession({
    required this.id,
    required this.courseId,
    required this.title,
    required this.sessionDate,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.lateAfterMinutes,
  });

  bool get isOpenNow {
    final now = DateTime.now();

    return status == 'open' &&
        !now.isBefore(startsAt) &&
        !now.isAfter(endsAt);
  }

  bool get hasEnded {
    return DateTime.now().isAfter(endsAt) ||
        status == 'closed' ||
        status == 'cancelled';
  }

  factory StudentAttendanceSession.fromMap(
    Map<String, dynamic> map,
  ) {
    return StudentAttendanceSession(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String? ??
          'Class attendance',
      sessionDate: DateTime.parse(
        map['session_date'] as String,
      ),
      startsAt: DateTime.parse(
        map['starts_at'] as String,
      ),
      endsAt: DateTime.parse(
        map['ends_at'] as String,
      ),
      status: map['status'] as String? ?? 'scheduled',
      lateAfterMinutes:
          map['late_after_minutes'] as int? ?? 15,
    );
  }
}

class StudentAttendanceEntry {
  final String recordId;
  final String sessionId;
  final String sessionTitle;
  final DateTime sessionDate;
  final DateTime startsAt;
  final DateTime endsAt;
  final String sessionStatus;
  final String attendanceStatus;
  final DateTime? checkedInAt;
  final String note;

  const StudentAttendanceEntry({
    required this.recordId,
    required this.sessionId,
    required this.sessionTitle,
    required this.sessionDate,
    required this.startsAt,
    required this.endsAt,
    required this.sessionStatus,
    required this.attendanceStatus,
    required this.note,
    this.checkedInAt,
  });

  factory StudentAttendanceEntry.fromMap(
    Map<String, dynamic> map,
  ) {
    return StudentAttendanceEntry(
      recordId: map['record_id'] as String,
      sessionId: map['session_id'] as String,
      sessionTitle: map['session_title'] as String? ??
          'Class attendance',
      sessionDate: DateTime.parse(
        map['session_date'] as String,
      ),
      startsAt: DateTime.parse(
        map['starts_at'] as String,
      ),
      endsAt: DateTime.parse(
        map['ends_at'] as String,
      ),
      sessionStatus:
          map['session_status'] as String? ?? 'scheduled',
      attendanceStatus:
          map['attendance_status'] as String? ?? 'absent',
      checkedInAt: map['checked_in_at'] == null
          ? null
          : DateTime.parse(
              map['checked_in_at'] as String,
            ),
      note: map['note'] as String? ?? '',
    );
  }
}

class StudentCheckInResult {
  final String id;
  final String sessionId;
  final String studentId;
  final String status;
  final DateTime? checkedInAt;

  const StudentCheckInResult({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.checkedInAt,
  });

  factory StudentCheckInResult.fromMap(
    Map<String, dynamic> map,
  ) {
    return StudentCheckInResult(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      status: map['status'] as String? ?? 'present',
      checkedInAt: map['checked_in_at'] == null
          ? null
          : DateTime.parse(
              map['checked_in_at'] as String,
            ),
    );
  }
}