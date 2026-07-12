import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/course_service.dart';
import '../../widgets/course_card.dart';

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<TeacherCourseSummary>> _coursesFuture;

  String _searchQuery = '';
  bool _isCreatingCourse = false;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _courseService.fetchTeacherCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadCourses() {
    setState(() {
      _coursesFuture = _courseService.fetchTeacherCourses();
    });
  }

  Future<void> _refreshCourses() async {
    final future = _courseService.fetchTeacherCourses();

    setState(() {
      _coursesFuture = future;
    });

    await future;
  }

  List<TeacherCourseSummary> _filterCourses(
    List<TeacherCourseSummary> courses,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return courses;
    }

    return courses.where((item) {
      final course = item.course;

      return course.title.toLowerCase().contains(query) ||
          course.courseCode.toLowerCase().contains(query) ||
          course.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showCreateCourseDialog() async {
    final result = await showDialog<_CreateCourseData>(
      context: context,
      builder: (dialogContext) {
        return const _CreateCourseDialog();
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _isCreatingCourse = true;
    });

    try {
      final createdCourse = await _courseService.createCourse(
        title: result.title,
        description: result.description,
      );

      if (!mounted) {
        return;
      }

      _reloadCourses();

      await _showCreatedCourseDialog(
        courseTitle: createdCourse.title,
        courseCode: createdCourse.courseCode,
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorMessage(_formatError(error));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingCourse = false;
        });
      }
    }
  }

  Future<void> _showCreatedCourseDialog({
    required String courseTitle,
    required String courseCode,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.check_circle_rounded,
            size: 54,
            color: colorScheme.primary,
          ),
          title: const Text(
            'Course created',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                courseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Course code',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SelectableText(
                  courseCode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share this code with your students so they can join the course.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: courseCode),
                );

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Course code copied'),
                    ),
                  );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy code'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  String _formatError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid course information.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Could not create the course. Please try again.';
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
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Courses',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Create and manage your classes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isCreatingCourse
                      ? null
                      : _showCreateCourseDialog,
                  icon: _isCreatingCourse
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    _isCreatingCourse ? 'Creating' : 'Create',
                  ),
                ),
              ],
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
                hintText: 'Search courses',
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
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<TeacherCourseSummary>>(
                future: _coursesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _TeacherCourseMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load courses',
                      message: snapshot.error.toString(),
                      buttonLabel: 'Try again',
                      buttonIcon: Icons.refresh_rounded,
                      onPressed: _reloadCourses,
                    );
                  }

                  final allCourses =
                      snapshot.data ?? const <TeacherCourseSummary>[];

                  final courses = _filterCourses(allCourses);

                  if (courses.isEmpty) {
                    return _TeacherCourseMessage(
                      icon: _searchQuery.isEmpty
                          ? Icons.menu_book_outlined
                          : Icons.search_off_rounded,
                      title: _searchQuery.isEmpty
                          ? 'No courses yet'
                          : 'No matching courses',
                      message: _searchQuery.isEmpty
                          ? 'Create your first course to get started.'
                          : 'Try using another title or course code.',
                      buttonLabel: _searchQuery.isEmpty
                          ? 'Create course'
                          : null,
                      buttonIcon: Icons.add_rounded,
                      onPressed: _searchQuery.isEmpty
                          ? _showCreateCourseDialog
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshCourses,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: courses.length,
                      separatorBuilder: (_, _) {
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        final item = courses[index];

                        return CourseCard(
                          course: item.course,
                          teacherView: true,
                          studentCount: item.studentCount,
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Selected ${item.course.title}',
                                  ),
                                ),
                              );
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

class _CreateCourseDialog extends StatefulWidget {
  const _CreateCourseDialog();

  @override
  State<_CreateCourseDialog> createState() {
    return _CreateCourseDialogState();
  }
}

class _CreateCourseDialogState extends State<_CreateCourseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      _CreateCourseData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Create course'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Course title',
                    hintText: 'Mobile Application Development',
                    prefixIcon: Icon(
                      Icons.menu_book_rounded,
                    ),
                  ),
                  validator: (value) {
                    final title = value?.trim() ?? '';

                    if (title.isEmpty) {
                      return 'Enter a course title';
                    }

                    if (title.length < 3) {
                      return 'Course title is too short';
                    }

                    if (title.length > 120) {
                      return 'Course title is too long';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe this course',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(
                      Icons.notes_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 19,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'A unique course code will be generated automatically.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

class _CreateCourseData {
  final String title;
  final String description;

  const _CreateCourseData({
    required this.title,
    required this.description,
  });
}

class _TeacherCourseMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final IconData buttonIcon;
  final VoidCallback? onPressed;

  const _TeacherCourseMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.buttonIcon = Icons.add_rounded,
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        if (buttonLabel != null && onPressed != null) ...[
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