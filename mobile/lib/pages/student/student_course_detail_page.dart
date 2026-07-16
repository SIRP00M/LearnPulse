import 'package:flutter/material.dart';

import '../../models/course.dart';
import 'student_attendance_tab.dart';

class StudentCourseDetailPage extends StatelessWidget {
  final Course course;

  const StudentCourseDetailPage({
    required this.course,
    super.key,
  });

  static const List<_CourseTabData> _tabs = [
    _CourseTabData(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
    ),
    _CourseTabData(
      label: 'Posts',
      icon: Icons.campaign_outlined,
    ),
    _CourseTabData(
      label: 'Lessons',
      icon: Icons.play_lesson_outlined,
    ),
    _CourseTabData(
      label: 'Assignments',
      icon: Icons.assignment_outlined,
    ),
    _CourseTabData(
      label: 'Attendance',
      icon: Icons.fact_check_outlined,
    ),
    _CourseTabData(
      label: 'Grades',
      icon: Icons.grade_outlined,
    ),
    _CourseTabData(
      label: 'Files',
      icon: Icons.folder_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            course.courseCode.isEmpty
                ? course.title
                : course.courseCode,
          ),
        ),
        body: Column(
          children: [
            _StudentCourseHeader(
              course: course,
            ),
            Material(
              color:
                  Theme.of(context).colorScheme.surface,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final tab in _tabs)
                    Tab(
                      icon: Icon(tab.icon),
                      text: tab.label,
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _StudentOverviewTab(
                    course: course,
                  ),
                  const _CourseEmptyTab(
                    icon: Icons.campaign_outlined,
                    title: 'No posts yet',
                    message:
                        'Announcements from your teacher will appear here.',
                  ),
                  const _CourseEmptyTab(
                    icon:
                        Icons.play_lesson_outlined,
                    title: 'No lessons yet',
                    message:
                        'Lessons published by your teacher will appear here.',
                  ),
                  const _StudentAssignmentsTab(),
                 StudentAttendanceTab(
  courseId: course.id,
  courseTitle: course.title,
),
                  const _StudentGradesTab(),
                  const _CourseEmptyTab(
                    icon: Icons.folder_outlined,
                    title: 'No files yet',
                    message:
                        'Files shared by your teacher will appear here.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCourseHeader extends StatelessWidget {
  final Course course;

  const _StudentCourseHeader({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final teacherName =
        course.teacherName.trim().isEmpty
            ? 'Unknown teacher'
            : course.teacherName.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        14,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: colorScheme.onPrimary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        color: colorScheme
                            .onPrimaryContainer,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course.courseCode,
                      style: TextStyle(
                        color: colorScheme
                            .onPrimaryContainer
                            .withValues(
                          alpha: 0.75,
                        ),
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (course.description
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              course.description,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme
                    .onPrimaryContainer,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: colorScheme
                    .onPrimaryContainer,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  teacherName,
                  style: TextStyle(
                    color: colorScheme
                        .onPrimaryContainer,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentOverviewTab
    extends StatelessWidget {
  final Course course;

  const _StudentOverviewTab({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final overview =
        course.overview.trim().isNotEmpty
            ? course.overview.trim()
            : course.description.trim();

    final teacherName =
        course.teacherName.trim().isEmpty
            ? 'Unknown teacher'
            : course.teacherName.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        32,
      ),
      children: [
        _SectionCard(
          title: 'About this course',
          icon: Icons.description_outlined,
          child: Text(
            overview.isEmpty
                ? 'The teacher has not added a course overview yet.'
                : overview,
            style: const TextStyle(
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Teacher',
          icon: Icons.person_outline_rounded,
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  _initials(teacherName),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: const [
            _StudentStatCard(
              value: '0',
              label: 'Completed',
              icon: Icons.task_alt_rounded,
            ),
            _StudentStatCard(
              value: '0',
              label: 'Pending',
              icon:
                  Icons.pending_actions_rounded,
            ),
            _StudentStatCard(
              value: '0',
              label: 'Late',
              icon:
                  Icons.warning_amber_rounded,
            ),
            _StudentStatCard(
              value: '—',
              label: 'Average score',
              icon: Icons.grade_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Learning progress',
          icon: Icons.insights_outlined,
          child: Text(
            'Your lesson progress, assignment completion '
            'and grades will appear here.',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (part) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

class _StudentAssignmentsTab
    extends StatelessWidget {
  const _StudentAssignmentsTab();

  @override
  Widget build(BuildContext context) {
    return const _CourseEmptyTab(
      icon: Icons.assignment_outlined,
      title: 'No assignments yet',
      message:
          'Assignments from your teacher will appear here. '
          'You will be able to submit text and files.',
    );
  }
}

class _StudentGradesTab
    extends StatelessWidget {
  const _StudentGradesTab();

  @override
  Widget build(BuildContext context) {
    return const _CourseEmptyTab(
      icon: Icons.grade_outlined,
      title: 'No grades yet',
      message:
          'Your scores and teacher feedback will appear here '
          'after your work is graded.',
    );
  }
}

class _StudentStatCard
    extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StudentStatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: colorScheme
                    .onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _CourseEmptyTab
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CourseEmptyTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        28,
        76,
        28,
        32,
      ),
      children: [
        Icon(
          icon,
          size: 65,
          color: colorScheme.primary
              .withValues(alpha: 0.65),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _CourseTabData {
  final String label;
  final IconData icon;

  const _CourseTabData({
    required this.label,
    required this.icon,
  });
}