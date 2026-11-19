import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';

enum AttendanceStatus {
  present('present', 'Present'),
  late('late', 'Late'),
  excused('excused', 'Excused'),
  absent('absent', 'Absent');

  const AttendanceStatus(this.wire, this.label);
  final String wire;
  final String label;

  String text(AppLocalizations l) => switch (this) {
    present => l.attPresent,
    late => l.attLate,
    excused => l.attExcused,
    absent => l.attAbsent,
  };

  static AttendanceStatus? parse(Object? v) {
    for (final s in values) {
      if (s.wire == v) return s;
    }
    return null;
  }
}

const maxAttendanceNote = 500;

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.courseId,
    required this.title,
    required this.startsAt,
    required this.closed,
    required this.version,
  });

  final String id;
  final String courseId;
  final String title;
  final DateTime startsAt; // UTC instant
  final bool closed;
  final int version;

  static AttendanceSession? fromRow(Map<String, dynamic> r) {
    final starts = DateTime.tryParse('${r['starts_at']}');
    if (r['id'] is! String || r['title'] is! String || starts == null) {
      return null;
    }
    return AttendanceSession(
      id: r['id'] as String,
      courseId: (r['course_id'] as String?) ?? '',
      title: r['title'] as String,
      startsAt: starts.toUtc(),
      closed: r['status'] == 'closed',
      version: (r['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.note,
    required this.version,
    this.sessionTitle = '',
    this.sessionStartsAt,
    this.sessionClosed = false,
    this.checkedInAt,
    this.checkedOutAt,
    this.source,
  });

  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final String note;
  final int version;
  final String sessionTitle; // student view only
  final DateTime? sessionStartsAt;
  final bool sessionClosed;

  /// Server timestamps (UTC). Null for historical records and for marks a teacher made by hand: nothing is invented.
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  /// `qr` when the student scanned the classroom code, `manual` for a teacher's mark.
  final String? source;

  static AttendanceRecord? fromRow(Map<String, dynamic> r) {
    final status = AttendanceStatus.parse(r['status']);
    if (status == null ||
        r['session_id'] is! String ||
        r['student_id'] is! String) {
      return null;
    }
    final s = r['attendance_sessions'];
    final session = s is Map ? Map<String, dynamic>.from(s) : null;
    return AttendanceRecord(
      sessionId: r['session_id'] as String,
      studentId: r['student_id'] as String,
      status: status,
      note: (r['note'] as String?) ?? '',
      version: (r['version'] as num?)?.toInt() ?? 1,
      sessionTitle: (session?['title'] as String?) ?? '',
      sessionStartsAt: DateTime.tryParse('${session?['starts_at']}')?.toUtc(),
      sessionClosed: session?['status'] == 'closed',
      checkedInAt: DateTime.tryParse('${r['checked_in_at']}')?.toUtc(),
      checkedOutAt: DateTime.tryParse('${r['checked_out_at']}')?.toUtc(),
      source: r['source'] as String?,
    );
  }
}

/// The server's answer to one scan. Business refusals arrive as `ok == false` with a [reason]
/// (`invalid`, `expired`, `closed`, `not_member`, `too_early`, `too_late`, `no_checkin`) so the attempt is logged server-side.
class ScanOutcome {
  const ScanOutcome({
    required this.ok,
    this.reason,
    this.action,
    this.already = false,
    this.status,
    this.checkedInAt,
    this.checkedOutAt,
    this.title,
  });

  final bool ok;
  final String? reason;
  final String? action; // 'in' | 'out'
  final bool already;
  final AttendanceStatus? status;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? title;

  bool get isCheckOut => action == 'out';

  static ScanOutcome fromJson(Map<String, dynamic> j) => ScanOutcome(
    ok: j['ok'] == true,
    reason: j['reason'] as String?,
    action: j['action'] as String?,
    already: j['already'] == true,
    status: AttendanceStatus.parse(j['status']),
    checkedInAt: DateTime.tryParse('${j['checked_in_at']}')?.toUtc(),
    checkedOutAt: DateTime.tryParse('${j['checked_out_at']}')?.toUtc(),
    title: j['title'] as String?,
  );
}

/// One line of the server-computed summary. `rate` = (present + late) / (present + late + absent);
/// excused is excluded and `null` means there is nothing to measure yet.
class AttendanceSummaryRow {
  const AttendanceSummaryRow({
    required this.studentId,
    required this.name,
    required this.present,
    required this.late,
    required this.excused,
    required this.absent,
    required this.rate,
  });

  final String studentId;
  final String name;
  final int present;
  final int late;
  final int excused;
  final int absent;
  final double? rate;

  int get total => present + late + excused + absent;

  static AttendanceSummaryRow? fromJson(Map<String, dynamic> j) {
    if (j['student_id'] is! String) return null;
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return AttendanceSummaryRow(
      studentId: j['student_id'] as String,
      name: (j['full_name'] as String?) ?? '',
      present: n('present'),
      late: n('late'),
      excused: n('excused'),
      absent: n('absent'),
      rate: (j['rate'] as num?)?.toDouble(),
    );
  }
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.sessionsTotal,
    required this.sessionsClosed,
    required this.rows,
  });

  final int sessionsTotal;
  final int sessionsClosed;
  final List<AttendanceSummaryRow> rows;

  static AttendanceSummary fromJson(Map<String, dynamic> j) =>
      AttendanceSummary(
        sessionsTotal: (j['sessions_total'] as num?)?.toInt() ?? 0,
        sessionsClosed: (j['sessions_closed'] as num?)?.toInt() ?? 0,
        rows: [
          for (final r in (j['students'] as List? ?? const []))
            ?AttendanceSummaryRow.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
      );
}

class AttendanceEvent {
  const AttendanceEvent({
    required this.action,
    required this.studentId,
    required this.oldStatus,
    required this.newStatus,
    required this.note,
    required this.createdAt,
  });

  final String action; // marked | corrected | closed
  final String? studentId;
  final AttendanceStatus? oldStatus;
  final AttendanceStatus? newStatus;
  final String note;
  final DateTime createdAt;

  static AttendanceEvent? fromRow(Map<String, dynamic> r) {
    final at = DateTime.tryParse('${r['created_at']}');
    if (r['action'] is! String || at == null) return null;
    return AttendanceEvent(
      action: r['action'] as String,
      studentId: r['student_id'] as String?,
      oldStatus: AttendanceStatus.parse(r['old_status']),
      newStatus: AttendanceStatus.parse(r['new_status']),
      note: (r['note'] as String?) ?? '',
      createdAt: at.toUtc(),
    );
  }
}

/// Renders a UTC instant in local wall-clock time ("Tue 10 Nov 2026, 14:30"). Malaysia (UTC+8) and
/// Thailand (UTC+7) differ by an hour, so the device zone decides; `offset` exists for tests only.
String formatSessionTime(DateTime utc, {Duration? offset, AppFormat? f}) {
  final t = offset == null ? utc.toLocal() : utc.toUtc().add(offset);
  return (f ?? AppFormat.current).dateTimeLong(t);
}
