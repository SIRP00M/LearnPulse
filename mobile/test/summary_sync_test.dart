import 'l10n_helpers.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app_services.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/assignments/assignment_controllers.dart';
import 'package:learn_pulse/features/assignments/grading_controller.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_controllers.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart'
    show LoadState;
import 'package:learn_pulse/features/dashboard/dashboard.dart';
import 'package:learn_pulse/features/dashboard/dashboard_controller.dart';
import 'package:learn_pulse/features/dashboard/dashboard_pages.dart';
import 'package:learn_pulse/features/dashboard/summary_bus.dart';
import 'package:learn_pulse/features/home/role_home.dart';

import 'fakes.dart';

/// A dashboard "backend": the V7 figures are derived from the same fixture state the mutations change, so the
/// expected numbers come from data, not from hardcoded UI text. A request snapshots the data when it is made
/// (like the server does) and may be held on [gate] to simulate a slow response.
class _Backend extends FakeDashboardRepository {
  _Backend(this.assignments, this.attendance);

  final FakeAssignmentRepository assignments;
  final FakeAttendanceRepository attendance;
  Completer<void>? gate;
  Object? failure; // thrown by every call until cleared

  int _count(Iterable<Submission> s, SubmissionStatus st) =>
      s.where((x) => x.status == st).length;

  double? get _rate {
    final all = attendance.records.values.toList();
    if (all.isEmpty) return null;
    final here = all.where(
      (r) =>
          r.status == AttendanceStatus.present ||
          r.status == AttendanceStatus.late,
    );
    return 100 * here.length / all.length;
  }

  @override
  Future<TeacherDashboard> teacher() async {
    calls++;
    if (failure != null) throw failure!;
    final view = assignments.teacherView;
    final snapshot = TeacherDashboard.fromJson({
      'courses_active': 1,
      'awaiting_grading': _count(view, SubmissionStatus.submitted),
      'graded': _count(view, SubmissionStatus.graded),
      'returned': _count(view, SubmissionStatus.returned),
      'attendance_rate': _rate,
      'courses': [],
    });
    await gate?.future;
    return snapshot;
  }

  @override
  Future<StudentDashboard> student() async {
    calls++;
    if (failure != null) throw failure!;
    final mine = assignments.mine.values;
    final snapshot = StudentDashboard.fromJson({
      'courses_active': 1,
      'published_assignments': 2,
      'done': mine.length,
      'awaiting_grade': _count(mine, SubmissionStatus.submitted),
      'graded': _count(mine, SubmissionStatus.graded),
      'attendance_rate': _rate,
      'courses': [],
    });
    await gate?.future;
    return snapshot;
  }
}

class _Fixture {
  _Fixture() {
    assignments = FakeAssignmentRepository(
      assignments: [fakeAssignment()],
      teacherView: [fakeSubmission()],
    );
    attendance = FakeAttendanceRepository(sessions: [fakeSession()]);
    backend = _Backend(assignments, attendance);
    bus = SummaryBus();
  }

  late final FakeAssignmentRepository assignments;
  late final FakeAttendanceRepository attendance;
  late final _Backend backend;
  late final SummaryBus bus;

  DashboardController<TeacherDashboard> teacherSummary({bool active = true}) =>
      teacherDashboardController(backend, bus: bus)..active = active;

  DashboardController<StudentDashboard> studentSummary() =>
      studentDashboardController(backend, bus: bus);

  GradingController grading() => GradingController(
    assignments,
    assignments.assignments.first,
    assignments.teacherView.first,
    summaries: bus,
  );

  AppServices fakeServicesFor() => fakeServices(
    assignments: assignments,
    attendance: attendance,
    dashboard: backend,
    summaries: bus,
  );
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('controllers', () {
    test('1 grading a submission refreshes the affected summary', () async {
      final f = _Fixture();
      final t = f.teacherSummary();
      addTearDown(t.dispose);
      await t.load();
      expect(t.data!.awaitingGrading, 1);
      expect(t.data!.graded, 0);

      final g = f.grading()..scoreText = '80';
      addTearDown(g.dispose);
      await g.saveGrade();
      await _settle();

      expect(f.bus.revision, 1);
      expect(t.data!.awaitingGrading, 0); // from the backend, not guessed
      expect(t.data!.graded, 1);
    });

    test('2 returning work for revision shows the backend result', () async {
      final f = _Fixture();
      final t = f.teacherSummary();
      addTearDown(t.dispose);
      await t.load();
      final g = f.grading()..feedback = 'Add a conclusion.';
      addTearDown(g.dispose);
      await g.returnForRevision();
      await _settle();
      expect(t.data!.awaitingGrading, 0);
      expect(t.data!.returned, 1);
    });

    test('3 a student submission updates every student summary', () async {
      final f = _Fixture();
      // The dashboard tab and the profile tab each own a controller on the same bus.
      final dashboard = f.studentSummary();
      final profile = f.studentSummary();
      addTearDown(dashboard.dispose);
      addTearDown(profile.dispose);
      await dashboard.load();
      await profile.load();
      expect(dashboard.data!.done, 0);

      final s = SubmissionController(
        f.assignments,
        FakeFilePicker(),
        f.assignments.assignments.first,
        summaries: f.bus,
      )..answer = 'My answer';
      addTearDown(s.dispose);
      await s.submit();
      await _settle();

      for (final c in [dashboard, profile]) {
        expect(c.data!.done, 1);
        expect(c.data!.awaitingGrade, 1);
      }
    });

    test('4 an attendance mark refreshes the attendance figure', () async {
      final f = _Fixture();
      final t = f.teacherSummary();
      addTearDown(t.dispose);
      await t.load();
      expect(t.data!.attendanceRate, isNull); // nothing marked yet

      final c = SessionController(
        f.attendance,
        'c1',
        fakeSession(),
        summaries: f.bus,
      );
      addTearDown(c.dispose);
      await c.load();
      expect(await c.mark(c.roster.first, AttendanceStatus.present), isTrue);
      await _settle();
      expect(t.data!.attendanceRate, 100);

      expect(await c.mark(c.roster.first, AttendanceStatus.absent), isTrue);
      await _settle();
      expect(t.data!.attendanceRate, 0); // a correction refreshes too
    });

    test('6 a failed mutation does not invalidate', () async {
      final f = _Fixture();
      final t = f.teacherSummary();
      addTearDown(t.dispose);
      await t.load();
      f.assignments.gradeFailures.add(
        const AppError(AppErrorKind.network, 'offline'),
      );
      final g = f.grading()..scoreText = '80';
      addTearDown(g.dispose);
      await g.saveGrade();
      await _settle();

      expect(f.bus.revision, 0);
      expect(f.backend.calls, 1);
      expect(t.stale, isFalse);
      expect(t.data!.awaitingGrading, 1);
    });

    test(
      '7 an obsolete response is discarded; no duplicate requests',
      () async {
        final f = _Fixture();
        final t = f.teacherSummary();
        addTearDown(t.dispose);
        f.backend.gate = Completer<void>();
        final first = t.load(); // snapshot: 1 awaiting, held
        await _settle();

        final g = f.grading()..scoreText = '80';
        addTearDown(g.dispose);
        f.backend.gate!.complete(); // later requests are not held
        await g.saveGrade(); // invalidates while the first request is in flight
        await first;
        await _settle();

        expect(
          t.data!.awaitingGrading,
          0,
        ); // the pre-mutation answer was not applied
        expect(f.backend.calls, 2); // the held request plus exactly one refresh

        for (var i = 0; i < 5; i++) {
          t.activate(); // nothing is stale, so tab flicker costs nothing
          t.deactivate();
        }
        await _settle();
        expect(f.backend.calls, 2);
      },
    );

    test(
      '9 a failed refresh keeps the figures, then a retry succeeds',
      () async {
        final f = _Fixture();
        final t = f.teacherSummary();
        addTearDown(t.dispose);
        await t.load();
        f.backend.failure = const AppError(
          AppErrorKind.network,
          'No connection.',
        );
        final g = f.grading()..scoreText = '80';
        addTearDown(g.dispose);
        await g.saveGrade();
        await _settle();

        expect(t.state, LoadState.ready);
        expect(t.data!.awaitingGrading, 1); // the last loaded figures stay
        expect(t.error?.kind, AppErrorKind.network);
        expect(t.stale, isTrue);

        f.backend.failure = null;
        await t.load(showSpinner: false); // pull to refresh
        expect(t.error, isNull);
        expect(t.data!.awaitingGrading, 0);
        expect(t.stale, isFalse);
      },
    );

    test('an inactive summary reloads once, on activation', () async {
      final f = _Fixture();
      final t = f.teacherSummary(active: false);
      addTearDown(t.dispose);
      await t.load();
      f.bus.invalidate();
      f.bus.invalidate();
      await _settle();
      expect(f.backend.calls, 1); // nothing while hidden
      t.activate();
      t.activate(); // the second call joins the running request
      await _settle();
      expect(f.backend.calls, 2);
    });
  });

  group('screens', () {
    Future<void> pumpHome(
      WidgetTester tester,
      _Fixture f, {
      Profile profile = const Profile(role: AppRole.teacher, fullName: 'Ms T'),
    }) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = AuthController(
        FakeAuthRepository(hasSession: true, profile: profile),
      );
      addTearDown(auth.dispose);
      await auth.start();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          theme: buildTheme(Brightness.light, reduceMotion: true),
          home: RoleHome(
            controller: auth,
            profile: profile,
            services: f.fakeServicesFor(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder metric(String label, String value) => find.descendant(
      of: find.widgetWithText(MetricCard, label),
      matching: find.text(value),
    );

    testWidgets('5 Profile is not permanently stale after a mutation', (
      tester,
    ) async {
      final f = _Fixture();
      await pumpHome(tester, f);
      expect(find.text('1 submission awaiting grading'), findsOneWidget);
      final loadsBefore = f.backend.calls; // dashboard + profile

      // The teacher grades while on the Dashboard tab...
      final g = f.grading()..scoreText = '80';
      addTearDown(g.dispose);
      await g.saveGrade();
      await tester.pumpAndSettle();
      expect(
        f.backend.calls,
        loadsBefore + 1,
      ); // visible summary refreshed at once
      expect(find.text('1 submission awaiting grading'), findsNothing);

      // ...the hidden Profile summary refreshes when it becomes active.
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(f.backend.calls, loadsBefore + 2);
      expect(metric('Awaiting grading', '0'), findsOneWidget);

      // Flicking between tabs afterwards costs no further requests.
      for (final tab in ['Courses', 'Profile', 'Dashboard', 'Profile']) {
        await tester.tap(find.text(tab).last);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(f.backend.calls, loadsBefore + 2);
    });

    testWidgets('7 rapid switching with a stale summary sends one request', (
      tester,
    ) async {
      final f = _Fixture();
      await pumpHome(tester, f);
      await tester.tap(find.text('Courses').last);
      await tester.pumpAndSettle();
      final before = f.backend.calls;
      f.attendance.records['x|s1'] = const AttendanceRecord(
        sessionId: 'a1',
        studentId: 's1',
        status: AttendanceStatus.present,
        note: '',
        version: 1,
      );
      f.bus.invalidate(); // both summaries are now stale, neither is visible
      await tester.pump();
      expect(f.backend.calls, before);

      f.backend.gate = Completer<void>(); // hold the answer
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Profile').last);
        await tester.pump();
        await tester.tap(find.text('Courses').last);
        await tester.pump();
      }
      await tester.tap(find.text('Profile').last);
      await tester.pump();
      f.backend.gate!.complete();
      await tester.pumpAndSettle();

      expect(
        f.backend.calls,
        before + 1,
      ); // Profile only; Dashboard stayed hidden
      expect(metric('Attendance rate', '100%'), findsOneWidget);
    });

    testWidgets('9 an offline refresh keeps the figures and offers a retry', (
      tester,
    ) async {
      final f = _Fixture();
      await pumpHome(tester, f);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      f.backend.failure = const AppError(
        AppErrorKind.network,
        'No connection to the server.',
      );
      final g = f.grading()..scoreText = '80';
      addTearDown(g.dispose);
      await g.saveGrade();
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not refresh'), findsOneWidget);
      expect(metric('Awaiting grading', '1'), findsOneWidget); // last figures

      f.backend.failure = null;
      await tester.fling(
        find.textContaining('Teaching summary').first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not refresh'), findsNothing);
      expect(metric('Awaiting grading', '0'), findsOneWidget);
    });

    testWidgets('8 account switching never shows the previous summary', (
      tester,
    ) async {
      final f = _Fixture();
      f.assignments.mine['a1'] = fakeSubmission(); // the student's own work
      await pumpHome(tester, f); // teacher: 1 awaiting grading
      expect(find.text('1 submission awaiting grading'), findsOneWidget);

      // Sign-out disposes the signed-in tree (and with it every summary controller).
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: SizedBox(),
        ),
      );
      expect(find.text('To grade'), findsNothing);
      expect(
        f.bus.revision,
        0,
      ); // the bus holds a counter only, never any figures

      // The next account gets fresh controllers that read the backend again.
      final loads = f.backend.calls;
      f.assignments.teacherView = [];
      await pumpHome(
        tester,
        f,
        profile: const Profile(role: AppRole.student, fullName: 'Sam'),
      );
      expect(f.backend.calls, loads + 2);
      expect(
        find.text('To grade'),
        findsNothing,
      ); // no teacher figures on a student account
    });
  });
}
