import 'l10n_helpers.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/assignments/grade_submission_page.dart';
import 'package:learn_pulse/features/assignments/grading_controller.dart';
import 'package:learn_pulse/features/assignments/student_assignment_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';
import 'ui_test_helpers.dart';

int _n = 0;
String _id() => 'g-${++_n}';

const _conflict = PostgrestException(
  message: 'The submission changed; reload and try again',
  code: 'PT409',
);

GradingController _ctl(
  FakeAssignmentRepository repo,
  Submission s, {
  Assignment? a,
}) => GradingController(repo, a ?? fakeAssignment(maxScore: 50), s, newId: _id);

void main() {
  setUp(() => _n = 0);

  group('GradingController', () {
    test('score validation mirrors the server (integer, 0..max)', () {
      final c = _ctl(FakeAssignmentRepository(), fakeSubmission());
      for (final bad in ['', 'abc', '-1', '51', '4.5']) {
        c.setScore(bad);
        expect(c.scoreProblem(), isNotNull, reason: bad);
      }
      for (final ok in ['0', '25', '50']) {
        c.setScore(ok);
        expect(c.scoreProblem(), isNull, reason: ok);
      }
    });

    test(
      'grade sends the expected version and request id, then reflects the new state and history',
      () async {
        final sub = fakeSubmission(version: 3);
        final repo = FakeAssignmentRepository(teacherView: [sub]);
        final c = _ctl(repo, sub)
          ..setScore('40')
          ..setFeedback(' Good ');
        await c.saveGrade();
        expect(repo.calls, contains('grade:${sub.id}:v3:40'));
        expect(c.submission.status, SubmissionStatus.graded);
        expect(c.submission.version, 4);
        expect(c.notice, 'Grade saved.');
        expect(c.history.single.action, 'graded');
      },
    );

    test('out-of-range score or empty form never reaches the server', () async {
      final repo = FakeAssignmentRepository(teacherView: [fakeSubmission()]);
      final c = _ctl(repo, fakeSubmission())..setScore('99');
      await c.saveGrade();
      expect(c.error!.kind, AppErrorKind.validation);
      expect(repo.calls.where((x) => x.startsWith('grade')), isEmpty);
    });

    test(
      'network failure then retry reuses the SAME request id; a changed score gets a new one',
      () async {
        final sub = fakeSubmission();
        final repo = FakeAssignmentRepository(teacherView: [sub])
          ..gradeFailures.add(const SocketException('offline'));
        final c = _ctl(repo, sub)..setScore('40');
        await c.saveGrade();
        expect(c.error!.kind, AppErrorKind.network);
        expect(c.busy, isFalse);
        await c.saveGrade();
        expect(repo.gradeRequestIds.length, 2);
        expect(repo.gradeRequestIds[0], repo.gradeRequestIds[1]);

        final sub2 = fakeSubmission(assignmentId: 'a2');
        final repo2 = FakeAssignmentRepository(teacherView: [sub2])
          ..gradeFailures.add(const SocketException('offline'));
        final c2 = _ctl(repo2, sub2)..setScore('40');
        await c2.saveGrade();
        c2.setScore('41');
        await c2.saveGrade();
        expect(repo2.gradeRequestIds[0], isNot(repo2.gradeRequestIds[1]));
      },
    );

    test('rapid double tap sends a single request', () async {
      final sub = fakeSubmission();
      final repo = FakeAssignmentRepository(teacherView: [sub])
        ..gate = Completer<void>();
      final c = _ctl(repo, sub)..setScore('40');
      final a = c.saveGrade();
      final b = c.saveGrade();
      repo.gate!.complete();
      await Future.wait([a, b]);
      expect(repo.gradeRequestIds.length, 1);
    });

    test(
      'stale version: conflict keeps typed input and a reload shows the student\'s newer version',
      () async {
        final old = fakeSubmission(version: 2);
        final newer = fakeSubmission(version: 3, answer: 'student edited');
        final repo = FakeAssignmentRepository(teacherView: [newer])
          ..gradeFailures.add(_conflict);
        final c = _ctl(repo, old)
          ..setScore('33')
          ..setFeedback('my unsent feedback');
        await c.saveGrade();
        expect(c.needsReload, isTrue);
        expect(c.scoreText, '33');
        expect(c.feedback, 'my unsent feedback');
        await c.reload();
        expect(c.submission.version, 3);
        expect(c.submission.answer, 'student edited');
        expect(c.scoreText, '33');
        await c.saveGrade();
        expect(repo.calls.last, startsWith('events'));
        expect(
          repo.calls.where((x) => x.startsWith('grade:')).last,
          endsWith('v3:33'),
        );
      },
    );

    test(
      'return needs feedback; success marks the work returned and the form read-only',
      () async {
        final sub = fakeSubmission();
        final repo = FakeAssignmentRepository(teacherView: [sub]);
        final c = _ctl(repo, sub);
        await c.returnForRevision();
        expect(c.error!.kind, AppErrorKind.validation);
        c.setFeedback('Show working');
        await c.returnForRevision();
        expect(c.submission.status, SubmissionStatus.returned);
        expect(c.canAct, isFalse);
        expect(repo.calls, contains('return:${sub.id}:v1'));
      },
    );

    test(
      'regrading an already graded submission is allowed and uses the current version',
      () async {
        final sub = fakeSubmission(
          version: 2,
          status: SubmissionStatus.graded,
          score: 40,
          feedback: 'ok',
        );
        final repo = FakeAssignmentRepository(teacherView: [sub]);
        final c = _ctl(repo, sub);
        expect(c.scoreText, '40');
        c.setScore('45');
        await c.saveGrade();
        expect(c.submission.score, 45);
        expect(c.submission.version, 3);
      },
    );
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: l10nDelegates,
        supportedLocales: l10nLocales,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('GradeSubmissionPage', () {
    testWidgets(
      'shows the work, validates the score, grades, and lists the history',
      (tester) async {
        final sub = fakeSubmission(answer: 'Student essay');
        final repo = FakeAssignmentRepository(teacherView: [sub]);
        await pump(
          tester,
          GradeSubmissionPage(
            assignment: fakeAssignment(maxScore: 50),
            submission: sub,
            services: fakeServices(assignments: repo),
          ),
        );
        expect(find.text('Student essay'), findsOneWidget);
        expect(find.text('Awaiting grading'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Score (0–50)'),
          '99',
        );
        await tapText(tester, 'Save grade');
        await tester.pump();
        expect(find.text('Score must be between 0 and 50'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Score (0–50)'),
          '40',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Feedback'),
          'Well argued',
        );
        await tapText(tester, 'Save grade');
        await tester.pumpAndSettle();
        expect(find.text('Graded 40/50'), findsWidgets);
        expect(find.byKey(const Key('grade-notice')), findsOneWidget);
        expect(find.text('Save new grade'), findsOneWidget);
      },
    );

    testWidgets(
      'return for revision requires feedback, then the form becomes read-only',
      (tester) async {
        final sub = fakeSubmission();
        final repo = FakeAssignmentRepository(teacherView: [sub]);
        await pump(
          tester,
          GradeSubmissionPage(
            assignment: fakeAssignment(maxScore: 50),
            submission: sub,
            services: fakeServices(assignments: repo),
          ),
        );
        await tapText(tester, 'Return for revision');
        await tester.pump();
        expect(
          find.text('Explain what the student should revise.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Feedback'),
          'Add more detail',
        );
        await tapText(tester, 'Return for revision');
        await tester.pumpAndSettle();
        expect(find.textContaining('Waiting for the student'), findsOneWidget);
        expect(find.text('Save grade'), findsNothing);
      },
    );

    testWidgets('a version conflict offers reload and keeps what was typed', (
      tester,
    ) async {
      final sub = fakeSubmission(version: 2);
      final repo = FakeAssignmentRepository(
        teacherView: [fakeSubmission(version: 3)],
      )..gradeFailures.add(_conflict);
      await pump(
        tester,
        GradeSubmissionPage(
          assignment: fakeAssignment(maxScore: 50),
          submission: sub,
          services: fakeServices(assignments: repo),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Score (0–50)'),
        '20',
      );
      await tapText(tester, 'Save grade');
      await tester.pumpAndSettle();
      expect(find.text('Reload latest'), findsOneWidget);
      expect(find.text('20'), findsOneWidget); // typed score kept
    });

    for (final size in [const Size(320, 568), const Size(320, 480)]) {
      testWidgets(
        'layout at ${size.width.toInt()}x${size.height.toInt()} with long text and file name',
        (tester) async {
          final up = const UploadInfo(
            id: 'u',
            fileName:
                'a-very-long-attachment-file-name-for-layout-testing.docx',
            mimeType: 'x',
            sizeBytes: 9000,
            path: 'p',
          );
          final sub = fakeSubmission(
            answer: 'A' * 500,
            upload: up,
            name: 'Student with a very long display name',
          );
          final repo = FakeAssignmentRepository(teacherView: [sub]);
          await pump(
            tester,
            GradeSubmissionPage(
              assignment: fakeAssignment(title: 'T' * 100),
              submission: sub,
              services: fakeServices(assignments: repo),
            ),
            size: size,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('student result states', () {
    testWidgets('graded: score and feedback shown, form locked', (
      tester,
    ) async {
      final saved = fakeSubmission(
        version: 2,
        status: SubmissionStatus.graded,
        score: 40,
        feedback: 'Nice job',
      );
      final repo = FakeAssignmentRepository(mine: {'a1': saved});
      await pump(
        tester,
        StudentAssignmentPage(
          assignment: fakeAssignment(maxScore: 50),
          existing: saved,
          services: fakeServices(assignments: repo),
        ),
      );
      expect(find.text('Graded: 40/50'), findsOneWidget);
      expect(find.text('Feedback: Nice job'), findsOneWidget);
      expect(find.textContaining('graded and locked'), findsOneWidget);
      expect(find.text('Resubmit'), findsNothing);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets(
      'returned: feedback shown and the form stays open even after the deadline',
      (tester) async {
        final saved = fakeSubmission(
          version: 4,
          status: SubmissionStatus.returned,
          feedback: 'Show your working',
          answer: 'first try',
        );
        final repo = FakeAssignmentRepository(mine: {'a1': saved});
        final past = fakeAssignment(dueAt: DateTime(2000));
        await pump(
          tester,
          StudentAssignmentPage(
            assignment: past,
            existing: saved,
            services: fakeServices(assignments: repo),
          ),
        );
        expect(find.text('Returned for revision'), findsWidgets);
        expect(find.text('Feedback: Show your working'), findsOneWidget);
        expect(
          find.text('first try'),
          findsOneWidget,
        ); // previous answer prefilled
        await tester.enterText(find.byType(TextField), 'second try');
        await tapText(tester, 'Resubmit');
        await tester.pumpAndSettle();
        expect(
          repo.calls.where((c) => c.startsWith('submit')).last,
          startsWith('submit:4'),
        );
        expect(find.text('Submission saved.'), findsOneWidget);
      },
    );

    testWidgets('submitted (ungraded) after the deadline stays closed', (
      tester,
    ) async {
      final saved = fakeSubmission();
      final repo = FakeAssignmentRepository(mine: {'a1': saved});
      await pump(
        tester,
        StudentAssignmentPage(
          assignment: fakeAssignment(dueAt: DateTime(2000)),
          existing: saved,
          services: fakeServices(assignments: repo),
        ),
      );
      expect(find.textContaining('deadline has passed'), findsOneWidget);
      expect(find.text('Resubmit'), findsNothing);
    });

    testWidgets('list badges show Graded x/y and Returned', (tester) async {
      final repo = FakeAssignmentRepository(
        assignments: [
          fakeAssignment(id: 'a1', title: 'One', maxScore: 50),
          fakeAssignment(id: 'a2', title: 'Two'),
        ],
        mine: {
          'a1': fakeSubmission(
            assignmentId: 'a1',
            status: SubmissionStatus.graded,
            score: 40,
          ),
          'a2': fakeSubmission(
            assignmentId: 'a2',
            status: SubmissionStatus.returned,
            feedback: 'again',
          ),
        },
      );
      await pump(
        tester,
        Scaffold(
          body: StudentAssignmentsSection(
            courseId: 'c1',
            services: fakeServices(assignments: repo),
          ),
        ),
      );
      expect(find.text('Graded 40/50'), findsOneWidget);
      expect(find.text('Returned'), findsOneWidget);
    });
  });
}
