import 'package:flutter/material.dart';

import '../../core/states.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/academic.dart';
import '../assignments/student_assignment_pages.dart';
import '../assignments/teacher_assignment_pages.dart';
import '../attendance/attendance_pages.dart';
import '../../core/adaptive.dart';
import '../auth/profile.dart';
import 'course.dart';
import 'course_dialogs.dart';
import '../../app_services.dart';
import 'course_widgets.dart';
import 'courses_controller.dart';
import 'student_course_page.dart';
import 'teacher_course_page.dart';

enum CourseArea { overview, assignments, attendance }

/// The role-aware course list: a Teacher manages their courses, a Student joins and views theirs.
class CoursesPage extends StatefulWidget {
  const CoursesPage({
    super.key,
    required this.profile,
    required this.services,
    this.area = CourseArea.overview,
    this.onAreaChanged,
  });

  final ValueChanged<CourseArea>? onAreaChanged;
  final CourseArea area;
  final Profile profile;
  final AppServices services;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  late final CoursesController _c = CoursesController(
    widget.services.courses,
    summaries: widget.services.summaries,
  );
  CourseStatus? _status;
  late CourseArea _area = widget.area;

  @override
  void didUpdateWidget(covariant CoursesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) _area = widget.area;
  }

  bool get _teacher => widget.profile.role == AppRole.teacher;

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    _c.clearMessages();
    final result = await showDialog<Object>(
      context: context,
      builder: (_) => CourseFormDialog(controller: _c),
    );
    if (result is NewCourse && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => JoinCodeDialog(course: result),
      );
    }
  }

  Future<void> _join() async {
    _c.clearMessages();
    final joined = await showDialog<bool>(
      context: context,
      builder: (_) => JoinCourseDialog(controller: _c),
    );
    if (joined == true && mounted) {
      final text = _c.noticeText(AppLocalizations.of(context));
      if (text != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text)));
      }
    }
  }

  Future<void> _open(Course course) async {
    final l = AppLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _area != CourseArea.overview
            ? Scaffold(
                appBar: AppBar(),
                body: StudioPage(
                  children: [
                    AcademicPageHeader(
                      eyebrow: _area == CourseArea.assignments
                          ? (_teacher
                                ? l.courseAreaTeachingAssignments
                                : l.courseAreaLearningAssignments)
                          : (_teacher
                                ? l.courseAreaTeachingAttendance
                                : l.courseAreaLearningAttendance),
                      icon: _area == CourseArea.assignments
                          ? Icons.assignment_outlined
                          : Icons.fact_check_outlined,
                      title: course.title,
                    ),
                    const SizedBox(height: Space.md),
                    if (_area == CourseArea.assignments)
                      if (_teacher)
                        TeacherAssignmentsSection(
                          courseId: course.id,
                          services: widget.services,
                          archived: course.archived,
                        )
                      else
                        StudentAssignmentsSection(
                          courseId: course.id,
                          services: widget.services,
                        )
                    else if (_teacher)
                      TeacherAttendanceSection(
                        courseId: course.id,
                        services: widget.services,
                        archived: course.archived,
                      )
                    else
                      StudentAttendanceSection(
                        courseId: course.id,
                        services: widget.services,
                      ),
                  ],
                ),
              )
            : _teacher
            ? TeacherCoursePage(
                course: course,
                controller: _c,
                services: widget.services,
              )
            : StudentCoursePage(course: course, services: widget.services),
      ),
    );
    if (mounted) {
      _c.load(
        showSpinner: false,
      ); // reflect edits/removals made on the detail page
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final l = AppLocalizations.of(context);
        if (_c.state == LoadState.loading) {
          return const SkeletonPage();
        }
        if (_c.state == LoadState.error) {
          return ErrorState(error: _c.loadError!, onRetry: _c.load);
        }
        return RefreshIndicator(
          onRefresh: () => _c.load(showSpinner: false),
          child: StudioPage(
            children: [
              AcademicPageHeader(
                eyebrow: _teacher
                    ? l.courseEyebrowTeaching
                    : l.courseEyebrowLearning,
                icon: Icons.menu_book_outlined,
                title: l.courseYourCourses,
                description: _teacher
                    ? l.courseDescTeacher
                    : l.courseDescStudent,
                actions: [
                  FilledButton.icon(
                    onPressed: _teacher ? _create : _join,
                    icon: Icon(_teacher ? Icons.add : Icons.login),
                    label: Text(_teacher ? l.courseNew : l.courseJoin),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              AcademicCard(
                children: [
                  DropdownButtonFormField<CourseArea>(
                    key: ValueKey(_area),
                    initialValue: _area,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l.courseServiceLabel,
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: CourseArea.overview,
                        child: Text(l.courseAllContent),
                      ),
                      DropdownMenuItem(
                        value: CourseArea.assignments,
                        child: Text(l.commonAssignments),
                      ),
                      DropdownMenuItem(
                        value: CourseArea.attendance,
                        child: Text(l.commonAttendance),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _area = value);
                        widget.onAreaChanged?.call(value);
                      }
                    },
                  ),
                  const SizedBox(height: Space.md),
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth < 360 ||
                            MediaQuery.textScalerOf(context).scale(14) > 21
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final entry in <(CourseStatus?, String)>[
                                (null, l.commonAll),
                                (CourseStatus.active, l.commonActive),
                                (CourseStatus.archived, l.commonArchived),
                              ])
                                ChoiceChip(
                                  label: Text(entry.$2),
                                  selected: _status == entry.$1,
                                  onSelected: (_) =>
                                      setState(() => _status = entry.$1),
                                ),
                            ],
                          )
                        : SegmentedButton<CourseStatus?>(
                            segments: [
                              ButtonSegment(
                                value: null,
                                label: Text(l.commonAll),
                              ),
                              ButtonSegment(
                                value: CourseStatus.active,
                                label: Text(l.commonActive),
                              ),
                              ButtonSegment(
                                value: CourseStatus.archived,
                                label: Text(l.commonArchived),
                              ),
                            ],
                            selected: {_status},
                            onSelectionChanged: (value) =>
                                setState(() => _status = value.single),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              if (_c.courses.isNotEmpty &&
                  !_c.courses.any(
                    (course) => _status == null || course.status == _status,
                  ))
                AcademicCard(children: [Text(l.courseNoInCategory)]),
              if (_c.loadError != null)
                Text(
                  l.courseCouldNotRefresh(_c.loadError!.text(context)),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_c.courses.isEmpty)
                EmptyState(
                  icon: _teacher ? Icons.school : Icons.menu_book,
                  title: _teacher
                      ? l.courseEmptyTeacherTitle
                      : l.courseEmptyStudentTitle,
                  hint: _teacher
                      ? l.courseEmptyTeacherHint
                      : l.courseEmptyStudentHint,
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols =
                      StudioLayout.columns(context, constraints.maxWidth)
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (cols - 1) * Space.md) / cols;
                  return Wrap(
                    spacing: Space.md,
                    runSpacing: Space.sm,
                    children: [
                      for (final course in _c.courses.where(
                        (course) => _status == null || course.status == _status,
                      ))
                        SizedBox(
                          width: width,
                          child: CourseCard(
                            course: course,
                            teacherView: _teacher,
                            onTap: () => _open(course),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
