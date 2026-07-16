import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/assignment.dart';
import '../../models/attendance_session.dart';
import '../../models/course.dart';
import '../../models/course_file.dart';
import '../../models/course_post.dart';
import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/attendance_service.dart';
import '../../services/teacher_course_service.dart';

class TeacherCourseDetailPage extends StatefulWidget {
  final Course course;

  /// ใช้เป็นค่าชั่วคราวระหว่างรอโหลดรายชื่อนักเรียนจาก Backend
  final int studentCount;

  const TeacherCourseDetailPage({
    required this.course,
    this.studentCount = 0,
    super.key,
  });

  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState
    extends State<TeacherCourseDetailPage> {
  final TeacherCourseService _courseService =
      TeacherCourseService();

  final AttendanceService _attendanceService =
      AttendanceService();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  late Course _course;

  late Future<List<CoursePost>> _postsFuture;
  late Future<List<Lesson>> _lessonsFuture;
  late Future<List<Assignment>> _assignmentsFuture;
  late Future<List<AttendanceSession>>
      _attendanceSessionsFuture;
  late Future<List<_SubmissionRow>> _submissionsFuture;
  late Future<List<UserProfile>> _studentsFuture;
  late Future<List<CourseFile>> _filesFuture;

  bool _isUploadingFile = false;

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
      label: 'Submissions',
      icon: Icons.assignment_turned_in_outlined,
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
  void initState() {
    super.initState();

    _course = widget.course;
    _loadCourseData();
  }

  void _loadCourseData() {
    final courseId = _course.id;

    _postsFuture =
        _courseService.getPosts(courseId);

    _lessonsFuture =
        _courseService.getLessons(courseId);

    _assignmentsFuture =
        _courseService.getAssignments(courseId);

    _attendanceSessionsFuture =
        _attendanceService.getCourseSessions(courseId);

    _submissionsFuture =
        _getSubmissions(courseId);

    _studentsFuture =
        _courseService.getStudents(courseId);

    _filesFuture =
        _courseService.getFiles(courseId);
  }

  Future<void> _refreshCourseData() async {
    setState(_loadCourseData);

    await Future.wait<dynamic>([
      _postsFuture,
      _lessonsFuture,
      _assignmentsFuture,
      _attendanceSessionsFuture,
      _submissionsFuture,
      _studentsFuture,
      _filesFuture,
    ]);
  }

  Future<List<_SubmissionRow>> _getSubmissions(
    String courseId,
  ) async {
    final data = await _supabase
        .from('submissions')
        .select('''
          id,
          status,
          submitted_at,
          score,
          feedback,
          answer_text,
          file_path,
          assignment:assignments!inner(
            id,
            title,
            max_score,
            course_id
          ),
          student:profiles!submissions_student_id_fkey(
            id,
            full_name,
            avatar_url
          )
        ''')
        .eq('assignment.course_id', courseId)
        .order(
          'submitted_at',
          ascending: false,
        );

    return (data as List<dynamic>)
        .map(
          (item) => _SubmissionRow.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _course.courseCode.isEmpty
                ? _course.title
                : _course.courseCode,
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshCourseData,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Copy course code',
              onPressed: _copyCourseCode,
              icon: const Icon(
                Icons.copy_rounded,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Course options',
              onSelected: _handleCourseOption,
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text('Edit course'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined),
                        SizedBox(width: 12),
                        Text('Archive course'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: _showCreateMenu,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create'),
        ),
        body: Column(
          children: [
            FutureBuilder<List<UserProfile>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ??
                    widget.studentCount;

                return _TeacherCourseHeader(
                  course: _course,
                  studentCount: count,
                );
              },
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
                  _buildOverviewTab(),
                  _buildPostsTab(),
                  _buildLessonsTab(),
                  _buildAssignmentsTab(),
                  _buildAttendanceTab(),
                  _buildSubmissionsTab(),
                  _buildStudentsTab(),
                  _buildFilesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Overview
  // =========================================================

  Widget _buildOverviewTab() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _postsFuture,
        _lessonsFuture,
        _assignmentsFuture,
        _attendanceSessionsFuture,
        _submissionsFuture,
        _studentsFuture,
        _filesFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final posts =
            snapshot.data?[0] as List<CoursePost>? ??
                const [];

        final lessons =
            snapshot.data?[1] as List<Lesson>? ??
                const [];

        final assignments =
            snapshot.data?[2] as List<Assignment>? ??
                const [];

        final attendance =
            snapshot.data?[3]
                    as List<AttendanceSession>? ??
                const [];

        final submissions =
            snapshot.data?[4]
                    as List<_SubmissionRow>? ??
                const [];

        final students =
            snapshot.data?[5] as List<UserProfile>? ??
                const [];

        final files =
            snapshot.data?[6] as List<CourseFile>? ??
                const [];

        final graded = submissions
            .where((item) => item.score != null)
            .toList();

        final averageScore = graded.isEmpty
            ? null
            : graded
                    .map((item) => item.score!)
                    .reduce((a, b) => a + b) /
                graded.length;

        final submittedCount = submissions
            .where(
              (item) => item.submittedAt != null,
            )
            .length;

        final publishedLessons = lessons
            .where((item) => item.isPublished)
            .length;

        final overview =
            _course.overview.trim().isNotEmpty
                ? _course.overview.trim()
                : _course.description.trim();

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            children: [
              _SectionCard(
                title: 'Course overview',
                icon: Icons.description_outlined,
                child: Text(
                  overview.isEmpty
                      ? 'No course overview has been added yet.'
                      : overview,
                  style: const TextStyle(
                    height: 1.55,
                  ),
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
                childAspectRatio: 1.18,
                children: [
                  _CourseStatCard(
                    value: '${students.length}',
                    label: 'Students',
                    icon: Icons.groups_rounded,
                  ),
                  _CourseStatCard(
                    value: '${assignments.length}',
                    label: 'Assignments',
                    icon: Icons.assignment_rounded,
                  ),
                  _CourseStatCard(
                    value: '$submittedCount',
                    label: 'Submissions',
                    icon: Icons
                        .assignment_turned_in_rounded,
                  ),
                  _CourseStatCard(
                    value: averageScore == null
                        ? '—'
                        : averageScore
                            .toStringAsFixed(1),
                    label: 'Average score',
                    icon: Icons.grade_rounded,
                  ),
                  _CourseStatCard(
                    value:
                        '$publishedLessons/${lessons.length}',
                    label: 'Published lessons',
                    icon: Icons.play_lesson_rounded,
                  ),
                  _CourseStatCard(
                    value: '${attendance.length}',
                    label: 'Attendance sessions',
                    icon: Icons.fact_check_rounded,
                  ),
                  _CourseStatCard(
                    value: '${posts.length}',
                    label: 'Posts',
                    icon: Icons.campaign_rounded,
                  ),
                  _CourseStatCard(
                    value: '${files.length}',
                    label: 'Files',
                    icon: Icons.folder_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Course code',
                icon: Icons.key_rounded,
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _course.courseCode,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy',
                      onPressed: _copyCourseCode,
                      icon: const Icon(
                        Icons.copy_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // Posts
  // =========================================================

  Widget _buildPostsTab() {
    return FutureBuilder<List<CoursePost>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final posts = snapshot.data ?? const [];

        if (posts.isEmpty) {
          return _ActionEmptyTab(
            icon: Icons.campaign_outlined,
            title: 'No posts yet',
            message:
                'Create an announcement for your students.',
            buttonLabel: 'Create announcement',
            buttonIcon: Icons.add_rounded,
            onPressed: _showCreatePostDialog,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView.separated(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            itemCount: posts.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = posts[index];

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
                          Expanded(
                            child: Text(
                              post.title.trim().isEmpty
                                  ? 'Announcement'
                                  : post.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                          if (post.isPinned)
                            const Padding(
                              padding:
                                  EdgeInsets.only(
                                right: 8,
                              ),
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 18,
                              ),
                            ),
                          _PublishChip(
                            published:
                                post.publishedAt != null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.content,
                        style: const TextStyle(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatDateTime(
                          post.publishedAt ??
                              post.createdAt,
                        ),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // Lessons
  // =========================================================

  Widget _buildLessonsTab() {
    return FutureBuilder<List<Lesson>>(
      future: _lessonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final lessons = snapshot.data ?? const [];

        if (lessons.isEmpty) {
          return _ActionEmptyTab(
            icon: Icons.play_lesson_outlined,
            title: 'No lessons yet',
            message:
                'Create lessons and learning materials for this course.',
            buttonLabel: 'Create lesson',
            buttonIcon: Icons.add_rounded,
            onPressed: _showCreateLessonDialog,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView.separated(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            itemCount: lessons.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final lesson = lessons[index];

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  onTap: () => _showLesson(lesson),
                  contentPadding:
                      const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    child: Text(
                      '${lesson.position > 0 ? lesson.position : index + 1}',
                    ),
                  ),
                  title: Text(
                    lesson.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    lesson.description.trim().isEmpty
                        ? lesson.isPublished
                            ? 'Published lesson'
                            : 'Draft lesson'
                        : lesson.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _PublishChip(
                    published: lesson.isPublished,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // Assignments
  // =========================================================

  Widget _buildAssignmentsTab() {
    return FutureBuilder<List<Assignment>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final assignments =
            snapshot.data ?? const [];

        if (assignments.isEmpty) {
          return _ActionEmptyTab(
            icon: Icons.assignment_outlined,
            title: 'No assignments yet',
            message:
                'Create an assignment, deadline and maximum score.',
            buttonLabel: 'Create assignment',
            buttonIcon: Icons.add_task_rounded,
            onPressed:
                _showCreateAssignmentDialog,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView.separated(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            itemCount: assignments.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final assignment =
                  assignments[index];

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(15),
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.assignment_rounded,
                    ),
                  ),
                  title: Text(
                    assignment.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    assignment.dueAt == null
                        ? '${assignment.maxScore.toStringAsFixed(0)} points • No deadline'
                        : '${assignment.maxScore.toStringAsFixed(0)} points • Due ${_formatDateTime(assignment.dueAt!)}',
                  ),
                  trailing: _PublishChip(
                    published:
                        assignment.isPublished,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // Attendance
  // =========================================================

  Widget _buildAttendanceTab() {
    return FutureBuilder<List<AttendanceSession>>(
      future: _attendanceSessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final sessions = snapshot.data ?? const [];

        if (sessions.isEmpty) {
          return _ActionEmptyTab(
            icon: Icons.fact_check_outlined,
            title: 'No attendance sessions',
            message:
                'Open an attendance session and share the code with students.',
            buttonLabel: 'Create attendance',
            buttonIcon: Icons.add_task_rounded,
            onPressed:
                _showCreateAttendanceDialog,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView.separated(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            itemCount: sessions.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];

              return Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () =>
                      _openAttendanceSession(session),
                  borderRadius:
                      BorderRadius.circular(20),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ),
                            _AttendanceStatusChip(
                              status: session.status,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_formatDateTime(session.startsAt)}'
                          ' – ${_formatTime(session.endsAt)}',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.key_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            SelectableText(
                              session.checkInCode,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Copy code',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: session
                                        .checkInCode,
                                  ),
                                );

                                _showMessage(
                                  'Attendance code copied.',
                                );
                              },
                              icon: const Icon(
                                Icons.copy_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // Submissions
  // =========================================================

  Widget _buildSubmissionsTab() {
    return FutureBuilder<List<_SubmissionRow>>(
      future: _submissionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final submissions =
            snapshot.data ?? const [];

        if (submissions.isEmpty) {
          return const _CourseEmptyTab(
            icon: Icons
                .assignment_turned_in_outlined,
            title: 'No submissions yet',
            message:
                'Student work will appear here after they submit an assignment.',
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView.separated(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            itemCount: submissions.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final submission =
                  submissions[index];

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  onTap: () =>
                      _showGradeSubmissionDialog(
                    submission,
                  ),
                  contentPadding:
                      const EdgeInsets.all(15),
                  leading: _ProfileAvatar(
                    name: submission.studentName,
                    avatarUrl:
                        submission.avatarUrl,
                  ),
                  title: Text(
                    submission.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${submission.assignmentTitle}\n'
                    '${submission.submittedAt == null ? 'Not submitted' : 'Submitted ${_formatDateTime(submission.submittedAt!)}'}',
                  ),
                  isThreeLine: true,
                  trailing: submission.score == null
                      ? _SubmissionStatusChip(
                          status:
                              submission.status,
                        )
                      : Text(
                          '${submission.score!.toStringAsFixed(0)}/'
                          '${submission.maxScore.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // Students
  // =========================================================

  Widget _buildStudentsTab() {
    return FutureBuilder<List<UserProfile>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final students = snapshot.data ?? const [];

        if (students.isEmpty) {
          return const _CourseEmptyTab(
            icon: Icons.groups_outlined,
            title: 'No students yet',
            message:
                'Share the course code so students can join this course.',
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView.separated(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            itemCount: students.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = students[index];

              final name =
                  student.fullName.trim().isEmpty
                      ? 'Unnamed student'
                      : student.fullName.trim();

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(15),
                  leading: _ProfileAvatar(
                    name: name,
                    avatarUrl: student.avatarUrl,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Enrolled student',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // Files
  // =========================================================

  Widget _buildFilesTab() {
    return FutureBuilder<List<CourseFile>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _refreshCourseData,
          );
        }

        final files = snapshot.data ?? const [];

        if (files.isEmpty) {
          return _ActionEmptyTab(
            icon: Icons.folder_outlined,
            title: 'No files yet',
            message:
                'Upload course resources for your students.',
            buttonLabel: 'Upload file',
            buttonIcon:
                Icons.upload_file_rounded,
            onPressed: _pickAndUploadFile,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourseData,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              100,
            ),
            children: [
              FilledButton.icon(
                onPressed: _isUploadingFile
                    ? null
                    : _pickAndUploadFile,
                icon: _isUploadingFile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.upload_file_rounded,
                      ),
                label: Text(
                  _isUploadingFile
                      ? 'Uploading...'
                      : 'Upload file',
                ),
              ),
              const SizedBox(height: 14),
              for (final file in files) ...[
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    onTap: () => _openFile(file),
                    contentPadding:
                        const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      child: Icon(
                        _getFileIcon(
                          file.fileName,
                        ),
                      ),
                    ),
                    title: Text(
                      file.fileName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${_formatFileSize(file.sizeBytes)}'
                      ' • ${_formatDateTime(file.createdAt)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'open') {
                          _openFile(file);
                        }

                        if (value == 'delete') {
                          _deleteFile(file);
                        }
                      },
                      itemBuilder: (_) {
                        return const [
                          PopupMenuItem(
                            value: 'open',
                            child: Text('Open'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // Create menu
  // =========================================================

  Future<void> _showCreateMenu() async {
    final selected =
        await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Create course content',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _CreateMenuTile(
                  value: 'announcement',
                  icon: Icons.campaign_outlined,
                  title: 'Announcement',
                  subtitle:
                      'Post an update for students',
                  sheetContext: sheetContext,
                ),
                _CreateMenuTile(
                  value: 'lesson',
                  icon:
                      Icons.play_lesson_outlined,
                  title: 'Lesson',
                  subtitle:
                      'Add learning content',
                  sheetContext: sheetContext,
                ),
                _CreateMenuTile(
                  value: 'assignment',
                  icon:
                      Icons.assignment_outlined,
                  title: 'Assignment',
                  subtitle:
                      'Create work for students',
                  sheetContext: sheetContext,
                ),
                _CreateMenuTile(
                  value: 'attendance',
                  icon:
                      Icons.fact_check_outlined,
                  title: 'Attendance',
                  subtitle:
                      'Open a check-in session',
                  sheetContext: sheetContext,
                ),
                _CreateMenuTile(
                  value: 'file',
                  icon:
                      Icons.upload_file_outlined,
                  title: 'File',
                  subtitle:
                      'Upload course material',
                  sheetContext: sheetContext,
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (selected) {
      case 'announcement':
        await _showCreatePostDialog();
        break;

      case 'lesson':
        await _showCreateLessonDialog();
        break;

      case 'assignment':
        await _showCreateAssignmentDialog();
        break;

      case 'attendance':
        await _showCreateAttendanceDialog();
        break;

      case 'file':
        await _pickAndUploadFile();
        break;
    }
  }

  // =========================================================
  // Create post
  // =========================================================

  Future<void> _showCreatePostDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreatePostDialog(
        service: _courseService,
        courseId: _course.id,
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _postsFuture =
            _courseService.getPosts(_course.id);
      });

      _showMessage('Announcement created.');
    }
  }

  // =========================================================
  // Create lesson
  // =========================================================

  Future<void> _showCreateLessonDialog() async {
    var position = 1;

    try {
      final lessons = await _lessonsFuture;
      position = lessons.length + 1;
    } catch (_) {
      position = 1;
    }

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateLessonDialog(
        service: _courseService,
        courseId: _course.id,
        position: position,
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _lessonsFuture =
            _courseService.getLessons(_course.id);
      });

      _showMessage('Lesson created.');
    }
  }

  // =========================================================
  // Create assignment
  // =========================================================

  Future<void>
      _showCreateAssignmentDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateAssignmentDialog(
        service: _courseService,
        courseId: _course.id,
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _assignmentsFuture =
            _courseService.getAssignments(
          _course.id,
        );
      });

      _showMessage('Assignment created.');
    }
  }

  // =========================================================
  // Create attendance
  // =========================================================

  Future<void>
      _showCreateAttendanceDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateAttendanceDialog(
        service: _attendanceService,
        courseId: _course.id,
      ),
    );

    if (created == true && mounted) {
      setState(() {
        _attendanceSessionsFuture =
            _attendanceService
                .getCourseSessions(_course.id);
      });

      _showMessage(
        'Attendance session opened.',
      );
    }
  }

  // =========================================================
  // Attendance records
  // =========================================================

  Future<void> _openAttendanceSession(
    AttendanceSession session,
  ) async {
    final changed =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AttendanceSessionSheet(
        session: session,
        service: _attendanceService,
      ),
    );

    if (changed == true && mounted) {
      setState(() {
        _attendanceSessionsFuture =
            _attendanceService
                .getCourseSessions(_course.id);
      });
    }
  }

  // =========================================================
  // Grade submission
  // =========================================================

  Future<void> _showGradeSubmissionDialog(
    _SubmissionRow submission,
  ) async {
    final graded = await showDialog<bool>(
      context: context,
      builder: (_) => _GradeSubmissionDialog(
        submission: submission,
        supabase: _supabase,
      ),
    );

    if (graded == true && mounted) {
      setState(() {
        _submissionsFuture =
            _getSubmissions(_course.id);
      });

      _showMessage('Submission graded.');
    }
  }

  // =========================================================
  // File upload
  // =========================================================

  Future<void> _pickAndUploadFile() async {
    if (_isUploadingFile) return;

    final result =
        await FilePicker.pickFiles(
      withData: true,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    final bytes = pickedFile.bytes;
    final user = _supabase.auth.currentUser;

    if (bytes == null) {
      _showMessage(
        'Unable to read the selected file.',
      );
      return;
    }

    if (user == null) {
      _showMessage('You are not signed in.');
      return;
    }

    setState(() {
      _isUploadingFile = true;
    });

    String? uploadedPath;

    try {
      final safeName = pickedFile.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      uploadedPath =
          '${_course.id}/resources/'
          '${DateTime.now().millisecondsSinceEpoch}_'
          '$safeName';

      final mimeType = _guessMimeType(
        pickedFile.extension,
      );

      await _supabase.storage
          .from('course-files')
          .uploadBinary(
            uploadedPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: mimeType,
            ),
          );

      await _supabase
          .from('course_files')
          .insert({
        'course_id': _course.id,
        'uploaded_by': user.id,
        'file_name': pickedFile.name,
        'storage_path': uploadedPath,
        'mime_type': mimeType,
        'size_bytes': pickedFile.size,
      });

      if (!mounted) return;

      setState(() {
        _filesFuture =
            _courseService.getFiles(_course.id);

        _isUploadingFile = false;
      });

      _showMessage('File uploaded.');
    } catch (error) {
      if (uploadedPath != null) {
        try {
          await _supabase.storage
              .from('course-files')
              .remove([uploadedPath]);
        } catch (_) {
          // Ignore cleanup failure.
        }
      }

      if (!mounted) return;

      setState(() {
        _isUploadingFile = false;
      });

      _showMessage(
        'Unable to upload file: $error',
      );
    }
  }

  Future<void> _openFile(
    CourseFile file,
  ) async {
    try {
      final url = await _supabase.storage
          .from('course-files')
          .createSignedUrl(
            file.storagePath,
            600,
          );

      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw StateError(
          'Unable to open the file.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to open file: $error',
      );
    }
  }

  Future<void> _deleteFile(
    CourseFile file,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete file?'),
          content: Text(
            'Delete "${file.fileName}" permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _supabase.storage
          .from('course-files')
          .remove([file.storagePath]);

      await _supabase
          .from('course_files')
          .delete()
          .eq('id', file.id);

      if (!mounted) return;

      setState(() {
        _filesFuture =
            _courseService.getFiles(_course.id);
      });

      _showMessage('File deleted.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete file: $error',
      );
    }
  }

  // =========================================================
  // Lesson content
  // =========================================================

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
          builder: (
            context,
            scrollController,
          ) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                32,
              ),
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                if (lesson.description
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  lesson.content.trim().isEmpty
                      ? 'No lesson content.'
                      : lesson.content,
                  style: const TextStyle(
                    height: 1.6,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // Course options
  // =========================================================

  Future<void> _copyCourseCode() async {
    await Clipboard.setData(
      ClipboardData(
        text: _course.courseCode,
      ),
    );

    if (!mounted) return;

    _showMessage('Course code copied.');
  }

  Future<void> _handleCourseOption(
    String value,
  ) async {
    switch (value) {
      case 'edit':
        await _editCourse();
        break;

      case 'archive':
        await _archiveCourse();
        break;
    }
  }

  Future<void> _editCourse() async {
    final result =
        await showDialog<_CourseEditResult>(
      context: context,
      builder: (_) => _EditCourseDialog(
        course: _course,
      ),
    );

    if (result == null) return;

    try {
      await _supabase
          .from('courses')
          .update({
        'title': result.title,
        'description': result.description,
        'overview': result.overview,
        'status': result.status,
      }).eq('id', _course.id);

      if (!mounted) return;

  setState(() {
  _course = Course(
    id: _course.id,
    teacherId: _course.teacherId,
    title: result.title,
    courseCode: _course.courseCode,
    description: result.description,
    overview: result.overview,
    coverUrl: _course.coverUrl,
    status: result.status,
    teacherName: _course.teacherName,
    createdAt: _course.createdAt,
    updatedAt: DateTime.now(),
  );
});

      _showMessage('Course updated.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to update course: $error',
      );
    }
  }

  Future<void> _archiveCourse() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archive course?'),
          content: const Text(
            'Students will no longer see this course '
            'as an active published course.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _supabase
          .from('courses')
          .update({
        'status': 'archived',
      }).eq('id', _course.id);

      if (!mounted) return;

setState(() {
  _course = Course(
    id: _course.id,
    teacherId: _course.teacherId,
    title: _course.title,
    courseCode: _course.courseCode,
    description: _course.description,
    overview: _course.overview,
    coverUrl: _course.coverUrl,
    status: 'archived',
    teacherName: _course.teacherName,
    createdAt: _course.createdAt,
    updatedAt: DateTime.now(),
  );
});

      _showMessage('Course archived.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to archive course: $error',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  static String _formatDateTime(
    DateTime date,
  ) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatTime(
    DateTime date,
  ) {
    final local = date.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static IconData _getFileIcon(
    String fileName,
  ) {
    final parts = fileName.split('.');

    final extension = parts.length > 1
        ? parts.last.toLowerCase()
        : '';

    return switch (extension) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'ppt' || 'pptx' => Icons.slideshow_rounded,
      'doc' || 'docx' =>
        Icons.description_rounded,
      'zip' || 'rar' =>
        Icons.folder_zip_rounded,
      'jpg' || 'jpeg' || 'png' || 'webp' =>
        Icons.image_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  static String _guessMimeType(
    String? extension,
  ) {
    return switch (extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'zip' => 'application/zip',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt' =>
        'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      _ => 'application/octet-stream',
    };
  }
}

// =========================================================
// Header
// =========================================================

class _TeacherCourseHeader extends StatelessWidget {
  final Course course;
  final int studentCount;

  const _TeacherCourseHeader({
    required this.course,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

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
        color: colors.primaryContainer,
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
                  color: colors.primary,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colors.onPrimary,
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
                        color: colors
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
                        color: colors
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
              _StatusChip(
                status: course.status,
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
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    colors.onPrimaryContainer,
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
                color:
                    colors.onPrimaryContainer,
              ),
              const SizedBox(width: 7),
              Text(
                '$studentCount '
                '${studentCount == 1 ? 'student' : 'students'}',
                style: TextStyle(
                  color:
                      colors.onPrimaryContainer,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================
// Create post dialog
// =========================================================

class _CreatePostDialog extends StatefulWidget {
  final TeacherCourseService service;
  final String courseId;

  const _CreatePostDialog({
    required this.service,
    required this.courseId,
  });

  @override
  State<_CreatePostDialog> createState() =>
      _CreatePostDialogState();
}

class _CreatePostDialogState
    extends State<_CreatePostDialog> {
  final _titleController =
      TextEditingController();

  final _contentController =
      TextEditingController();

  bool _publishNow = true;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final content =
        _contentController.text.trim();

    if (content.isEmpty) {
      setState(() {
        _error =
            'Please enter announcement content.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.createPost(
        courseId: widget.courseId,
        title: _titleController.text,
        content: content,
        publishNow: _publishNow,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _saving = false;
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
      title:
          const Text('Create announcement'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_saving,
                decoration:
                    const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _contentController,
                enabled: !_saving,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Announcement',
                  alignLabelWithHint: true,
                  errorText: _error,
                ),
              ),
              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text('Publish now'),
                value: _publishNow,
                onChanged: _saving
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
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const _SmallLoader()
              : const Text('Create'),
        ),
      ],
    );
  }
}

// =========================================================
// Create lesson dialog
// =========================================================

class _CreateLessonDialog
    extends StatefulWidget {
  final TeacherCourseService service;
  final String courseId;
  final int position;

  const _CreateLessonDialog({
    required this.service,
    required this.courseId,
    required this.position,
  });

  @override
  State<_CreateLessonDialog> createState() =>
      _CreateLessonDialogState();
}

class _CreateLessonDialogState
    extends State<_CreateLessonDialog> {
  final _titleController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  final _contentController =
      TextEditingController();

  bool _publishNow = true;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final title =
        _titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _error =
            'Please enter a lesson title.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.createLesson(
        courseId: widget.courseId,
        title: title,
        description:
            _descriptionController.text,
        content: _contentController.text,
        position: widget.position,
        publishNow: _publishNow,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _saving = false;
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
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: 'Lesson title',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _descriptionController,
                enabled: !_saving,
                maxLines: 2,
                decoration:
                    const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _contentController,
                enabled: !_saving,
                minLines: 4,
                maxLines: 9,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Lesson content',
                  alignLabelWithHint: true,
                ),
              ),
              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text('Publish now'),
                value: _publishNow,
                onChanged: _saving
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
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const _SmallLoader()
              : const Text('Create'),
        ),
      ],
    );
  }
}

// =========================================================
// Create assignment dialog
// =========================================================

class _CreateAssignmentDialog
    extends StatefulWidget {
  final TeacherCourseService service;
  final String courseId;

  const _CreateAssignmentDialog({
    required this.service,
    required this.courseId,
  });

  @override
  State<_CreateAssignmentDialog>
      createState() =>
          _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState
    extends State<_CreateAssignmentDialog> {
  final _titleController =
      TextEditingController();

  final _instructionsController =
      TextEditingController();

  final _scoreController =
      TextEditingController(text: '100');

  DateTime? _dueAt;

  bool _allowLate = false;
  bool _publishNow = true;
  bool _saving = false;
  String? _error;

  Future<void> _pickDueDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate:
          _dueAt ??
          now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 23,
        minute: 59,
      ),
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
    final title =
        _titleController.text.trim();

    final score = double.tryParse(
      _scoreController.text.trim(),
    );

    if (title.isEmpty) {
      setState(() {
        _error =
            'Please enter an assignment title.';
      });

      return;
    }

    if (score == null || score < 0) {
      setState(() {
        _error =
            'Please enter a valid score.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.createAssignment(
        courseId: widget.courseId,
        title: title,
        instructions:
            _instructionsController.text,
        dueAt: _dueAt,
        maxScore: score,
        allowLate: _allowLate,
        publishNow: _publishNow,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _saving = false;
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
      title:
          const Text('Create assignment'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText:
                      'Assignment title',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _instructionsController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 7,
                decoration:
                    const InputDecoration(
                  labelText: 'Instructions',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _scoreController,
                enabled: !_saving,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Maximum score',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading: const Icon(
                  Icons.schedule_rounded,
                ),
                title:
                    const Text('Due date'),
                subtitle: Text(
                  _dueAt == null
                      ? 'No deadline'
                      : _TeacherCourseDetailPageState
                          ._formatDateTime(
                          _dueAt!,
                        ),
                ),
                trailing: TextButton(
                  onPressed: _saving
                      ? null
                      : _pickDueDate,
                  child: Text(
                    _dueAt == null
                        ? 'Select'
                        : 'Change',
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Allow late submission',
                ),
                value: _allowLate,
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _allowLate = value;
                        });
                      },
              ),
              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text('Publish now'),
                value: _publishNow,
                onChanged: _saving
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
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const _SmallLoader()
              : const Text('Create'),
        ),
      ],
    );
  }
}

// =========================================================
// Create attendance dialog
// =========================================================

class _CreateAttendanceDialog
    extends StatefulWidget {
  final AttendanceService service;
  final String courseId;

  const _CreateAttendanceDialog({
    required this.service,
    required this.courseId,
  });

  @override
  State<_CreateAttendanceDialog>
      createState() =>
          _CreateAttendanceDialogState();
}

class _CreateAttendanceDialogState
    extends State<_CreateAttendanceDialog> {
  final _titleController =
      TextEditingController(
    text: 'Class attendance',
  );

  late DateTime _startsAt;
  late DateTime _endsAt;

  int _lateMinutes = 15;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _startsAt = DateTime.now();
    _endsAt = _startsAt.add(
      const Duration(hours: 2),
    );
  }

  Future<void> _pickStart() async {
    final value = await _pickDateTime(
      context,
      _startsAt,
    );

    if (value == null) return;

    setState(() {
      _startsAt = value;

      if (_endsAt.isBefore(_startsAt)) {
        _endsAt = _startsAt.add(
          const Duration(hours: 2),
        );
      }
    });
  }

  Future<void> _pickEnd() async {
    final value = await _pickDateTime(
      context,
      _endsAt,
    );

    if (value == null) return;

    setState(() {
      _endsAt = value;
    });
  }

  Future<void> _save() async {
    final title =
        _titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _error =
            'Please enter a session title.';
      });

      return;
    }

    if (!_endsAt.isAfter(_startsAt)) {
      setState(() {
        _error =
            'End time must be after start time.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.createSession(
        courseId: widget.courseId,
        title: title,
        startsAt: _startsAt,
        endsAt: _endsAt,
        lateAfterMinutes: _lateMinutes,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          const Text('Create attendance'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: 'Session title',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading:
                    const Icon(Icons.login),
                title:
                    const Text('Starts at'),
                subtitle: Text(
                  _TeacherCourseDetailPageState
                      ._formatDateTime(
                    _startsAt,
                  ),
                ),
                trailing: TextButton(
                  onPressed:
                      _saving ? null : _pickStart,
                  child: const Text('Change'),
                ),
              ),
              ListTile(
                contentPadding:
                    EdgeInsets.zero,
                leading:
                    const Icon(Icons.logout),
                title: const Text('Ends at'),
                subtitle: Text(
                  _TeacherCourseDetailPageState
                      ._formatDateTime(
                    _endsAt,
                  ),
                ),
                trailing: TextButton(
                  onPressed:
                      _saving ? null : _pickEnd,
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _lateMinutes,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Mark late after',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Immediately'),
                  ),
                  DropdownMenuItem(
                    value: 5,
                    child: Text('5 minutes'),
                  ),
                  DropdownMenuItem(
                    value: 10,
                    child: Text('10 minutes'),
                  ),
                  DropdownMenuItem(
                    value: 15,
                    child: Text('15 minutes'),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text('30 minutes'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _lateMinutes = value;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const _SmallLoader()
              : const Text('Open session'),
        ),
      ],
    );
  }
}

// =========================================================
// Attendance session bottom sheet
// =========================================================

class _AttendanceSessionSheet
    extends StatefulWidget {
  final AttendanceSession session;
  final AttendanceService service;

  const _AttendanceSessionSheet({
    required this.session,
    required this.service,
  });

  @override
  State<_AttendanceSessionSheet>
      createState() =>
          _AttendanceSessionSheetState();
}

class _AttendanceSessionSheetState
    extends State<_AttendanceSessionSheet> {
  late Future<List<Map<String, dynamic>>>
      _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _recordsFuture = widget.service
        .getSessionRecords(widget.session.id);
  }

  Future<void> _updateStatus(
    String recordId,
    String status,
  ) async {
    await widget.service.updateRecordStatus(
      recordId: recordId,
      status: status,
    );

    if (!mounted) return;

    setState(_loadRecords);
  }

  Future<void> _closeSession() async {
    await widget.service.closeSession(
      widget.session.id,
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.96,
      builder: (
        context,
        scrollController,
      ) {
        return FutureBuilder<
            List<Map<String, dynamic>>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                32,
              ),
              children: [
                Text(
                  widget.session.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Code: ${widget.session.checkInCode}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.session.status ==
                    'open')
                  FilledButton.icon(
                    onPressed: _closeSession,
                    icon: const Icon(
                      Icons.lock_rounded,
                    ),
                    label: const Text(
                      'Close attendance',
                    ),
                  ),
                const SizedBox(height: 18),
                if (snapshot.connectionState ==
                    ConnectionState.waiting)
                  const Padding(
                    padding:
                        EdgeInsets.all(40),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  Text(
                    snapshot.error.toString(),
                  )
                else if ((snapshot.data ??
                        const [])
                    .isEmpty)
                  const _CourseEmptyTab(
                    icon: Icons.groups_outlined,
                    title: 'No records',
                    message:
                        'There are no enrolled students in this session.',
                  )
                else
                  for (final record
                      in snapshot.data!) ...[
                    _AttendanceRecordTile(
                      record: record,
                      onStatusChanged: (
                        status,
                      ) {
                        _updateStatus(
                          record['id'] as String,
                          status,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        );
      },
    );
  }
}

// =========================================================
// Grade dialog
// =========================================================

class _GradeSubmissionDialog
    extends StatefulWidget {
  final _SubmissionRow submission;
  final SupabaseClient supabase;

  const _GradeSubmissionDialog({
    required this.submission,
    required this.supabase,
  });

  @override
  State<_GradeSubmissionDialog>
      createState() =>
          _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState
    extends State<_GradeSubmissionDialog> {
  late final TextEditingController
      _scoreController;

  late final TextEditingController
      _feedbackController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _scoreController =
        TextEditingController(
      text: widget.submission.score
              ?.toStringAsFixed(0) ??
          '',
    );

    _feedbackController =
        TextEditingController(
      text: widget.submission.feedback,
    );
  }

  Future<void> _save() async {
    final score = double.tryParse(
      _scoreController.text.trim(),
    );

    if (score == null ||
        score < 0 ||
        score >
            widget.submission.maxScore) {
      setState(() {
        _error =
            'Score must be between 0 and '
            '${widget.submission.maxScore.toStringAsFixed(0)}.';
      });

      return;
    }

    final user =
        widget.supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _error = 'You are not signed in.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.supabase
          .from('submissions')
          .update({
        'score': score,
        'feedback':
            _feedbackController.text.trim(),
        'status': 'graded',
        'graded_by': user.id,
        'graded_at':
            DateTime.now().toIso8601String(),
      }).eq(
        'id',
        widget.submission.id,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.submission.studentName,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget
                    .submission.assignmentTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Student answer',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.submission.answerText
                        .trim()
                        .isEmpty
                    ? 'No written answer.'
                    : widget
                        .submission.answerText,
              ),
              if (widget.submission.filePath !=
                  null) ...[
                const SizedBox(height: 10),
                Text(
                  'Attached file: '
                  '${widget.submission.filePath}',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: _scoreController,
                enabled: !_saving,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'Score / ${widget.submission.maxScore.toStringAsFixed(0)}',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _feedbackController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 7,
                decoration:
                    const InputDecoration(
                  labelText: 'Feedback',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const _SmallLoader()
              : const Text('Save grade'),
        ),
      ],
    );
  }
}

// =========================================================
// Edit course
// =========================================================

class _EditCourseDialog
    extends StatefulWidget {
  final Course course;

  const _EditCourseDialog({
    required this.course,
  });

  @override
  State<_EditCourseDialog> createState() =>
      _EditCourseDialogState();
}

class _EditCourseDialogState
    extends State<_EditCourseDialog> {
  late final TextEditingController
      _titleController;

  late final TextEditingController
      _descriptionController;

  late final TextEditingController
      _overviewController;

  late String _status;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(
      text: widget.course.title,
    );

    _descriptionController =
        TextEditingController(
      text: widget.course.description,
    );

    _overviewController =
        TextEditingController(
      text: widget.course.overview,
    );

    _status = widget.course.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _overviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit course'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration:
                    const InputDecoration(
                  labelText: 'Course title',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    _overviewController,
                minLines: 3,
                maxLines: 7,
                decoration:
                    const InputDecoration(
                  labelText: 'Overview',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration:
                    const InputDecoration(
                  labelText: 'Status',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'draft',
                    child: Text('Draft'),
                  ),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Published'),
                  ),
                  DropdownMenuItem(
                    value: 'archived',
                    child: Text('Archived'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _status = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title =
                _titleController.text.trim();

            if (title.isEmpty) return;

            Navigator.pop(
              context,
              _CourseEditResult(
                title: title,
                description:
                    _descriptionController
                        .text
                        .trim(),
                overview:
                    _overviewController
                        .text
                        .trim(),
                status: _status,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// =========================================================
// Models local to page
// =========================================================

class _SubmissionRow {
  final String id;
  final String assignmentTitle;
  final String studentName;
  final String? avatarUrl;
  final String status;
  final DateTime? submittedAt;
  final double? score;
  final double maxScore;
  final String feedback;
  final String answerText;
  final String? filePath;

  const _SubmissionRow({
    required this.id,
    required this.assignmentTitle,
    required this.studentName,
    required this.status,
    required this.maxScore,
    required this.feedback,
    required this.answerText,
    this.avatarUrl,
    this.submittedAt,
    this.score,
    this.filePath,
  });

  factory _SubmissionRow.fromMap(
    Map<String, dynamic> map,
  ) {
    final assignment =
        map['assignment']
            as Map<String, dynamic>? ??
        const {};

    final student =
        map['student']
            as Map<String, dynamic>? ??
        const {};

    return _SubmissionRow(
      id: map['id'] as String,
      assignmentTitle:
          assignment['title'] as String? ??
              'Assignment',
      studentName:
          student['full_name'] as String? ??
              'Unnamed student',
      avatarUrl:
          student['avatar_url'] as String?,
      status:
          map['status'] as String? ??
              'draft',
      submittedAt:
          map['submitted_at'] == null
              ? null
              : DateTime.parse(
                  map['submitted_at']
                      as String,
                ),
      score: map['score'] == null
          ? null
          : (map['score'] as num)
              .toDouble(),
      maxScore:
          (assignment['max_score']
                      as num? ??
                  100)
              .toDouble(),
      feedback:
          map['feedback'] as String? ?? '',
      answerText:
          map['answer_text'] as String? ??
              '',
      filePath:
          map['file_path'] as String?,
    );
  }
}

class _CourseEditResult {
  final String title;
  final String description;
  final String overview;
  final String status;

  const _CourseEditResult({
    required this.title,
    required this.description,
    required this.overview,
    required this.status,
  });
}

class _CourseTabData {
  final String label;
  final IconData icon;

  const _CourseTabData({
    required this.label,
    required this.icon,
  });
}

// =========================================================
// Reusable widgets
// =========================================================

class _CreateMenuTile
    extends StatelessWidget {
  final String value;
  final IconData icon;
  final String title;
  final String subtitle;
  final BuildContext sheetContext;

  const _CreateMenuTile({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sheetContext,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(
          sheetContext,
          value,
        );
      },
    );
  }
}

class _CourseStatCard
    extends StatelessWidget {
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
    final colors =
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
              color: colors.primary,
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                color:
                    colors.onSurfaceVariant,
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
    final colors =
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
                  color: colors.primary,
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
    final colors =
        Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        28,
        76,
        28,
        100,
      ),
      children: [
        Icon(
          icon,
          size: 65,
          color: colors.primary.withValues(
            alpha: 0.65,
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
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ActionEmptyTab
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  const _ActionEmptyTab({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        28,
        76,
        28,
        100,
      ),
      children: [
        Icon(
          icon,
          size: 65,
          color: colors.primary.withValues(
            alpha: 0.65,
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
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        28,
        76,
        28,
        100,
      ),
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 60,
        ),
        const SizedBox(height: 16),
        const Text(
          'Unable to load course data',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar
    extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _ProfileAvatar({
    required this.name,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null &&
        avatarUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        backgroundImage:
            NetworkImage(avatarUrl!),
      );
    }

    final value = name.trim().isEmpty
        ? '?'
        : name.trim()[0].toUpperCase();

    return CircleAvatar(
      child: Text(value),
    );
  }
}

class _PublishChip
    extends StatelessWidget {
  final bool published;

  const _PublishChip({
    required this.published,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: published
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        published ? 'Published' : 'Draft',
        style: TextStyle(
          color: published
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AttendanceStatusChip
    extends StatelessWidget {
  final String status;

  const _AttendanceStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final label = switch (status) {
      'open' => 'Open',
      'closed' => 'Closed',
      'cancelled' => 'Cancelled',
      _ => 'Scheduled',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: status == 'open'
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SubmissionStatusChip
    extends StatelessWidget {
  final String status;

  const _SubmissionStatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AttendanceRecordTile
    extends StatelessWidget {
  final Map<String, dynamic> record;
  final ValueChanged<String>
      onStatusChanged;

  const _AttendanceRecordTile({
    required this.record,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final student =
        record['student']
            as Map<String, dynamic>? ??
        const {};

    final name =
        student['full_name'] as String? ??
            'Unnamed student';

    final avatarUrl =
        student['avatar_url'] as String?;

    final status =
        record['status'] as String? ??
            'absent';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(14),
        leading: _ProfileAvatar(
          name: name,
          avatarUrl: avatarUrl,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          status.toUpperCase(),
        ),
        trailing: PopupMenuButton<String>(
          initialValue: status,
          onSelected: onStatusChanged,
          itemBuilder: (_) {
            return const [
              PopupMenuItem(
                value: 'present',
                child: Text('Present'),
              ),
              PopupMenuItem(
                value: 'late',
                child: Text('Late'),
              ),
              PopupMenuItem(
                value: 'absent',
                child: Text('Absent'),
              ),
              PopupMenuItem(
                value: 'excused',
                child: Text('Excused'),
              ),
            ];
          },
        ),
      ),
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
    final colors =
        Theme.of(context).colorScheme;

    final label = switch (status) {
      'published' => 'Published',
      'archived' => 'Archived',
      _ => 'Draft',
    };

    final background = switch (status) {
      'published' => colors.primary,
      'archived' =>
        colors.surfaceContainerHighest,
      _ => colors.secondaryContainer,
    };

    final foreground = switch (status) {
      'published' => colors.onPrimary,
      'archived' =>
        colors.onSurfaceVariant,
      _ => colors.onSecondaryContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallLoader extends StatelessWidget {
  const _SmallLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    );
  }
}

// =========================================================
// Date/time helper
// =========================================================

Future<DateTime?> _pickDateTime(
  BuildContext context,
  DateTime initial,
) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(
      const Duration(days: 1),
    ),
    lastDate: DateTime(
      DateTime.now().year + 5,
    ),
  );

  if (date == null || !context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime:
        TimeOfDay.fromDateTime(initial),
  );

  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}