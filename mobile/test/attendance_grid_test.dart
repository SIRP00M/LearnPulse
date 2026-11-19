import 'l10n_helpers.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_controllers.dart';
import 'package:learn_pulse/features/attendance/attendance_grid_page.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart'
    show LoadState;

import 'fakes.dart';
import 'ui_test_helpers.dart';

// Wednesday 11 Nov 2026 -> the week is Mon 9 Nov .. Sun 15 Nov (device-local weeks).
final _today = DateTime(2026, 11, 11, 9);

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize <= 20 ? fontSize * 2 : fontSize;
  @override
  double get textScaleFactor => 2;
}

AttendanceSession _s(
  String id,
  String title,
  DateTime localStart, {
  bool closed = true,
}) => AttendanceSession(
  id: id,
  courseId: 'c1',
  title: title,
  startsAt: localStart.toUtc(),
  closed: closed,
  version: 2,
);

Future<FakeAttendanceRepository> _repo({String? viewer}) async {
  final repo = FakeAttendanceRepository(
    sessions: [
      _s('a1', 'Mon class', DateTime(2026, 11, 9, 10)),
      _s('a2', 'Tue morning', DateTime(2026, 11, 10, 9)),
      _s('a3', 'Tue evening', DateTime(2026, 11, 10, 18)),
      _s('old', 'Last week', DateTime(2026, 11, 3, 10)),
    ],
    students: [
      (id: 's1', name: 'Student One'),
      (id: 's2', name: 'Student Two'),
    ],
  )..viewerId = viewer;
  Future<void> mark(String s, String st, AttendanceStatus v) => repo.mark(
    sessionId: s,
    studentId: st,
    requestId: '$s$st',
    expectedVersion: 0,
    status: v,
    note: '',
  );
  await mark('a1', 's1', AttendanceStatus.present);
  await mark('a1', 's2', AttendanceStatus.absent);
  await mark('a2', 's1', AttendanceStatus.late);
  await mark('a3', 's1', AttendanceStatus.excused); // s2 unmarked on a3
  await mark('old', 's1', AttendanceStatus.absent);
  return repo;
}

void main() {
  testWidgets(
    'nonlinear 200% weekly names have enough height for two readable lines',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const _NonlinearScaler()),
            child: child!,
          ),
          home: AttendanceWeekGridPage(
            controller: WeekGridController(await _repo(), 'c1', today: _today),
            teacher: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Student One'));
      final node = find.text('Student One');
      final widget = tester.widget<Text>(node);
      final painter = TextPainter(
        text: TextSpan(
          text: widget.data,
          style: DefaultTextStyle.of(
            tester.element(node),
          ).style.merge(widget.style),
        ),
        textDirection: TextDirection.ltr,
        textScaler: const _NonlinearScaler(),
        maxLines: 2,
      )..layout(maxWidth: tester.getSize(node).width);
      expect(tester.getSize(node).height, greaterThanOrEqualTo(painter.height));
      painter.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  group('WeekGridController', () {
    test(
      'week bounds, only this week\'s sessions, status mapping, several sessions per day',
      () async {
        final c = WeekGridController(await _repo(), 'c1', today: _today);
        await c.load();
        expect(c.weekStart, DateTime(2026, 11, 9));
        expect(c.days.length, 7);
        expect(c.days.last, DateTime(2026, 11, 15));
        expect(c.sessions.map((s) => s.id), [
          'a1',
          'a2',
          'a3',
        ]); // last week excluded
        expect(c.sessionsOn(DateTime(2026, 11, 10)).length, 2);
        expect(c.sessionsOn(DateTime(2026, 11, 12)), isEmpty);
        expect(c.statusOf('s1', 'a2'), AttendanceStatus.late);
        expect(
          c.statusOf('s2', 'a3'),
          isNull,
        ); // unmarked stays unmarked, not absent
        expect(c.roster.length, 2);
        expect(c.isCurrentWeek, isTrue);
      },
    );

    test('week navigation moves by seven days and back to this week', () async {
      final c = WeekGridController(await _repo(), 'c1', today: _today);
      await c.shiftWeeks(-1);
      expect(c.weekStart, DateTime(2026, 11, 2));
      expect(c.sessions.map((s) => s.id), ['old']);
      expect(c.statusOf('s1', 'old'), AttendanceStatus.absent);
      expect(c.isCurrentWeek, isFalse);
      await c.shiftWeeks(2); // month boundary: 16 Nov
      expect(c.weekStart, DateTime(2026, 11, 16));
      expect(c.sessions, isEmpty);
      await c.goToThisWeek();
      expect(c.weekStart, DateTime(2026, 11, 9));
      expect(c.sessions.length, 3);
    });

    test('week crossing a month and year boundary', () {
      final c = WeekGridController(
        FakeAttendanceRepository(),
        'c1',
        today: DateTime(2026, 12, 31),
      );
      expect(c.weekStart, DateTime(2026, 12, 28));
      expect(c.days.last, DateTime(2027, 1, 3));
    });

    test('a student sees only their own records (RLS-shaped fake)', () async {
      final c = WeekGridController(
        await _repo(viewer: 's1'),
        'c1',
        today: _today,
      );
      await c.load();
      expect(c.statusOf('s1', 'a1'), AttendanceStatus.present);
      expect(c.statusOf('s2', 'a1'), isNull);
    });

    test(
      'a slow answer for an old week never overwrites the week now shown',
      () async {
        final slow = _SlowRepo();
        final c = WeekGridController(slow, 'c1', today: _today);
        final first = c.load(); // this week, held back
        await Future<void>.delayed(Duration.zero);
        await c.shiftWeeks(1); // next week answers immediately
        slow.release();
        await first;
        expect(c.weekStart, DateTime(2026, 11, 16));
        expect(
          c.sessions,
          isEmpty,
        ); // the held-back answer for 9 Nov was dropped
      },
    );

    test('load failure then retry', () async {
      final repo = await _repo();
      repo.loadError = Exception('socket');
      final c = WeekGridController(repo, 'c1', today: _today);
      await c.load();
      expect(c.state, LoadState.error);
      repo.loadError = null;
      await c.load();
      expect(c.state, LoadState.ready);
    });
  });

  group('AttendanceWeekGridPage', () {
    testWidgets(
      'shows names, legend with shapes and letters, week range and accessible cell labels',
      (tester) async {
        final handle = tester.ensureSemantics();
        final c = WeekGridController(await _repo(), 'c1', today: _today);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: l10nDelegates,
            supportedLocales: l10nLocales,
            home: AttendanceWeekGridPage(controller: c, teacher: true),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('9 Nov – 15 Nov 2026'), findsOneWidget);
        await reveal(tester, find.text('Student One'));
        expect(find.text('Student One'), findsOneWidget);
        expect(find.text('P Present'), findsOneWidget);
        expect(find.text('Not marked'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
        expect(
          find.bySemanticsLabel(
            'Student One, Tue 10 Nov, Tue morning: Late; Tue evening: Excused',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'Student Two, Tue 10 Nov, Tue morning: not marked; Tue evening: not marked',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Student One, Thu 12 Nov: no session'),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'week buttons change the range; This week appears only off the current week',
      (tester) async {
        final c = WeekGridController(await _repo(), 'c1', today: _today);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: l10nDelegates,
            supportedLocales: l10nLocales,
            home: AttendanceWeekGridPage(controller: c, teacher: true),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('This week'), findsNothing);
        await tester.tap(find.byTooltip('Previous week'));
        await tester.pumpAndSettle();
        expect(find.text('2 Nov – 8 Nov 2026'), findsOneWidget);
        expect(find.text('This week'), findsOneWidget);
        await tester.tap(find.text('This week'));
        await tester.pumpAndSettle();
        expect(find.text('9 Nov – 15 Nov 2026'), findsOneWidget);
      },
    );

    testWidgets('student view says "My week" and lists only the student', (
      tester,
    ) async {
      final c = WeekGridController(
        await _repo(viewer: 's1'),
        'c1',
        today: _today,
      );
      // the real server returns only the caller in the summary; mimic it
      final repo = FakeAttendanceRepository(
        sessions: [_s('a1', 'Mon class', DateTime(2026, 11, 9, 10))],
        students: [(id: 's1', name: 'Student One')],
      );
      await repo.mark(
        sessionId: 'a1',
        studentId: 's1',
        requestId: 'x',
        expectedVersion: 0,
        status: AttendanceStatus.present,
        note: '',
      );
      final mine = WeekGridController(repo, 'c1', today: _today);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: AttendanceWeekGridPage(controller: mine, teacher: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(c.roster, isEmpty); // untouched controller
      expect(find.text('My week'), findsOneWidget);
      await reveal(tester, find.text('Student One'));
      expect(find.text('Student One'), findsOneWidget);
      expect(find.text('Student Two'), findsNothing);
    });

    testWidgets('empty roster and empty week explain themselves', (
      tester,
    ) async {
      final empty = FakeAttendanceRepository(students: []);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: AttendanceWeekGridPage(
            controller: WeekGridController(empty, 'c1', today: _today),
            teacher: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No students enrolled yet'), findsOneWidget);
    });

    testWidgets(
      'fits 320x568 and 320x480: the days scroll sideways, names stay visible',
      (tester) async {
        for (final size in const [Size(320, 568), Size(320, 480)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final c = WeekGridController(await _repo(), 'c1', today: _today);
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: l10nDelegates,
              supportedLocales: l10nLocales,
              home: AttendanceWeekGridPage(
                key: UniqueKey(),
                controller: c,
                teacher: true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await reveal(tester, find.text('Student One'));
          expect(find.text('Student One'), findsOneWidget);
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(-400, 0),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await reveal(tester, find.text('Student One'));
          expect(find.text('Student One'), findsOneWidget); // frozen column
        }
      },
    );
  });
}

class _SlowRepo extends FakeAttendanceRepository {
  _SlowRepo() : super(students: [(id: 's1', name: 'S')]) {
    sessions.add(_s('a1', 'Mon class', DateTime(2026, 11, 9, 10)));
  }
  final _gate = Completer<void>();
  void release() => _gate.complete();

  @override
  Future<List<AttendanceSession>> listSessionsBetween(
    String courseId,
    DateTime from,
    DateTime to,
  ) async {
    if (from == DateTime(2026, 11, 9)) await _gate.future;
    return super.listSessionsBetween(courseId, from, to);
  }
}
