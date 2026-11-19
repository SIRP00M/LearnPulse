import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/adaptive.dart';
import '../../core/app_error.dart';
import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../courses/course_widgets.dart' show formatDate, formatDateTime;
import '../courses/courses_controller.dart' show LoadState;
import '../dashboard/dashboard_controller.dart';
import '../dashboard/summary_bus.dart';
import 'activity.dart';
import 'activity_controllers.dart';
import 'activity_widgets.dart';

/// Editable form state of a schedule (new activity or a new schedule version).
class ScheduleDraft {
  ScheduleDraft({
    Set<int>? weekdays,
    DateTime? start,
    this.end,
    this.mode = 'day_end',
    this.time = const TimeOfDay(hour: 20, minute: 0),
    this.timezone = 'Asia/Bangkok',
  }) : weekdays = weekdays ?? {1, 2, 3, 4, 5},
       start = start ?? DateTime.now();

  Set<int> weekdays;
  DateTime start;
  DateTime? end;
  String mode; // day_end | time | none
  TimeOfDay time;
  String timezone;

  String? get timeWire => mode == 'time'
      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      : null;
  List<int> get days => (weekdays.toList()..sort());

  factory ScheduleDraft.from(ActivitySchedule s, {required DateTime start}) {
    final parts = (s.deadlineTime ?? '20:00').split(':');
    return ScheduleDraft(
      weekdays: s.weekdays.isEmpty ? {1, 2, 3, 4, 5} : s.weekdays.toSet(),
      start: start,
      end: s.endDate,
      mode: s.deadlineMode,
      time: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 20,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
      timezone: commonTimezones.containsKey(s.timezone)
          ? s.timezone
          : 'Asia/Bangkok',
    );
  }
}

/// Weekdays, dates, deadline mode/time and timezone. Pure presentation: the server validates everything again.
class ScheduleFields extends StatelessWidget {
  const ScheduleFields({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.startLabel,
    required this.firstDate,
  });
  final ScheduleDraft draft;
  final VoidCallback onChanged;
  final String startLabel;
  final DateTime firstDate;

  Future<void> _pickDate(BuildContext context, {required bool end}) async {
    final base = end ? (draft.end ?? draft.start) : draft.start;
    final picked = await showDatePicker(
      context: context,
      initialDate: base.isBefore(firstDate) ? firstDate : base,
      firstDate: end ? draft.start : firstDate,
      lastDate: firstDate.add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    if (end) {
      draft.end = picked;
    } else {
      draft.start = picked;
      if (draft.end != null && draft.end!.isBefore(picked)) draft.end = picked;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.actDaysOfWeek, style: text.titleSmall),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (var d = 1; d <= 7; d++)
              FilterChip(
                label: Text(f.weekdayShort(d)),
                selected: draft.weekdays.contains(d),
                onSelected: (v) {
                  v ? draft.weekdays.add(d) : draft.weekdays.remove(d);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, end: false),
              icon: const Icon(Icons.event),
              label: Text('$startLabel: ${formatDate(draft.start, f: f)}'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context, end: true),
              icon: const Icon(Icons.event_busy),
              label: Text(
                draft.end == null
                    ? l.actNoEndDate
                    : l.actEnds(formatDate(draft.end!, f: f)),
              ),
            ),
            if (draft.end != null)
              TextButton(
                onPressed: () {
                  draft.end = null;
                  onChanged();
                },
                child: Text(l.actClearEnd),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        Text(l.actDeadline, style: text.titleSmall),
        RadioGroup<String>(
          groupValue: draft.mode,
          onChanged: (v) {
            draft.mode = v ?? 'day_end';
            onChanged();
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'day_end',
                title: Text(l.actDlDayEnd),
                subtitle: Text(l.actDlDayEndHint),
              ),
              RadioListTile<String>(value: 'time', title: Text(l.actDlTime)),
              RadioListTile<String>(
                value: 'none',
                title: Text(l.asgNoDeadline),
                subtitle: Text(l.actDlNoneHint),
              ),
            ],
          ),
        ),
        if (draft.mode == 'time')
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: draft.time,
                );
                if (t != null) {
                  draft.time = t;
                  onChanged();
                }
              },
              icon: const Icon(Icons.schedule),
              label: Text(l.actDueAtPicker(draft.time.format(context))),
            ),
          ),
        const SizedBox(height: Space.md),
        DropdownButtonFormField<String>(
          initialValue: draft.timezone,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.actTimezone),
          items: [
            for (final e in commonTimezones.entries)
              DropdownMenuItem(
                value: e.key,
                child: Text(
                  timezoneText(e.key, l),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            draft.timezone = v ?? draft.timezone;
            onChanged();
          },
        ),
      ],
    );
  }
}

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Teacher course page section: the course's activities with today's numbers, create, and the verification queue.
class TeacherActivitiesSection extends StatefulWidget {
  const TeacherActivitiesSection({
    super.key,
    required this.courseId,
    required this.services,
    required this.archived,
  });
  final String courseId;
  final AppServices services;
  final bool archived;

  @override
  State<TeacherActivitiesSection> createState() =>
      _TeacherActivitiesSectionState();
}

class _TeacherActivitiesSectionState extends State<TeacherActivitiesSection> {
  late final DashboardController<List<Activity>> _c;

  @override
  void initState() {
    super.initState();
    _c = DashboardController<List<Activity>>(
      () => widget.services.activities.overview(widget.courseId),
      bus: widget.services.summaries,
      topic: SummaryTopic.activities,
    )..load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _create() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ActivityFormPage(
        courseId: widget.courseId,
        services: widget.services,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final list = [
          for (final a in _c.data ?? const <Activity>[])
            if (!a.archived) a,
        ];
        final pending = list.fold<int>(0, (n, a) => n + a.pendingTotal);
        return AcademicSection(
          title: l.actDaily,
          icon: Icons.local_fire_department_outlined,
          subtitle: l.actSectionSubtitle,
          count: _c.state == LoadState.ready ? '${list.length}' : null,
          actions: [
            if (!widget.archived)
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: Text(l.actNewActivity),
              ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PendingQueuePage(
                    services: widget.services,
                    courseId: widget.courseId,
                  ),
                ),
              ),
              icon: const Icon(Icons.rule_folder_outlined),
              label: Text(
                pending > 0 ? l.actReviewN(pending) : l.actReviewQueue,
              ),
            ),
          ],
          children: [
            if (_c.state == LoadState.loading)
              const SkeletonBlock(rows: 2)
            else if (_c.state == LoadState.error)
              ErrorPanel(
                error: _c.error!,
                onRetry: _c.load,
                full: false,
                framed: false,
              )
            else if (list.isEmpty)
              EmptyPanel(
                icon: Icons.event_repeat_outlined,
                title: l.actEmptyTitle,
                message: l.actEmptyHint,
                framed: false,
              )
            else
              for (final a in list)
                TrailingTile(
                  leading: const AcademicIcon(
                    Icons.local_fire_department_outlined,
                    category: 3,
                  ),
                  title: Text(a.title),
                  subtitle: Text(
                    [
                      a.schedule?.weekdaysText(l, f) ?? '',
                      a.policy.text(l),
                      if (a.status == 'inactive') l.actPaused,
                      if (a.today.scheduled)
                        l.actTodayDone(a.today.completed, a.today.expected)
                      else
                        l.actNotScheduledToday,
                      if (a.pendingTotal > 0) l.actToReview(a.pendingTotal),
                    ].where((s) => s.isNotEmpty).join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TeacherActivityPage(
                        courseId: widget.courseId,
                        activityId: a.id,
                        services: widget.services,
                        archived: widget.archived,
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Create an activity: title, description, completion policy and the first schedule version.
class ActivityFormPage extends StatefulWidget {
  const ActivityFormPage({
    super.key,
    required this.courseId,
    required this.services,
  });
  final String courseId;
  final AppServices services;

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _draft = ScheduleDraft(start: _today());
  ActivityPolicy _policy = ActivityPolicy.selfReported;
  late final ActivityActions _actions = ActivityActions(
    widget.services.activities,
    summaries: widget.services.summaries,
  );
  _FormProblem? _problem;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _actions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _problem = _FormProblem.title);
      return;
    }
    if (_draft.weekdays.isEmpty) {
      setState(() => _problem = _FormProblem.days);
      return;
    }
    setState(() => _problem = null);
    final ok = await _actions.create(
      courseId: widget.courseId,
      title: _title.text,
      description: _desc.text,
      policy: _policy,
      weekdays: _draft.days,
      startDate: _draft.start,
      endDate: _draft.end,
      deadlineMode: _draft.mode,
      deadlineTime: _draft.timeWire,
      timezone: _draft.timezone,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: _actions,
        builder: (context, _) => StudioPage(
          maxWidth: StudioLayout.reading,
          children: [
            AcademicPageHeader(
              eyebrow: l.actDaily,
              icon: Icons.add_task,
              title: l.actNewActivity,
              description: l.actFormDesc,
            ),
            const SizedBox(height: Space.md),
            AcademicSection(
              title: l.actDetails,
              icon: Icons.edit_note,
              padded: true,
              children: [
                TextField(
                  controller: _title,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l.commonTitle),
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  controller: _desc,
                  maxLength: 2000,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l.actDescriptionOptional,
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  l.actHowRecorded,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                RadioGroup<ActivityPolicy>(
                  groupValue: _policy,
                  onChanged: (v) => setState(() => _policy = v ?? _policy),
                  child: Column(
                    children: [
                      for (final p in ActivityPolicy.values)
                        RadioListTile<ActivityPolicy>(
                          value: p,
                          title: Text(p.text(l)),
                          subtitle: Text(p.detailText(l)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            AcademicSection(
              title: l.actSchedule,
              icon: Icons.event_repeat_outlined,
              padded: true,
              children: [
                ScheduleFields(
                  draft: _draft,
                  onChanged: () => setState(() {}),
                  startLabel: l.actStarts,
                  firstDate: _today(),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            if (_problem != null || _actions.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  switch (_problem) {
                    _FormProblem.title => l.actProblemTitle,
                    _FormProblem.days => l.actProblemDays,
                    null => _actions.error!.text(context),
                  },
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: _actions.busy ? null : _save,
              icon: _actions.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(l.actCreate),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FormProblem { title, days }

/// A new schedule version for an existing activity (starts tomorrow or later; history keeps the old rules).
class ScheduleChangePage extends StatefulWidget {
  const ScheduleChangePage({
    super.key,
    required this.activity,
    required this.services,
  });
  final Activity activity;
  final AppServices services;

  @override
  State<ScheduleChangePage> createState() => _ScheduleChangePageState();
}

class _ScheduleChangePageState extends State<ScheduleChangePage> {
  late final ScheduleDraft _draft = widget.activity.schedule == null
      ? ScheduleDraft(start: _today().add(const Duration(days: 1)))
      : ScheduleDraft.from(
          widget.activity.schedule!,
          start: _today().add(const Duration(days: 1)),
        );
  late final ActivityActions _actions = ActivityActions(
    widget.services.activities,
    summaries: widget.services.summaries,
  );

  @override
  void dispose() {
    _actions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await _actions.addSchedule(
      widget.activity,
      weekdays: _draft.days,
      effectiveFrom: _draft.start,
      endDate: _draft.end,
      deadlineMode: _draft.mode,
      deadlineTime: _draft.timeWire,
      timezone: _draft.timezone,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: _actions,
        builder: (context, _) => StudioPage(
          maxWidth: StudioLayout.reading,
          children: [
            AcademicPageHeader(
              eyebrow: l.actChangeSchedule,
              icon: Icons.event_repeat_outlined,
              title: widget.activity.title,
              description: l.actChangeDesc,
            ),
            const SizedBox(height: Space.md),
            AcademicSection(
              title: l.actNewSchedule,
              icon: Icons.edit_calendar_outlined,
              padded: true,
              children: [
                ScheduleFields(
                  draft: _draft,
                  onChanged: () => setState(() {}),
                  startLabel: l.actStarts,
                  firstDate: _today().add(const Duration(days: 1)),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            if (_actions.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(
                  _actions.error!.text(context),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: _actions.busy || _draft.weekdays.isEmpty
                  ? null
                  : _save,
              icon: const Icon(Icons.check),
              label: Text(l.actSaveSchedule),
            ),
          ],
        ),
      ),
    );
  }
}

/// One activity: details, schedule, status actions and the weekly register.
class TeacherActivityPage extends StatefulWidget {
  const TeacherActivityPage({
    super.key,
    required this.courseId,
    required this.activityId,
    required this.services,
    this.archived = false,
  });
  final String courseId;
  final String activityId;
  final AppServices services;
  final bool archived;

  @override
  State<TeacherActivityPage> createState() => _TeacherActivityPageState();
}

class _TeacherActivityPageState extends State<TeacherActivityPage> {
  late final DashboardController<Activity?> _activity;
  late final ActivityRegisterController _register;
  late final ActivityActions _actions;

  @override
  void initState() {
    super.initState();
    final s = widget.services;
    _activity = DashboardController<Activity?>(
      () async {
        final list = await s.activities.overview(widget.courseId);
        return list.where((a) => a.id == widget.activityId).firstOrNull;
      },
      bus: s.summaries,
      topic: SummaryTopic.activities,
    )..load();
    _register = ActivityRegisterController(
      s.activities,
      widget.activityId,
      bus: s.summaries,
    )..load();
    _actions = ActivityActions(s.activities, summaries: s.summaries);
  }

  @override
  void dispose() {
    _activity.dispose();
    _register.dispose();
    _actions.dispose();
    super.dispose();
  }

  Future<void> _edit(Activity a) async {
    final d = await askDetails(
      context,
      title: a.title,
      description: a.description,
    );
    if (d != null) {
      await _actions.update(a, title: d.title, description: d.description);
    }
  }

  Future<void> _status(Activity a, String status) async {
    final tomorrow = _today().add(const Duration(days: 1));
    final needsDate =
        status != 'archived' &&
        !(a.status == 'archived' && status == 'inactive');
    final l = AppLocalizations.of(context);
    final label = switch (status) {
      'inactive' => l.actConfirmPause,
      'archived' => l.actConfirmArchive,
      _ => l.actConfirmResume,
    };
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.commonConfirm),
          ),
        ],
      ),
    );
    if (go == true) {
      await _actions.setStatus(
        a,
        status,
        effectiveFrom: needsDate ? tomorrow : null,
      );
    }
  }

  Future<void> _openCell(
    ActivityRegister r,
    RegisterStudent s,
    RegisterCell c,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CellSheet(
        register: r,
        student: s,
        cell: c,
        actions: _actions,
        readOnly: widget.archived,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: Listenable.merge([_activity, _register, _actions]),
        builder: (context, _) {
          if (_activity.state == LoadState.loading) return const SkeletonPage();
          if (_activity.state == LoadState.error || _activity.data == null) {
            return ErrorPanel(
              error:
                  _activity.error ??
                  const AppError(
                    AppErrorKind.notFound,
                    'Activity not found.',
                    AppErrorCode.activityNotFound,
                  ),
              onRetry: _activity.load,
              onBack: () => Navigator.of(context).maybePop(),
            );
          }
          final a = _activity.data!;
          final sch = a.schedule;
          return RefreshIndicator(
            onRefresh: () async {
              await _activity.load(showSpinner: false);
              await _register.load(showSpinner: false);
            },
            child: StudioPage(
              maxWidth: StudioLayout.maxWorkspace,
              children: [
                AcademicPageHeader(
                  eyebrow: l.actDailyOne,
                  icon: Icons.local_fire_department_outlined,
                  title: a.title,
                  description: a.description.isEmpty ? null : a.description,
                  meta: [
                    MetadataRow(
                      Icons.rule,
                      '${a.policy.text(l)}: ${a.policy.hintText(l)}',
                    ),
                    if (sch != null)
                      MetadataRow(
                        Icons.event_repeat_outlined,
                        '${sch.weekdaysText(l, f)} · ${sch.deadlineText(l)}',
                      ),
                    if (sch != null)
                      MetadataRow(
                        Icons.play_arrow_outlined,
                        sch.endDate == null
                            ? l.actScheduleFrom(
                                formatDate(sch.effectiveFrom, f: f),
                                sch.versionNo,
                              )
                            : l.actScheduleFromTo(
                                formatDate(sch.effectiveFrom, f: f),
                                formatDate(sch.endDate!, f: f),
                                sch.versionNo,
                              ),
                      ),
                    if (a.status != 'active')
                      MetadataRow(
                        Icons.pause_circle_outline,
                        a.status == 'archived' ? l.commonArchived : l.actPaused,
                      ),
                  ],
                  actions: [
                    if (!widget.archived && !a.archived) ...[
                      OutlinedButton.icon(
                        onPressed: () => _edit(a),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l.actEditDetails),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ScheduleChangePage(
                              activity: a,
                              services: widget.services,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: Text(l.actChangeSchedule),
                      ),
                      if (a.status == 'active')
                        OutlinedButton.icon(
                          onPressed: () => _status(a, 'inactive'),
                          icon: const Icon(Icons.pause),
                          label: Text(l.actPause),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _status(a, 'active'),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l.actResume),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _status(a, 'archived'),
                        icon: const Icon(Icons.archive_outlined),
                        label: Text(l.actArchive),
                      ),
                    ],
                  ],
                ),
                if (_actions.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: Text(
                      _actions.error!.text(context),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: Space.md),
                _RegisterSection(controller: _register, onCell: _openCell),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RegisterSection extends StatelessWidget {
  const _RegisterSection({required this.controller, required this.onCell});
  final ActivityRegisterController controller;
  final void Function(ActivityRegister, RegisterStudent, RegisterCell) onCell;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final r = c.data;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return AcademicSection(
      title: l.actWeeklyRegister,
      icon: Icons.grid_view_outlined,
      subtitle: l.actRegisterSubtitle(f.weekdayDayMonth(c.weekStart)),
      actions: [
        OutlinedButton.icon(
          onPressed: () => c.shiftWeeks(-1),
          icon: const Icon(Icons.chevron_left),
          label: Text(l.actPrevWeek),
        ),
        OutlinedButton.icon(
          onPressed: () => c.shiftWeeks(1),
          icon: const Icon(Icons.chevron_right),
          label: Text(l.actNextWeek),
        ),
      ],
      padded: true,
      children: [
        if (c.error != null && r != null)
          Text(
            l.actCouldNotRefreshWeek(c.error!.text(context)),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (c.state == LoadState.loading)
          const SkeletonBlock(rows: 3)
        else if (c.state == LoadState.error)
          ErrorPanel(
            error: c.error!,
            onRetry: c.load,
            full: false,
            framed: false,
          )
        else if (r == null || r.students.isEmpty)
          EmptyPanel(
            icon: Icons.groups_outlined,
            title: l.actNoStudentsTitle,
            message: l.actNoStudentsHint,
            framed: false,
          )
        else if (r.days.isEmpty)
          EmptyPanel(
            icon: Icons.event_busy_outlined,
            title: l.actNotScheduledWeek,
            message: l.actNotScheduledWeekHint,
            framed: false,
          )
        else ...[
          _Legend(l),
          const SizedBox(height: Space.sm),
          for (final s in r.students)
            _StudentRow(register: r, student: s, onCell: onCell),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.t);
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.md,
    runSpacing: 4,
    children: [
      for (final s in [
        OccurrenceState.completed,
        OccurrenceState.pending,
        OccurrenceState.open,
        OccurrenceState.missed,
        OccurrenceState.upcoming,
      ])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateGlyph(s, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                s.text(t),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
    ],
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.register,
    required this.student,
    required this.onCell,
  });
  final ActivityRegister register;
  final RegisterStudent student;
  final void Function(ActivityRegister, RegisterStudent, RegisterCell) onCell;

  @override
  Widget build(BuildContext context) {
    final cells = {for (final c in student.cells) c.date: c};
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.name.isEmpty ? l.roleStudent : student.name,
            style: text.titleSmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 7; i++)
                Builder(
                  builder: (context) {
                    final day = register.weekStart.add(Duration(days: i));
                    final cell = cells[DateTime(day.year, day.month, day.day)];
                    final label = '${f.weekdayShort(i + 1)} ${day.day}';
                    return Semantics(
                      button: cell != null,
                      label:
                          '${student.name}, $label: ${cell == null ? l.actStateNotScheduled.toLowerCase() : cell.state.text(l)}',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: cell == null
                            ? null
                            : () => onCell(register, student, cell),
                        borderRadius: BorderRadius.circular(Radii.sm),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 56,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(label, style: text.labelSmall),
                              const SizedBox(height: 4),
                              StateGlyph(cell?.state),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CellSheet extends StatefulWidget {
  const _CellSheet({
    required this.register,
    required this.student,
    required this.cell,
    required this.actions,
    required this.readOnly,
  });
  final ActivityRegister register;
  final RegisterStudent student;
  final RegisterCell cell;
  final ActivityActions actions;
  final bool readOnly;

  @override
  State<_CellSheet> createState() => _CellSheetState();
}

class _CellSheetState extends State<_CellSheet> {
  final _reason = TextEditingController();
  bool _rejecting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _do(Future<bool> Function() call) async {
    final ok = await call();
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cell;
    final r = widget.register;
    final s = widget.student;
    final a = widget.actions;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final future = c.state == OccurrenceState.upcoming;
    return Padding(
      padding: EdgeInsets.only(
        left: Space.lg,
        right: Space.lg,
        top: Space.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: a,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.name, style: Theme.of(context).textTheme.titleLarge),
              Text('${r.title} · ${friendlyDay(c.date, l: l, f: f)}'),
              const SizedBox(height: Space.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: OccurrencePill(c.state),
              ),
              if (c.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(l.actStudentNote(c.note)),
                ),
              if (c.reason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(l.actReasonGiven(c.reason)),
                ),
              const SizedBox(height: Space.md),
              if (a.error != null)
                Text(
                  a.error!.text(context),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (widget.readOnly)
                Text(l.actArchivedReadOnly)
              else if (c.state == OccurrenceState.pending) ...[
                if (_rejecting)
                  TextField(
                    controller: _reason,
                    maxLength: 500,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l.actReasonRequired),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: a.busy
                            ? null
                            : () => _do(
                                () => a.reviewCell(
                                  r.activityId,
                                  s.studentId,
                                  c.date,
                                  c.version,
                                  approve: true,
                                ),
                              ),
                        icon: const Icon(Icons.check),
                        label: Text(l.actApprove),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: a.busy
                            ? null
                            : () {
                                if (!_rejecting) {
                                  setState(() => _rejecting = true);
                                } else if (_reason.text.trim().isNotEmpty) {
                                  _do(
                                    () => a.reviewCell(
                                      r.activityId,
                                      s.studentId,
                                      c.date,
                                      c.version,
                                      approve: false,
                                      reason: _reason.text,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.close),
                        label: Text(
                          _rejecting ? l.actSendRejection : l.actReject,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (future)
                Text(l.actFutureDays)
              else
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: a.busy
                          ? null
                          : () => _do(
                              () => a.mark(
                                r.activityId,
                                s.studentId,
                                c.date,
                                c.version,
                                completed: true,
                              ),
                            ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l.actMarkCompleted),
                    ),
                    OutlinedButton.icon(
                      onPressed: a.busy
                          ? null
                          : () => _do(
                              () => a.mark(
                                r.activityId,
                                s.studentId,
                                c.date,
                                c.version,
                                completed: false,
                              ),
                            ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(l.actMarkNotDone),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teacher: submissions waiting for verification, oldest first (pages of 50).
class PendingQueuePage extends StatefulWidget {
  const PendingQueuePage({super.key, required this.services, this.courseId});
  final AppServices services;
  final String? courseId;

  @override
  State<PendingQueuePage> createState() => _PendingQueuePageState();
}

class _PendingQueuePageState extends State<PendingQueuePage> {
  late final PendingQueueController _c;
  late final ActivityActions _actions;

  @override
  void initState() {
    super.initState();
    _c = PendingQueueController(
      widget.services.activities,
      courseId: widget.courseId,
      bus: widget.services.summaries,
    )..load();
    _actions = ActivityActions(
      widget.services.activities,
      summaries: widget.services.summaries,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    _actions.dispose();
    super.dispose();
  }

  Future<void> _reject(PendingVerification p) async {
    final l = AppLocalizations.of(context);
    final reason = await askText(
      context,
      title: l.actRejectTitle,
      label: l.actReasonRequired,
      confirm: l.actReject,
      required: true,
    );
    if (reason != null) {
      await _actions.review(p, approve: false, reason: reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: Listenable.merge([_c, _actions]),
        builder: (context, _) {
          return StudioPage(
            maxWidth: StudioLayout.maxWorkspace,
            children: [
              AcademicPageHeader(
                eyebrow: l.actDaily,
                icon: Icons.rule_folder_outlined,
                title: l.actVerificationQueue,
                description: _c.state == LoadState.ready
                    ? l.actWaitingDecision(_c.total ?? _c.items.length)
                    : null,
              ),
              const SizedBox(height: Space.md),
              AcademicSection(
                title: l.actWaitingReview,
                icon: Icons.pending_actions_outlined,
                padded: true,
                children: [
                  if (_actions.error != null)
                    Text(
                      _actions.error!.text(context),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_c.state == LoadState.loading)
                    const SkeletonBlock(rows: 3)
                  else if (_c.state == LoadState.error)
                    ErrorPanel(
                      error: _c.error!,
                      onRetry: _c.load,
                      full: false,
                      framed: false,
                    )
                  else if (_c.items.isEmpty)
                    EmptyPanel(
                      icon: Icons.task_alt,
                      title: l.actNothingToReview,
                      message: l.actNothingToReviewHint,
                      framed: false,
                    )
                  else ...[
                    for (final p in _c.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.studentName.isEmpty
                                  ? l.roleStudent
                                  : p.studentName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${p.activityTitle} · ${friendlyDay(p.date, l: l, f: f)}${p.submittedAt == null ? '' : ' · ${l.actSubmittedAt(formatDateTime(p.submittedAt!, f: f))}'}',
                            ),
                            if (p.note.isNotEmpty) Text(l.actNoteLine(p.note)),
                            const SizedBox(height: Space.sm),
                            Wrap(
                              spacing: Space.sm,
                              runSpacing: Space.sm,
                              children: [
                                FilledButton.icon(
                                  onPressed: _actions.busy
                                      ? null
                                      : () => _actions.review(p, approve: true),
                                  icon: const Icon(Icons.check),
                                  label: Text(l.actApprove),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _actions.busy
                                      ? null
                                      : () => _reject(p),
                                  icon: const Icon(Icons.close),
                                  label: Text(l.actReject),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_c.next != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: _c.loadingMore ? null : _c.loadMore,
                          child: Text(
                            _c.loadingMore
                                ? l.commonLoadingEllipsis
                                : l.commonLoadMore,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
