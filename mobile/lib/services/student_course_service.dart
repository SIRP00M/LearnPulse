import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../widgets/course_card.dart';

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  State<StudentCoursesPage> createState() {
    return _StudentCoursesPageState();
  }
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  final CourseService _courseService = CourseService();

  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<Course>> _coursesFuture;

  String _searchQuery = '';
  bool _isJoiningCourse = false;

  @override
  void initState() {
    super.initState();

    _coursesFuture = _courseService.fetchStudentCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  void _reloadCourses() {
    setState(() {
      _coursesFuture = _courseService.fetchStudentCourses();
    });
  }

  Future<void> _refreshCourses() async {
    final future = _courseService.fetchStudentCourses();

    setState(() {
      _coursesFuture = future;
    });

    await future;
  }

  List<Course> _filterCourses(List<Course> courses) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return courses;
    }

    return courses.where((course) {
      return course.title.toLowerCase().contains(query) ||
          course.courseCode.toLowerCase().contains(query) ||
          course.description.toLowerCase().contains(query) ||
          course.teacherName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showJoinCourseDialog() async {
    final courseCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return const _JoinCourseDialog();
      },
    );

    if (courseCode == null || !mounted) {
      return;
    }

    setState(() {
      _isJoiningCourse = true;
    });

    try {
      await _courseService.joinCourseByCode(courseCode);

      if (!mounted) {
        return;
      }

      _reloadCourses();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Joined ${courseCode.toUpperCase()} successfully.',
            ),
          ),
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
          _isJoiningCourse = false;
        });
      }
    }
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
      return error.message?.toString() ??
          'Invalid course code.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Could not join the course. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Courses',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Continue learning and track your classes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isJoiningCourse
                      ? null
                      : _showJoinCourseDialog,
                  icon: _isJoiningCourse
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.group_add_rounded,
                        ),
                  label: Text(
                    _isJoiningCourse
                        ? 'Joining'
                        : 'Join',
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
                hintText: 'Search courses or teachers',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
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
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                filled: true,
                fillColor: colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Course>>(
                future: _coursesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _StudentCourseMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load courses',
                      message: snapshot.error.toString(),
                      buttonLabel: 'Try again',
                      buttonIcon: Icons.refresh_rounded,
                      onPressed: _reloadCourses,
                    );
                  }

                  final allCourses =
                      snapshot.data ?? const <Course>[];

                  final courses =
                      _filterCourses(allCourses);

                  if (courses.isEmpty) {
                    return _StudentCourseMessage(
                      icon: _searchQuery.isEmpty
                          ? Icons.school_outlined
                          : Icons.search_off_rounded,
                      title: _searchQuery.isEmpty
                          ? 'You have not joined a course'
                          : 'No matching courses',
                      message: _searchQuery.isEmpty
                          ? 'Enter the course code provided by your teacher.'
                          : 'Try searching with another title, code, or teacher.',
                      buttonLabel: _searchQuery.isEmpty
                          ? 'Join course'
                          : null,
                      buttonIcon:
                          Icons.group_add_rounded,
                      onPressed: _searchQuery.isEmpty
                          ? _showJoinCourseDialog
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshCourses,
                    child: ListView.separated(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.only(bottom: 24),
                      itemCount: courses.length,
                      separatorBuilder: (_, _) {
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        final course = courses[index];

                        return CourseCard(
                          course: course,
                          teacherView: false,
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Selected ${course.title}',
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

class _JoinCourseDialog extends StatefulWidget {
  const _JoinCourseDialog();

  @override
  State<_JoinCourseDialog> createState() {
    return _JoinCourseDialogState();
  }
}

class _JoinCourseDialogState
    extends State<_JoinCourseDialog> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();

    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();

    super.dispose();
  }

  void _submit() {
    final valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      _codeController.text.trim().toUpperCase(),
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
      icon: Icon(
        Icons.meeting_room_rounded,
        size: 48,
        color: colorScheme.primary,
      ),
      title: const Text(
        'Join course',
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the code shared by your teacher.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                autofocus: true,
                textCapitalization:
                    TextCapitalization.characters,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                maxLength: 8,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
                decoration: const InputDecoration(
                  labelText: 'Course code',
                  hintText: 'CH2CQQTX',
                  counterText: '',
                  prefixIcon: Icon(
                    Icons.tag_rounded,
                  ),
                ),
                validator: (value) {
                  final code =
                      value?.trim().toUpperCase() ?? '';

                  if (code.isEmpty) {
                    return 'Enter a course code';
                  }

                  if (code.length != 8) {
                    return 'Course code must contain 8 characters';
                  }

                  if (!RegExp(
                    r'^[A-Z2-9]+$',
                  ).hasMatch(code)) {
                    return 'Course code contains invalid characters';
                  }

                  return null;
                },
                onFieldSubmitted: (_) {
                  _submit();
                },
              ),
            ],
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
          icon: const Icon(
            Icons.login_rounded,
          ),
          label: const Text('Join'),
        ),
      ],
    );
  }
}

class _StudentCourseMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final IconData buttonIcon;
  final VoidCallback? onPressed;

  const _StudentCourseMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.buttonIcon = Icons.group_add_rounded,
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
          color: colorScheme.primary.withValues(
            alpha: 0.7,
          ),
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