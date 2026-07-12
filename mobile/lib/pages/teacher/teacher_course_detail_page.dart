import 'package:flutter/material.dart';

import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../models/course_file.dart';
import '../../models/course_post.dart';
import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/teacher_course_service.dart';
import '../../widgets/course_section_tab.dart';

class TeacherCourseDetailPage extends StatefulWidget {
  final Course course;

  const TeacherCourseDetailPage({required this.course, super.key});

  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  final TeacherCourseService _courseService = TeacherCourseService();

  int selected = 0;

  late Future<List<CoursePost>> _postsFuture;
  late Future<List<Lesson>> _lessonsFuture;
  late Future<List<Assignment>> _assignmentsFuture;
  late Future<List<UserProfile>> _studentsFuture;
  late Future<List<CourseFile>> _filesFuture;

  final tabs = const [
    ('Overview', Icons.dashboard_outlined),
    ('Posts', Icons.campaign_outlined),
    ('Lessons', Icons.play_lesson_outlined),
    ('Assignments', Icons.assignment_outlined),
    ('Students', Icons.groups_outlined),
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
    _studentsFuture = _courseService.getStudents(courseId);
    _filesFuture = _courseService.getFiles(courseId);
  }

  Future<void> _refreshCourseData() async {
    setState(_loadCourseData);

    await Future.wait([
      _postsFuture,
      _lessonsFuture,
      _assignmentsFuture,
      _studentsFuture,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMenu,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCourseData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
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
        return _buildStudents();

      case 5:
        return _buildFiles();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverview() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _postsFuture,
        _lessonsFuture,
        _assignmentsFuture,
        _studentsFuture,
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

        final posts = snapshot.data?[0] as List<CoursePost>? ?? [];
        final lessons = snapshot.data?[1] as List<Lesson>? ?? [];
        final assignments = snapshot.data?[2] as List<Assignment>? ?? [];
        final students = snapshot.data?[3] as List<UserProfile>? ?? [];
        final files = snapshot.data?[4] as List<CourseFile>? ?? [];

        final publishedLessons = lessons
            .where((lesson) => lesson.isPublished)
            .length;

        final publishedAssignments = assignments
            .where((assignment) => assignment.isPublished)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.course.overview.trim().isNotEmpty) ...[
              const Text(
                'Course overview',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    widget.course.overview,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _Stat(
                  value: students.length.toString(),
                  label: 'Students',
                  icon: Icons.groups_rounded,
                ),
                _Stat(
                  value: assignments.length.toString(),
                  label: 'Assignments',
                  icon: Icons.assignment_rounded,
                ),
                _Stat(
                  value: '$publishedLessons/${lessons.length}',
                  label: 'Published lessons',
                  icon: Icons.play_lesson_rounded,
                ),
                _Stat(
                  value: '$publishedAssignments/${assignments.length}',
                  label: 'Published work',
                  icon: Icons.publish_rounded,
                ),
                _Stat(
                  value: posts.length.toString(),
                  label: 'Posts',
                  icon: Icons.campaign_rounded,
                ),
                _Stat(
                  value: files.length.toString(),
                  label: 'Files',
                  icon: Icons.folder_rounded,
                ),
              ],
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
          return _EmptySection(
            icon: Icons.campaign_outlined,
            title: 'No posts yet',
            description: 'Create an announcement for your students.',
            actionLabel: 'Create post',
            onAction: _showCreatePostDialog,
          );
        }

        return Column(
          children: posts.map((post) {
            final isPublished = post.publishedAt != null;

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
                          Expanded(
                            child: Text(
                              post.title.trim().isEmpty
                                  ? 'Announcement'
                                  : post.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (post.isPinned)
                            const Icon(Icons.push_pin_rounded, size: 19),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: isPublished ? 'Published' : 'Draft',
                            isPublished: isPublished,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(post.content, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 12),
                      Text(
                        _formatDateTime(post.publishedAt ?? post.createdAt),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
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
          return _EmptySection(
            icon: Icons.play_lesson_outlined,
            title: 'No lessons yet',
            description: 'Create the first lesson for this course.',
            actionLabel: 'Create lesson',
            onAction: _showCreateLessonDialog,
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
                  leading: CircleAvatar(
                    child: Text(
                      '${lesson.position > 0 ? lesson.position : index + 1}',
                    ),
                  ),
                  title: Text(
                    lesson.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    lesson.description.trim().isEmpty
                        ? lesson.isPublished
                              ? 'Published'
                              : 'Draft'
                        : lesson.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _StatusChip(
                    label: lesson.isPublished ? 'Published' : 'Draft',
                    isPublished: lesson.isPublished,
                  ),
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
          return _EmptySection(
            icon: Icons.assignment_outlined,
            title: 'No assignments yet',
            description: 'Create work and assign it to students.',
            actionLabel: 'Create assignment',
            onAction: _showCreateAssignmentDialog,
          );
        }

        return Column(
          children: assignments.map((assignment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(
                    child: Icon(Icons.assignment_rounded),
                  ),
                  title: Text(
                    assignment.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    assignment.dueAt == null
                        ? '${assignment.maxScore.toStringAsFixed(0)} points • No deadline'
                        : '${assignment.maxScore.toStringAsFixed(0)} points • Due ${_formatDateTime(assignment.dueAt!)}',
                  ),
                  trailing: _StatusChip(
                    label: assignment.isPublished ? 'Published' : 'Draft',
                    isPublished: assignment.isPublished,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStudents() {
    return FutureBuilder<List<UserProfile>>(
      future: _studentsFuture,
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

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const _EmptySection(
            icon: Icons.groups_outlined,
            title: 'No students yet',
            description: 'Share the course code so students can join.',
          );
        }

        return Column(
          children: students.map((student) {
            final displayName = student.fullName.trim().isEmpty
                ? 'Unnamed student'
                : student.fullName.trim();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading:
                      student.avatarUrl != null && student.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(student.avatarUrl!),
                        )
                      : CircleAvatar(child: Text(_getInitials(displayName))),
                  title: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Enrolled student'),
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
          return _EmptySection(
            icon: Icons.folder_outlined,
            title: 'No files yet',
            description: 'Upload course resources for students.',
            actionLabel: 'Upload file',
            onAction: _showFileUploadMessage,
          );
        }

        return Column(
          children: files.map((file) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
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
                    '${_formatFileSize(file.sizeBytes)} • ${_formatDateTime(file.createdAt)}',
                  ),
                  trailing: const Icon(Icons.more_vert_rounded),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create in course',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ListTile(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showCreatePostDialog();
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.campaign_rounded),
                  ),
                  title: const Text('Announcement'),
                  subtitle: const Text('Post to the class'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showCreateLessonDialog();
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.play_lesson_rounded),
                  ),
                  title: const Text('Lesson'),
                  subtitle: const Text('Add lesson content'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showCreateAssignmentDialog();
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.assignment_rounded),
                  ),
                  title: const Text('Assignment'),
                  subtitle: const Text('Create work and deadline'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showFileUploadMessage();
                  },
                  leading: const CircleAvatar(
                    child: Icon(Icons.upload_file_rounded),
                  ),
                  title: const Text('File'),
                  subtitle: const Text('Upload a course resource'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreatePostDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreatePostDialog(
        courseService: _courseService,
        courseId: widget.course.id,
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _postsFuture = _courseService.getPosts(widget.course.id);
      });

      _showMessage('Announcement created.');
    }
  }

  Future<void> _showCreateLessonDialog() async {
    final lessons = await _lessonsFuture;

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateLessonDialog(
        courseService: _courseService,
        courseId: widget.course.id,
        initialPosition: lessons.length + 1,
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _lessonsFuture = _courseService.getLessons(widget.course.id);
      });

      _showMessage('Lesson created.');
    }
  }

  Future<void> _showCreateAssignmentDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateAssignmentDialog(
        courseService: _courseService,
        courseId: widget.course.id,
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _assignmentsFuture = _courseService.getAssignments(widget.course.id);
      });

      _showMessage('Assignment created.');
    }
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

  void _showFileUploadMessage() {
    _showMessage('File upload will be connected with file_picker next.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getInitials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'S';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _formatDateTime(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
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
                  course.courseCode,
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

class _CreatePostDialog extends StatefulWidget {
  final TeacherCourseService courseService;
  final String courseId;

  const _CreatePostDialog({
    required this.courseService,
    required this.courseId,
  });

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _publishNow = true;
  bool _isSaving = false;
  String? _error;

  Future<void> _save() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      setState(() {
        _error = 'Please enter announcement content.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.courseService.createPost(
        courseId: widget.courseId,
        title: _titleController.text,
        content: content,
        publishNow: _publishNow,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _isSaving = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create announcement'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _contentController,
                enabled: !_isSaving,
                minLines: 4,
                maxLines: 7,
                decoration: InputDecoration(
                  labelText: 'Announcement',
                  alignLabelWithHint: true,
                  errorText: _error,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish now'),
                value: _publishNow,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _publishNow = value;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _CreateLessonDialog extends StatefulWidget {
  final TeacherCourseService courseService;
  final String courseId;
  final int initialPosition;

  const _CreateLessonDialog({
    required this.courseService,
    required this.courseId,
    required this.initialPosition,
  });

  @override
  State<_CreateLessonDialog> createState() => _CreateLessonDialogState();
}

class _CreateLessonDialogState extends State<_CreateLessonDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  bool _publishNow = true;
  bool _isSaving = false;
  String? _error;

  Future<void> _save() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _error = 'Please enter a lesson title.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.courseService.createLesson(
        courseId: widget.courseId,
        title: title,
        description: _descriptionController.text,
        content: _contentController.text,
        position: widget.initialPosition,
        publishNow: _publishNow,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _isSaving = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create lesson'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'Lesson title',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _contentController,
                enabled: !_isSaving,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Lesson content',
                  alignLabelWithHint: true,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish now'),
                value: _publishNow,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _publishNow = value;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _CreateAssignmentDialog extends StatefulWidget {
  final TeacherCourseService courseService;
  final String courseId;

  const _CreateAssignmentDialog({
    required this.courseService,
    required this.courseId,
  });

  @override
  State<_CreateAssignmentDialog> createState() =>
      _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');

  DateTime? _dueAt;
  bool _allowLate = false;
  bool _publishNow = true;
  bool _isSaving = false;
  String? _error;

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );

    if (time == null) return;

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final score = double.tryParse(_scoreController.text.trim());

    if (title.isEmpty) {
      setState(() {
        _error = 'Please enter an assignment title.';
      });
      return;
    }

    if (score == null || score < 0) {
      setState(() {
        _error = 'Please enter a valid maximum score.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.courseService.createAssignment(
        courseId: widget.courseId,
        title: title,
        instructions: _instructionsController.text,
        dueAt: _dueAt,
        maxScore: score,
        allowLate: _allowLate,
        publishNow: _publishNow,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _isSaving = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create assignment'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'Assignment title',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _instructionsController,
                enabled: !_isSaving,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _scoreController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Maximum score'),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Due date'),
                subtitle: Text(
                  _dueAt == null
                      ? 'No deadline'
                      : _TeacherCourseDetailPageState._formatDateTime(_dueAt!),
                ),
                trailing: TextButton(
                  onPressed: _isSaving ? null : _pickDueDate,
                  child: Text(_dueAt == null ? 'Select' : 'Change'),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow late submission'),
                value: _allowLate,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _allowLate = value;
                        });
                      },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish now'),
                value: _publishNow,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _publishNow = value;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isPublished;

  const _StatusChip({required this.label, required this.isPublished});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isPublished
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPublished
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptySection({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
