import 'package:flutter/material.dart';

import '../../services/course_service.dart';

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});

  @override
  State<TeacherStudentsPage> createState() {
    return _TeacherStudentsPageState();
  }
}

class _TeacherStudentsPageState
    extends State<TeacherStudentsPage> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController =
      TextEditingController();

  final Set<String> _expandedCourseIds = <String>{};

  late Future<List<TeacherCourseStudents>> _coursesFuture;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _coursesFuture =
        _courseService.fetchTeacherCourseStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  void _reload() {
    setState(() {
      _coursesFuture =
          _courseService.fetchTeacherCourseStudents();
    });
  }

  Future<void> _refresh() async {
    final future =
        _courseService.fetchTeacherCourseStudents();

    setState(() {
      _coursesFuture = future;
    });

    await future;
  }

  void _toggleCourse(String courseId) {
    setState(() {
      if (_expandedCourseIds.contains(courseId)) {
        _expandedCourseIds.remove(courseId);
      } else {
        _expandedCourseIds.add(courseId);
      }
    });
  }

  List<TeacherCourseStudents> _filterCourses(
    List<TeacherCourseStudents> courses,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return courses;
    }

    return courses.where((course) {
      final matchesCourse =
          course.courseTitle.toLowerCase().contains(query) ||
          course.courseCode.toLowerCase().contains(query);

      final matchesStudent = course.students.any(
        (student) =>
            student.fullName.toLowerCase().contains(query),
      );

      return matchesCourse || matchesStudent;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Students',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'View students enrolled in each course',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search courses or students',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  FutureBuilder<List<TeacherCourseStudents>>(
                future: _coursesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _StudentsPageMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load students',
                      message: snapshot.error.toString(),
                      buttonLabel: 'Try again',
                      buttonIcon: Icons.refresh_rounded,
                      onPressed: _reload,
                    );
                  }

                  final allCourses = snapshot.data ??
                      const <TeacherCourseStudents>[];

                  final courses = _filterCourses(allCourses);

                  if (courses.isEmpty) {
                    return _StudentsPageMessage(
                      icon: _searchQuery.isEmpty
                          ? Icons.groups_outlined
                          : Icons.search_off_rounded,
                      title: _searchQuery.isEmpty
                          ? 'No courses available'
                          : 'No matching results',
                      message: _searchQuery.isEmpty
                          ? 'Create a course first, then students can join using its code.'
                          : 'Try searching with another course or student name.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.only(bottom: 24),
                      itemCount: courses.length,
                      separatorBuilder: (_, _) {
                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (context, index) {
                        final course = courses[index];

                        return _CourseStudentsCard(
                          course: course,
                          expanded: _expandedCourseIds
                              .contains(course.courseId),
                          onToggle: () {
                            _toggleCourse(course.courseId);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseStudentsCard extends StatelessWidget {
  final TeacherCourseStudents course;
  final bool expanded;
  final VoidCallback onToggle;

  const _CourseStudentsCard({
    required this.course,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final students = course.students;

    final visibleStudents = expanded
        ? students
        : students.take(3).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.courseCode} • '
                          '${students.length} '
                          '${students.length == 1 ? 'student' : 'students'}',
                          style: TextStyle(
                            color:
                                colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration:
                        const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 22,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_alt_1_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'No students have joined this course.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  for (var index = 0;
                      index < visibleStudents.length;
                      index++) ...[
                    _StudentRow(
                      student: visibleStudents[index],
                    ),
                    if (index != visibleStudents.length - 1)
                      Divider(
                        height: 1,
                        indent: 72,
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.7),
                      ),
                  ],
                  if (students.length > 3)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        4,
                        12,
                        8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onToggle,
                          icon: Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(
                            expanded
                                ? 'Show less'
                                : 'Show all ${students.length} students',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final CourseStudentSummary student;

  const _StudentRow({
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 3,
      ),
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        child: Text(
          _initials(student.fullName),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        student.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        _joinedText(student.joinedAt),
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final normalized = fullName.trim();

    if (normalized.isEmpty) {
      return '?';
    }

    final parts = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);

    return '$first$last'.toUpperCase();
  }

  String _joinedText(DateTime? joinedAt) {
    if (joinedAt == null) {
      return 'Joined date unavailable';
    }

    final localDate = joinedAt.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month =
        localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return 'Joined $day/$month/$year';
  }
}

class _StudentsPageMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final IconData buttonIcon;
  final VoidCallback? onPressed;

  const _StudentsPageMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.buttonIcon = Icons.refresh_rounded,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Icon(
          icon,
          size: 64,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        if (buttonLabel != null &&
            onPressed != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonLabel!),
            ),
          ),
        ],
      ],
    );
  }
}