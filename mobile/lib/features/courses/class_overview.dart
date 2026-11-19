import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/states.dart';
import '../../core/app_error.dart';
import '../../core/theme.dart';
import '../../core/formatting.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import '../assignments/assignment.dart';
import '../assignments/grade_submission_page.dart'
    show submissionIcon, submissionTone;
import '../attendance/attendance.dart';
import '../dashboard/dashboard.dart';
import 'course_widgets.dart' show formatDateTime;

/// One assignment's receipt progress.
class AssignmentProgress {
  const AssignmentProgress(this.assignment, this.received, this.awaiting);
  final Assignment assignment;
  final int received;
  final int awaiting;
}

class RecentWork {
  const RecentWork(this.submission, this.assignmentTitle);
  final Submission submission;
  final String assignmentTitle;
}

/// Class-level figures for one course, assembled only from reads the teacher is already authorised for.
/// Each part loads and fails on its own: one broken read never blanks the whole dashboard.
class ClassOverviewController extends ChangeNotifier {
  ClassOverviewController(this._services, this.courseId);

  final AppServices _services;
  final String courseId;
  bool _disposed = false;

  /// Assignments whose submissions are read for completion and recent activity (one read each).
  static const progressLimit = 4;

  bool loading = true;

  // Server figures for this course from the existing teacher-dashboard contract.
  TeacherCourseRow? courseRow;

  AttendanceSummary? attendance;
  List<AttendanceSession> sessions = const [];
  AttendanceSession? latest;
  Map<AttendanceStatus, int> latestCounts = const {};
  int latestNotMarked = 0;
  AppError? attendanceError;

  List<Assignment> assignments = const [];
  List<AssignmentProgress> progress = const [];
  List<RecentWork> recent = const [];
  AppError? workError;

  int get openSessions => sessions.where((s) => !s.closed).length;
  int get activeStudents => attendance?.rows.length ?? courseRow?.students ?? 0;
  int get published => assignments.where((a) => a.published).length;
  int get drafts => assignments.length - published;

  /// (Present + Late) / (Present + Late + Absent) over the whole class; Excused is not counted. Null without data.
  double? get classRate {
    var good = 0, all = 0;
    for (final r in attendance?.rows ?? const <AttendanceSummaryRow>[]) {
      good += r.present + r.late;
      all += r.present + r.late + r.absent;
    }
    return all == 0 ? null : 100.0 * good / all;
  }

  Future<void> load() async {
    if (attendanceError != null || workError != null) {
      loading =
          true; // a retry shows the loading state instead of the old error
      if (!_disposed) notifyListeners();
    }
    await Future.wait([_loadRow(), _loadAttendance(), _loadWork()]);
    loading = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadRow() async {
    try {
      final d = await _services.dashboard.teacher();
      courseRow = d.courses.where((c) => c.courseId == courseId).firstOrNull;
    } on Object {
      courseRow =
          null; // the figure falls back to local reads; the row is only a cross-check
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final summary = await _services.attendance.summary(courseId);
      final all = [...await _services.attendance.listSessions(courseId)]
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
      final newest = all.isEmpty ? null : all.first;
      final records = newest == null
          ? const <AttendanceRecord>[]
          : await _services.attendance.listRecordsForSessions([newest.id]);
      final counts = <AttendanceStatus, int>{};
      for (final r in records) {
        counts[r.status] = (counts[r.status] ?? 0) + 1;
      }
      attendance = summary;
      sessions = all;
      latest = newest;
      latestCounts = counts;
      latestNotMarked = (summary.rows.length - records.length).clamp(
        0,
        1 << 30,
      );
      attendanceError = null;
    } on Object catch (e) {
      attendanceError = AppError.from(e);
    }
  }

  Future<void> _loadWork() async {
    try {
      final all = await _services.assignments.listAssignments(courseId);
      final live = all.where((a) => a.published).toList()
        ..sort((a, b) {
          final x = a.dueAt, y = b.dueAt;
          if (x == null && y == null) return 0;
          if (x == null) return 1; // undated work after dated work
          if (y == null) return -1;
          return y.compareTo(x);
        });
      final rows = <AssignmentProgress>[];
      final work = <RecentWork>[];
      for (final a in live.take(progressLimit)) {
        final subs = await _services.assignments.listSubmissions(a.id);
        rows.add(
          AssignmentProgress(
            a,
            subs.length,
            subs.where((s) => s.status == SubmissionStatus.submitted).length,
          ),
        );
        work.addAll([for (final s in subs) RecentWork(s, a.title)]);
      }
      work.sort(
        (a, b) => b.submission.submittedAt.compareTo(a.submission.submittedAt),
      );
      assignments = all;
      progress = rows;
      recent = work.take(5).toList();
      workError = null;
    } on Object catch (e) {
      workError = AppError.from(e);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String _pct(BuildContext context, double? v) => v == null
    ? AppLocalizations.of(context).commonNoDataYet
    : AppFormat.of(context).percent(v);

String _attLabel(AppLocalizations l, AttendanceStatus s) => switch (s) {
  AttendanceStatus.present => l.attPresent,
  AttendanceStatus.late => l.attLate,
  AttendanceStatus.excused => l.attExcused,
  AttendanceStatus.absent => l.attAbsent,
};

/// Deep-teal class header: identity first, then the three figures a teacher checks on entry.
class ClassHeader extends StatelessWidget {
  const ClassHeader({
    super.key,
    required this.title,
    required this.description,
    required this.archived,
    required this.students,
    required this.openSessions,
    required this.toGrade,
  });
  final String title;
  final String description;
  final bool archived;
  final int students;
  final int openSessions;
  final int? toGrade;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Container(
      key: const Key('class-header'),
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: s.secondary,
        borderRadius: BorderRadius.circular(Radii.lg + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.sm,
            children: [
              Chip(
                backgroundColor: Color.alphaBlend(
                  s.onSecondary.withValues(alpha: .12),
                  s.secondary,
                ),
                side: BorderSide(color: s.onSecondary.withValues(alpha: .3)),
                labelStyle: t.labelMedium?.copyWith(color: s.onSecondary),
                avatar: Icon(
                  Icons.groups_outlined,
                  size: 16,
                  color: s.onSecondary,
                ),
                label: Text(l.classYourClass),
              ),
              if (archived)
                Chip(
                  backgroundColor: s.tertiaryContainer,
                  labelStyle: t.labelMedium?.copyWith(
                    color: s.onTertiaryContainer,
                  ),
                  avatar: Icon(
                    Icons.archive_outlined,
                    size: 16,
                    color: s.onTertiaryContainer,
                  ),
                  label: Text(l.classArchivedReadOnly),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Semantics(
            header: true,
            child: ScaleCap(
              max: 1.5,
              child: Text(
                title,
                style: t.headlineMedium?.copyWith(
                  color: s.onSecondary,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(
              description,
              style: t.bodyMedium?.copyWith(
                color: s.onSecondary.withValues(alpha: .9),
              ),
            ),
          ],
          const SizedBox(height: Space.md),
          Semantics(
            container: true,
            excludeSemantics: true,
            label: l.classHeroSemantics(
              students,
              openSessions,
              toGrade == null ? l.classUnknownNumber : '$toGrade',
            ),
            child: ScaleCap(
              max: 1.3,
              child: HeroStatTiles([
                (value: '$students', label: l.dashStatStudents),
                (value: '$openSessions', label: l.classOpenSessions),
                (
                  value: toGrade == null ? '–' : '$toGrade',
                  label: l.dashStatToGrade,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Latest-session attendance and class rate. Never shows a "today" figure: only the newest real session.
class ClassAttendanceCard extends StatelessWidget {
  const ClassAttendanceCard({super.key, required this.c});
  final ClassOverviewController c;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    if (c.loading) {
      return AcademicSection(
        title: l.commonAttendance,
        icon: Icons.fact_check_outlined,
        children: const [SkeletonBlock(rows: 2)],
      );
    }
    if (c.attendanceError != null) {
      return AcademicSection(
        title: l.commonAttendance,
        icon: Icons.fact_check_outlined,
        children: [
          ErrorPanel(
            error: c.attendanceError!,
            onRetry: c.load,
            full: false,
            framed: false,
          ),
        ],
      );
    }
    final latest = c.latest;
    return AcademicSummary(
      title: l.commonAttendance,
      status: StatusPill(
        c.sessions.isEmpty
            ? l.classNoSessions
            : l.classRateValue(_pct(context, c.classRate)),
        tone: c.sessions.isEmpty ? Tone.neutral : Tone.info,
        icon: c.sessions.isEmpty
            ? Icons.event_busy_outlined
            : Icons.fact_check_outlined,
      ),
      stats: [
        (label: l.classSessions, value: '${c.sessions.length}'),
        (label: l.commonOpen, value: '${c.openSessions}'),
        (label: l.commonClosed, value: '${c.attendance?.sessionsClosed ?? 0}'),
      ],
      footer: latest == null
          ? Text(l.classNoAttendanceSessions)
          : InfoGroup(
              children: [
                Text(l.classLatestSession, style: t.labelLarge),
                MetadataRow(
                  Icons.event_available_outlined,
                  '${latest.title.isEmpty ? l.classSessionFallback : latest.title} · ${formatDateTime(latest.startsAt, f: f)} · ${latest.closed ? l.commonClosed : l.commonOpen}',
                ),
                Wrap(
                  spacing: Space.md,
                  runSpacing: Space.xs,
                  children: [
                    for (final s in AttendanceStatus.values)
                      Text(
                        '${_attLabel(l, s)} ${c.latestCounts[s] ?? 0}',
                        style: t.bodyMedium,
                      ),
                    Text(
                      l.classNotMarked(c.latestNotMarked),
                      style: t.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Assignment completion for the most recent published assignments, plus the server's pending-grading figure.
class ClassWorkCard extends StatelessWidget {
  const ClassWorkCard({super.key, required this.c});
  final ClassOverviewController c;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    if (c.loading) {
      return AcademicSection(
        title: l.commonAssignments,
        icon: Icons.assignment_outlined,
        children: const [SkeletonBlock(rows: 2)],
      );
    }
    if (c.workError != null) {
      return AcademicSection(
        title: l.commonAssignments,
        icon: Icons.assignment_outlined,
        children: [
          ErrorPanel(
            error: c.workError!,
            onRetry: c.load,
            full: false,
            framed: false,
          ),
        ],
      );
    }
    final awaiting =
        c.courseRow?.awaitingGrading ??
        c.progress.fold<int>(0, (n, p) => n + p.awaiting);
    return AcademicSummary(
      title: l.commonAssignments,
      status: awaiting == 0
          ? StatusPill(
              l.classNothingToGrade,
              tone: Tone.success,
              icon: Icons.check_circle_outline,
            )
          : StatusPill(
              l.dashToGradeCount(awaiting),
              tone: Tone.attention,
              icon: Icons.hourglass_top,
            ),
      stats: [
        (label: l.classPublished, value: '${c.published}'),
        (label: l.classDrafts, value: '${c.drafts}'),
        (label: l.dashStatToGrade, value: '$awaiting'),
      ],
      footer: c.progress.isEmpty
          ? Text(l.classNoPublished)
          : InfoGroup(
              children: [
                Text(l.classSubmissionsReceived, style: t.labelLarge),
                for (final p in c.progress)
                  Semantics(
                    container: true,
                    label:
                        '${p.assignment.title}: ${l.dashSubmittedOf(p.received, c.activeStudents)}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.assignment.title, style: t.bodyMedium),
                        const SizedBox(height: Space.xs),
                        LinearProgressIndicator(
                          value: c.activeStudents == 0
                              ? 0
                              : (p.received / c.activeStudents).clamp(0.0, 1.0),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        Text(
                          '${l.dashSubmittedOf(p.received, c.activeStudents)}'
                          '${p.assignment.dueAt == null ? '' : ' · ${l.classDueLower(formatDateTime(p.assignment.dueAt!, f: f))}'}',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class ClassRecentWork extends StatelessWidget {
  const ClassRecentWork({super.key, required this.c});
  final ClassOverviewController c;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    if (c.loading) {
      return AcademicSection(
        title: l.dashRecentSubmissions,
        icon: Icons.assignment_turned_in_outlined,
        children: const [SkeletonBlock(rows: 2)],
      );
    }
    if (c.recent.isEmpty) {
      return AcademicSection(
        title: l.dashRecentSubmissions,
        icon: Icons.assignment_turned_in_outlined,
        children: [
          EmptyPanel(
            icon: Icons.inbox_outlined,
            title: l.classNoRecent,
            message: l.classNoRecentHint,
            framed: false,
          ),
        ],
      );
    }
    return AcademicSection(
      title: l.dashRecentSubmissions,
      icon: Icons.assignment_turned_in_outlined,
      count: '${c.recent.length}',
      children: [
        for (final r in c.recent)
          TrailingTile(
            leading: const AcademicIcon(
              Icons.assignment_turned_in_outlined,
              category: 1,
            ),
            title: Text(
              '${r.submission.studentName ?? l.roleStudent} · ${r.assignmentTitle}',
            ),
            subtitle: Text(formatDateTime(r.submission.submittedAt, f: f)),
            trailing: StatusPill(
              switch (r.submission.status) {
                SubmissionStatus.submitted => l.dashStatToGrade,
                SubmissionStatus.graded => l.metricGraded,
                SubmissionStatus.returned => l.statusReturned,
              },
              tone: submissionTone(r.submission.status),
              icon: submissionIcon(r.submission.status),
            ),
          ),
      ],
    );
  }
}

/// Private to the teacher: each student's own attendance record counts, alphabetical (no ranking).
class ClassStudentAttendance extends StatelessWidget {
  const ClassStudentAttendance({
    super.key,
    required this.c,
    this.onOpenStudent,
  });
  final ClassOverviewController c;

  /// Opens that student's private progress (teacher only; one student at a time).
  final void Function(String studentId, String? name)? onOpenStudent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = [...?c.attendance?.rows]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (c.loading) {
      return AcademicSection(
        title: l.classAttendanceByStudent,
        icon: Icons.person_search_outlined,
        children: const [SkeletonBlock(rows: 3)],
      );
    }
    if (rows.isEmpty) {
      return AcademicSection(
        title: l.classAttendanceByStudent,
        icon: Icons.person_search_outlined,
        children: [
          EmptyPanel(
            icon: Icons.groups_outlined,
            title: l.classNoStudentsEnrolled,
            message: l.classShareCode,
            framed: false,
          ),
        ],
      );
    }
    return AcademicSection(
      title: l.classAttendanceByStudent,
      icon: Icons.person_search_outlined,
      count: '${rows.length}',
      children: [
        for (final r in rows)
          TrailingTile(
            leading: const AcademicIcon(Icons.person_outline, category: 2),
            title: Text(r.name.isEmpty ? l.roleStudent : r.name),
            subtitle: Text(
              '${l.attPresent} ${r.present} · ${l.attLate} ${r.late} · ${l.attExcused} ${r.excused} · ${l.attAbsent} ${r.absent}',
            ),
            trailing: Text(
              _pct(context, r.rate),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            onTap: onOpenStudent == null
                ? null
                : () => onOpenStudent!(r.studentId, r.name),
          ),
      ],
    );
  }
}
