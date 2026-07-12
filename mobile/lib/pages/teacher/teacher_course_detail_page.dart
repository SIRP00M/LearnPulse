import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/course.dart';

class TeacherCourseDetailPage extends StatelessWidget {
  final Course course;
  final int studentCount;

  const TeacherCourseDetailPage({
    required this.course,
    this.studentCount = 0,
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
      label: 'Students',
      icon: Icons.groups_outlined,
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
          title: Text(course.courseCode),
          actions: [
            IconButton(
              tooltip: 'Copy course code',
              onPressed: () {
                _copyCourseCode(context);
              },
              icon: const Icon(Icons.copy_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: 'Course options',
              onSelected: (value) {
                _handleCourseOption(context, value);
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit course'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.archive_outlined),
                      title: Text('Archive course'),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showCreateMenu(context);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
        ),
        body: Column(
          children: [
            _TeacherCourseHeader(
              course: course,
              studentCount: studentCount,
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
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
                  _TeacherOverviewTab(
                    course: course,
                    studentCount: studentCount,
                  ),
                  const _CourseEmptyTab(
                    icon: Icons.campaign_outlined,
                    title: 'No posts yet',
                    message:
                        'Announcements and course updates will appear here.',
                  ),
                  const _CourseEmptyTab(
                    icon: Icons.play_lesson_outlined,
                    title: 'No lessons yet',
                    message:
                        'Create the first lesson for this course.',
                  ),
                  const _CourseEmptyTab(
                    icon: Icons.assignment_outlined,
                    title: 'No assignments yet',
                    message:
                        'Assignments created for this course will appear here.',
                  ),
                  _TeacherStudentsTab(
                    studentCount: studentCount,
                  ),
                  const _CourseEmptyTab(
                    icon: Icons.folder_outlined,
                    title: 'No files yet',
                    message:
                        'Course materials and uploaded files will appear here.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyCourseCode(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: course.courseCode),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Course code copied'),
        ),
      );
  }

  void _handleCourseOption(
    BuildContext context,
    String value,
  ) {
    final message = switch (value) {
      'edit' => 'Course editing will be added next.',
      'archive' => 'Course archiving will be added later.',
      _ => 'This option is not available yet.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _showCreateMenu(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Create course content',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.campaign_outlined,
                  ),
                  title: const Text('Announcement'),
                  subtitle: const Text(
                    'Post an update for students',
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'announcement',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.play_lesson_outlined,
                  ),
                  title: const Text('Lesson'),
                  subtitle: const Text(
                    'Add learning content',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'lesson');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.assignment_outlined,
                  ),
                  title: const Text('Assignment'),
                  subtitle: const Text(
                    'Create work for students',
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'assignment',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.upload_file_outlined,
                  ),
                  title: const Text('File'),
                  subtitle: const Text(
                    'Upload course material',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'file');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !context.mounted) {
      return;
    }

    final label = switch (selected) {
      'announcement' => 'Announcement',
      'lesson' => 'Lesson',
      'assignment' => 'Assignment',
      'file' => 'File',
      _ => 'Content',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$label creation will be connected next.',
          ),
        ),
      );
  }
}

class _TeacherCourseHeader extends StatelessWidget {
  final Course course;
  final int studentCount;

  const _TeacherCourseHeader({
    required this.course,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colorScheme.onPrimary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course.courseCode,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: course.status),
            ],
          ),
          if (course.description.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              course.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 19,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 7),
              Text(
                '$studentCount '
                '${studentCount == 1 ? 'student' : 'students'}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherOverviewTab extends StatelessWidget {
  final Course course;
  final int studentCount;

  const _TeacherOverviewTab({
    required this.course,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    final overview = course.overview.trim().isNotEmpty
        ? course.overview.trim()
        : course.description.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      children: [
        _SectionCard(
          title: 'Course overview',
          icon: Icons.description_outlined,
          child: Text(
            overview.isEmpty
                ? 'No course overview has been added yet.'
                : overview,
            style: const TextStyle(height: 1.55),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _CourseStatCard(
              value: '$studentCount',
              label: 'Students',
              icon: Icons.groups_rounded,
            ),
            _CourseStatCard(
              value: course.status.toUpperCase(),
              label: 'Status',
              icon: Icons.publish_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Course code',
          icon: Icons.key_rounded,
          child: SelectableText(
            course.courseCode,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherStudentsTab extends StatelessWidget {
  final int studentCount;

  const _TeacherStudentsTab({
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    return _CourseEmptyTab(
      icon: Icons.groups_outlined,
      title: studentCount == 0
          ? 'No students yet'
          : '$studentCount students enrolled',
      message: studentCount == 0
          ? 'Share the course code so students can join.'
          : 'The complete student list is available from the Students page.',
    );
  }
}

class _CourseStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _CourseStatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _CourseEmptyTab extends StatelessWidget {
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
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 100),
      children: [
        Icon(
          icon,
          size: 65,
          color: colorScheme.primary.withValues(alpha: 0.65),
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
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final label = switch (status) {
      'published' => 'Published',
      'archived' => 'Archived',
      _ => 'Draft',
    };

    final backgroundColor = switch (status) {
      'published' => colorScheme.primary,
      'archived' => colorScheme.surfaceContainerHighest,
      _ => colorScheme.secondaryContainer,
    };

    final foregroundColor = switch (status) {
      'published' => colorScheme.onPrimary,
      'archived' => colorScheme.onSurfaceVariant,
      _ => colorScheme.onSecondaryContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
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