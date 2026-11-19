import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../core/adaptive.dart';
import '../../core/ui.dart';
import '../../core/academic.dart';
import '../courses/courses_page.dart' show CourseArea;
import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import '../courses/course_widgets.dart' show EmptyState, ErrorState;
import '../courses/courses_controller.dart' show LoadState;
import 'dashboard.dart';
import 'dashboard_controller.dart';
import '../tasks/today_section.dart';

class MetricCard extends StatelessWidget {
  const MetricCard(this.value, this.label, {this.hint, super.key});
  final String value;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: text.headlineSmall),
          Text(label, style: text.bodyMedium),
          if (hint != null) Text(hint!, style: text.bodySmall),
        ],
      ),
    );
  }
}

/// Two figures per row on any width, all on one quiet surface; text wraps instead of overflowing.
Widget metricGrid(List<MetricCard> items) => LayoutBuilder(
  builder: (context, c) {
    // One column once text is scaled up: half-width cells would break words.
    final cols = MediaQuery.textScalerOf(context).scale(16) > 24 ? 1 : 2;
    final w = (c.maxWidth - Space.md * (cols + 1)) / cols;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Wrap(
        spacing: Space.md,
        runSpacing: Space.md,
        children: [for (final m in items) SizedBox(width: w, child: m)],
      ),
    );
  },
);

Widget sectionTitle(BuildContext context, String t) => SectionHeader(t);

/// A framed list section: rows inside one bordered container, or a plain sentence when there are none.
Widget _section(
  BuildContext context,
  String title,
  IconData icon,
  List<Widget> rows, {
  String? empty,
}) => Padding(
  padding: const EdgeInsets.only(top: Space.md),
  child: rows.isEmpty
      ? AcademicSection(
          title: title,
          icon: icon,
          padded: true,
          children: [
            Text(empty ?? AppLocalizations.of(context).dashNothingToShow),
          ],
        )
      : AcademicSection(
          title: title,
          icon: icon,
          count: '${rows.length}',
          children: rows,
        ),
);

/// A prominent next step using only information returned by the dashboard.
class StudioTask extends StatelessWidget {
  const StudioTask({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.detail,
    this.action,
    this.onPressed,
    this.urgent = false,
  });
  final bool urgent;
  final String eyebrow;
  final String title;
  final String detail;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AcademicCard(
      tint: urgent ? scheme.tertiaryContainer : null,
      children: [
        Row(
          children: [
            const AcademicIcon(Icons.assignment_outlined, category: 1),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                eyebrow,
                style: text.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Text(title, style: text.headlineSmall),
        const SizedBox(height: Space.sm),
        Text(detail, style: text.bodyMedium),
        if (action != null && onPressed != null) ...[
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward),
            label: Text(action!),
          ),
        ],
      ],
    );
  }
}

class _TeachingFocus extends StatelessWidget {
  const _TeachingFocus(this.data, this.onOpenCourses);
  final TeacherDashboard data;
  final VoidCallback? onOpenCourses;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      key: const Key('teaching-review-focus'),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: s.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border(
          left: BorderSide(color: s.primary, width: Space.xs),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.md,
            runSpacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${data.awaitingGrading}',
                style: t.displaySmall?.copyWith(
                  color: s.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppLocalizations.of(context).metricAwaitingGrading,
                style: t.titleLarge,
              ),
            ],
          ),
          if (onOpenCourses != null) ...[
            const SizedBox(height: Space.sm),
            FilledButton.icon(
              onPressed: onOpenCourses,
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(AppLocalizations.of(context).dashOpenCourses),
            ),
          ],
        ],
      ),
    );
  }
}

/// The one thing to look at first; only built from server figures, and only when there is something to act on.
class FocusBanner extends StatelessWidget {
  const FocusBanner(this.text, {super.key, this.icon = Icons.flag_outlined});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: s.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: s.onSecondaryContainer),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: s.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _row(
  String title,
  String subtitle, {
  Widget? trailing,
  Widget? leading,
}) => TrailingTile(
  leading: leading,
  title: Text(title),
  subtitle: Text(subtitle),
  trailing: trailing,
);

String _due(BuildContext context, DateTime? d) {
  final l = AppLocalizations.of(context);
  return d == null
      ? l.asgNoDeadline
      : l.asgDue(AppFormat.of(context).dateTimeLong(d.toLocal()));
}

String _statusText(AppLocalizations l, String status) => switch (status) {
  'submitted' => l.statusSubmitted,
  'graded' => l.metricGraded,
  'returned' => l.statusReturned,
  _ => status,
};

/// Skeleton / error-with-retry / pull-to-refresh frame shared by both dashboards.
class DashboardFrame<T> extends StatelessWidget {
  const DashboardFrame({
    super.key,
    required this.controller,
    required this.builder,
    this.displayName,
    this.teacher = false,
  });
  final String? displayName;
  final bool teacher;
  final DashboardController<T> controller;
  final List<Widget> Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.state == LoadState.loading) {
        return const SkeletonList();
      }
      if (controller.state == LoadState.error) {
        return ErrorState(error: controller.error!, onRetry: controller.load);
      }
      final error = Theme.of(context).colorScheme.error;
      return RefreshIndicator(
        onRefresh: () => controller.load(showSpinner: false),
        child: StudioPage(
          children: [
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Row(
                  children: [
                    Icon(Icons.sync_problem, color: error),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).stateCouldNotRefresh(controller.error!.text(context)),
                        style: TextStyle(color: error),
                      ),
                    ),
                  ],
                ),
              ),
            ...builder(context, controller.data as T),
          ],
        ),
      );
    },
  );
}

class TeacherDashboardView extends StatefulWidget {
  const TeacherDashboardView({
    super.key,
    required this.services,
    this.active = true,
    this.onOpenCourses,
    this.displayName,
    this.onOpenArea,
    this.onOpenProfile,
  });

  /// False while another tab is showing; a stale summary then reloads when this one becomes active.
  final bool active;
  final ValueChanged<CourseArea>? onOpenArea;
  final VoidCallback? onOpenProfile;
  final String? displayName;
  final AppServices services;
  final VoidCallback? onOpenCourses;

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  late final _c = teacherDashboardController(
    widget.services.dashboard,
    bus: widget.services.summaries,
  );

  @override
  void initState() {
    super.initState();
    _c.active = widget.active;
    _c.load();
  }

  @override
  void didUpdateWidget(covariant TeacherDashboardView old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _c.activate() : _c.deactivate();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DashboardFrame<TeacherDashboard>(
    controller: _c,
    displayName: widget.displayName,
    teacher: true,
    builder: (context, d) {
      final l = AppLocalizations.of(context);
      final f = AppFormat.of(context);
      String pct(double? v) => percentLabel(v, l: l, f: f);
      return [
        if (widget.displayName != null) ...[
          AcademicHero(
            title: l.dashHello(widget.displayName!),
            role: l.roleTeacher,
            detail: l.dashTeacherHeroDetail(
              l.dashActiveCourses(d.coursesActive),
              d.awaitingGrading,
            ),
            onOpenCourses: widget.onOpenCourses,
            stats: [
              (value: '${d.coursesActive}', label: l.dashStatCourses),
              (value: '${d.awaitingGrading}', label: l.dashStatToGrade),
              (value: '${d.activeStudents}', label: l.dashStatStudents),
            ],
          ),
          sectionTitle(context, l.dashServices),
          AcademicServices(
            services: [
              (
                label: l.dashStatCourses,
                detail: l.dashDetailActive(d.coursesActive),
                icon: Icons.menu_book_outlined,
                onTap: widget.onOpenCourses,
              ),
              (
                label: l.dashServiceGrading,
                detail: l.dashDetailToReview(d.awaitingGrading),
                icon: Icons.rate_review_outlined,
                onTap: widget.onOpenArea == null
                    ? null
                    : () => widget.onOpenArea!(CourseArea.assignments),
              ),
              (
                label: l.commonAttendance,
                detail: l.dashDetailOpen(d.openSessions),
                icon: Icons.fact_check_outlined,
                onTap: widget.onOpenArea == null
                    ? null
                    : () => widget.onOpenArea!(CourseArea.attendance),
              ),
              (
                label: l.dashStatStudents,
                detail: l.dashDetailEnrolled(d.activeStudents),
                icon: Icons.groups_outlined,
                onTap: widget.onOpenCourses,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
        ],
        if (d.isEmpty)
          EmptyState(
            icon: Icons.school_outlined,
            title: l.dashEmptyTeacherTitle,
            hint: l.dashEmptyTeacherHint,
          )
        else
          StudioColumns(
            primary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.displayName == null)
                  _TeachingFocus(
                    d,
                    widget.displayName == null ? widget.onOpenCourses : null,
                  ),
                const SizedBox(height: Space.md),
                AcademicCard(
                  key: const Key('teacher-priority'),
                  tint: d.awaitingGrading > 0
                      ? Theme.of(context).colorScheme.tertiaryContainer
                      : null,
                  children: [
                    Row(
                      children: [
                        const AcademicIcon(
                          Icons.rate_review_outlined,
                          category: 1,
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.dashNeedsAttention,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(
                                d.awaitingGrading == 0
                                    ? l.dashAllCaughtUp
                                    : l.dashSubmissionsAwaiting(
                                        d.awaitingGrading,
                                      ),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      '${l.dashSubmittedLine(d.receivedSubmissions, d.expectedSubmissions, pct(d.attendanceRate))}${d.openSessions == 0 ? '' : ' · ${l.metricOpenSessions(d.openSessions)}'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (d.awaitingGrading > 0 && widget.onOpenArea != null) ...[
                      const SizedBox(height: Space.md),
                      FilledButton.icon(
                        onPressed: () =>
                            widget.onOpenArea!(CourseArea.assignments),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(l.dashReviewSubmissions),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ],
                ),
                _section(
                  context,
                  l.dashUpcomingDeadlines,
                  Icons.event_outlined,
                  [
                    for (final x in d.deadlines)
                      _row(
                        x.title,
                        '${x.courseTitle}\n${_due(context, x.dueAt)}',
                        leading: DateBadge(x.dueAt),
                        trailing: Text('${x.received ?? 0}/${x.expected ?? 0}'),
                      ),
                  ],
                  empty: l.dashNoDeadlines,
                ),
                _section(
                  context,
                  l.dashRecentSubmissions,
                  Icons.assignment_turned_in_outlined,
                  [
                    for (final r in d.recent)
                      _row(
                        '${r.studentName.isEmpty ? l.roleStudent : r.studentName} · ${r.assignmentTitle}',
                        '${r.courseTitle}${r.at == null ? '' : '\n${f.dateTimeLong(r.at!.toLocal())}'}',
                        trailing: StatusPill(_statusText(l, r.status)),
                      ),
                  ],
                  empty: l.dashNoSubmissions,
                ),
              ],
            ),
            secondary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(context, l.navCourses, Icons.menu_book_outlined, [
                  for (final c in d.courses)
                    _row(
                      c.title,
                      c.archived
                          ? l.dashArchivedStudents(
                              l.dashCountStudents(c.students),
                            )
                          : [
                              l.dashCountStudents(c.students),
                              l.dashCountAssignments(c.assignments),
                              l.dashToGradeCount(c.awaitingGrading),
                              l.dashCountSessions(c.attendanceSessions),
                            ].join(' · '),
                    ),
                ]),
                const SizedBox(height: Space.section),
                MoreFigures(
                  title: l.dashAllFigures,
                  children: [
                    metricGrid([
                      MetricCard(
                        '${d.coursesActive}',
                        l.dashActiveCoursesLabel,
                        hint: d.coursesArchived == 0
                            ? null
                            : l.metricArchived(d.coursesArchived),
                      ),
                      MetricCard('${d.activeStudents}', l.metricActiveStudents),
                      MetricCard(
                        '${d.awaitingGrading}',
                        l.metricAwaitingGrading,
                      ),
                      MetricCard(
                        '${d.outstanding}',
                        l.dashOutstanding,
                        hint: l.dashSubmittedOf(
                          d.receivedSubmissions,
                          d.expectedSubmissions,
                        ),
                      ),
                      MetricCard(
                        pct(d.attendanceRate),
                        l.metricAttendanceRate,
                        hint: d.openSessions == 0
                            ? null
                            : l.metricOpenSessions(d.openSessions),
                      ),
                      MetricCard(
                        '${d.publishedAssignments}',
                        l.dashPublishedAssignments,
                        hint: l.dashGradedReturned(d.graded, d.returned),
                      ),
                    ]),
                    const SizedBox(height: Space.md),
                    Text(
                      l.dashTeacherFootnote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ];
    },
  );
}

class StudentDashboardView extends StatefulWidget {
  const StudentDashboardView({
    super.key,
    required this.services,
    this.active = true,
    this.onOpenCourses,
    this.displayName,
    this.onOpenArea,
    this.onOpenProfile,
    this.onOpenTasks,
  });

  /// False while another tab is showing; a stale summary then reloads when this one becomes active.
  final bool active;
  final ValueChanged<CourseArea>? onOpenArea;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenTasks;
  final String? displayName;
  final AppServices services;
  final VoidCallback? onOpenCourses;

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  late final _c = studentDashboardController(
    widget.services.dashboard,
    bus: widget.services.summaries,
  );

  @override
  void initState() {
    super.initState();
    _c.active = widget.active;
    _c.load();
  }

  @override
  void didUpdateWidget(covariant StudentDashboardView old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _c.activate() : _c.deactivate();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DashboardFrame<StudentDashboard>(
    controller: _c,
    displayName: widget.displayName,
    builder: (context, d) {
      final l = AppLocalizations.of(context);
      final f = AppFormat.of(context);
      String pct(double? v) => percentLabel(v, l: l, f: f);
      final next = d.deadlines.isEmpty ? null : d.deadlines.first;
      return [
        if (widget.displayName != null) ...[
          AcademicHero(
            title: l.dashHello(widget.displayName!),
            role: l.roleStudent,
            detail: l.dashStudentHeroDetail(
              l.dashActiveCourses(d.coursesActive),
              d.done,
              d.published,
            ),
            onOpenCourses: widget.onOpenCourses,
            stats: [
              (value: '${d.coursesActive}', label: l.dashStatCourses),
              (value: '${d.done}/${d.published}', label: l.dashStatDone),
              (value: pct(d.attendanceRate), label: l.commonAttendance),
            ],
          ),
          TodayTasksSection(
            services: widget.services,
            active: widget.active,
            onOpenTasks: widget.onOpenTasks,
          ),
          const SizedBox(height: Space.md),
          sectionTitle(context, l.dashServices),
          AcademicServices(
            services: [
              (
                label: l.dashStatCourses,
                detail: l.dashDetailActive(d.coursesActive),
                icon: Icons.menu_book_outlined,
                onTap: widget.onOpenCourses,
              ),
              (
                label: l.commonAssignments,
                detail: l.dashDetailPublished(d.published),
                icon: Icons.assignment_outlined,
                onTap: widget.onOpenArea == null
                    ? null
                    : () => widget.onOpenArea!(CourseArea.assignments),
              ),
              (
                label: l.commonAttendance,
                detail: pct(d.attendanceRate),
                icon: Icons.fact_check_outlined,
                onTap: widget.onOpenArea == null
                    ? null
                    : () => widget.onOpenArea!(CourseArea.attendance),
              ),
              (
                label: l.dashServiceProfile,
                detail: l.dashServiceProfileDetail,
                icon: Icons.person_outline,
                onTap: widget.onOpenProfile,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
        ],
        if (d.isEmpty)
          EmptyState(
            icon: Icons.menu_book_outlined,
            title: l.dashEmptyStudentTitle,
            hint: l.dashEmptyStudentHint,
          )
        else
          StudioColumns(
            primary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioTask(
                  urgent: d.overdue > 0,
                  eyebrow: d.overdue > 0
                      ? l.dashNeedsYourAttention
                      : l.dashYourNextStep,
                  title: d.overdue > 0
                      ? l.dashOverdueCount(d.overdue)
                      : (next?.title ?? l.dashReadyToLearn),
                  detail: next == null
                      ? l.dashExploreCourses
                      : '${next.title} · ${next.courseTitle} · ${_due(context, next.dueAt)}',
                  action: widget.displayName == null ? l.dashOpenCourses : null,
                  onPressed: widget.onOpenCourses,
                ),
                _section(
                  context,
                  l.dashUpcomingDeadlines,
                  Icons.event_outlined,
                  [
                    for (final x in d.deadlines)
                      _row(
                        x.title,
                        '${x.courseTitle}\n${_due(context, x.dueAt)}',
                        leading: DateBadge(
                          x.dueAt,
                          overdue:
                              x.dueAt != null &&
                              x.dueAt!.isBefore(DateTime.now()),
                        ),
                        trailing: x.status == 'returned'
                            ? StatusPill(
                                l.dashStatusRevise,
                                tone: Tone.attention,
                                icon: Icons.edit_note,
                              )
                            : StatusPill(
                                l.dashStatusTodo,
                                icon: Icons.radio_button_unchecked,
                              ),
                      ),
                  ],
                  empty: l.dashNothingDueSoon,
                ),
              ],
            ),
            secondary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.md),
                AcademicSection(
                  title: l.dashLearningProgress,
                  icon: Icons.trending_up,
                  padded: true,
                  children: [
                    Text(
                      l.dashDoneOfPublished(d.done, d.published),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.sm),
                    LinearProgressIndicator(
                      value: d.published == 0
                          ? 0
                          : (d.done / d.published).clamp(0.0, 1.0),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      l.dashAttendanceValue(pct(d.attendanceRate)),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                _section(context, l.dashMyCourses, Icons.menu_book_outlined, [
                  for (final c in d.courses)
                    _row(
                      c.title,
                      c.archived
                          ? l.dashArchivedReadOnly
                          : l.dashCourseProgressLine(
                              c.done,
                              c.assignments,
                              pct(c.attendanceRate),
                            ),
                      trailing: c.archived
                          ? null
                          : Text(
                              pct(c.progressPercent),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                    ),
                ]),
                _section(context, l.dashRecentResults, Icons.grading, [
                  for (final g in d.recentGraded)
                    _row(
                      g.title,
                      '${g.courseTitle}${g.hasFeedback ? ' · ${l.dashFeedbackAvailable}' : ''}',
                      trailing: Text(
                        '${g.score}/${g.maxScore}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                ], empty: l.dashNoGraded),
                if (d.recentLessons.isNotEmpty) ...[
                  _section(
                    context,
                    l.dashNewLessons,
                    Icons.new_releases_outlined,
                    [
                      for (final x in d.recentLessons)
                        _row(
                          x.title,
                          '${x.courseTitle}${x.publishedAt == null ? '' : '\n${f.dateTimeLong(x.publishedAt!.toLocal())}'}',
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Space.section),
                MoreFigures(
                  title: l.dashAllFigures,
                  children: [
                    metricGrid([
                      MetricCard(
                        '${d.notStarted}',
                        l.dashNotStarted,
                        hint: d.overdue == 0
                            ? null
                            : l.dashOverdueHint(d.overdue),
                      ),
                      MetricCard('${d.awaitingGrade}', l.metricAwaitingGrade),
                      MetricCard('${d.needsRevision}', l.dashNeedsRevision),
                      MetricCard(
                        '${d.graded}',
                        l.metricGraded,
                        hint: l.metricAverage(pct(d.averagePercent)),
                      ),
                      MetricCard(pct(d.attendanceRate), l.metricAttendanceRate),
                      MetricCard(
                        l.metricDoneOfPublished(d.done, d.published),
                        l.metricAssignmentsDone,
                        hint: l.metricSubmittedOrGraded,
                      ),
                    ]),
                    const SizedBox(height: Space.md),
                    Text(
                      l.dashStudentFootnote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ];
    },
  );
}
