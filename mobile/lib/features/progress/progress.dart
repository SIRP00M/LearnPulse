import '../activities/activity.dart';

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
double? _d(Object? v) => (v as num?)?.toDouble();

class AttendanceEntry {
  const AttendanceEntry({
    required this.title,
    required this.startsAt,
    required this.closed,
    this.status,
  });
  final String title;
  final DateTime? startsAt;
  final bool closed;
  final String? status; // present | late | excused | absent | null (unmarked)
}

class AttendanceProgress {
  const AttendanceProgress({
    required this.total,
    required this.closed,
    required this.present,
    required this.late,
    required this.excused,
    required this.absent,
    required this.unmarked,
    required this.rate,
    required this.recent,
  });

  final int total;
  final int closed;
  final int present;
  final int late;
  final int excused;
  final int absent;
  final int unmarked;

  /// (present + late) / (present + late + absent), exactly as the V6 summary; null when nothing is countable.
  final double? rate;
  final List<AttendanceEntry> recent;

  int get counted => present + late + absent;

  static AttendanceProgress fromJson(Object? j) {
    final m = (j as Map?) ?? const {};
    return AttendanceProgress(
      total: _i(m['sessions_total']),
      closed: _i(m['sessions_closed']),
      present: _i(m['present']),
      late: _i(m['late']),
      excused: _i(m['excused']),
      absent: _i(m['absent']),
      unmarked: _i(m['unmarked']),
      rate: _d(m['rate']),
      recent: [
        for (final e in (m['recent'] as List? ?? const []))
          AttendanceEntry(
            title: ((e as Map)['title'] as String?) ?? '',
            startsAt: parseInstant(e['starts_at']),
            closed: e['closed'] == true,
            status: e['status'] as String?,
          ),
      ],
    );
  }
}

class AssignmentEntry {
  const AssignmentEntry({
    required this.id,
    required this.title,
    required this.status,
    this.dueAt,
    this.maxScore = 0,
    this.score,
  });
  final String id;
  final String title;

  /// todo | overdue | awaiting_review | graded | needs_revision
  final String status;
  final DateTime? dueAt;
  final int maxScore;
  final int? score;
}

class AssignmentProgress {
  const AssignmentProgress({
    required this.published,
    required this.done,
    required this.awaitingReview,
    required this.graded,
    required this.needsRevision,
    required this.notStarted,
    required this.overdue,
    required this.averagePercent,
    required this.itemsTotal,
    required this.items,
  });

  final int published;
  final int done;
  final int awaitingReview;
  final int graded;
  final int needsRevision;
  final int notStarted;
  final int overdue;
  final double? averagePercent;
  final int itemsTotal;
  final List<AssignmentEntry> items;

  /// True when the server listed only the most recent 100 of [itemsTotal] (shown, never silent).
  bool get truncated => itemsTotal > items.length;

  static AssignmentProgress fromJson(Object? j) {
    final m = (j as Map?) ?? const {};
    return AssignmentProgress(
      published: _i(m['published']),
      done: _i(m['done']),
      awaitingReview: _i(m['awaiting_review']),
      graded: _i(m['graded']),
      needsRevision: _i(m['needs_revision']),
      notStarted: _i(m['not_started']),
      overdue: _i(m['overdue']),
      averagePercent: _d(m['average_percent']),
      itemsTotal: _i(m['items_total']),
      items: [
        for (final e in (m['items'] as List? ?? const []))
          AssignmentEntry(
            id: (e as Map)['id'] as String,
            title: (e['title'] as String?) ?? '',
            status: (e['status'] as String?) ?? 'todo',
            dueAt: parseInstant(e['due_at']),
            maxScore: _i(e['max_score']),
            score: (e['score'] as num?)?.toInt(),
          ),
      ],
    );
  }
}

class ActivityProgress {
  const ActivityProgress({
    required this.activities,
    required this.pendingVerification,
  });
  final List<ActivityStreak> activities;
  final int pendingVerification;

  static ActivityProgress fromJson(Object? j) {
    final m = (j as Map?) ?? const {};
    return ActivityProgress(
      activities: [
        for (final e in (m['activities'] as List? ?? const []))
          ActivityStreak.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      pendingVerification: _i(m['pending_verification']),
    );
  }
}

/// One student's progress in one course (private to that student and the course teacher). Factual figures only.
class StudentProgress {
  const StudentProgress({
    required this.courseId,
    required this.courseTitle,
    required this.courseArchived,
    required this.studentId,
    required this.studentName,
    required this.enrollmentStatus,
    required this.joinedAt,
    required this.attendance,
    required this.assignments,
    required this.activities,
  });

  final String courseId;
  final String courseTitle;
  final bool courseArchived;
  final String studentId;
  final String studentName;
  final String enrollmentStatus;
  final DateTime? joinedAt;
  final AttendanceProgress attendance;
  final AssignmentProgress assignments;
  final ActivityProgress activities;

  static StudentProgress fromJson(Map<String, dynamic> j) {
    final c = (j['course'] as Map?) ?? const {};
    final s = (j['student'] as Map?) ?? const {};
    final e = (j['enrollment'] as Map?) ?? const {};
    return StudentProgress(
      courseId: (c['id'] as String?) ?? '',
      courseTitle: (c['title'] as String?) ?? '',
      courseArchived: c['status'] == 'archived',
      studentId: (s['id'] as String?) ?? '',
      studentName: (s['full_name'] as String?) ?? '',
      enrollmentStatus: (e['status'] as String?) ?? 'active',
      joinedAt: parseInstant(e['joined_at']),
      attendance: AttendanceProgress.fromJson(j['attendance']),
      assignments: AssignmentProgress.fromJson(j['assignments']),
      activities: ActivityProgress.fromJson(j['activities']),
    );
  }
}
