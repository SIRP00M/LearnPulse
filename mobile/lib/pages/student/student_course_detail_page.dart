import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../models/course_file.dart';
import '../../models/course_post.dart';
import '../../models/lesson.dart';
import '../../services/student_course_service.dart';
import '../../widgets/course_section_tab.dart';
import 'student_assignment_detail_page.dart';

class StudentCourseDetailPage extends StatefulWidget {
  final Course course;

  const StudentCourseDetailPage({required this.course, super.key});

  @override
  State<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState extends State<StudentCourseDetailPage> {
  final StudentCourseService _courseService = StudentCourseService();

  int selected = 0;

  late Future<List<CoursePost>> _postsFuture;
  late Future<List<Lesson>> _lessonsFuture;
  late Future<List<Assignment>> _assignmentsFuture;
  late Future<List<CourseFile>> _filesFuture;

  final tabs = const [
    ('Overview', Icons.dashboard_outlined),
    ('Posts', Icons.campaign_outlined),
    ('Lessons', Icons.play_lesson_outlined),
    ('Assignments', Icons.assignment_outlined),
    ('Files', Icons.folder_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  void _loadCourseData() {
    final courseId = widget.course.id;

    _postsFuture = _courseService.getPosts(courseId);
    _lessonsFuture = _courseService.getLessons(courseId);
    _assignmentsFuture = _courseService.getAssignments(courseId);
    _filesFuture = _courseService.getFiles(courseId);
  }

  Future<void> _refreshCourseData() async {
    setState(_loadCourseData);

    await Future.wait([
      _postsFuture,
      _lessonsFuture,
      _assignmentsFuture,
      _filesFuture,
    ]);
  }

  void _retry() {
    setState(_loadCourseData);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.courseCode.isEmpty ? course.title : course.courseCode,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCourseData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _CourseHeader(course: course),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  return CourseSectionTab(
                    icon: tabs[index].$2,
                    label: tabs[index].$1,
                    selected: selected == index,
                    onTap: () {
                      setState(() {
                        selected = index;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (selected) {
      case 0:
        return _buildOverview();

      case 1:
        return _buildPosts();

      case 2:
        return _buildLessons();

      case 3:
        return _buildAssignments();

      case 4:
        return _buildFiles();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverview() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _lessonsFuture,
        _assignmentsFuture,
        _filesFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        if (snapshot.hasError) {
          return _SectionError(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final lessons = snapshot.data?[0] as List<Lesson>? ?? [];
        final assignments = snapshot.data?[1] as List<Assignment>? ?? [];
        final files = snapshot.data?[2] as List<CourseFile>? ?? [];

        final nextAssignment = _findNextAssignment(assignments);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course overview',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (widget.course.overview.trim().isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    widget.course.overview,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.play_lesson_outlined),
                    title: const Text('Lessons'),
                    trailing: Text(lessons.length.toString()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: const Text('Assignments'),
                    trailing: Text(assignments.length.toString()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Next deadline'),
                    trailing: SizedBox(
                      width: 150,
                      child: Text(
                        nextAssignment == null
                            ? 'No deadline'
                            : _formatDate(nextAssignment.dueAt),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('Files'),
                    trailing: Text(files.length.toString()),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPosts() {
    return FutureBuilder<List<CoursePost>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        if (snapshot.hasError) {
          return _SectionError(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const _EmptySection(
            icon: Icons.campaign_outlined,
            title: 'No posts yet',
            description: 'Announcements from your teacher will appear here.',
          );
        }

        return Column(
          children: posts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text(_getTeacherInitial())),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.course.teacherName.trim().isEmpty
                                      ? 'Teacher'
                                      : widget.course.teacherName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(
                                    post.publishedAt ?? post.createdAt,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (post.isPinned)
                            const Icon(Icons.push_pin_rounded, size: 19),
                        ],
                      ),
                      if (post.title.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(post.content, style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLessons() {
    return FutureBuilder<List<Lesson>>(
      future: _lessonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        if (snapshot.hasError) {
          return _SectionError(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final lessons = snapshot.data ?? [];

        if (lessons.isEmpty) {
          return const _EmptySection(
            icon: Icons.play_lesson_outlined,
            title: 'No lessons yet',
            description: 'Published lessons will appear here.',
          );
        }

        return Column(
          children: List.generate(lessons.length, (index) {
            final lesson = lessons[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () => _showLesson(lesson),
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    lesson.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    lesson.description.trim().isEmpty
                        ? 'Lesson ${index + 1}'
                        : lesson.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAssignments() {
    return FutureBuilder<List<Assignment>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        if (snapshot.hasError) {
          return _SectionError(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final assignments = snapshot.data ?? [];

        if (assignments.isEmpty) {
          return const _EmptySection(
            icon: Icons.assignment_outlined,
            title: 'No assignments yet',
            description: 'Published assignments will appear here.',
          );
        }

        return Column(
          children: assignments.map((assignment) {
            final isOverdue =
                assignment.dueAt != null &&
                assignment.dueAt!.isBefore(DateTime.now());

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentAssignmentDetailPage(
                          course: widget.course,
                          title: assignment.title,
                        ),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.all(14),
                  leading: Icon(
                    Icons.assignment_rounded,
                    color: isOverdue
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    assignment.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    assignment.dueAt == null
                        ? 'No deadline • ${assignment.maxScore.toStringAsFixed(0)} points'
                        : '${isOverdue ? 'Past due' : 'Due'} ${_formatDateTime(assignment.dueAt!)} • ${assignment.maxScore.toStringAsFixed(0)} points',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFiles() {
    return FutureBuilder<List<CourseFile>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoading();
        }

        if (snapshot.hasError) {
          return _SectionError(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final files = snapshot.data ?? [];

        if (files.isEmpty) {
          return const _EmptySection(
            icon: Icons.folder_outlined,
            title: 'No files yet',
            description: 'Course resources will appear here.',
          );
        }

        return Column(
          children: files.map((file) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () => _openFile(file),
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    child: Icon(_getFileIcon(file.fileName)),
                  ),
                  title: Text(
                    file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${_formatFileSize(file.sizeBytes)} • ${_formatDate(file.createdAt)}',
                  ),
                  trailing: const Icon(Icons.download_rounded),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showLesson(Lesson lesson) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (lesson.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lesson.description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  lesson.content.trim().isEmpty
                      ? 'No lesson content.'
                      : lesson.content,
                  style: const TextStyle(height: 1.6),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openFile(CourseFile file) async {
    try {
      final url = await _courseService.createFileDownloadUrl(file.storagePath);

      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw StateError('Unable to open file.');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open file: $error')));
    }
  }

  Assignment? _findNextAssignment(List<Assignment> assignments) {
    final upcoming =
        assignments
            .where(
              (assignment) =>
                  assignment.dueAt != null &&
                  assignment.dueAt!.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _getTeacherInitial() {
    final name = widget.course.teacherName.trim();

    if (name.isEmpty) {
      return 'T';
    }

    return name[0].toUpperCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No deadline';
    }

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();

    return '${_formatDate(local)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) {
      return 'Unknown size';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String fileName) {
    final parts = fileName.split('.');
    final extension = parts.length > 1 ? parts.last.toLowerCase() : '';

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class _CourseHeader extends StatelessWidget {
  final Course course;

  const _CourseHeader({required this.course});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
      ),
      child: Stack(
        children: [
          if (course.coverUrl != null && course.coverUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                course.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          if (course.coverUrl != null && course.coverUrl!.isNotEmpty)
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 16),
                Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${course.teacherName} • ${course.courseCode}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (course.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    course.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Unable to load course content',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptySection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(icon, size: 58, color: Colors.black38),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
