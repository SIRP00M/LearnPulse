class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String status;
  final DateTime? checkedInAt;
  final String note;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.note,
    this.checkedInAt,
  });

  factory AttendanceRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    return AttendanceRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      status: map['status'] as String? ?? 'absent',
      checkedInAt: map['checked_in_at'] == null
          ? null
          : DateTime.parse(
              map['checked_in_at'] as String,
            ),
      note: map['note'] as String? ?? '',
    );
  }
}