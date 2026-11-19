import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/adaptive.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import '../activities/activity_widgets.dart';
import '../courses/courses_controller.dart' show LoadState;
import '../courses/course_widgets.dart' show formatDate, formatDateTime;
import '../dashboard/dashboard.dart' show percentLabel;
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_pages.dart' show MetricCard, metricGrid;
import '../dashboard/summary_bus.dart';
import 'progress.dart';

/// Private progress of one student in one course. Teacher: opened from the class roster (one student at a time, no
/// ranking, no cross-student comparison). Student: "My progress". Every figure is a server figure with its denominator.
class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    required this.services,
    required this.courseId,
    required this.teacherView,
    this.studentId,
    this.studentName,
  });

  final AppServices services;
  final String courseId;
  final bool teacherView;
  final String? studentId;
  final String? studentName;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late final DashboardController<StudentProgress> _c;

  @override
  void initState() {
    super.initState();
    final r = widget.services.progress;
    _c = DashboardController<StudentProgress>(
      () => widget.teacherView
          ? r.forStudent(widget.courseId, widget.studentId!)
          : r.mine(widget.courseId),
      bus: widget.services.summaries,
      topic: SummaryTopic.progress,
    )..load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          if (_c.state == LoadState.loading) return const SkeletonPage();
          if (_c.state == LoadState.error) {
            return ErrorPanel(
              error: _c.error!,
              onRetry: _c.load,
              onBack: () => Navigator.of(context).maybePop(),
            );
          }
          final p = _c.data!;
          return RefreshIndicator(
            onRefresh: () => _c.load(showSpinner: false),
            child: StudioPage(
              maxWidth: StudioLayout.maxWorkspace,
              children: [
                AcademicPageHeader(
                  eyebrow: widget.teacherView
                      ? l.progEyebrowTeacher
                      : l.actMyProgress,
                  icon: Icons.insights_outlined,
                  title: widget.teacherView && p.studentName.isNotEmpty
                      ? p.studentName
                      : (widget.studentName ?? l.actMyProgress),
                  description: p.courseTitle,
                  meta: [
                    if (p.joinedAt != null)
                      MetadataRow(
                        Icons.event_outlined,
                        l.progEnrolledSince(formatDate(p.joinedAt!, f: f)),
                      ),
                    MetadataRow(
                      Icons.verified_user_outlined,
                      widget.teacherView
                          ? l.progPrivateTeacher
                          : l.progPrivateStudent,
                    ),
                    if (p.courseArchived)
                      MetadataRow(Icons.archive_outlined, l.progArchived),
                  ],
                ),
                if (_c.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: Text(
                      l.progCouldNotRefresh(_c.error!.text(context)),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: Space.md),
                StudioColumns(
                  primary: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AssignmentsBlock(p.assignments),
                      const SizedBox(height: Space.lg),
                      _ActivitiesBlock(p.activities),
                    ],
                  ),
                  secondary: _AttendanceBlock(p.attendance),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Tone _tone(String status) => switch (status) {
  'graded' => Tone.success,
  'awaiting_review' => Tone.info,
  'needs_revision' => Tone.attention,
  'overdue' => Tone.danger,
  _ => Tone.neutral,
};

String _statusLabel(String status, AppLocalizations l) => switch (status) {
  'graded' => l.taskGraded,
  'awaiting_review' => l.progAwaitingGrading,
  'needs_revision' => l.taskNeedsRevision,
  'overdue' => l.taskOverdue,
  _ => l.asgNotSubmitted,
};

class _AssignmentsBlock extends StatelessWidget {
  const _AssignmentsBlock(this.a);
  final AssignmentProgress a;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return AcademicSection(
      title: l.commonAssignments,
      icon: Icons.assignment_outlined,
      subtitle: a.published == 0
          ? l.progAssignmentsNone
          : l.progAssignmentsSummary(a.done, a.published),
      count: '${a.published}',
      padded: true,
      children: [
        if (a.published == 0)
          EmptyPanel(
            icon: Icons.assignment_outlined,
            title: l.progNoPublishedTitle,
            message: l.progNoPublishedHint,
            framed: false,
          )
        else ...[
          metricGrid([
            MetricCard(
              l.progOfCount(a.done, a.published),
              l.metricSubmittedOrGraded,
            ),
            MetricCard(
              '${a.notStarted}',
              l.asgNotSubmitted,
              hint: l.progOverdueHint(a.overdue),
            ),
            MetricCard('${a.awaitingReview}', l.progAwaitingGrading),
            MetricCard(
              '${a.graded}',
              l.taskGraded,
              hint: a.averagePercent == null
                  ? l.metricNoGradesYet
                  : l.metricAverage(percentLabel(a.averagePercent, l: l, f: f)),
            ),
            MetricCard('${a.needsRevision}', l.metricReturnedRevision),
          ]),
          const SizedBox(height: Space.sm),
          for (final e in a.items)
            TrailingTile(
              leading: const AcademicIcon(
                Icons.assignment_outlined,
                category: 1,
              ),
              title: Text(e.title),
              subtitle: Text(
                [
                  e.dueAt == null
                      ? l.asgNoDeadline
                      : l.asgDue(formatDateTime(e.dueAt!, f: f)),
                  if (e.status == 'graded' && e.score != null)
                    l.progScore(e.score!, e.maxScore),
                ].join(' · '),
              ),
              trailing: StatusPill(
                _statusLabel(e.status, l),
                tone: _tone(e.status),
              ),
            ),
          if (a.truncated)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(l.progTruncated(a.items.length, a.itemsTotal)),
            ),
        ],
      ],
    );
  }
}

class _ActivitiesBlock extends StatelessWidget {
  const _ActivitiesBlock(this.a);
  final ActivityProgress a;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AcademicSection(
      title: l.actDaily,
      icon: Icons.local_fire_department_outlined,
      subtitle: l.progActivitiesSubtitle,
      count: '${a.activities.length}',
      padded: true,
      children: [
        if (a.pendingVerification > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: StatusPill(
              l.progAwaitingVerification(a.pendingVerification),
              tone: Tone.info,
              icon: Icons.hourglass_top,
            ),
          ),
        if (a.activities.isEmpty)
          EmptyPanel(
            icon: Icons.event_note_outlined,
            title: l.actEmptyTitle,
            message: l.progNoActivitiesHint,
            framed: false,
          )
        else
          for (final s in a.activities)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    [
                      s.policy.text(l),
                      if (s.status == 'inactive')
                        l.actPaused
                      else if (s.status == 'archived')
                        l.commonArchived
                      else if (s.status != 'active')
                        s.status,
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.sm),
                  StreakChips(s.streak),
                  if (s.streak.resolved == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.progNoClosedDay,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _AttendanceBlock extends StatelessWidget {
  const _AttendanceBlock(this.a);
  final AttendanceProgress a;

  @override
  Widget build(BuildContext context) {
    final rate = a.rate;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return AcademicSection(
      title: l.commonAttendance,
      icon: Icons.fact_check_outlined,
      subtitle: a.total == 0
          ? l.progAttNone
          : l.progAttSummary(a.total, a.closed),
      padded: true,
      children: [
        if (a.total == 0)
          EmptyPanel(
            icon: Icons.event_busy_outlined,
            title: l.progNoSessionsTitle,
            message: l.progNoSessionsHint,
            framed: false,
          )
        else ...[
          InfoGroup(
            children: [
              MetadataRow(
                Icons.percent,
                rate == null
                    ? l.progRateNone
                    : l.progRate(
                        percentLabel(rate, l: l, f: f),
                        a.present + a.late,
                        a.counted,
                      ),
              ),
              MetadataRow(
                Icons.check_circle_outline,
                '${l.attPresent} ${a.present} · ${l.attLate} ${a.late} · ${l.attExcused} ${a.excused} · ${l.attAbsent} ${a.absent}',
              ),
              MetadataRow(Icons.help_outline, l.progNotMarkedCount(a.unmarked)),
            ],
          ),
          const SizedBox(height: Space.sm),
          SectionLabel(l.progRecentSessions),
          for (final e in a.recent.take(10))
            TrailingTile(
              title: Text(e.title),
              subtitle: Text(
                e.startsAt == null ? '' : formatDateTime(e.startsAt!, f: f),
              ),
              trailing: StatusPill(
                switch (e.status) {
                  'present' => l.attPresent,
                  'late' => l.attLate,
                  'excused' => l.attExcused,
                  'absent' => l.attAbsent,
                  _ => l.atdNotMarked,
                },
                tone: switch (e.status) {
                  'present' || 'late' => Tone.success,
                  'absent' => Tone.danger,
                  _ => Tone.neutral,
                },
              ),
            ),
        ],
      ],
    );
  }
}
