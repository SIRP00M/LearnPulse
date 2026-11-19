import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart'
    show LoadState;
import 'package:learn_pulse/features/dashboard/dashboard.dart';
import 'package:learn_pulse/features/dashboard/dashboard_controller.dart';
import 'package:learn_pulse/features/dashboard/dashboard_pages.dart';

import 'fakes.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: l10nDelegates,
  supportedLocales: l10nLocales,
  home: Scaffold(body: child),
);

Future<void> _openFigures(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('All figures'),
    300,
    scrollable: find.byType(Scrollable),
  );
  await tester.ensureVisible(find.text('All figures'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('All figures'));
  await tester.pumpAndSettle();
}

void main() {
  group('models', () {
    test(
      'teacher parsing derives outstanding and tolerates null rate / missing lists',
      () {
        final d = fakeTeacherDashboard();
        expect(d.outstanding, 3);
        expect(d.attendanceRate, 66.7);
        final empty = TeacherDashboard.fromJson({});
        expect(empty.isEmpty, isTrue);
        expect(empty.attendanceRate, isNull);
        expect(empty.deadlines, isEmpty);
        expect(empty.outstanding, 0);
      },
    );

    test('student parsing keeps null rates and returned-work deadlines', () {
      final d = fakeStudentDashboard();
      expect(d.averagePercent, isNull);
      expect(d.deadlines.single.status, 'returned');
      expect(d.courses.single.progressPercent, 50.0);
      expect(fakeStudentDashboard(empty: true).isEmpty, isTrue);
    });

    test('percentLabel never shows a misleading 0% for missing data', () {
      expect(percentLabel(null), 'No data yet');
      expect(percentLabel(0), '0%');
      expect(percentLabel(66.7), '66.7%');
      expect(percentLabel(100), '100%');
    });
  });

  group('DashboardController', () {
    test(
      'first failure shows an error; a later failed refresh keeps the data',
      () async {
        final repo = FakeDashboardRepository()
          ..error = const AppError(AppErrorKind.network, 'down');
        final c = teacherDashboardController(repo);
        await c.load();
        expect(c.state, LoadState.error);
        await c.load();
        expect(c.state, LoadState.ready);
        expect(c.data!.activeStudents, 3);
        repo.error = const AppError(AppErrorKind.network, 'down');
        await c.load(showSpinner: false);
        expect(c.state, LoadState.ready); // old figures stay
        expect(c.error, isNotNull);
        await c.load(showSpinner: false);
        expect(c.error, isNull);
      },
    );

    test('overlapping loads collapse into one request', () async {
      final repo = FakeDashboardRepository();
      final c = studentDashboardController(repo);
      await Future.wait([c.load(), c.load(), c.load()]);
      expect(repo.calls, 1);
    });
  });

  group('widgets', () {
    testWidgets(
      'teacher dashboard shows server figures, definitions and recent items',
      (tester) async {
        final repo = FakeDashboardRepository();
        await tester.pumpWidget(
          _wrap(TeacherDashboardView(services: fakeServices(dashboard: repo))),
        );
        await tester.pumpAndSettle();
        await _openFigures(tester);
        expect(find.text('Awaiting grading'), findsWidgets);
        expect(find.textContaining('Submitted: 3 of 6'), findsOneWidget);
        expect(find.textContaining('66.7%'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('2/3'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('2/3'), findsOneWidget); // deadline progress
        await tester.scrollUntilVisible(
          find.textContaining('Attendance rate = (Present + Late)'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(
          find.textContaining('Attendance rate = (Present + Late)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('teacher zero-data state explains what to do', (tester) async {
      final repo = FakeDashboardRepository(
        teacher: fakeTeacherDashboard(active: 0, students: 0),
      );
      await tester.pumpWidget(
        _wrap(TeacherDashboardView(services: fakeServices(dashboard: repo))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing to show yet'), findsOneWidget);
    });

    testWidgets(
      'student dashboard: counts, no-data average, overdue hint and revise chip',
      (tester) async {
        final repo = FakeDashboardRepository();
        await tester.pumpWidget(
          _wrap(StudentDashboardView(services: fakeServices(dashboard: repo))),
        );
        await tester.pumpAndSettle();
        expect(find.text('1 assignment overdue'), findsOneWidget);
        expect(find.text('1 of 2 assignments done'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Revise'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('Revise'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('80/100'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('80/100'), findsOneWidget);
        await _openFigures(tester);
        await tester.scrollUntilVisible(
          find.text('1 of 2'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('1 of 2'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Average No data yet'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('Average No data yet'), findsOneWidget);
      },
    );

    testWidgets('student with no courses sees guidance; failure offers retry', (
      tester,
    ) async {
      final repo =
          FakeDashboardRepository(student: fakeStudentDashboard(empty: true))
            ..error = const AppError(
              AppErrorKind.network,
              'No connection to the server.',
            );
      await tester.pumpWidget(
        _wrap(StudentDashboardView(services: fakeServices(dashboard: repo))),
      );
      await tester.pumpAndSettle();
      expect(find.text('No connection to the server.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No courses yet'), findsOneWidget);
      expect(
        find.textContaining('join code from your teacher'),
        findsOneWidget,
      );
    });

    testWidgets('both dashboards fit 320x568 without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final services = fakeServices(dashboard: FakeDashboardRepository());
      await tester.pumpWidget(_wrap(TeacherDashboardView(services: services)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(_wrap(StudentDashboardView(services: services)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
