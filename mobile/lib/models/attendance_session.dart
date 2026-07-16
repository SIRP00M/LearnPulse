class AttendanceSession {
  final String id;
  final String courseId;
  final String title;
  final DateTime sessionDate;
  final DateTime startsAt;
  final DateTime endsAt;
  final String checkInCode;
  final String status;
  final int lateAfterMinutes;

  const AttendanceSession({
    required this.id,
    required this.courseId,
    required this.title,
    required this.sessionDate,
    required this.startsAt,
    required this.endsAt,
    required this.checkInCode,
    required this.status,
    required this.lateAfterMinutes,
  });

  factory AttendanceSession.fromMap(
    Map<String, dynamic> map,
  ) {
    return AttendanceSession(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String? ?? '',
      sessionDate: DateTime.parse(
        map['session_date'] as String,
      ),
      startsAt: DateTime.parse(
        map['starts_at'] as String,
      ),
      endsAt: DateTime.parse(
        map['ends_at'] as String,
      ),
      checkInCode:
          map['check_in_code'] as String? ?? '',
      status: map['status'] as String? ?? 'scheduled',
      lateAfterMinutes:
          map['late_after_minutes'] as int? ?? 15,
    );
  }
}