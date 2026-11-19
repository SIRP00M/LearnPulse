import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/courses/course.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

void main() {
  group('Course models', () {
    test('Course.fromRow parses embedded owner and rejects unknown status', () {
      final c = Course.fromRow({
        'id': 'a',
        'owner_id': 'o',
        'title': 'T',
        'description': null,
        'status': 'archived',
        'created_at': '2030-01-01T00:00:00Z',
        'owner': {'full_name': 'Tia'},
      })!;
      expect(c.archived, isTrue);
      expect(c.teacherName, 'Tia');
      expect(c.description, '');
      expect(
        Course.fromRow({'id': 'a', 'title': 'T', 'status': 'weird'}),
        isNull,
      );
    });

    test('JoinResult maps server answers', () {
      expect(
        JoinResult.fromJson({'joined': true, 'title': 'X'}).outcome,
        JoinOutcome.joined,
      );
      expect(
        JoinResult.fromJson({'joined': false, 'reason': 'removed'}).outcome,
        JoinOutcome.removed,
      );
      expect(
        JoinResult.fromJson({
          'joined': false,
          'reason': 'invalid_code',
        }).outcome,
        JoinOutcome.invalidCode,
      );
    });

    test('RosterEntry hides the name of removed students', () {
      final r = RosterEntry.fromRow({
        'student_id': 's',
        'status': 'removed',
        'joined_at': '2030-01-01T00:00:00Z',
        'student': null,
      })!;
      expect(r.name, isNull);
      expect(r.active, isFalse);
    });
  });

  group('CoursesController', () {
    test(
      'empty list -> ready with no courses; failure -> error with retry',
      () async {
        final repo = FakeCourseRepository()
          ..listFailures.add(const SocketException('offline'));
        final c = CoursesController(repo);
        await c.load();
        expect(c.state, LoadState.error);
        expect(c.loadError!.kind, AppErrorKind.network);
        await c.load();
        expect(c.state, LoadState.ready);
        expect(c.courses, isEmpty);
      },
    );

    test('a failed refresh keeps the stale list visible', () async {
      final repo = FakeCourseRepository(courses: [fakeCourse()]);
      final c = CoursesController(repo);
      await c.load();
      repo.listFailures.add(const SocketException('offline'));
      await c.load(showSpinner: false);
      expect(c.state, LoadState.ready);
      expect(c.courses.length, 1);
      expect(c.loadError, isNotNull);
    });

    test('create returns the join code and refreshes the list', () async {
      final repo = FakeCourseRepository();
      final c = CoursesController(repo);
      await c.load();
      final created = await c.create('  Physics ', ' Intro ');
      expect(created!.joinCode, 'NEWCODE2');
      expect(repo.calls, contains('create:Physics'));
      expect(c.courses.single.title, 'Physics');
    });

    test('create failure is reported, list unchanged, busy cleared', () async {
      final repo = FakeCourseRepository()
        ..createError = const PostgrestException(message: 'x', code: 'PT403');
      final c = CoursesController(repo);
      await c.load();
      expect(await c.create('A', ''), isNull);
      expect(c.actionError!.kind, AppErrorKind.forbidden);
      expect(c.busy, isFalse);
      expect(c.courses, isEmpty);
    });

    test('join normalises the code and refreshes on success', () async {
      final repo = FakeCourseRepository();
      final c = CoursesController(repo);
      await c.load();
      final r = await c.join(' abcd2345 ');
      expect(r!.outcome, JoinOutcome.joined);
      expect(repo.calls, contains('join:ABCD2345'));
      expect(c.courses.single.title, 'Algebra');
      expect(c.notice, contains('Algebra'));
    });

    test('invalid and removed answers do not add a course', () async {
      for (final outcome in [JoinOutcome.invalidCode, JoinOutcome.removed]) {
        final repo = FakeCourseRepository()..joinResult = JoinResult(outcome);
        final c = CoursesController(repo);
        await c.load();
        expect((await c.join('ABCD2345'))!.outcome, outcome);
        expect(c.courses, isEmpty);
      }
    });

    test('throttling (PT429) surfaces a rate-limit error', () async {
      final repo = FakeCourseRepository()
        ..joinError = const PostgrestException(message: 'x', code: 'PT429');
      final c = CoursesController(repo);
      await c.load();
      expect(await c.join('ABCD2345'), isNull);
      expect(c.actionError!.kind, AppErrorKind.rateLimited);
    });

    test('rapid double submit sends one request', () async {
      final repo = FakeCourseRepository()..gate = Completer<void>();
      final c = CoursesController(repo);
      await c.load();
      final a = c.create('A', '');
      final b = c.create('A', '');
      repo.gate!.complete();
      await Future.wait([a, b]);
      expect(repo.calls.where((x) => x.startsWith('create')).length, 1);
    });

    test('update / archive reloads the list', () async {
      final repo = FakeCourseRepository(courses: [fakeCourse()]);
      final c = CoursesController(repo);
      await c.load();
      expect(await c.update('c1', status: CourseStatus.archived), isTrue);
      expect(c.courses.single.archived, isTrue);
      repo.updateError = const PostgrestException(message: 'x', code: 'PT404');
      expect(await c.update('c1', title: 'x'), isFalse);
      expect(c.actionError!.kind, AppErrorKind.notFound);
    });
  });

  group('CourseDetailController', () {
    test('loads code and roster; removal refreshes', () async {
      final repo = FakeCourseRepository(
        roster: [fakeMember('s1', 'Sam'), fakeMember('s2', 'Sue')],
      );
      final d = CourseDetailController(repo, 'c1');
      await d.load();
      expect(d.state, LoadState.ready);
      expect(d.joinCode, 'ABCD2345');
      expect(d.roster.length, 2);
      await d.remove('s1');
      expect(d.roster.where((r) => r.active).length, 1);
    });

    test('permission loss (PT404) is an error state, not a crash', () async {
      final repo = FakeCourseRepository()
        ..codeError = const PostgrestException(message: 'x', code: 'PT404');
      final d = CourseDetailController(repo, 'c1');
      await d.load();
      expect(d.state, LoadState.error);
      expect(d.error!.kind, AppErrorKind.notFound);
    });
  });
}
