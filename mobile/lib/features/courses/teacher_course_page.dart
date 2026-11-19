import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatting.dart';
import '../../core/states.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/academic.dart';
import '../../core/adaptive.dart';
import 'course.dart';
import 'course_dialogs.dart';
import '../../app_services.dart';
import '../profile/avatar_widgets.dart';
import '../assignments/teacher_assignment_pages.dart';
import '../attendance/attendance_controllers.dart';
import '../attendance/attendance_grid_page.dart';
import '../activities/teacher_activity_pages.dart';
import '../attendance/attendance_pages.dart';
import '../progress/progress_pages.dart';
import '../lessons/lessons_pages.dart';
import 'class_overview.dart';
import 'course_widgets.dart';
import 'courses_controller.dart';

/// Teacher view of one course: join code, edit/archive and the authorized roster.
class TeacherCoursePage extends StatefulWidget {
  const TeacherCoursePage({
    super.key,
    required this.course,
    required this.controller,
    required this.services,
    this.today,
  });

  /// Pins the weekly table's "this week" (fixtures); defaults to the device clock.
  final DateTime? today;
  final Course course;
  final CoursesController
  controller; // shared list controller (edit/archive refresh the list)
  final AppServices services;

  @override
  State<TeacherCoursePage> createState() => _TeacherCoursePageState();
}

class _TeacherCoursePageState extends State<TeacherCoursePage> {
  late final CourseDetailController _d = CourseDetailController(
    widget.services.courses,
    widget.course.id,
    summaries: widget.services.summaries,
  );

  Course get _course => widget.controller.courses.firstWhere(
    (c) => c.id == widget.course.id,
    orElse: () => widget.course,
  );

  late final ClassOverviewController _o = ClassOverviewController(
    widget.services,
    widget.course.id,
  );
  late final WeekGridController _week = WeekGridController(
    widget.services.attendance,
    widget.course.id,
    today: widget.today,
  );
  final _attendanceKey = GlobalKey();
  final _workKey = GlobalKey();
  final _rosterKey = GlobalKey();
  final _lessonsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _d.load();
    _o.load();
    _week.load();
  }

  @override
  void dispose() {
    _d.dispose();
    _o.dispose();
    _week.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      Future.wait([_d.load(), _o.load(), _week.load(showSpinner: false)]);

  void _goTo(GlobalKey key) {
    final c = key.currentContext;
    if (c != null) {
      Scrollable.ensureVisible(
        c,
        duration: const Duration(milliseconds: 250),
        alignment: .05,
      );
    }
  }

  Future<void> _edit() async {
    widget.controller.clearMessages();
    await showDialog<Object>(
      context: context,
      builder: (_) =>
          CourseFormDialog(controller: widget.controller, existing: _course),
    );
  }

  Future<void> _toggleArchive() async {
    final archive = !_course.archived;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(archive ? l.courseArchiveTitle : l.courseReopenTitle),
          content: Text(archive ? l.courseArchiveBody : l.courseReopenBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                archive ? l.courseArchiveAction : l.courseReopenAction,
              ),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await widget.controller.update(
        widget.course.id,
        status: archive ? CourseStatus.archived : CourseStatus.active,
      );
    }
  }

  void _openProgress(String studentId, String? name) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProgressPage(
            services: widget.services,
            courseId: widget.course.id,
            teacherView: true,
            studentId: studentId,
            studentName: name,
          ),
        ),
      );

  Future<void> _remove(RosterEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l.courseRemoveTitle),
          content: Text(l.courseRemoveBody(entry.name ?? l.courseThisStudent)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.commonRemove),
            ),
          ],
        );
      },
    );
    if (ok == true) await _d.remove(entry.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_d, widget.controller]),
      builder: (context, _) {
        final course = _course;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: AppLocalizations.of(context).courseEdit,
                icon: const Icon(Icons.edit),
                onPressed: widget.controller.busy ? null : _edit,
              ),
            ],
          ),
          body: _body(context, course, scheme),
        );
      },
    );
  }

  Widget _body(BuildContext context, Course course, ColorScheme scheme) {
    if (_d.state == LoadState.loading) {
      return const SkeletonPage();
    }
    if (_d.state == LoadState.error) {
      return ErrorState(error: _d.error!, onRetry: _d.load);
    }
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final active = _d.roster.where((r) => r.active).toList();
    final removed = _d.roster.length - active.length;
    // One column on phones: class status goes straight under the quick actions; beside the table when wide.
    final wide = StudioLayout.columns(
      context,
      MediaQuery.sizeOf(context).width,
    );
    final statusCards = ListenableBuilder(
      listenable: _o,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClassAttendanceCard(c: _o),
          const SizedBox(height: Space.md),
          ClassWorkCard(c: _o),
          const SizedBox(height: Space.md),
          ClassStudentAttendance(c: _o, onOpenStudent: _openProgress),
        ],
      ),
    );
    return RefreshIndicator(
      onRefresh: _refresh,
      child: StudioPage(
        children: [
          ListenableBuilder(
            listenable: _o,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClassHeader(
                  title: course.title,
                  description: course.description,
                  archived: course.archived,
                  students: active.length,
                  openSessions: _o.openSessions,
                  toGrade: _o.courseRow?.awaitingGrading,
                ),
                if (widget.controller.actionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: Text(
                      widget.controller.actionError!.text(context),
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                if (active.isEmpty) ...[
                  const SizedBox(height: Space.md),
                  AcademicCard(
                    key: const Key('empty-class'),
                    tint: scheme.primaryContainer,
                    children: [
                      Text(
                        l.courseInviteTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(l.courseInviteBody),
                    ],
                  ),
                ],
                const SizedBox(height: Space.md),
                AcademicServices(
                  services: [
                    (
                      label: l.commonAttendance,
                      detail: l.dashDetailOpen(_o.openSessions),
                      icon: Icons.fact_check_outlined,
                      onTap: () => _goTo(_attendanceKey),
                    ),
                    (
                      label: l.courseSvcSubmissions,
                      detail: _o.courseRow == null
                          ? l.courseSvcReviewWork
                          : l.dashToGradeCount(_o.courseRow!.awaitingGrading),
                      icon: Icons.rate_review_outlined,
                      onTap: () => _goTo(_workKey),
                    ),
                    (
                      label: l.courseSvcRoster,
                      detail: l.dashCountStudents(active.length),
                      icon: Icons.groups_outlined,
                      onTap: () => _goTo(_rosterKey),
                    ),
                    (
                      label: l.commonLessons,
                      detail: l.courseSvcContent,
                      icon: Icons.menu_book_outlined,
                      onTap: () => _goTo(_lessonsKey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!wide) ...[const SizedBox(height: Space.md), statusCards],
          const SizedBox(height: Space.md),
          StudioColumns(
            primary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AcademicSection(
                  key: const Key('class-week-grid'),
                  title: l.courseWeeklyAttendance,
                  icon: Icons.calendar_view_week_outlined,
                  padded: true,
                  children: [
                    WeekGridPanel(
                      controller: _week,
                      teacher: true,
                      framed: false,
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                ListenableBuilder(
                  listenable: _o,
                  builder: (context, _) => ClassRecentWork(c: _o),
                ),
                const SizedBox(height: Space.lg),
                KeyedSubtree(
                  key: _lessonsKey,
                  child: TeacherLessonsSection(
                    courseId: course.id,
                    services: widget.services,
                    archived: course.archived,
                  ),
                ),
                const SizedBox(height: Space.lg),
                KeyedSubtree(
                  key: _workKey,
                  child: TeacherAssignmentsSection(
                    courseId: course.id,
                    services: widget.services,
                    archived: course.archived,
                  ),
                ),
              ],
            ),
            secondary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) ...[statusCards, const SizedBox(height: Space.lg)],
                KeyedSubtree(
                  key: _attendanceKey,
                  child: TeacherAttendanceSection(
                    courseId: course.id,
                    services: widget.services,
                    archived: course.archived,
                  ),
                ),
                TeacherActivitiesSection(
                  courseId: course.id,
                  services: widget.services,
                  archived: course.archived,
                ),
                AcademicSection(
                  title: l.courseAdmin,
                  icon: Icons.admin_panel_settings_outlined,
                  padded: true,
                  children: [
                    Text(
                      l.courseJoinCode,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: Space.xs),
                    Container(
                      margin: const EdgeInsets.only(top: Space.xs),
                      padding: const EdgeInsets.only(left: Space.md),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _d.joinCode ?? '',
                              key: const Key('join-code'),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(letterSpacing: 3),
                            ),
                          ),
                          IconButton(
                            tooltip: l.courseCopyCode,
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _d.joinCode ?? ''),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.courseCodeCopied)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (course.archived)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: Text(l.courseArchivedNoJoin),
                      ),
                    const SizedBox(height: Space.md),
                    OutlinedButton.icon(
                      icon: Icon(
                        course.archived ? Icons.unarchive : Icons.archive,
                      ),
                      label: Text(
                        course.archived
                            ? l.courseReopenCourse
                            : l.courseArchiveCourse,
                      ),
                      onPressed: widget.controller.busy ? null : _toggleArchive,
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                AcademicSection(
                  key: _rosterKey,
                  title: l.courseStudentsTitle(active.length),
                  icon: Icons.groups_outlined,
                  children: [
                    if (_d.actionError != null)
                      Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Text(
                          _d.actionError!.text(context),
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    if (active.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Text(l.courseNoStudents),
                      ),
                    for (final r in active)
                      ListTile(
                        leading: AvatarCircle(
                          repository: widget.services.avatars,
                          userId: r.studentId,
                          name: r.name ?? '',
                          lookup: true,
                        ),
                        title: Text(r.name ?? l.roleStudent),
                        subtitle: Text(
                          l.courseJoinedTap(formatDate(r.joinedAt, f: f)),
                        ),
                        onTap: () => _openProgress(r.studentId, r.name),
                        trailing: IconButton(
                          tooltip: l.commonRemoveNamed(r.name ?? l.roleStudent),
                          icon: const Icon(Icons.person_remove),
                          onPressed: _d.busy ? null : () => _remove(r),
                        ),
                      ),
                    if (removed > 0)
                      Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Text(
                          l.courseRemovedCount(removed),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}
