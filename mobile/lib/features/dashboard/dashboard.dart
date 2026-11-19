import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
double? _d(Object? v) => (v as num?)?.toDouble();
DateTime? _t(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toUtc();
List<Map<String, dynamic>> _list(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];

class DeadlineItem {
  const DeadlineItem({
    required this.title,
    required this.courseTitle,
    required this.dueAt,
    this.received,
    this.expected,
    this.status,
  });

  final String title;
  final String courseTitle;
  final DateTime? dueAt;
  final int? received; // teacher: submissions received so far
  final int? expected; // teacher: active students expected to submit
  final String? status; // student: null (not started) or returned

  static DeadlineItem fromJson(Map<String, dynamic> j) => DeadlineItem(
    title: (j['title'] as String?) ?? '',
    courseTitle: (j['course_title'] as String?) ?? '',
    dueAt: _t(j['due_at']),
    received: j.containsKey('received') ? _i(j['received']) : null,
    expected: j.containsKey('expected') ? _i(j['expected']) : null,
    status: j['status'] as String?,
  );
}

class RecentSubmission {
  const RecentSubmission({
    required this.studentName,
    required this.assignmentTitle,
    required this.courseTitle,
    required this.status,
    required this.at,
  });

  final String studentName;
  final String assignmentTitle;
  final String courseTitle;
  final String status;
  final DateTime? at;
}

class TeacherCourseRow {
  const TeacherCourseRow({
    this.courseId = '',
    required this.title,
    required this.archived,
    required this.students,
    required this.assignments,
    required this.awaitingGrading,
    required this.attendanceSessions,
  });

  final String courseId; // empty for older payloads
  final String title;
  final bool archived;
  final int students;
  final int assignments;
  final int awaitingGrading;
  final int attendanceSessions;
}

/// Server-computed figures; definitions live in the V7 migration header and are repeated in the UI.
class TeacherDashboard {
  const TeacherDashboard({
    required this.coursesActive,
    required this.coursesArchived,
    required this.activeStudents,
    required this.publishedAssignments,
    required this.expectedSubmissions,
    required this.receivedSubmissions,
    required this.awaitingGrading,
    required this.graded,
    required this.returned,
    required this.openSessions,
    required this.attendanceRate,
    required this.deadlines,
    required this.recent,
    required this.courses,
  });

  final int coursesActive;
  final int coursesArchived;
  final int activeStudents;
  final int publishedAssignments;
  final int expectedSubmissions;
  final int receivedSubmissions;
  final int awaitingGrading;
  final int graded;
  final int returned;
  final int openSessions;
  final double? attendanceRate;
  final List<DeadlineItem> deadlines;
  final List<RecentSubmission> recent;
  final List<TeacherCourseRow> courses;

  int get outstanding => expectedSubmissions - receivedSubmissions;
  bool get isEmpty => coursesActive + coursesArchived == 0;

  static TeacherDashboard fromJson(Map<String, dynamic> j) => TeacherDashboard(
    coursesActive: _i(j['courses_active']),
    coursesArchived: _i(j['courses_archived']),
    activeStudents: _i(j['active_students']),
    publishedAssignments: _i(j['published_assignments']),
    expectedSubmissions: _i(j['expected_submissions']),
    receivedSubmissions: _i(j['received_submissions']),
    awaitingGrading: _i(j['awaiting_grading']),
    graded: _i(j['graded']),
    returned: _i(j['returned']),
    openSessions: _i(j['open_attendance_sessions']),
    attendanceRate: _d(j['attendance_rate']),
    deadlines: [
      for (final e in _list(j['upcoming_deadlines'])) DeadlineItem.fromJson(e),
    ],
    recent: [
      for (final e in _list(j['recent_activity']))
        RecentSubmission(
          studentName: (e['student_name'] as String?) ?? '',
          assignmentTitle: (e['assignment_title'] as String?) ?? '',
          courseTitle: (e['course_title'] as String?) ?? '',
          status: (e['status'] as String?) ?? 'submitted',
          at: _t(e['at']),
        ),
    ],
    courses: [
      for (final e in _list(j['courses']))
        TeacherCourseRow(
          courseId: (e['course_id'] as String?) ?? '',
          title: (e['title'] as String?) ?? '',
          archived: e['status'] == 'archived',
          students: _i(e['students']),
          assignments: _i(e['assignments']),
          awaitingGrading: _i(e['awaiting_grading']),
          attendanceSessions: _i(e['attendance_sessions']),
        ),
    ],
  );
}

class GradedItem {
  const GradedItem({
    required this.title,
    required this.courseTitle,
    required this.score,
    required this.maxScore,
    required this.hasFeedback,
  });

  final String title;
  final String courseTitle;
  final int score;
  final int maxScore;
  final bool hasFeedback;
}

class LessonItem {
  const LessonItem({
    required this.title,
    required this.courseTitle,
    required this.publishedAt,
  });

  final String title;
  final String courseTitle;
  final DateTime? publishedAt;
}

class StudentCourseRow {
  const StudentCourseRow({
    required this.title,
    required this.teacherName,
    required this.archived,
    required this.assignments,
    required this.done,
    required this.progressPercent,
    required this.attendanceRate,
  });

  final String title;
  final String teacherName;
  final bool archived;
  final int assignments;
  final int done;
  final double?
  progressPercent; // done / published assignments; null when there are none
  final double? attendanceRate;
}

class StudentDashboard {
  const StudentDashboard({
    required this.coursesActive,
    required this.published,
    required this.done,
    required this.awaitingGrade,
    required this.graded,
    required this.needsRevision,
    required this.notStarted,
    required this.overdue,
    required this.averagePercent,
    required this.attendanceRate,
    required this.deadlines,
    required this.recentGraded,
    required this.recentLessons,
    required this.courses,
  });

  final int coursesActive;
  final int published;
  final int done;
  final int awaitingGrade;
  final int graded;
  final int needsRevision;
  final int notStarted;
  final int overdue;
  final double? averagePercent;
  final double? attendanceRate;
  final List<DeadlineItem> deadlines;
  final List<GradedItem> recentGraded;
  final List<LessonItem> recentLessons;
  final List<StudentCourseRow> courses;

  bool get isEmpty => courses.isEmpty;

  static StudentDashboard fromJson(Map<String, dynamic> j) => StudentDashboard(
    coursesActive: _i(j['courses_active']),
    published: _i(j['published_assignments']),
    done: _i(j['done']),
    awaitingGrade: _i(j['awaiting_grade']),
    graded: _i(j['graded']),
    needsRevision: _i(j['needs_revision']),
    notStarted: _i(j['not_started']),
    overdue: _i(j['overdue']),
    averagePercent: _d(j['average_percent']),
    attendanceRate: _d(j['attendance_rate']),
    deadlines: [
      for (final e in _list(j['upcoming_deadlines'])) DeadlineItem.fromJson(e),
    ],
    recentGraded: [
      for (final e in _list(j['recent_graded']))
        GradedItem(
          title: (e['title'] as String?) ?? '',
          courseTitle: (e['course_title'] as String?) ?? '',
          score: _i(e['score']),
          maxScore: _i(e['max_score']),
          hasFeedback: e['has_feedback'] == true,
        ),
    ],
    recentLessons: [
      for (final e in _list(j['recent_lessons']))
        LessonItem(
          title: (e['title'] as String?) ?? '',
          courseTitle: (e['course_title'] as String?) ?? '',
          publishedAt: _t(e['published_at']),
        ),
    ],
    courses: [
      for (final e in _list(j['courses']))
        StudentCourseRow(
          title: (e['title'] as String?) ?? '',
          teacherName: (e['teacher_name'] as String?) ?? '',
          archived: e['status'] == 'archived',
          assignments: _i(e['assignments']),
          done: _i(e['done']),
          progressPercent: _d(e['progress_percent']),
          attendanceRate: _d(e['attendance_rate']),
        ),
    ],
  );
}

/// Shared percent label: "No data yet" instead of a misleading 0% when there is nothing to measure.
/// Pass [l] and [f] (from the context) to follow the active language; without them it uses English /
/// the app-wide current format.
String percentLabel(double? v, {AppLocalizations? l, AppFormat? f}) => v == null
    ? (l?.commonNoDataYet ?? 'No data yet')
    : (f ?? AppFormat.current).percent(v);
