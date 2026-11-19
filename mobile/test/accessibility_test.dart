import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_controllers.dart';
import 'package:learn_pulse/features/attendance/attendance_grid_page.dart';
import 'package:learn_pulse/features/attendance/attendance_pages.dart';
import 'package:learn_pulse/features/dashboard/dashboard_pages.dart';

import 'fakes.dart';

/// Narrow phone + system font at 200%: nothing may overflow and primary controls stay reachable.
Widget _big(Widget child) => MaterialApp(
  localizationsDelegates: l10nDelegates,
  supportedLocales: l10nLocales,
  builder: (context, w) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: w!,
  ),
  home: child,
);

void _narrow(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('teacher and student dashboards at 320 px and 200% text', (
    tester,
  ) async {
    _narrow(tester);
    final services = fakeServices();
    await tester.pumpWidget(
      _big(Scaffold(body: TeacherDashboardView(services: services))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      _big(Scaffold(body: StudentDashboardView(services: services))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'attendance section, session page and grid at 320 px and 200% text',
    (tester) async {
      _narrow(tester);
      final repo = FakeAttendanceRepository(
        sessions: [fakeSession(startsAt: DateTime.now().toUtc())],
      );
      await repo.mark(
        sessionId: 'a1',
        studentId: 's1',
        requestId: 'r',
        expectedVersion: 0,
        status: AttendanceStatus.late,
        note: 'bus',
      );
      final services = fakeServices(attendance: repo);
      await tester.pumpWidget(
        _big(
          Scaffold(
            body: SingleChildScrollView(
              child: TeacherAttendanceSection(
                courseId: 'c1',
                services: services,
                archived: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _big(
          TeacherSessionPage(
            key: UniqueKey(),
            controller: SessionController(repo, 'c1', fakeSession()),
            archived: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _big(
          AttendanceWeekGridPage(
            key: UniqueKey(),
            controller: WeekGridController(repo, 'c1'),
            teacher: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _big(
          Scaffold(
            body: SingleChildScrollView(
              child: StudentAttendanceSection(
                courseId: 'c1',
                services: services,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'status is never colour-only: every grid mark has an icon and a letter',
    (tester) async {
      final repo = FakeAttendanceRepository(
        sessions: [fakeSession(startsAt: DateTime.now().toUtc(), closed: true)],
      );
      for (final st in AttendanceStatus.values) {
        await repo.mark(
          sessionId: 'a1',
          studentId: 's${st.index}',
          requestId: st.wire,
          expectedVersion: 0,
          status: st,
          note: '',
        );
      }
      final grid = FakeAttendanceRepository(
        sessions: repo.sessions,
        students: [
          for (final st in AttendanceStatus.values)
            (id: 's${st.index}', name: st.label),
        ],
      );
      grid.records.addAll(repo.records);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: AttendanceWeekGridPage(
            controller: WeekGridController(grid, 'c1'),
            teacher: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final letter in ['P', 'L', 'E', 'A']) {
        expect(find.text(letter), findsWidgets);
      }
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.cancel_outlined), findsWidgets);
    },
  );
}
