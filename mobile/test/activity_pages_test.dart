import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app_services.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/features/activities/activity.dart';
import 'package:learn_pulse/features/activities/student_activity_pages.dart';
import 'package:learn_pulse/features/activities/teacher_activity_pages.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/assignments/student_assignment_pages.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/courses/class_overview.dart';
import 'package:learn_pulse/features/progress/progress_pages.dart';
import 'package:learn_pulse/features/tasks/tasks_page.dart';

import 'fakes.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class _Env {
  _Env() {
    activities = FakeActivityRepository();
    final today = _day(DateTime.now());
    for (final (id, title, policy) in [
      ('act-read', 'Reading Practice', ActivityPolicy.selfReported),
      ('act-journal', 'Research Journal', ActivityPolicy.teacherVerified),
      ('act-lab', 'Lab Preparation', ActivityPolicy.teacherMarked),
    ]) {
      activities.activities.add(
        FakeActivity(
          id: id,
          courseId: 'c1',
          title: title,
          policy: policy,
          schedules: [
            FakeSchedule(
              effectiveFrom: today.subtract(const Duration(days: 8)),
              weekdays: const [1, 2, 3, 4, 5, 6, 7],
            ),
          ],
        ),
      );
    }
    assignments = FakeAssignmentRepository(
      assignments: [
        fakeAssignment(
          id: 'as-late',
          title: 'Essay',
          dueAt: today.subtract(const Duration(days: 3)),
        ),
        fakeAssignment(
          id: 'as-soon',
          title: 'Quiz',
          dueAt: today.add(const Duration(days: 2)),
        ),
      ],
      mine: {
        'as-soon': fakeSubmission(
          assignmentId: 'as-soon',
          status: SubmissionStatus.submitted,
        ),
      },
    );
    attendance = FakeAttendanceRepository(sessions: [fakeSession()]);
    services = fakeServices(
      assignments: assignments,
      attendance: attendance,
      activities: activities,
    );
  }

  late final FakeActivityRepository activities;
  late final FakeAssignmentRepository assignments;
  late final FakeAttendanceRepository attendance;
  late final AppServices services;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 1600),
  double scale = 1,
  bool scaffold = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: l10nDelegates,
      supportedLocales: l10nLocales,
      key:
          UniqueKey(), // a fresh tree per pump: never reuse the previous environment's State
      theme: buildTheme(Brightness.light, reduceMotion: true),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: scaffold ? Scaffold(body: child) : child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('student', () {
    testWidgets(
      'daily activities: policy decides the action; the state changes from the server',
      (tester) async {
        final e = _Env();
        await _pump(
          tester,
          ListView(
            children: [
              StudentActivitiesSection(
                courseId: 'c1',
                courseTitle: 'Algebra',
                services: e.services,
              ),
            ],
          ),
        );
        expect(find.text('Reading Practice'), findsOneWidget);
        expect(find.text('Lab Preparation'), findsOneWidget);
        // Teacher-marked: status only, no student action.
        expect(
          find.widgetWithText(FilledButton, 'Mark as done'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilledButton, 'Submit for review'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Mark as done'));
        await tester.pumpAndSettle();
        expect(
          find.text('Done'),
          findsOneWidget,
        ); // refreshed through the SummaryBus, no manual refresh
        expect(find.widgetWithText(OutlinedButton, 'Withdraw'), findsOneWidget);
        expect(find.text('1 streak'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Submit for review'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'finished');
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
        await tester.pumpAndSettle();
        expect(find.text('Awaiting review'), findsOneWidget);

        // Withdrawing the self-reported entry puts it back to "To do".
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Withdraw').last,
        ); // Reading Practice sorts last by id
        await tester.pumpAndSettle();
        expect(find.text('Done'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a server failure shows its sentence and keeps the screen usable',
      (tester) async {
        final e = _Env();
        await _pump(
          tester,
          ListView(
            children: [
              StudentActivitiesSection(
                courseId: 'c1',
                courseTitle: 'Algebra',
                services: e.services,
              ),
            ],
          ),
        );
        e.activities.error = const AppError(
          AppErrorKind.conflict,
          'The deadline has passed',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Mark as done'));
        await tester.pumpAndSettle();
        expect(find.text('The deadline has passed'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Mark as done'),
          findsOneWidget,
        );
      },
    );

    testWidgets('empty and offline states use the shared panels', (
      tester,
    ) async {
      final e = _Env();
      e.activities.activities.clear();
      await _pump(
        tester,
        ListView(
          children: [
            StudentActivitiesSection(
              courseId: 'c1',
              courseTitle: 'Algebra',
              services: e.services,
            ),
          ],
        ),
      );
      expect(find.text('Nothing scheduled today'), findsOneWidget);

      final f = _Env();
      f.activities.error = const AppError(
        AppErrorKind.network,
        'No connection to the server.',
      );
      await _pump(
        tester,
        ListView(
          children: [
            StudentActivitiesSection(
              courseId: 'c1',
              courseTitle: 'Algebra',
              services: f.services,
            ),
          ],
        ),
      );
      expect(find.text('You are offline'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Reading Practice'), findsOneWidget);
    });

    testWidgets(
      'week view lists the days with occurrences and navigates weeks',
      (tester) async {
        final e = _Env();
        await _pump(
          tester,
          StudentActivityWeekPage(
            services: e.services,
            courseId: 'c1',
            title: 'Algebra',
          ),
          scaffold: false,
          size: const Size(400, 3000),
        );
        expect(find.text('This week'), findsOneWidget);
        expect(find.text('Reading Practice'), findsWidgets);
        await tester.tap(find.text('Next week'));
        await tester.pumpAndSettle();
        expect(find.text('Reading Practice'), findsWidgets);
      },
    );
  });

  group('teacher', () {
    testWidgets(
      'create form validates, then creates the activity through the repository',
      (tester) async {
        final e = _Env();
        e.activities.activities.clear();
        await _pump(
          tester,
          ActivityFormPage(courseId: 'c1', services: e.services),
          scaffold: false,
          size: const Size(400, 3000),
        );
        await tester.tap(find.text('Create activity'));
        await tester.pumpAndSettle();
        expect(find.text('Give the activity a title.'), findsOneWidget);
        expect(e.activities.activities, isEmpty);

        await tester.enterText(
          find.widgetWithText(TextField, 'Title'),
          'Vocabulary Review',
        );
        await tester.tap(find.text('Teacher verified'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create activity'));
        await tester.pumpAndSettle();
        expect(e.activities.activities.single.title, 'Vocabulary Review');
        expect(
          e.activities.activities.single.policy,
          ActivityPolicy.teacherVerified,
        );
        expect(e.activities.activities.single.schedules.single.weekdays, [
          1,
          2,
          3,
          4,
          5,
        ]);
        expect(
          e.activities.activities.single.schedules.single.timezone,
          'Asia/Bangkok',
        ); // approved default
      },
    );

    testWidgets(
      'overview lists activities with today\'s numbers; empty state when none',
      (tester) async {
        final e = _Env();
        await _pump(
          tester,
          ListView(
            children: [
              TeacherActivitiesSection(
                courseId: 'c1',
                services: e.services,
                archived: false,
              ),
            ],
          ),
        );
        expect(find.text('Reading Practice'), findsOneWidget);
        expect(find.textContaining('Today 0/2 done'), findsWidgets);
        expect(find.text('New activity'), findsOneWidget);
        expect(find.text('Review queue'), findsOneWidget);

        e.activities.activities.clear();
        final f = _Env();
        f.activities.activities.clear();
        await _pump(
          tester,
          ListView(
            children: [
              TeacherActivitiesSection(
                courseId: 'c1',
                services: f.services,
                archived: true,
              ),
            ],
          ),
        );
        expect(find.text('No activities yet'), findsOneWidget);
        expect(
          find.text('New activity'),
          findsNothing,
        ); // archived course: read-only
      },
    );

    testWidgets(
      'register: tap a cell, record completion; the grid reflects the server',
      (tester) async {
        final e = _Env();
        await _pump(
          tester,
          TeacherActivityPage(
            courseId: 'c1',
            activityId: 'act-lab',
            services: e.services,
          ),
          scaffold: false,
          size: const Size(400, 3000),
        );
        expect(find.text('Lab Preparation'), findsWidgets);
        final today = _day(DateTime.now());
        final label = RegExp('Student One, .* ${today.day}: To do');
        expect(find.bySemanticsLabel(label), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark completed'));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp('Student One, .* ${today.day}: Done')),
          findsOneWidget,
        );
        expect(e.activities.completions.values.single.status, 'teacher_marked');
      },
    );

    testWidgets('verification queue: approve, and reject only with a reason', (
      tester,
    ) async {
      final e = _Env();
      final today = _day(DateTime.now());
      e.activities.completions['act-journal|s1|${wireDate(today)}'] =
          FakeCompletion('pending', note: 'Chapter 3');
      e.activities.completions['act-journal|s2|${wireDate(today)}'] =
          FakeCompletion('pending');
      await _pump(
        tester,
        PendingQueuePage(services: e.services),
        scaffold: false,
        size: const Size(400, 3000),
      );
      expect(find.text('2 waiting for your decision.'), findsOneWidget);
      expect(find.text('Note: Chapter 3'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Approve').first);
      await tester.pumpAndSettle();
      expect(find.text('1 waiting for your decision.'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Reject'),
      ); // empty reason: nothing happens
      await tester.pumpAndSettle();
      expect(
        e.activities.completions.values
            .where((c) => c.status == 'pending')
            .length,
        1,
      );
      await tester.enterText(find.byType(TextField), 'Add more detail');
      await tester.pump(); // the confirm button enables on the next frame
      await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing to review'), findsOneWidget);
      expect(
        e.activities.completions.values
            .where((c) => c.status == 'rejected')
            .single
            .reason,
        'Add more detail',
      );
    });

    testWidgets('roster entry opens that student\'s progress', (tester) async {
      final e = _Env();
      final c = ClassOverviewController(e.services, 'c1');
      addTearDown(c.dispose);
      await c.load();
      String? opened;
      await _pump(
        tester,
        ListView(
          children: [
            ClassStudentAttendance(
              c: c,
              onOpenStudent: (id, name) => opened = id,
            ),
          ],
        ),
      );
      await tester.tap(find.text('Student One'));
      expect(opened, 's1');
    });
  });

  group('progress', () {
    testWidgets(
      'teacher view: factual figures with denominators from the server data',
      (tester) async {
        final e = _Env();
        e.attendance.records['a1|s1'] = const AttendanceRecord(
          sessionId: 'a1',
          studentId: 's1',
          status: AttendanceStatus.present,
          note: '',
          version: 1,
        );
        await _pump(
          tester,
          ProgressPage(
            services: e.services,
            courseId: 'c1',
            teacherView: true,
            studentId: 's1',
            studentName: 'Student One',
          ),
          scaffold: false,
          size: const Size(400, 4000),
        );
        expect(find.text('Student One'), findsWidgets);
        expect(
          find.textContaining('Private to you and this student'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            '1 of 2 published assignments submitted or graded',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('(1 of 1 counted sessions)'),
          findsOneWidget,
        );
        expect(
          find.text('Overdue'),
          findsWidgets,
        ); // the past-due essay, from the same status definition as Tasks
        expect(find.text('Reading Practice'), findsOneWidget);
        expect(
          find.textContaining('rank'),
          findsNothing,
        ); // no rankings or labels
      },
    );

    testWidgets(
      'a student sees only their own progress; a removed or foreign student gets "not found"',
      (tester) async {
        final e = _Env();
        await _pump(
          tester,
          ProgressPage(
            services: e.services,
            courseId: 'c1',
            teacherView: false,
          ),
          scaffold: false,
          size: const Size(400, 4000),
        );
        expect(
          find.text('Only you and your teacher can see this.'),
          findsOneWidget,
        );

        final f = _Env();
        (f.services.progress as FakeProgressRepository).error = const AppError(
          AppErrorKind.notFound,
          'Student not found',
        );
        await _pump(
          tester,
          ProgressPage(
            services: f.services,
            courseId: 'c1',
            teacherView: true,
            studentId: 'x',
          ),
          scaffold: false,
        );
        expect(find.text('Not found'), findsOneWidget);
      },
    );
  });

  group('tasks tab', () {
    testWidgets(
      'student: Today, Overdue and Completed use one status vocabulary and deep links open the destination',
      (tester) async {
        final e = _Env();
        const profile = Profile(role: AppRole.student, fullName: 'Sam');
        await _pump(
          tester,
          TasksTab(profile: profile, services: e.services),
          size: const Size(400, 3000),
        );
        expect(find.text('What to do'), findsOneWidget);
        expect(find.text('Reading Practice'), findsOneWidget); // today
        expect(find.text('To do'), findsWidgets);

        await tester.tap(find.text('Overdue'));
        await tester.pumpAndSettle();
        expect(find.text('Essay'), findsOneWidget);
        expect(find.text('Overdue'), findsWidgets);

        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();
        expect(find.text('Quiz'), findsOneWidget);
        expect(find.text('Awaiting review'), findsWidgets);

        // The essay's deep link reaches the existing assignment workspace.
        await tester.tap(find.text('Overdue').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Essay'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentAssignmentPage), findsOneWidget);
      },
    );

    testWidgets('student: modes, month grid and empty states', (tester) async {
      final e = _Env();
      e.activities.activities.clear();
      e.assignments.assignments.clear();
      const profile = Profile(role: AppRole.student, fullName: 'Sam');
      await _pump(
        tester,
        TasksTab(profile: profile, services: e.services),
        size: const Size(400, 3000),
      );
      expect(find.text('Nothing due today'), findsOneWidget);
      await tester.tap(find.text('Overdue'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing overdue'), findsOneWidget);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.byType(MonthGrid), findsOneWidget);
      expect(find.text('Nothing this month'), findsOneWidget);
    });

    testWidgets(
      'student: an offline refresh keeps the tasks and offers recovery',
      (tester) async {
        final e = _Env();
        const profile = Profile(role: AppRole.student, fullName: 'Sam');
        final tasks = e.services.tasks as FakeTaskRepository;
        tasks.error = const AppError(
          AppErrorKind.network,
          'No connection to the server.',
        );
        await _pump(
          tester,
          TasksTab(profile: profile, services: e.services),
          size: const Size(400, 3000),
        );
        expect(find.text('You are offline'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Reading Practice'), findsOneWidget);
      },
    );

    testWidgets(
      'account switch in place: the other role starts from fresh controllers and shows none of the previous rows',
      (tester) async {
        final e = _Env();
        tester.view.physicalSize = const Size(400, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Future<void> show(Profile p) async {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: l10nDelegates,
              supportedLocales: l10nLocales,
              theme: buildTheme(Brightness.light, reduceMotion: true),
              home: Scaffold(
                body: TasksTab(profile: p, services: e.services),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await show(const Profile(role: AppRole.student, fullName: 'Sam'));
        expect(find.text('Reading Practice'), findsOneWidget);
        await show(
          const Profile(role: AppRole.teacher, fullName: 'Ms T'),
        ); // same widget position, other account
        expect(find.text('Teaching calendar'), findsOneWidget);
        expect(find.text('Reading Practice'), findsNothing);
        expect(tester.takeException(), isNull);
        await show(const Profile(role: AppRole.student, fullName: 'Sue'));
        expect(find.text('What to do'), findsOneWidget);
        expect(find.text('Teaching calendar'), findsNothing);
      },
    );

    testWidgets(
      'teacher: calendar with verification workload, no student-only modes',
      (tester) async {
        final e = _Env();
        final today = _day(DateTime.now());
        e.activities.completions['act-journal|s1|${wireDate(today)}'] =
            FakeCompletion('pending');
        const profile = Profile(role: AppRole.teacher, fullName: 'Ms T');
        await _pump(
          tester,
          TasksTab(profile: profile, services: e.services),
          size: const Size(400, 3000),
        );
        expect(find.text('Teaching calendar'), findsOneWidget);
        expect(
          find.textContaining('1 activity submissions waiting for review'),
          findsOneWidget,
        );
        expect(find.text('Overdue'), findsNothing);
        expect(find.text('Completed'), findsNothing);
        expect(find.text('Today'), findsWidgets);
      },
    );
  });
}
