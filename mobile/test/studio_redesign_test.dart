import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/core/ui.dart';
import 'package:learn_pulse/core/academic.dart';
import 'package:learn_pulse/features/assignments/student_assignment_pages.dart';
import 'package:learn_pulse/features/assignments/grade_submission_page.dart';
import 'package:learn_pulse/features/attendance/attendance_controllers.dart';
import 'package:learn_pulse/features/attendance/attendance_pages.dart';
import 'package:learn_pulse/features/lessons/lessons_controller.dart';
import 'package:learn_pulse/features/lessons/lessons_pages.dart';
import 'package:learn_pulse/features/dashboard/dashboard_pages.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/home/role_home.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'fakes.dart';

void main() {
  testWidgets(
    'Teacher portal prioritizes welcome action and service access on a normal phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const profile = Profile(role: AppRole.teacher, fullName: 'Ms Tester');
      final controller = AuthController(
        FakeAuthRepository(hasSession: true, profile: profile),
      );
      addTearDown(controller.dispose);
      await controller.start();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          theme: buildTheme(Brightness.light),
          home: RoleHome(
            controller: controller,
            profile: profile,
            services: fakeServices(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getBottomRight(find.widgetWithText(FilledButton, 'Open courses'))
            .dy,
        lessThan(tester.getTopLeft(find.byType(NavigationBar)).dy),
      );
      expect(find.byType(AcademicServices), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Teacher uses a grading register; Student keeps the task hero', (
    tester,
  ) async {
    final services = fakeServices();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: l10nDelegates,
        supportedLocales: l10nLocales,
        home: Scaffold(body: TeacherDashboardView(services: services)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('teaching-review-focus')), findsOneWidget);
    expect(find.byType(StudioTask), findsNothing);
    expect(find.byKey(const Key('teacher-priority')), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: l10nDelegates,
        supportedLocales: l10nLocales,
        home: Scaffold(body: StudentDashboardView(services: services)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StudioTask), findsOneWidget);
    expect(find.textContaining('Essay · Algebra'), findsOneWidget);
  });

  testWidgets(
    'Recorded attendance stays visually enabled and reselecting sends nothing',
    (tester) async {
      final repo = FakeAttendanceRepository(sessions: [fakeSession()]);
      await repo.mark(
        sessionId: 'a1',
        studentId: 's1',
        requestId: 'seed',
        expectedVersion: 0,
        status: AttendanceStatus.present,
        note: '',
      );
      final before = repo.calls.length;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: TeacherSessionPage(
            controller: SessionController(repo, 'c1', fakeSession()),
            archived: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Present'),
      );
      expect(chip.selected, isTrue);
      expect(chip.onSelected, isNotNull);
      chip.onSelected!(false);
      await tester.pumpAndSettle();
      expect(repo.calls.length, before);
    },
  );
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Studio workflows 320dp ${brightness.name} text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = FakeAssignmentRepository(teacherView: [fakeSubmission()]);
        final lessonRepo = FakeLessonRepository(
          lessons: [fakeLesson()],
          resources: [fakeResource()],
        );
        final lessonController = LessonsController(lessonRepo, 'c1');
        await lessonController.load();
        addTearDown(lessonController.dispose);
        final attendance = FakeAttendanceRepository(sessions: [fakeSession()]);
        final services = fakeServices(
          assignments: repo,
          lessons: lessonRepo,
          attendance: attendance,
        );
        final pages = <Widget>[
          StudentAssignmentPage(
            assignment: fakeAssignment(),
            existing: null,
            services: services,
          ),
          GradeSubmissionPage(
            assignment: fakeAssignment(),
            submission: fakeSubmission(),
            services: services,
          ),
          StudentLessonPage(lesson: fakeLesson(), controller: lessonController),
          TeacherLessonPage(
            lessonId: 'l1',
            controller: lessonController,
            services: services,
          ),
          TeacherSessionPage(
            controller: SessionController(attendance, 'c1', fakeSession()),
            archived: false,
          ),
        ];
        for (final page in pages) {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: l10nDelegates,
              supportedLocales: l10nLocales,
              theme: buildTheme(brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: page,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: page.runtimeType.toString(),
          );
          for (var i = 0; i < 7; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -400),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.runtimeType} scroll $i',
            );
          }
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }

  testWidgets('Flat rows keep the entire status readable at 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: l10nDelegates,
        supportedLocales: l10nLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: StudioListItem(
                title: 'A long and meaningful assignment title',
                detail: 'Due tomorrow · Course resources',
                icon: Icons.assignment_outlined,
                status: const StatusPill(
                  'Returned for revision',
                  tone: Tone.attention,
                ),
                onTap: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('A long and meaningful assignment title'));
    expect(opened, isTrue);
  });

  test('Studio text pairs meet normal-text contrast in both themes', () {
    for (final brightness in Brightness.values) {
      final s = buildTheme(brightness).colorScheme;
      for (final pair in [
        (s.primary, s.onPrimary),
        (s.primaryContainer, s.onPrimaryContainer),
        (s.surface, s.onSurface),
        (s.surfaceContainerLow, s.onSurfaceVariant),
      ]) {
        final a = pair.$1.computeLuminance(), b = pair.$2.computeLuminance();
        final contrast = ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    }
  });
}
