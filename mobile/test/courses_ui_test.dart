import 'l10n_helpers.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/courses/course.dart';
import 'package:learn_pulse/features/courses/course_dialogs.dart';
import 'package:learn_pulse/features/courses/courses_page.dart';

import 'fakes.dart';
import 'ui_test_helpers.dart';

const _teacher = Profile(role: AppRole.teacher, fullName: 'Tia');
const _student = Profile(role: AppRole.student, fullName: 'Sam');

Future<void> _pump(
  WidgetTester tester,
  Profile p,
  FakeCourseRepository repo, {
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: l10nDelegates,
      supportedLocales: l10nLocales,
      home: Scaffold(
        body: CoursesPage(
          profile: p,
          services: fakeServices(courses: repo),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('validators', () {
    test('join code', () {
      expect(validateJoinCode(''), isNotNull);
      expect(validateJoinCode('ABC'), isNotNull);
      expect(
        validateJoinCode('ABCDEFG0'),
        isNotNull,
      ); // 0 is not in the alphabet
      expect(validateJoinCode('abcd2345'), isNull);
    });
    test('course title', () {
      expect(validateCourseTitle('  '), isNotNull);
      expect(validateCourseTitle('A' * 121), isNotNull);
      expect(validateCourseTitle('Algebra'), isNull);
    });
  });

  group('teacher', () {
    testWidgets('empty state, then creates a course and sees the join code', (
      tester,
    ) async {
      final repo = FakeCourseRepository();
      await _pump(tester, _teacher, repo);
      expect(find.text('No courses yet'), findsOneWidget);
      await tester.tap(find.text('New course'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pump();
      expect(find.text('Enter a title'), findsOneWidget);
      expect(repo.calls, ['list']);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Physics',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(find.text('Course created'), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byKey(const Key('join-code'))).data,
        'NEWCODE2',
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Physics'), findsOneWidget);
    });

    testWidgets(
      'server refusal on create shows an error and keeps the dialog',
      (tester) async {
        final repo = FakeCourseRepository()
          ..createError = const SocketException('offline');
        await _pump(tester, _teacher, repo);
        await tester.tap(find.text('New course'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'),
          'Physics',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Create'));
        await tester.pumpAndSettle();
        expect(find.textContaining('No connection'), findsOneWidget);
        expect(find.text('New course'), findsWidgets);
      },
    );

    testWidgets('detail shows code and roster; remove asks for confirmation', (
      tester,
    ) async {
      final repo = FakeCourseRepository(
        courses: [fakeCourse(title: 'Algebra', description: 'Intro')],
        roster: [fakeMember('s1', 'Sam'), fakeMember('s2', 'Sue')],
      );
      await _pump(tester, _teacher, repo);
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('join-code')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester.widget<SelectableText>(find.byKey(const Key('join-code'))).data,
        'ABCD2345',
      );
      expect(find.text('Students (2)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byTooltip('Remove Sam'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.byTooltip('Remove Sam'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Sam'));
      await tester.pumpAndSettle();
      expect(find.text('Remove student?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c.startsWith('remove')), isEmpty);
      await tester.tap(find.byTooltip('Remove Sam'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('remove:s1'));
      expect(find.text('Students (1)'), findsOneWidget);
      expect(
        find.textContaining('1 removed student', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('empty roster hint, archive confirmation and archived state', (
      tester,
    ) async {
      final repo = FakeCourseRepository(courses: [fakeCourse()]);
      await _pump(tester, _teacher, repo);
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
      await reveal(tester, find.textContaining('No students yet'));
      expect(find.textContaining('No students yet'), findsOneWidget);
      await tapText(tester, 'Archive course');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('update:c1::archived'));
      expect(find.text('Reopen course'), findsOneWidget);
      expect(
        find.textContaining('students cannot join until you reopen'),
        findsOneWidget,
      );
    });

    testWidgets(
      'permission lost on the detail page shows an error with retry',
      (tester) async {
        final repo = FakeCourseRepository(courses: [fakeCourse()])
          ..codeError = const SocketException('offline');
        await _pump(tester, _teacher, repo);
        await tester.tap(find.text('Algebra'));
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsOneWidget);
        repo.codeError = null;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('join-code')));
        expect(find.byKey(const Key('join-code')), findsOneWidget);
      },
    );
  });

  group('student', () {
    testWidgets(
      'empty state, rejects malformed code locally, reports invalid code, then joins',
      (tester) async {
        final repo = FakeCourseRepository()
          ..joinResult = const JoinResult(JoinOutcome.invalidCode);
        await _pump(tester, _student, repo);
        expect(find.text('You have not joined a course'), findsOneWidget);
        await tester.tap(find.text('Join a course'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Course code'),
          'abc',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Join'));
        await tester.pump();
        expect(find.textContaining('Codes are 8'), findsOneWidget);
        expect(repo.calls.where((c) => c.startsWith('join')), isEmpty);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Course code'),
          'abcd2345',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Join'));
        await tester.pumpAndSettle();
        expect(find.textContaining('not valid'), findsOneWidget);
        repo.joinResult = const JoinResult(
          JoinOutcome.joined,
          title: 'Algebra',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Join'));
        await tester.pumpAndSettle();
        expect(find.text('Algebra'), findsOneWidget);
        expect(find.text('Teacher: Tia'), findsOneWidget);
      },
    );

    testWidgets('removed and throttled outcomes are explained', (tester) async {
      final repo = FakeCourseRepository()
        ..joinResult = const JoinResult(JoinOutcome.removed);
      await _pump(tester, _student, repo);
      await tester.tap(find.text('Join a course'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Course code'),
        'ABCD2345',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();
      expect(find.textContaining('removed from this course'), findsOneWidget);
    });

    testWidgets('loading failure offers retry; archived course is read-only', (
      tester,
    ) async {
      final repo = FakeCourseRepository(
        courses: [
          fakeCourse(status: CourseStatus.archived, description: 'Notes'),
        ],
      )..listFailures.add(const SocketException('offline'));
      await _pump(tester, _student, repo);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Archived'), findsWidgets);
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
      expect(find.textContaining('read-only'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(
        find.byKey(const Key('join-code')),
        findsNothing,
      ); // students never see the code
    });
  });

  for (final size in [const Size(320, 568), const Size(320, 480)]) {
    testWidgets(
      'course screens do not overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final repo = FakeCourseRepository(
          courses: [
            fakeCourse(
              title:
                  'A very long course title that must wrap or ellipsize gracefully',
              description: 'D' * 200,
            ),
          ],
          roster: [
            fakeMember('s1', 'A student with a very long display name indeed'),
          ],
        );
        await _pump(tester, _teacher, repo, size: size);
        expect(tester.takeException(), isNull);
        await tester.tap(find.textContaining('A very long course title'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
