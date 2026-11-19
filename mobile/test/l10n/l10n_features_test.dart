import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/formatting.dart';
import 'package:learn_pulse/features/activities/student_activity_pages.dart';
import 'package:learn_pulse/features/activities/teacher_activity_pages.dart';
import 'package:learn_pulse/features/attendance/attendance_pages.dart';
import 'package:learn_pulse/features/progress/progress_pages.dart';
import 'package:learn_pulse/features/tasks/tasks_page.dart';
import 'package:learn_pulse/features/tasks/today_section.dart';
import 'package:learn_pulse/l10n/app_localizations.dart';
import 'package:learn_pulse/features/assignments/grade_submission_page.dart';
import 'package:learn_pulse/features/assignments/student_assignment_pages.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart';
import 'package:learn_pulse/features/courses/courses_page.dart';
import 'package:learn_pulse/features/courses/student_course_page.dart';
import 'package:learn_pulse/features/courses/teacher_course_page.dart';
import 'package:learn_pulse/features/dashboard/dashboard_pages.dart';
import 'package:learn_pulse/features/lessons/lessons_pages.dart';

import '../fakes.dart';
import '../l10n_helpers.dart';

typedef _Build = Widget Function();

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  ValueNotifier<Locale> locale, {
  Size size = const Size(393, 780),
  double scale = 1,
}) async {
  await initFormatting();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ValueListenableBuilder<Locale>(
      valueListenable: locale,
      builder: (_, value, _) => MaterialApp(
        localizationsDelegates: l10nDelegates,
        supportedLocales: l10nLocales,
        locale: value,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const teacher = Profile(role: AppRole.teacher, fullName: 'Tia');
  const student = Profile(role: AppRole.student, fullName: 'Sam');

  final pages = <String, _Build>{
    'student tasks': () => TasksTab(profile: student, services: fakeServices()),
    'teacher calendar': () =>
        TasksTab(profile: teacher, services: fakeServices()),
    'today': () => SingleChildScrollView(
      child: TodayTasksSection(services: fakeServices(), onOpenTasks: () {}),
    ),
    'month grid': () => SingleChildScrollView(
      child: MonthGrid(
        month: DateTime(2026, 11),
        counts: const {},
        selected: null,
        onSelect: (_) {},
      ),
    ),
    'student activities': () => SingleChildScrollView(
      child: StudentActivitiesSection(
        courseId: 'c1',
        courseTitle: 'Algebra',
        services: fakeServices(),
      ),
    ),
    'teacher activities': () => SingleChildScrollView(
      child: TeacherActivitiesSection(
        courseId: 'c1',
        services: fakeServices(),
        archived: false,
      ),
    ),
    'student attendance': () => SingleChildScrollView(
      child: StudentAttendanceSection(courseId: 'c1', services: fakeServices()),
    ),
    'teacher attendance': () => SingleChildScrollView(
      child: TeacherAttendanceSection(
        courseId: 'c1',
        services: fakeServices(),
        archived: false,
      ),
    ),
    'student progress': () => ProgressPage(
      courseId: 'c1',
      teacherView: false,
      services: fakeServices(),
    ),
    'teacher progress': () => ProgressPage(
      courseId: 'c1',
      studentId: 's1',
      teacherView: true,
      services: fakeServices(),
    ),
    'teacher dashboard': () =>
        TeacherDashboardView(services: fakeServices(), displayName: 'Tia'),
    'student dashboard': () =>
        StudentDashboardView(services: fakeServices(), displayName: 'Sam'),
    'courses list (student)': () =>
        CoursesPage(profile: student, services: fakeServices()),
    'courses list (teacher)': () =>
        CoursesPage(profile: teacher, services: fakeServices()),
    'teacher course': () {
      final services = fakeServices();
      return TeacherCoursePage(
        course: fakeCourse(),
        controller: CoursesController(services.courses),
        services: services,
      );
    },
    'student course': () =>
        StudentCoursePage(course: fakeCourse(), services: fakeServices()),
    'lessons': () =>
        StudentLessonsSection(courseId: 'c1', services: fakeServices()),
    'student assignment': () => StudentAssignmentPage(
      assignment: fakeAssignment(),
      existing: null,
      services: fakeServices(),
    ),
    'teacher grade page': () {
      final sub = fakeSubmission(answer: 'Student essay');
      return GradeSubmissionPage(
        assignment: fakeAssignment(maxScore: 50),
        submission: sub,
        services: fakeServices(
          assignments: FakeAssignmentRepository(teacherView: [sub]),
        ),
      );
    },
  };

  for (final e in pages.entries) {
    for (final lang in const ['th', 'ms']) {
      for (final w in const [320.0, 393.0]) {
        testWidgets('${e.key} fits ${w.toInt()}dp x2.0 in $lang', (
          tester,
        ) async {
          await _pump(
            tester,
            e.value(),
            ValueNotifier(Locale(lang)),
            size: Size(w, 780),
            scale: 2.0,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('tasks switch language in place without fetching again', (
    tester,
  ) async {
    final services = fakeServices();
    final repo = services.tasks as FakeTaskRepository;
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);
    await _pump(tester, TasksTab(profile: student, services: services), locale);
    final state = tester.state(find.byType(TasksTab));
    final calls = repo.calls;
    for (final code in ['th', 'ms', 'en']) {
      locale.value = Locale(code);
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(TasksTab)));
      expect(find.text(l.taskHeaderTitle), findsOneWidget);
      expect(tester.state(find.byType(TasksTab)), same(state));
      expect(repo.calls, calls);
    }
  });

  testWidgets('language switch retranslates and keeps the typed answer', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('en'));
    await _pump(
      tester,
      StudentAssignmentPage(
        assignment: fakeAssignment(),
        existing: null,
        services: fakeServices(),
      ),
      locale,
    );
    await tester.enterText(find.byType(TextField), 'My typed answer');
    await tester.pump();
    expect(find.text('Your response'), findsOneWidget);

    locale.value = const Locale('th');
    await tester.pumpAndSettle();
    expect(find.text('Your response'), findsNothing);
    expect(find.text('คำตอบของคุณ'), findsWidgets);
    expect(find.text('My typed answer'), findsOneWidget);

    locale.value = const Locale('ms');
    await tester.pumpAndSettle();
    expect(find.text('Respons anda'), findsOneWidget);
    expect(find.text('My typed answer'), findsOneWidget);
  });

  testWidgets('dashboard retranslates on switch', (tester) async {
    final locale = ValueNotifier(const Locale('en'));
    await _pump(
      tester,
      StudentDashboardView(services: fakeServices(), displayName: 'Sam'),
      locale,
    );
    expect(find.text('Hello, Sam'), findsOneWidget);
    locale.value = const Locale('ms');
    await tester.pumpAndSettle();
    expect(find.text('Helo, Sam'), findsOneWidget);
  });
}
