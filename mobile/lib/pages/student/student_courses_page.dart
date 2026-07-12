import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/course.dart';
import '../../services/course_service.dart';
import 'student_course_detail_page.dart';

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Course>> _coursesFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  void _loadCourses() {
    _coursesFuture = _courseService.getMyCourses();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _refreshCourses() async {
    setState(_loadCourses);
    await _coursesFuture;
  }

  List<Course> _filterCourses(List<Course> courses) {
    if (_searchQuery.isEmpty) {
      return courses;
    }

    return courses.where((course) {
      return course.title.toLowerCase().contains(_searchQuery) ||
          course.courseCode.toLowerCase().contains(_searchQuery) ||
          course.teacherName.toLowerCase().contains(_searchQuery) ||
          course.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _showJoinCourseDialog() async {
    final joined = await showDialog<bool>(
      context: context,
      builder: (_) => const _JoinCourseDialog(),
    );

    if (joined == true && mounted) {
      await _refreshCourses();
    }
  }

  void _openCourse(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentCourseDetailPage(course: course),
      ),
    );
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshCourses,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My courses',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Track lessons and learning progress',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _showJoinCourseDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Join'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SearchBar(
                      controller: _searchController,
                      hintText: 'Search courses',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, child) {
                            if (value.text.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<Course>>(
              future: _coursesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorView(
                      message: snapshot.error.toString(),
                      onRetry: () {
                        setState(_loadCourses);
                      },
                    ),
                  );
                }

                final courses = _filterCourses(snapshot.data ?? const []);

                if (courses.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyView(
                      hasSearch: _searchQuery.isNotEmpty,
                      onJoin: _showJoinCourseDialog,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];

                      return _CourseCard(
                        course: course,
                        onTap: () => _openCourse(course),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (course.coverUrl != null && course.coverUrl!.isNotEmpty)
              Image.network(
                course.coverUrl!,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _CoursePlaceholder(title: course.title),
              )
            else
              _CoursePlaceholder(title: course.title),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.courseCode,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description.trim().isEmpty
                        ? 'No course description'
                        : course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          course.teacherName.trim().isEmpty
                              ? 'Unknown teacher'
                              : course.teacherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
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

class _CoursePlaceholder extends StatelessWidget {
  final String title;

  const _CoursePlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(_getIcon(title), size: 52, color: colorScheme.primary),
      ),
    );
  }

  IconData _getIcon(String title) {
    final normalized = title.toLowerCase();

    if (normalized.contains('computer') ||
        normalized.contains('flutter') ||
        normalized.contains('mobile')) {
      return Icons.memory_rounded;
    }

    if (normalized.contains('language') ||
        normalized.contains('japanese') ||
        normalized.contains('english')) {
      return Icons.translate_rounded;
    }

    if (normalized.contains('ai') || normalized.contains('artificial')) {
      return Icons.smart_toy_rounded;
    }

    return Icons.menu_book_rounded;
  }
}

class _JoinCourseDialog extends StatefulWidget {
  const _JoinCourseDialog();

  @override
  State<_JoinCourseDialog> createState() => _JoinCourseDialogState();
}

class _JoinCourseDialogState extends State<_JoinCourseDialog> {
  final CourseService _courseService = CourseService();
  final TextEditingController _codeController = TextEditingController();

  bool _isJoining = false;
  String? _error;

  Future<void> _join() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _error = 'Please enter a course code.';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      await _courseService.joinCourseByCode(code);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      setState(() {
        _isJoining = false;
        _error = error.message;
      });
    } catch (error) {
      setState(() {
        _isJoining = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a course'),
      content: TextField(
        controller: _codeController,
        enabled: !_isJoining,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        onSubmitted: (_) => _join(),
        decoration: InputDecoration(
          labelText: 'Course code',
          hintText: 'Example: ABCD1234',
          prefixIcon: const Icon(Icons.key_rounded),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isJoining ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isJoining ? null : _join,
          child: _isJoining
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join course'),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onJoin;

  const _EmptyView({required this.hasSearch, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.menu_book_outlined,
              size: 64,
              color: Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No matching courses' : 'No courses yet',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try another keyword.'
                  : 'Join your first course using a code from your teacher.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Join a course'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 58),
            const SizedBox(height: 14),
            const Text(
              'Unable to load courses',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
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
      ),
    );
  }
}
