// ignore_for_file: prefer_initializing_formals
import '../../core/paged_controller.dart';
import '../activities/activity.dart' show ServerPage;
import '../dashboard/summary_bus.dart';
import 'task.dart';
import 'task_repository.dart';

/// How the Tasks screen slices time. Ranges use the device's local calendar (Dart resolves DST), the server gets UTC instants.
enum TaskMode {
  today('Today'),
  week('This week'),
  month('Month'),
  upcoming('Upcoming'),
  overdue('Overdue'),
  completed('Completed');

  const TaskMode(this.label);
  final String label;

  bool get isRange => this == today || this == week || this == month;
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// [from, to) of a range mode around [focus] in local time.
(DateTime, DateTime) rangeFor(TaskMode mode, DateTime focus) {
  final d = dayOf(focus);
  switch (mode) {
    case TaskMode.week:
      final start = d.subtract(Duration(days: d.weekday - 1));
      return (start, DateTime(start.year, start.month, start.day + 7));
    case TaskMode.month:
      return (DateTime(d.year, d.month), DateTime(d.year, d.month + 1));
    default:
      return (d, DateTime(d.year, d.month, d.day + 1));
  }
}

/// Student: unified derived tasks. One server status per task; this class only chooses the window and the page.
class TasksController extends PagedController<TaskItem> {
  TasksController(
    this._repo, {
    TaskMode mode = TaskMode.today,
    DateTime? focus,
    super.bus,
  }) : _mode = mode,
       _focus = dayOf(focus ?? DateTime.now()),
       super(topic: SummaryTopic.tasks);

  final TaskRepository _repo;
  TaskMode _mode;
  DateTime _focus;

  TaskMode get mode => _mode;
  DateTime get focus => _focus;

  @override
  Future<ServerPage<TaskItem>> fetch(Map<String, dynamic>? cursor) {
    if (_mode.isRange) {
      final (from, to) = rangeFor(_mode, _focus);
      return _repo.myTasks(
        TaskView.range,
        from: from,
        to: to,
        limit: 400,
        cursor: cursor,
      );
    }
    final view = switch (_mode) {
      TaskMode.upcoming => TaskView.upcoming,
      TaskMode.overdue => TaskView.overdue,
      _ => TaskView.completed,
    };
    return _repo.myTasks(view, limit: 100, cursor: cursor);
  }

  void setMode(TaskMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    reset();
  }

  /// Move the focus (previous / next day, week or month) or jump to a date.
  void shift(int n) {
    final d = _focus;
    _focus = switch (_mode) {
      TaskMode.week => d.add(Duration(days: 7 * n)),
      TaskMode.month => DateTime(d.year, d.month + n),
      _ => DateTime(d.year, d.month, d.day + n),
    };
    reset();
  }

  void jumpTo(DateTime day, {TaskMode? mode}) {
    _focus = dayOf(day);
    if (mode != null) _mode = mode;
    reset();
  }
}

/// Teacher: assignment due dates, activity workload and attendance sessions of owned courses.
class TeacherCalendarController extends PagedController<CalendarItem> {
  TeacherCalendarController(
    this._repo, {
    TaskMode mode = TaskMode.week,
    DateTime? focus,
    super.bus,
  }) : _mode = mode,
       _focus = dayOf(focus ?? DateTime.now()),
       super(topic: SummaryTopic.tasks);

  final TaskRepository _repo;
  TaskMode _mode;
  DateTime _focus;

  TaskMode get mode => _mode;
  DateTime get focus => _focus;

  /// Pending activity verifications across the teacher's active courses (the "verification workload").
  int get pendingVerifications => total ?? 0;

  @override
  Future<ServerPage<CalendarItem>> fetch(Map<String, dynamic>? cursor) async {
    final (from, to) = rangeFor(_mode, _focus);
    final page = await _repo.teacherCalendar(
      from,
      to,
      limit: 400,
      cursor: cursor,
    );
    return ServerPage(page.items, page.next, total: page.pendingVerifications);
  }

  void setMode(TaskMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    reset();
  }

  void shift(int n) {
    final d = _focus;
    _focus = switch (_mode) {
      TaskMode.week => d.add(Duration(days: 7 * n)),
      TaskMode.month => DateTime(d.year, d.month + n),
      _ => DateTime(d.year, d.month, d.day + n),
    };
    reset();
  }
}
