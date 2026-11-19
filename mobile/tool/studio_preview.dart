// Isolated visual fixture runner. No Supabase initialization or network connection.
import 'package:flutter/material.dart';
import 'package:learn_pulse/app_services.dart';
import 'package:learn_pulse/l10n/app_localizations.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/courses/course.dart';
import 'package:learn_pulse/features/lessons/lesson.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/auth/sign_in_page.dart';
import 'package:learn_pulse/features/auth/forgot_password_page.dart';
import 'package:learn_pulse/features/auth/sign_up_page.dart';
import 'package:learn_pulse/features/home/role_home.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart';
import 'package:learn_pulse/features/courses/courses_page.dart';
import 'package:learn_pulse/features/courses/student_course_page.dart';
import 'package:learn_pulse/features/courses/teacher_course_page.dart';
import 'package:learn_pulse/features/assignments/assignment_controllers.dart';
import 'package:learn_pulse/features/assignments/student_assignment_pages.dart';
import 'package:learn_pulse/features/assignments/teacher_assignment_pages.dart';
import 'package:learn_pulse/features/assignments/grade_submission_page.dart';
import 'package:learn_pulse/features/lessons/lessons_controller.dart';
import 'package:learn_pulse/features/lessons/lessons_pages.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_controllers.dart';
import 'package:learn_pulse/features/attendance/attendance_pages.dart';
import 'package:learn_pulse/features/attendance/attendance_grid_page.dart';
import 'package:learn_pulse/features/profile/profile_pages.dart';
import 'package:learn_pulse/features/activities/student_activity_pages.dart';
import 'package:learn_pulse/features/activities/teacher_activity_pages.dart';
import 'package:learn_pulse/features/progress/progress_pages.dart';
import 'package:learn_pulse/features/tasks/tasks_page.dart';
import '../test/fakes.dart';

const previewRoutes = [
  'sign-in',
  'sign-up',
  'recovery',
  'student',
  'teacher',
  'student-courses',
  'teacher-courses',
  'student-course',
  'teacher-course',
  'teacher-class',
  'teacher-class-empty',
  'teacher-class-nosessions',
  'lesson',
  'lesson-editor',
  'assignment',
  'teacher-assignment',
  'grading',
  'attendance',
  'summary',
  'week',
  'profile',
  'account',
  'tasks',
  'tasks-teacher',
  'student-activities',
  'teacher-activity',
  'activity-form',
  'pending',
  'progress-teacher',
  'progress-student',
];

Future<Map<String, WidgetBuilder>> createPreviewRoutes({
  void Function(VoidCallback)? onDispose,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final student = const Profile(role: AppRole.student, fullName: 'Sam Learner');
  final teacher = const Profile(role: AppRole.teacher, fullName: 'Ms Tester');
  final auth = AuthController(
    FakeAuthRepository(hasSession: true, profile: student),
  );
  final teacherAuth = AuthController(
    FakeAuthRepository(hasSession: true, profile: teacher),
  );
  await auth.start();
  await teacherAuth.start();
  final course = fakeCourse(
    title: 'Algebra',
    description:
        'Think clearly. Solve creatively. Build your mathematical toolkit.',
  );
  final lesson = fakeLesson(
    title: 'Understanding motion',
    body:
        'Observe the world in motion.\n\nA moving object changes position over time. Start by choosing a reference point, then measure how far the object travels.\n\nTry it yourself\nRecord the distance a toy car travels in five seconds. Repeat three times and compare your results.',
  );
  final submission = fakeSubmission(
    answer:
        'I measured the distance three times and calculated the average. My observations show a consistent rate of change.',
  );
  final assignment = fakeAssignment(
    instructions:
        'Explain your method and show each step. Include a diagram or table if it helps communicate your thinking.',
    dueAt: DateTime.utc(2099, 11, 15, 9),
  );
  final attendance = FakeAttendanceRepository(
    sessions: [
      fakeSession(
        title: 'Studio workshop',
        startsAt: DateTime.utc(2026, 11, 13, 9),
      ),
    ],
    students: [
      (id: 's1', name: 'Sam Learner'),
      (id: 's2', name: 'Sue Learner'),
    ],
  );
  await attendance.mark(
    sessionId: 'a1',
    studentId: 's1',
    requestId: 'fixture',
    expectedVersion: 0,
    status: AttendanceStatus.present,
    note: '',
  );
  final services = fakeServices(
    courses: FakeCourseRepository(courses: [course]),
    assignments: FakeAssignmentRepository(
      assignments: [assignment],
      teacherView: [submission],
    ),
    lessons: FakeLessonRepository(
      lessons: [lesson],
      resources: [fakeResource(title: 'Workshop notes')],
    ),
    attendance: attendance,
    activities: seededActivities(),
    picker: FakeFilePicker()..next = fakeFile(name: 'observations.txt'),
  );
  final lessons = LessonsController(services.lessons, 'c1');
  await lessons.load();
  final courses = CoursesController(services.courses);
  await courses.load();
  final assignments = AssignmentsController(services.assignments, 'c1');
  await assignments.load();
  for (final dispose in [
    auth.dispose,
    teacherAuth.dispose,
    lessons.dispose,
    courses.dispose,
    assignments.dispose,
  ]) {
    onDispose?.call(dispose);
  }
  // Class-dashboard scenarios; each has its own isolated in-memory services.
  final fixtureToday = DateTime(2026, 11, 13);
  final classFull = await _classServices(course, lesson, full: true);
  final classEmpty = await _classServices(course, lesson, students: 0);
  final classNoSessions = await _classServices(course, lesson);
  final routes = <String, WidgetBuilder>{
    '/teacher-class': (_) => TeacherCoursePage(
      course: course,
      controller: courses,
      services: classFull,
      today: fixtureToday,
    ),
    '/teacher-class-empty': (_) => TeacherCoursePage(
      course: course,
      controller: courses,
      services: classEmpty,
      today: fixtureToday,
    ),
    '/teacher-class-nosessions': (_) => TeacherCoursePage(
      course: course,
      controller: courses,
      services: classNoSessions,
      today: fixtureToday,
    ),
    '/sign-in': (_) => SignInPage(controller: auth),
    '/sign-up': (_) => SignUpPage(controller: auth),
    '/recovery': (_) => ForgotPasswordPage(controller: auth),
    '/student': (_) =>
        RoleHome(controller: auth, profile: student, services: services),
    '/teacher': (_) =>
        RoleHome(controller: teacherAuth, profile: teacher, services: services),
    '/student-courses': (_) => Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: CoursesPage(profile: student, services: services),
    ),
    '/teacher-courses': (_) => Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: CoursesPage(profile: teacher, services: services),
    ),
    '/student-course': (_) =>
        StudentCoursePage(course: course, services: services),
    '/teacher-course': (_) => TeacherCoursePage(
      course: course,
      controller: courses,
      services: services,
    ),
    '/lesson': (_) => StudentLessonPage(
      lesson: lesson,
      controller: lessons,
      courseTitle: 'Algebra',
    ),
    '/lesson-editor': (_) => TeacherLessonPage(
      lessonId: lesson.id,
      controller: lessons,
      services: services,
    ),
    '/assignment': (_) => StudentAssignmentPage(
      assignment: assignment,
      existing: null,
      services: services,
    ),
    '/teacher-assignment': (_) => TeacherAssignmentPage(
      assignmentId: assignment.id,
      controller: assignments,
      services: services,
    ),
    '/grading': (_) => GradeSubmissionPage(
      assignment: assignment,
      submission: submission,
      services: services,
    ),
    '/attendance': (_) => TeacherSessionPage(
      controller: SessionController(
        services.attendance,
        'c1',
        attendance.sessions.first,
      ),
      archived: false,
    ),
    '/summary': (_) => AttendanceSummaryPage(
      controller: AttendanceSummaryController(services.attendance, 'c1'),
      teacher: true,
    ),
    '/week': (_) => AttendanceWeekGridPage(
      controller: WeekGridController(
        services.attendance,
        'c1',
        today: DateTime(2026, 11, 13),
      ),
      teacher: true,
    ),
    '/profile': (_) => Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ProfileTab(
        controller: auth,
        profile: student,
        services: services,
        onOpenCourses: () {},
      ),
    ),
    '/account': (_) => AccountPage(controller: auth, services: services),
    '/tasks': (_) => Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: TasksTab(profile: student, services: services),
    ),
    '/tasks-teacher': (_) => Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: TasksTab(profile: teacher, services: services),
    ),
    '/student-activities': (_) => StudentActivityWeekPage(
      services: services,
      courseId: 'c1',
      title: 'Algebra',
    ),
    '/teacher-activity': (_) => TeacherActivityPage(
      courseId: 'c1',
      activityId: 'act-read',
      services: services,
    ),
    '/activity-form': (_) =>
        ActivityFormPage(courseId: 'c1', services: services),
    '/pending': (_) => PendingQueuePage(services: services),
    '/progress-teacher': (_) => ProgressPage(
      services: services,
      courseId: 'c1',
      teacherView: true,
      studentId: 's1',
      studentName: 'Sam Learner',
    ),
    '/progress-student': (_) =>
        ProgressPage(services: services, courseId: 'c1', teacherView: false),
  };
  return routes;
}

/// Services for one teacher class scenario. [full] adds same-week sessions (two on one day),
/// varied marks, assignments and submissions; [students] 0 gives an empty class.
Future<AppServices> _classServices(
  Course course,
  Lesson lesson, {
  bool full = false,
  int students = 5,
}) async {
  const names = [
    'Sam Learner',
    'Sue Learner',
    'Priya Patel',
    'Tom Nguyen',
    'Amira Hassan',
  ];
  final roster = [
    for (var i = 0; i < students; i++) (id: 's${i + 1}', name: names[i]),
  ];
  final sessions = full
      ? [
          fakeSession(
            id: 'k1',
            title: 'Algebra review',
            startsAt: DateTime.utc(2026, 11, 9, 2),
          ),
          fakeSession(
            id: 'k2',
            title: 'Problem set lab',
            startsAt: DateTime.utc(2026, 11, 11, 2),
            closed: true,
          ),
          fakeSession(
            id: 'k3',
            title: 'Quiz',
            startsAt: DateTime.utc(2026, 11, 11, 7),
            closed: true,
          ),
          fakeSession(
            id: 'k4',
            title: 'Studio workshop',
            startsAt: DateTime.utc(2026, 11, 13, 2),
          ),
        ]
      : <AttendanceSession>[];
  final attendance = FakeAttendanceRepository(
    sessions: sessions,
    students: roster,
  );
  if (full) {
    const marks = {
      'k1': [
        AttendanceStatus.present,
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.absent,
        AttendanceStatus.present,
      ],
      'k2': [
        AttendanceStatus.present,
        AttendanceStatus.excused,
        AttendanceStatus.present,
        AttendanceStatus.present,
        AttendanceStatus.late,
      ],
      'k3': [
        AttendanceStatus.present,
        AttendanceStatus.present,
        AttendanceStatus.absent,
        AttendanceStatus.present,
        AttendanceStatus.present,
      ],
      'k4': [
        AttendanceStatus.present,
        AttendanceStatus.late,
        AttendanceStatus.present,
      ],
    };
    for (final e in marks.entries) {
      for (var i = 0; i < e.value.length; i++) {
        await attendance.mark(
          sessionId: e.key,
          studentId: 's${i + 1}',
          requestId: '${e.key}-$i',
          expectedVersion: 0,
          status: e.value[i],
          note: '',
        );
      }
    }
  }
  final assignments = full
      ? [
          fakeAssignment(
            id: 'a1',
            title: 'Essay',
            dueAt: DateTime.utc(2026, 11, 20, 9),
          ),
          fakeAssignment(
            id: 'a2',
            title: 'Problem set 3',
            dueAt: DateTime.utc(2026, 11, 16, 9),
          ),
        ]
      : <Assignment>[];
  return fakeServices(
    courses: FakeCourseRepository(
      courses: [course],
      roster: [
        for (final r in roster)
          RosterEntry(
            studentId: r.id,
            name: r.name,
            active: true,
            joinedAt: DateTime(2026, 11, 1),
          ),
      ],
    ),
    attendance: attendance,
    assignments: FakeAssignmentRepository(
      assignments: assignments,
      teacherView: full
          ? [
              fakeSubmission(name: 'Sam Learner'),
              fakeSubmission(
                name: 'Priya Patel',
                status: SubmissionStatus.graded,
                score: 88,
              ),
              fakeSubmission(name: 'Tom Nguyen'),
            ]
          : [],
    ),
    lessons: FakeLessonRepository(lessons: [lesson]),
    dashboard: FakeDashboardRepository(
      teacher: fakeTeacherDashboard(students: students, awaiting: full ? 1 : 0),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final routes = await createPreviewRoutes();
  runApp(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'LearnPulse · Isolated visual fixtures',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routes: routes,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Visual fixtures · Mock data')),
          body: ListView(
            children: [
              for (final route in previewRoutes)
                ListTile(
                  title: Text(route),
                  onTap: () => Navigator.pushNamed(context, '/$route'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
