import '../activities/activity.dart';

int _i(Object? v) => (v as num?)?.toInt() ?? 0;

enum TaskKind { assignment, activity, attendanceSession }

enum TaskView { range, upcoming, overdue, completed }

/// One derived task row for a student (never stored; the server builds it from assignments, activity occurrences and
/// attendance sessions with exactly one status definition per source).
class TaskItem {
  const TaskItem({
    required this.kind,
    required this.id,
    required this.key2,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.status,
    this.taskAt,
    this.dueAt,
    this.occurrenceDate,
    this.policy,
    this.version = 0,
  });

  final TaskKind kind;
  final String id;
  final String key2; // occurrence date for activities, '' otherwise
  final String courseId;
  final String courseTitle;
  final String title;

  /// todo | overdue | needs_revision | awaiting_review | done | graded | upcoming | missed | scheduled | held
  final String status;
  final DateTime? taskAt;
  final DateTime? dueAt;
  final DateTime? occurrenceDate;
  final ActivityPolicy? policy;
  final int version;

  String get key => '${kind.name}|$id|$key2';

  bool get isDone => status == 'done' || status == 'graded';
  bool get needsAction =>
      status == 'todo' || status == 'overdue' || status == 'needs_revision';

  static TaskItem fromJson(Map<String, dynamic> j) {
    final kind = switch (j['kind']) {
      'activity' => TaskKind.activity,
      'attendance_session' => TaskKind.attendanceSession,
      _ => TaskKind.assignment,
    };
    return TaskItem(
      kind: kind,
      id: j['id'] as String,
      key2: (j['key2'] as String?) ?? '',
      courseId: (j['course_id'] as String?) ?? '',
      courseTitle: (j['course_title'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      status: (j['status'] as String?) ?? 'todo',
      taskAt: parseInstant(j['task_at']),
      dueAt: parseInstant(j['due_at']),
      occurrenceDate: j['occurrence_date'] == null
          ? null
          : parseDate(j['occurrence_date']),
      policy: j['policy'] == null ? null : ActivityPolicy.parse(j['policy']),
      version: _i(j['version']),
    );
  }
}

/// A teacher calendar row: an assignment due date, one activity day with its workload, or an attendance session.
class CalendarItem {
  const CalendarItem({
    required this.kind,
    required this.id,
    required this.key2,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.status,
    required this.taskAt,
    this.received = 0,
    this.expected = 0,
    this.pending = 0,
    this.occurrenceDate,
  });

  final String kind; // assignment_due | activity_day | attendance_session
  final String id;
  final String key2;
  final String courseId;
  final String courseTitle;
  final String title;
  final String status;
  final DateTime? taskAt;
  final int received;
  final int expected;
  final int pending;
  final DateTime? occurrenceDate;

  String get key => '$kind|$id|$key2';

  static CalendarItem fromJson(Map<String, dynamic> j) => CalendarItem(
    kind: (j['kind'] as String?) ?? 'assignment_due',
    id: j['id'] as String,
    key2: (j['key2'] as String?) ?? '',
    courseId: (j['course_id'] as String?) ?? '',
    courseTitle: (j['course_title'] as String?) ?? '',
    title: (j['title'] as String?) ?? '',
    status: (j['status'] as String?) ?? '',
    taskAt: parseInstant(j['task_at']),
    received: _i(j['received']),
    expected: _i(j['expected']),
    pending: _i(j['pending']),
    occurrenceDate: j['occurrence_date'] == null
        ? null
        : parseDate(j['occurrence_date']),
  );
}

class CalendarPage {
  const CalendarPage(this.items, this.next, this.pendingVerifications);
  final List<CalendarItem> items;
  final Map<String, dynamic>? next;
  final int pendingVerifications;
}
