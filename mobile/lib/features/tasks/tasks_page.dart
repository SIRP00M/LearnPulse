import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/adaptive.dart';
import '../../core/app_error.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../activities/student_activity_pages.dart';
import '../activities/teacher_activity_pages.dart';
import '../assignments/student_assignment_pages.dart';
import '../auth/profile.dart';
import '../courses/courses_controller.dart';
import '../courses/student_course_page.dart';
import '../courses/teacher_course_page.dart';
import 'task.dart';
import 'tasks_controller.dart';

Tone _taskTone(String status) => switch (status) {
  'done' || 'graded' => Tone.success,
  'awaiting_review' => Tone.info,
  'overdue' || 'missed' => Tone.danger,
  'needs_revision' || 'todo' => Tone.attention,
  _ => Tone.neutral,
};

String _taskLabel(AppLocalizations l, String status) => switch (status) {
  'todo' => l.actStateOpen,
  'overdue' => l.taskOverdue,
  'needs_revision' => l.taskNeedsRevision,
  'awaiting_review' => l.actStatePending,
  'done' => l.actStateCompleted,
  'graded' => l.taskGraded,
  'upcoming' => l.actStateUpcoming,
  'missed' => l.actStateMissed,
  'held' => l.taskHeld,
  _ => l.taskScheduled,
};

IconData _taskIcon(String status) => switch (status) {
  'done' || 'graded' => Icons.check_circle_outline,
  'awaiting_review' => Icons.hourglass_top,
  'overdue' || 'missed' => Icons.error_outline,
  'needs_revision' => Icons.replay,
  _ => Icons.radio_button_unchecked,
};

IconData _kindIcon(TaskKind k) => switch (k) {
  TaskKind.assignment => Icons.assignment_outlined,
  TaskKind.activity => Icons.local_fire_department_outlined,
  TaskKind.attendanceSession => Icons.fact_check_outlined,
};

/// The local calendar day a task belongs to: an activity's own occurrence date, otherwise its deadline instant.
DateTime? taskDay(TaskItem t) {
  if (t.kind == TaskKind.activity && t.occurrenceDate != null) {
    return dayOf(t.occurrenceDate!);
  }
  return t.taskAt == null ? null : dayOf(t.taskAt!.toLocal());
}

/// Opens the existing destination of a task: the assignment workspace, the activity's week, or the course.
Future<void> openTask(
  BuildContext context,
  AppServices services,
  TaskItem t,
) async {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    switch (t.kind) {
      case TaskKind.assignment:
        final all = await services.assignments.listAssignments(t.courseId);
        final a = all.where((x) => x.id == t.id).firstOrNull;
        if (a == null) {
          throw const AppError(
            AppErrorKind.notFound,
            'This assignment is no longer available.',
            AppErrorCode.assignmentUnavailable,
          );
        }
        final mine = await services.assignments.listMySubmissions();
        final existing = mine.where((s) => s.assignmentId == a.id).firstOrNull;
        await nav.push(
          MaterialPageRoute<void>(
            builder: (_) => StudentAssignmentPage(
              assignment: a,
              existing: existing,
              services: services,
            ),
          ),
        );
      case TaskKind.activity:
        await nav.push(
          MaterialPageRoute<void>(
            builder: (_) => StudentActivityWeekPage(
              services: services,
              courseId: t.courseId,
              title: t.courseTitle,
              activityId: t.id,
              initialDate: t.occurrenceDate,
            ),
          ),
        );
      case TaskKind.attendanceSession:
        final courses = await services.courses.listCourses();
        final c = courses.where((x) => x.id == t.courseId).firstOrNull;
        if (c == null) {
          throw const AppError(
            AppErrorKind.notFound,
            'This course is no longer available.',
            AppErrorCode.courseUnavailable,
          );
        }
        await nav.push(
          MaterialPageRoute<void>(
            builder: (_) => StudentCoursePage(course: c, services: services),
          ),
        );
    }
  } on Object catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppError.from(e).localizedMessage(AppLocalizations.of(context)),
        ),
      ),
    );
  }
}

/// Fourth root destination. Students get their derived tasks; teachers their calendar and verification workload.
class TasksTab extends StatefulWidget {
  const TasksTab({
    super.key,
    required this.profile,
    required this.services,
    this.active = true,
  });
  final Profile profile;
  final AppServices services;
  final bool active;

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  TasksController? _student;
  TeacherCalendarController? _teacher;
  DateTime? _selected; // month view: the tapped day

  bool get _isTeacher => widget.profile.role == AppRole.teacher;

  @override
  void initState() {
    super.initState();
    _createControllers();
  }

  void _createControllers() {
    final s = widget.services;
    _selected = null;
    if (_isTeacher) {
      _teacher = TeacherCalendarController(s.tasks, bus: s.summaries)
        ..active = widget.active
        ..load();
    } else {
      _student = TasksController(s.tasks, bus: s.summaries)
        ..active = widget.active
        ..load();
    }
  }

  void _disposeControllers() {
    _student?.dispose();
    _teacher?.dispose();
    _student = null;
    _teacher = null;
  }

  @override
  void didUpdateWidget(covariant TasksTab old) {
    super.didUpdateWidget(old);
    // A different role (account switch) never inherits the previous account's rows: start from fresh controllers.
    if (widget.profile.role != old.profile.role ||
        widget.profile.fullName != old.profile.fullName ||
        widget.services != old.services) {
      _disposeControllers();
      _createControllers();
      return;
    }
    if (widget.active != old.active) {
      if (widget.active) {
        _student?.activate();
        _teacher?.activate();
      } else {
        _student?.deactivate();
        _teacher?.deactivate();
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _isTeacher ? _buildTeacher(context) : _buildStudent(context);

  // ---------------------------------------------------------------- student
  Widget _buildStudent(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _student!;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final items = c.items;
        final selected = c.mode == TaskMode.month ? _selected : null;
        final shown = selected == null
            ? items
            : [
                for (final t in items)
                  if (taskDay(t) == selected) t,
              ];
        return RefreshIndicator(
          onRefresh: () => c.load(showSpinner: false),
          child: StudioPage(
            maxWidth: StudioLayout.maxWorkspace,
            children: [
              AcademicPageHeader(
                eyebrow: l.navTasks,
                icon: Icons.checklist_rtl,
                title: l.taskHeaderTitle,
                description: l.taskHeaderDesc,
              ),
              const SizedBox(height: Space.md),
              _ModeChips(
                modes: TaskMode.values,
                selected: c.mode,
                onSelected: (m) {
                  setState(() => _selected = null);
                  c.setMode(m);
                },
              ),
              const SizedBox(height: Space.md),
              if (c.mode.isRange)
                _RangeNav(
                  label: _rangeLabel(context, c.mode, c.focus),
                  onPrev: () => c.shift(-1),
                  onNext: () => c.shift(1),
                  onToday: () => c.jumpTo(DateTime.now()),
                ),
              if (c.mode == TaskMode.month && c.state == LoadState.ready)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: MonthGrid(
                    month: c.focus,
                    counts: _counts(items),
                    selected: _selected,
                    onSelect: (d) =>
                        setState(() => _selected = _selected == d ? null : d),
                  ),
                ),
              if (c.error != null && c.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Text(
                    l.taskCouldNotRefreshTasks(c.error!.localizedMessage(l)),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (c.state == LoadState.loading)
                const SkeletonSection(rows: 3)
              else if (c.state == LoadState.error)
                ErrorPanel(error: c.error!, onRetry: c.load, full: false)
              else if (shown.isEmpty)
                _studentEmpty(l, c.mode, selected)
              else
                _StudentList(
                  items: shown,
                  mode: c.mode,
                  services: widget.services,
                ),
              if (c.next != null && selected == null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.md),
                  child: OutlinedButton(
                    onPressed: c.loadingMore ? null : c.loadMore,
                    child: Text(
                      c.loadingMore
                          ? l.commonLoadingEllipsis
                          : l.commonLoadMore,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Map<DateTime, int> _counts(List<TaskItem> items) {
    final m = <DateTime, int>{};
    for (final t in items) {
      final d = taskDay(t);
      if (d != null) m[d] = (m[d] ?? 0) + 1;
    }
    return m;
  }

  Widget _studentEmpty(AppLocalizations l, TaskMode m, DateTime? selected) {
    final (icon, title, msg) = switch (m) {
      TaskMode.today => (
        Icons.celebration_outlined,
        l.taskEmptyTodayTitle,
        l.taskEmptyTodayHint,
      ),
      TaskMode.week => (
        Icons.event_available_outlined,
        l.taskEmptyWeekTitle,
        l.taskEmptyWeekHint,
      ),
      TaskMode.month => (
        Icons.calendar_month_outlined,
        selected == null ? l.taskEmptyMonthTitle : l.taskEmptyDayTitle,
        l.taskEmptyMonthHint,
      ),
      TaskMode.upcoming => (
        Icons.event_available_outlined,
        l.taskEmptyUpcomingTitle,
        l.taskEmptyUpcomingHint,
      ),
      TaskMode.overdue => (
        Icons.thumb_up_alt_outlined,
        l.taskEmptyOverdueTitle,
        l.taskEmptyOverdueHint,
      ),
      TaskMode.completed => (
        Icons.inbox_outlined,
        l.taskEmptyCompletedTitle,
        l.taskEmptyCompletedHint,
      ),
    };
    return EmptyPanel(icon: icon, title: title, message: msg, full: false);
  }

  // ---------------------------------------------------------------- teacher
  Widget _buildTeacher(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _teacher!;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final selected = c.mode == TaskMode.month ? _selected : null;
        final shown = selected == null
            ? c.items
            : [
                for (final i in c.items)
                  if (_calendarDay(i) == selected) i,
              ];
        final counts = <DateTime, int>{};
        for (final i in c.items) {
          final d = _calendarDay(i);
          if (d != null) counts[d] = (counts[d] ?? 0) + 1;
        }
        return RefreshIndicator(
          onRefresh: () => c.load(showSpinner: false),
          child: StudioPage(
            maxWidth: StudioLayout.maxWorkspace,
            children: [
              AcademicPageHeader(
                eyebrow: l.taskCalendarEyebrow,
                icon: Icons.calendar_month_outlined,
                title: l.taskCalendarTitle,
                description: l.taskCalendarDesc,
                meta: [
                  if (c.state == LoadState.ready)
                    MetadataRow(
                      Icons.rule_folder_outlined,
                      c.pendingVerifications == 0
                          ? l.taskNoPending
                          : l.taskPending(c.pendingVerifications),
                    ),
                ],
                actions: [
                  if (c.pendingVerifications > 0)
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PendingQueuePage(services: widget.services),
                        ),
                      ),
                      icon: const Icon(Icons.rule_folder_outlined),
                      label: Text(l.taskReview(c.pendingVerifications)),
                    ),
                ],
              ),
              const SizedBox(height: Space.md),
              _ModeChips(
                modes: const [TaskMode.today, TaskMode.week, TaskMode.month],
                selected: c.mode,
                onSelected: (m) {
                  setState(() => _selected = null);
                  c.setMode(m);
                },
              ),
              const SizedBox(height: Space.md),
              _RangeNav(
                label: _rangeLabel(context, c.mode, c.focus),
                onPrev: () => c.shift(-1),
                onNext: () => c.shift(1),
                onToday: null,
              ),
              if (c.mode == TaskMode.month && c.state == LoadState.ready)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: MonthGrid(
                    month: c.focus,
                    counts: counts,
                    selected: _selected,
                    onSelect: (d) =>
                        setState(() => _selected = _selected == d ? null : d),
                  ),
                ),
              if (c.error != null && c.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Text(
                    l.taskCouldNotRefreshCalendar(c.error!.localizedMessage(l)),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (c.state == LoadState.loading)
                const SkeletonSection(rows: 3)
              else if (c.state == LoadState.error)
                ErrorPanel(error: c.error!, onRetry: c.load, full: false)
              else if (shown.isEmpty)
                EmptyPanel(
                  icon: Icons.event_available_outlined,
                  title: l.taskNothingScheduled,
                  message: l.taskNothingScheduledHint,
                  full: false,
                )
              else
                _TeacherList(items: shown, services: widget.services),
              if (c.next != null && selected == null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.md),
                  child: OutlinedButton(
                    onPressed: c.loadingMore ? null : c.loadMore,
                    child: Text(
                      c.loadingMore
                          ? l.commonLoadingEllipsis
                          : l.commonLoadMore,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

DateTime? _calendarDay(CalendarItem i) {
  if (i.kind == 'activity_day' && i.occurrenceDate != null) {
    return dayOf(i.occurrenceDate!);
  }
  return i.taskAt == null ? null : dayOf(i.taskAt!.toLocal());
}

String _rangeLabel(BuildContext context, TaskMode m, DateTime focus) {
  final l = AppLocalizations.of(context);
  final f = AppFormat.of(context);
  return switch (m) {
    TaskMode.week => l.actWeekOf(f.weekdayDayMonth(rangeFor(m, focus).$1)),
    TaskMode.month => f.monthYear(focus),
    _ => f.relativeDay(l, focus),
  };
}

class _ModeChips extends StatelessWidget {
  const _ModeChips({
    required this.modes,
    required this.selected,
    required this.onSelected,
  });
  final List<TaskMode> modes;
  final TaskMode selected;
  final ValueChanged<TaskMode> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.sm,
    runSpacing: Space.sm,
    children: [
      for (final m in modes)
        ChoiceChip(
          label: Text(switch (m) {
            TaskMode.today => AppLocalizations.of(context).relativeToday,
            TaskMode.week => AppLocalizations.of(context).actThisWeek,
            TaskMode.month => AppLocalizations.of(context).taskModeMonth,
            TaskMode.upcoming => AppLocalizations.of(context).actStateUpcoming,
            TaskMode.overdue => AppLocalizations.of(context).taskOverdue,
            TaskMode.completed => AppLocalizations.of(
              context,
            ).taskModeCompleted,
          }),
          selected: m == selected,
          onSelected: (_) => onSelected(m),
        ),
    ],
  );
}

class _RangeNav extends StatelessWidget {
  const _RangeNav({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.sm),
    child: Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton.outlined(
          tooltip: AppLocalizations.of(context).taskPrevious,
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton.outlined(
          tooltip: AppLocalizations.of(context).taskNext,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
        if (onToday != null)
          TextButton(
            onPressed: onToday,
            child: Text(AppLocalizations.of(context).relativeToday),
          ),
      ],
    ),
  );
}

/// A month as a 7-column grid; each day shows how many items fall on it. Meaning never depends on colour alone.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });
  final DateTime month;
  final Map<DateTime, int> counts;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final s = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month);
    final lead = first.weekday - 1;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final today = dayOf(DateTime.now());
    final cells = <Widget>[
      for (var weekday = 1; weekday <= 7; weekday++)
        Center(
          child: Text(
            f.weekdayShort(weekday),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++)
        Builder(
          builder: (context) {
            final date = DateTime(month.year, month.month, d);
            final n = counts[date] ?? 0;
            final isSel = selected == date;
            return Semantics(
              button: true,
              selected: isSel,
              label: l.taskDayItems(d, f.monthYear(month), n),
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onSelect(date),
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    color: isSel ? s.primaryContainer : null,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: date == today
                        ? Border.all(color: s.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$d', style: Theme.of(context).textTheme.bodyMedium),
                      if (n > 0)
                        Text(
                          '$n',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: s.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    ];
    return Material(
      color: s.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: s.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: Space.xs,
          mainAxisExtent: MediaQuery.textScalerOf(context).scale(48) + Space.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ),
    );
  }
}

class _StudentList extends StatelessWidget {
  const _StudentList({
    required this.items,
    required this.mode,
    required this.services,
  });
  final List<TaskItem> items;
  final TaskMode mode;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final groups = <DateTime?, List<TaskItem>>{};
    for (final t in items) {
      groups.putIfAbsent(taskDay(t), () => []).add(t);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return mode == TaskMode.completed ? b.compareTo(a) : a.compareTo(b);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: AcademicSection(
              title: k == null ? l.asgNoDeadline : f.relativeDay(l, k),
              icon: Icons.today_outlined,
              count: '${groups[k]!.length}',
              children: [
                for (final t in groups[k]!)
                  TaskTile(
                    task: t,
                    onTap: () => openTask(context, services, t),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.onTap});
  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final detail = [
      task.courseTitle,
      switch (task.kind) {
        TaskKind.assignment =>
          task.dueAt == null
              ? l.asgNoDeadline
              : l.asgDue(f.dateTime(task.dueAt!.toLocal())),
        TaskKind.activity => task.policy?.text(l) ?? l.actDailyOne,
        TaskKind.attendanceSession =>
          task.taskAt == null
              ? ''
              : l.taskClassSession(f.dateTime(task.taskAt!.toLocal())),
      },
    ].where((s) => s.isNotEmpty).join(' · ');
    return TrailingTile(
      leading: AcademicIcon(_kindIcon(task.kind), category: task.kind.index),
      title: Text(task.title),
      subtitle: Text(detail),
      trailing: StatusPill(
        _taskLabel(l, task.status),
        tone: _taskTone(task.status),
        icon: _taskIcon(task.status),
      ),
      onTap: onTap,
    );
  }
}

class _TeacherList extends StatelessWidget {
  const _TeacherList({required this.items, required this.services});
  final List<CalendarItem> items;
  final AppServices services;

  Future<void> _open(BuildContext context, CalendarItem i) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    CoursesController? openedCourses;
    try {
      if (i.kind == 'activity_day') {
        await nav.push(
          MaterialPageRoute<void>(
            builder: (_) => TeacherActivityPage(
              courseId: i.courseId,
              activityId: i.id,
              services: services,
            ),
          ),
        );
        return;
      }
      final list = CoursesController(
        services.courses,
        summaries: services.summaries,
      );
      openedCourses = list;
      await list.load();
      final c = list.courses.where((x) => x.id == i.courseId).firstOrNull;
      if (c == null) {
        throw const AppError(
          AppErrorKind.notFound,
          'This course is no longer available.',
          AppErrorCode.courseUnavailable,
        );
      }
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => TeacherCoursePage(
            course: c,
            controller: list,
            services: services,
          ),
        ),
      );
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppError.from(e).localizedMessage(AppLocalizations.of(context)),
          ),
        ),
      );
    } finally {
      openedCourses?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final groups = <DateTime?, List<CalendarItem>>{};
    for (final i in items) {
      groups.putIfAbsent(_calendarDay(i), () => []).add(i);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => a == null ? 1 : (b == null ? -1 : a.compareTo(b)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: AcademicSection(
              title: k == null ? l.taskUndated : f.relativeDay(l, k),
              icon: Icons.today_outlined,
              count: '${groups[k]!.length}',
              children: [
                for (final i in groups[k]!)
                  TrailingTile(
                    leading: AcademicIcon(
                      switch (i.kind) {
                        'assignment_due' => Icons.assignment_outlined,
                        'activity_day' => Icons.local_fire_department_outlined,
                        _ => Icons.fact_check_outlined,
                      },
                      category: i.kind == 'activity_day'
                          ? 3
                          : (i.kind == 'assignment_due' ? 1 : 2),
                    ),
                    title: Text(i.title),
                    subtitle: Text(
                      [
                        i.courseTitle,
                        switch (i.kind) {
                          'assignment_due' => l.taskDueSubmitted(
                            i.taskAt == null
                                ? ''
                                : f.dateTime(i.taskAt!.toLocal()),
                            i.received,
                            i.expected,
                          ),
                          'activity_day' => [
                            l.taskDoneOf(i.received, i.expected),
                            if (i.pending > 0) l.actToReview(i.pending),
                          ].join(' · '),
                          _ => l.taskAttendanceSession(
                            i.taskAt == null
                                ? ''
                                : f.dateTime(i.taskAt!.toLocal()),
                            i.status == 'held' ? l.commonClosed : l.commonOpen,
                          ),
                        },
                      ].join(' · '),
                    ),
                    trailing: i.pending > 0
                        ? StatusPill(
                            l.actToReview(i.pending),
                            tone: Tone.info,
                            icon: Icons.hourglass_top,
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => _open(context, i),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
