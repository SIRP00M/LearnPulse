import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/adaptive.dart';
import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../courses/courses_controller.dart' show LoadState;
import '../dashboard/dashboard_controller.dart';
import '../dashboard/summary_bus.dart';
import '../progress/progress_pages.dart';
import 'activity.dart';
import 'activity_controllers.dart';
import 'activity_widgets.dart';

String dueText(ActivityOccurrence o, AppLocalizations l) {
  if (o.deadlineMode == 'none' || o.dueAt == null) return l.asgNoDeadline;
  final due = o.dueAt!;
  final end = o.deadlineMode == 'day_end';
  return end ? l.actDueEndOfDay : l.asgDue(clock(due));
}

/// One occurrence with the action its policy and state allow. The server re-checks everything; the buttons only
/// offer what can succeed, and a failure shows the server's sentence.
class OccurrenceTile extends StatelessWidget {
  const OccurrenceTile({
    super.key,
    required this.occurrence,
    required this.actions,
    this.streak,
    this.showDate = false,
  });

  final ActivityOccurrence occurrence;
  final ActivityActions actions;
  final StreakInfo? streak;
  final bool showDate;

  Future<void> _submit(BuildContext context) async {
    final o = occurrence;
    var note = '';
    if (o.policy == ActivityPolicy.teacherVerified) {
      final l = AppLocalizations.of(context);
      final text = await askText(
        context,
        title: l.actSubmitForReview,
        label: l.actNoteForTeacher,
        confirm: l.actSubmit,
      );
      if (text == null) return;
      note = text;
    }
    await actions.complete(o, note: note);
  }

  @override
  Widget build(BuildContext context) {
    final o = occurrence;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final verb = o.policy == ActivityPolicy.teacherVerified
        ? l.actSubmitForReview
        : l.actMarkDone;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(o.title, style: text.titleMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: Space.sm,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OccurrencePill(o.state),
              if (showDate)
                Text(
                  friendlyDay(o.date, l: l, f: f),
                  style: text.bodyMedium,
                ),
              Text(
                dueText(o, l),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            o.policy.hintText(l),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (o.state == OccurrenceState.rejected && o.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.actTeacherAskedRetry(o.reason),
                style: text.bodyMedium?.copyWith(color: scheme.tertiary),
              ),
            ),
          if (streak != null) ...[
            const SizedBox(height: Space.sm),
            StreakChips(streak!),
          ],
          if (o.canComplete || o.canWithdraw) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                if (o.canComplete)
                  FilledButton.icon(
                    onPressed: actions.busy ? null : () => _submit(context),
                    icon: const Icon(Icons.check),
                    label: Text(
                      o.state == OccurrenceState.rejected
                          ? l.commonTryAgain
                          : verb,
                    ),
                  ),
                if (o.canWithdraw)
                  OutlinedButton.icon(
                    onPressed: actions.busy ? null : () => actions.retract(o),
                    icon: const Icon(Icons.undo),
                    label: Text(l.actWithdraw),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Student course page: today's activities with streaks, plus the week view and "My progress".
class StudentActivitiesSection extends StatefulWidget {
  const StudentActivitiesSection({
    super.key,
    required this.courseId,
    required this.services,
    required this.courseTitle,
  });
  final String courseId;
  final String courseTitle;
  final AppServices services;

  @override
  State<StudentActivitiesSection> createState() =>
      _StudentActivitiesSectionState();
}

class _StudentActivitiesSectionState extends State<StudentActivitiesSection> {
  late final StudentActivitiesController _today;
  late final DashboardController<List<ActivityStreak>> _streaks;
  late final ActivityActions _actions;

  @override
  void initState() {
    super.initState();
    final s = widget.services;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    _today = StudentActivitiesController(
      s.activities,
      from: day,
      to: day,
      courseId: widget.courseId,
      bus: s.summaries,
    )..load();
    _streaks = DashboardController<List<ActivityStreak>>(
      () => s.activities.streaks(widget.courseId),
      bus: s.summaries,
      topic: SummaryTopic.activities,
    )..load();
    _actions = ActivityActions(s.activities, summaries: s.summaries);
  }

  @override
  void dispose() {
    _today.dispose();
    _streaks.dispose();
    _actions.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    await _today.load();
    await _streaks.load(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_today, _streaks, _actions]),
      builder: (context, _) {
        final byId = {
          for (final s in _streaks.data ?? const <ActivityStreak>[])
            s.activityId: s.streak,
        };
        final children = <Widget>[];
        if (_actions.error != null) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(
                _actions.error!.text(context),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }
        if (_today.state == LoadState.loading) {
          children.add(const SkeletonBlock(rows: 2));
        } else if (_today.state == LoadState.error) {
          children.add(
            ErrorPanel(
              error: _today.error!,
              onRetry: _retry,
              full: false,
              framed: false,
            ),
          );
        } else if (_today.items.isEmpty) {
          children.add(
            EmptyPanel(
              icon: Icons.event_available_outlined,
              title: l.actNothingToday,
              message: l.actNothingTodayHint,
              framed: false,
            ),
          );
        } else {
          for (final o in _today.items) {
            children.add(
              OccurrenceTile(
                occurrence: o,
                actions: _actions,
                streak: byId[o.activityId],
              ),
            );
          }
        }
        return AcademicSection(
          title: l.actDaily,
          icon: Icons.local_fire_department_outlined,
          subtitle: l.actTodaySubtitle,
          count: _today.state == LoadState.ready
              ? '${_today.items.length}'
              : null,
          actions: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudentActivityWeekPage(
                    services: widget.services,
                    courseId: widget.courseId,
                    title: widget.courseTitle,
                  ),
                ),
              ),
              icon: const Icon(Icons.view_week_outlined),
              label: Text(l.actWeekView),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProgressPage(
                    services: widget.services,
                    courseId: widget.courseId,
                    teacherView: false,
                  ),
                ),
              ),
              icon: const Icon(Icons.insights_outlined),
              label: Text(l.actMyProgress),
            ),
          ],
          padded: true,
          children: children,
        );
      },
    );
  }
}

/// The student's week of occurrences (one course, or all courses when [courseId] is null).
class StudentActivityWeekPage extends StatefulWidget {
  const StudentActivityWeekPage({
    super.key,
    required this.services,
    this.courseId,
    required this.title,
    this.activityId,
    this.initialDate,
  });
  final AppServices services;
  final String? courseId;
  final String title;
  final String? activityId;
  final DateTime? initialDate;

  @override
  State<StudentActivityWeekPage> createState() =>
      _StudentActivityWeekPageState();
}

class _StudentActivityWeekPageState extends State<StudentActivityWeekPage> {
  late DateTime _week = ActivityRegisterController.mondayOf(
    widget.initialDate ?? DateTime.now(),
  );
  late final StudentActivitiesController _c;
  late final ActivityActions _actions;

  @override
  void initState() {
    super.initState();
    _c = StudentActivitiesController(
      widget.services.activities,
      from: _week,
      to: _week.add(const Duration(days: 6)),
      courseId: widget.courseId,
      bus: widget.services.summaries,
    );
    _actions = ActivityActions(
      widget.services.activities,
      summaries: widget.services.summaries,
    );
    _c.load().then((_) => _c.loadAll());
  }

  @override
  void dispose() {
    _c.dispose();
    _actions.dispose();
    super.dispose();
  }

  void _shift(int n) {
    setState(() => _week = _week.add(Duration(days: 7 * n)));
    _c.setWindow(_week, _week.add(const Duration(days: 6)));
    _c.load().then((_) => _c.loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: StudioPage(
        maxWidth: StudioLayout.maxWorkspace,
        children: [
          AcademicPageHeader(
            eyebrow: l.actDaily,
            icon: Icons.view_week_outlined,
            title: l.actWeekOf(f.weekdayDayMonth(_week)),
            description: widget.title,
          ),
          const SizedBox(height: Space.md),
          ListenableBuilder(
            listenable: Listenable.merge([_c, _actions]),
            builder: (context, _) {
              final items = [
                for (final o in _c.items)
                  if (widget.activityId == null ||
                      o.activityId == widget.activityId)
                    o,
              ];
              final byDay = <DateTime, List<ActivityOccurrence>>{};
              for (final o in items) {
                byDay.putIfAbsent(o.date, () => []).add(o);
              }
              final days = byDay.keys.toList()..sort();
              return AcademicSection(
                title: l.actThisWeek,
                icon: Icons.event_note_outlined,
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left),
                    label: Text(l.actPrevWeek),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.chevron_right),
                    label: Text(l.actNextWeek),
                  ),
                ],
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
                  else if (days.isEmpty)
                    EmptyPanel(
                      icon: Icons.event_busy_outlined,
                      title: l.actNoWeekTitle,
                      message: l.actNoWeekHint,
                      framed: false,
                    )
                  else
                    for (final d in days) ...[
                      SectionLabel(friendlyDay(d, l: l, f: f)),
                      for (final o in byDay[d]!)
                        OccurrenceTile(occurrence: o, actions: _actions),
                    ],
                  if (_c.next != null)
                    const Padding(
                      padding: EdgeInsets.all(Space.sm),
                      child: LinearProgressIndicator(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
