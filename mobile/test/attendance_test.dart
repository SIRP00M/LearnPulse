import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_controllers.dart';
import 'package:learn_pulse/features/attendance/attendance_pages.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart'
    show LoadState;

import 'fakes.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: l10nDelegates,
  supportedLocales: l10nLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

SessionController _session(
  FakeAttendanceRepository repo, {
  AttendanceSession? s,
}) {
  var n = 0;
  return SessionController(
    repo,
    'c1',
    s ?? fakeSession(),
    newId: () => 'req${++n}',
  );
}

void main() {
  group('models and time', () {
    test('status parsing and malformed rows', () {
      expect(AttendanceStatus.parse('late'), AttendanceStatus.late);
      expect(AttendanceStatus.parse('nope'), isNull);
      expect(
        AttendanceRecord.fromRow({
          'session_id': 'a',
          'student_id': 'b',
          'status': 'x',
        }),
        isNull,
      );
      expect(
        AttendanceSession.fromRow({
          'id': 'a',
          'title': 't',
          'starts_at': 'bad',
        }),
        isNull,
      );
      final r = AttendanceRecord.fromRow({
        'session_id': 'a',
        'student_id': 'b',
        'status': 'excused',
        'attendance_sessions': {
          'title': 'W1',
          'starts_at': '2026-11-10T06:30:00+00:00',
          'status': 'closed',
        },
      });
      expect(r!.sessionTitle, 'W1');
      expect(r.sessionClosed, isTrue);
      expect(r.sessionStartsAt!.isUtc, isTrue);
    });

    test('summary parsing keeps a null rate and tolerates missing counts', () {
      final s = AttendanceSummary.fromJson({
        'sessions_total': 3,
        'sessions_closed': 2,
        'students': [
          {
            'student_id': 'a',
            'full_name': 'A',
            'present': 2,
            'late': 1,
            'excused': 1,
            'absent': 0,
            'rate': 100.0,
          },
          {'student_id': 'b', 'full_name': 'B', 'rate': null},
          {'full_name': 'broken'},
        ],
      });
      expect(s.rows.length, 2);
      expect(s.rows[0].total, 4);
      expect(s.rows[1].rate, isNull);
      expect(ratePercent(null), 'No rate yet');
      expect(ratePercent(66.7), '66.7%');
      expect(ratePercent(100.0), '100%');
    });

    test(
      'Malaysia (UTC+8) and Thailand (UTC+7) render different wall clocks across midnight',
      () {
        final t = DateTime.utc(2026, 11, 10, 16, 30);
        expect(
          formatSessionTime(t, offset: const Duration(hours: 8)),
          'Wed 11 Nov 2026, 00:30',
        );
        expect(
          formatSessionTime(t, offset: const Duration(hours: 7)),
          'Tue 10 Nov 2026, 23:30',
        );
        expect(
          formatSessionTime(t, offset: Duration.zero),
          'Tue 10 Nov 2026, 16:30',
        );
      },
    );
  });

  group('AttendanceListController', () {
    test(
      'create reuses the key while input is unchanged and replay adds one session',
      () async {
        var n = 0;
        final repo = FakeAttendanceRepository()
          ..error = const AppError(AppErrorKind.network, 'lost');
        final c = AttendanceListController(repo, 'c1', newId: () => 'k${++n}');
        final when = DateTime.utc(2026, 11, 10, 6);
        expect(await c.create('Week 1', when), isFalse);
        expect(c.actionError!.kind, AppErrorKind.network);
        expect(await c.create('Week 1', when), isTrue);
        expect(repo.calls, ['create:Week 1:k1', 'create:Week 1:k1']);
        expect(repo.sessions.length, 1);
        expect(c.sessions.length, 1);
        // different content = a new action
        await c.create('Week 2', when);
        expect(repo.calls.last, 'create:Week 2:k2');
      },
    );

    test('title validation and load failure', () async {
      expect(AttendanceListController.validateTitle('  '), isNotNull);
      expect(AttendanceListController.validateTitle('x' * 121), isNotNull);
      expect(AttendanceListController.validateTitle('ok'), isNull);
      final repo = FakeAttendanceRepository()
        ..loadError = const AppError(AppErrorKind.network, 'down');
      final c = AttendanceListController(repo, 'c1');
      await c.load();
      expect(c.state, LoadState.error);
      repo.loadError = null;
      await c.load();
      expect(c.state, LoadState.ready);
      expect(c.sessions, isEmpty);
    });
  });

  group('SessionController', () {
    test('mark, correct, replay key reuse after a lost response', () async {
      final repo = FakeAttendanceRepository(sessions: [fakeSession()]);
      final c = _session(repo);
      await c.load();
      final s = c.roster.first;
      expect(c.unmarked, 1);

      repo.error = const AppError(AppErrorKind.network, 'lost');
      expect(await c.mark(s, AttendanceStatus.present), isFalse);
      expect(
        await c.mark(s, AttendanceStatus.present),
        isTrue,
      ); // same key reused
      final keys = repo.calls
          .where((x) => x.startsWith('mark:'))
          .map((x) => x.split(':').last)
          .toSet();
      expect(keys.length, 1);
      expect(c.records['s1']!.version, 1);
      expect(c.unmarked, 0);

      expect(
        await c.mark(s, AttendanceStatus.late, note: 'bus'),
        isTrue,
      ); // new content + version = new key
      expect(c.records['s1']!.status, AttendanceStatus.late);
      expect(c.records['s1']!.version, 2);
      expect(c.history.first.action, 'corrected');
      expect(c.history.first.oldStatus, AttendanceStatus.present);
    });

    test('a conflict refreshes data and tells the teacher to retry', () async {
      final repo = FakeAttendanceRepository(sessions: [fakeSession()]);
      final c = _session(repo);
      await c.load();
      final s = c.roster.first;
      await c.mark(s, AttendanceStatus.present);
      // another device corrects the record behind our back
      await repo.mark(
        sessionId: 'a1',
        studentId: 's1',
        requestId: 'other',
        expectedVersion: 1,
        status: AttendanceStatus.excused,
        note: '',
      );
      expect(await c.mark(s, AttendanceStatus.absent), isFalse);
      expect(c.actionError!.kind, AppErrorKind.conflict);
      expect(c.records['s1']!.status, AttendanceStatus.excused); // refreshed
      expect(
        await c.mark(s, AttendanceStatus.absent),
        isTrue,
      ); // retry with the new version
      expect(c.records['s1']!.version, 3);
    });

    test('note is limited to 500 characters locally', () async {
      final repo = FakeAttendanceRepository(sessions: [fakeSession()]);
      final c = _session(repo);
      await c.load();
      expect(
        await c.mark(c.roster.first, AttendanceStatus.late, note: 'n' * 501),
        isFalse,
      );
      expect(c.actionError!.kind, AppErrorKind.validation);
      expect(repo.calls, isEmpty);
    });

    test(
      'close marks unmarked students absent and blocks a second close',
      () async {
        final repo = FakeAttendanceRepository(sessions: [fakeSession()]);
        final c = _session(repo);
        await c.load();
        expect(await c.closeSession(), isTrue);
        expect(c.session.closed, isTrue);
        expect(c.records['s1']!.status, AttendanceStatus.absent);
        expect(await c.closeSession(), isFalse);
        expect(repo.calls.where((x) => x.startsWith('close:')).length, 1);
      },
    );
  });

  group('widgets', () {
    testWidgets(
      'teacher section: empty state, then a created session is listed',
      (tester) async {
        final repo = FakeAttendanceRepository();
        await tester.pumpWidget(
          _wrap(
            TeacherAttendanceSection(
              courseId: 'c1',
              services: fakeServices(attendance: repo),
              archived: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('No attendance sessions yet'),
          findsOneWidget,
        );
        await tester.tap(find.text('New session'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'Lab 1');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();
        expect(find.text('Lab 1'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
      },
    );

    testWidgets('archived course disables session creation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TeacherAttendanceSection(
            courseId: 'c1',
            services: fakeServices(),
            archived: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'New session'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('teacher session page marks a student and closes the session', (
      tester,
    ) async {
      final repo = FakeAttendanceRepository(sessions: [fakeSession()]);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: TeacherSessionPage(controller: _session(repo), archived: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Student One'), findsOneWidget);
      expect(find.text('Not marked yet'), findsOneWidget);
      await tester.tap(find.text('Late'));
      await tester.pumpAndSettle();
      expect(find.text('Not marked yet'), findsNothing);
      expect(repo.records['a1|s1']!.status, AttendanceStatus.late);
      await tester.ensureVisible(find.textContaining('Close session'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Close session'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('will be recorded as Absent'),
        findsNothing,
      ); // everyone is marked
      await tester.tap(find.widgetWithText(FilledButton, 'Close session'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Session closed'), findsOneWidget);
    });

    testWidgets(
      'student section shows rate, counts and local session records; empty state',
      (tester) async {
        final repo = FakeAttendanceRepository(
          sessions: [fakeSession(closed: true)],
        );
        await tester.pumpWidget(
          _wrap(
            StudentAttendanceSection(
              courseId: 'c1',
              services: fakeServices(attendance: repo),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No attendance recorded yet'), findsOneWidget);

        await repo.mark(
          sessionId: 'a1',
          studentId: 's1',
          requestId: 'r',
          expectedVersion: 0,
          status: AttendanceStatus.late,
          note: 'bus delay',
        );
        await tester.pumpWidget(
          _wrap(
            StudentAttendanceSection(
              key: UniqueKey(),
              courseId: 'c1',
              services: fakeServices(attendance: repo),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Attendance rate: 100%'), findsOneWidget);
        expect(find.bySemanticsLabel('Late: 1'), findsOneWidget);
        expect(find.text('Week 1'), findsOneWidget);
        expect(find.textContaining('bus delay'), findsOneWidget);
        expect(
          find.text('Late'),
          findsNWidgets(2),
        ); // summary label + record pill
      },
    );

    testWidgets('student section shows an error with retry at 320x568', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeAttendanceRepository()
        ..loadError = const AppError(
          AppErrorKind.network,
          'No connection to the server.',
        );
      await tester.pumpWidget(
        _wrap(
          StudentAttendanceSection(
            courseId: 'c1',
            services: fakeServices(attendance: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No connection to the server.'), findsOneWidget);
      repo.loadError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No attendance recorded yet'), findsOneWidget);
    });

    testWidgets(
      'teacher session page fits 320x568 with four status chips per student',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = FakeAttendanceRepository(sessions: [fakeSession()]);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: l10nDelegates,
            supportedLocales: l10nLocales,
            home: TeacherSessionPage(
              controller: _session(repo),
              archived: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ChoiceChip), findsNWidgets(4));
      },
    );

    testWidgets('summary page lists counts and the rate definition', (
      tester,
    ) async {
      final repo = FakeAttendanceRepository(
        sessions: [fakeSession(closed: true)],
      );
      await repo.mark(
        sessionId: 'a1',
        studentId: 's1',
        requestId: 'r',
        expectedVersion: 0,
        status: AttendanceStatus.present,
        note: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: AttendanceSummaryPage(
            controller: AttendanceSummaryController(repo, 'c1'),
            teacher: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Student One'), findsOneWidget);
      expect(find.textContaining('100%'), findsOneWidget);
      expect(find.textContaining('Excused is not counted'), findsOneWidget);
    });
  });
}
