import 'l10n_helpers.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/assignments/assignment_controllers.dart';
import 'package:learn_pulse/features/assignments/student_assignment_pages.dart';
import 'package:learn_pulse/features/assignments/teacher_assignment_pages.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart'
    show LoadState;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';
import 'ui_test_helpers.dart';

int _idCounter = 0;
String _id() => 'req-${++_idCounter}';

SubmissionController _sub(
  FakeAssignmentRepository repo,
  FakeFilePicker picker, {
  Assignment? assignment,
  Submission? existing,
}) => SubmissionController(
  repo,
  picker,
  assignment ?? fakeAssignment(),
  existing: existing,
  newId: _id,
);

void main() {
  setUp(() => _idCounter = 0);

  group('models and validation', () {
    test('mimeForFileName mirrors the server allow-list', () {
      expect(mimeForFileName('a.PDF'), 'application/pdf');
      expect(mimeForFileName('a.jpeg'), 'image/jpeg');
      expect(mimeForFileName('a.exe'), isNull);
      expect(mimeForFileName('noext'), isNull);
      expect(mimeForFileName('trailing.'), isNull);
    });
    test('Assignment.fromRow rejects unknown status and computes closure', () {
      expect(
        Assignment.fromRow({'id': 'a', 'title': 'T', 'status': 'weird'}),
        isNull,
      );
      final a = Assignment.fromRow({
        'id': 'a',
        'title': 'T',
        'status': 'published',
        'due_at': '2020-01-01T00:00:00Z',
        'max_score': 50,
      })!;
      expect(a.isClosed(DateTime(2021)), isTrue);
      expect(a.maxScore, 50);
    });
    test('form validators', () {
      expect(validateAssignmentTitle(' '), isNotNull);
      expect(validateMaxScore('0'), isNotNull);
      expect(validateMaxScore('1001'), isNotNull);
      expect(validateMaxScore('50'), isNull);
    });
    test(
      'PT409 keeps the server wording; storage errors map to friendly kinds',
      () {
        expect(
          AppError.from(
            const PostgrestException(
              message: 'The deadline has passed',
              code: 'PT409',
            ),
          ).kind,
          AppErrorKind.conflict,
        );
        expect(
          AppError.from(const StorageException('x', statusCode: '403')).kind,
          AppErrorKind.forbidden,
        );
        expect(
          AppError.from(const StorageException('x', statusCode: '413')).kind,
          AppErrorKind.validation,
        );
      },
    );
  });

  group('AssignmentsController', () {
    test(
      'student load merges own submissions; failed refresh keeps stale data',
      () async {
        final repo = FakeAssignmentRepository(
          assignments: [fakeAssignment()],
          mine: {'a1': fakeSubmission()},
        );
        final c = AssignmentsController(repo, 'c1', student: true);
        await c.load();
        expect(c.state, LoadState.ready);
        expect(c.mine.containsKey('a1'), isTrue);
        repo.listFailures.add(const SocketException('offline'));
        await c.load(showSpinner: false);
        expect(c.assignments.length, 1);
        expect(c.loadError!.kind, AppErrorKind.network);
      },
    );

    test(
      'teacher create -> publish uses the loaded version; duplicate taps ignored',
      () async {
        final repo = FakeAssignmentRepository();
        final c = AssignmentsController(repo, 'c1');
        await c.load();
        expect(
          await c.create(title: ' Essay ', instructions: 'x', maxScore: 20),
          isTrue,
        );
        expect(repo.calls, contains('create:Essay:20'));
        final draft = c.assignments.single;
        expect(draft.published, isFalse);
        expect(await c.publish(draft), isTrue);
        expect(repo.calls, contains('publish:a-new:v1'));
        expect(c.assignments.single.published, isTrue);
      },
    );
  });

  group('SubmissionController (retry safety)', () {
    test(
      'text-only submit sends one request id and expects no version on first save',
      () async {
        final repo = FakeAssignmentRepository();
        final c = _sub(repo, FakeFilePicker())..setAnswer('My answer');
        await c.submit();
        expect(repo.submitRequestIds.length, 1);
        expect(
          repo.calls.lastWhere((x) => x.startsWith('submit')),
          'submit:-:-',
        );
        expect(c.existing!.version, 1);
        expect(c.notice, 'Submission saved.');
      },
    );

    test(
      'network failure then retry reuses the SAME request id (no duplicate submission)',
      () async {
        final repo = FakeAssignmentRepository()
          ..submitFailures.add(const SocketException('offline'));
        final c = _sub(repo, FakeFilePicker())..setAnswer('My answer');
        await c.submit();
        expect(c.error!.kind, AppErrorKind.network);
        expect(c.busy, isFalse);
        await c.submit();
        expect(repo.submitRequestIds.length, 2);
        expect(repo.submitRequestIds[0], repo.submitRequestIds[1]);
        expect(c.existing, isNotNull);
      },
    );

    test('editing the answer between attempts uses a new request id', () async {
      final repo = FakeAssignmentRepository()
        ..submitFailures.add(const SocketException('offline'));
      final c = _sub(repo, FakeFilePicker())..setAnswer('first');
      await c.submit();
      c.setAnswer('first, edited');
      await c.submit();
      expect(repo.submitRequestIds[0], isNot(repo.submitRequestIds[1]));
    });

    test(
      'file: ticket and upload are reused when only the final save failed',
      () async {
        final repo = FakeAssignmentRepository()
          ..submitFailures.add(const SocketException('offline'));
        final picker = FakeFilePicker()..next = fakeFile();
        final c = _sub(repo, picker);
        await c.pickFile();
        await c.submit();
        await c.submit();
        expect(repo.prepareCount, 1);
        expect(repo.calls.where((x) => x.startsWith('upload')).length, 1);
        expect(repo.submitRequestIds[0], repo.submitRequestIds[1]);
        expect(
          repo.calls.lastWhere((x) => x.startsWith('submit')),
          'submit:-:up-1',
        );
      },
    );

    test('upload failure retries the upload with the same ticket', () async {
      final repo = FakeAssignmentRepository()
        ..uploadFailures.add(const SocketException('offline'));
      final picker = FakeFilePicker()..next = fakeFile();
      final c = _sub(repo, picker);
      await c.pickFile();
      await c.submit();
      expect(c.error!.kind, AppErrorKind.network);
      expect(repo.calls.where((x) => x.startsWith('submit')), isEmpty);
      await c.submit();
      expect(repo.prepareCount, 1);
      expect(repo.calls.where((x) => x.startsWith('upload')).length, 2);
      expect(c.existing, isNotNull);
    });

    test(
      "server says the file didn't arrive: ticket is dropped and the next try re-uploads",
      () async {
        final repo = FakeAssignmentRepository()
          ..submitFailures.add(
            const PostgrestException(
              message: 'The file was not uploaded; retry the upload',
              code: 'PT409',
            ),
          );
        final picker = FakeFilePicker()..next = fakeFile();
        final c = _sub(repo, picker);
        await c.pickFile();
        await c.submit();
        expect(c.error!.message, contains("didn't finish uploading"));
        await c.submit();
        expect(repo.prepareCount, 2);
        expect(c.existing, isNotNull);
      },
    );

    test(
      'stale version conflict keeps the typed text and offers a reload',
      () async {
        final repo =
            FakeAssignmentRepository(mine: {'a1': fakeSubmission(version: 3)})
              ..submitFailures.add(
                const PostgrestException(
                  message:
                      'Your submission changed elsewhere; reload and retry',
                  code: 'PT409',
                ),
              );
        final c = _sub(
          repo,
          FakeFilePicker(),
          existing: fakeSubmission(version: 2),
        )..setAnswer('my unsent edit');
        await c.submit();
        expect(c.needsReload, isTrue);
        expect(c.answer, 'my unsent edit');
        await c.reload();
        expect(c.existing!.version, 3);
        expect(c.answer, 'my unsent edit');
        await c.submit();
        expect(
          repo.calls.lastWhere((x) => x.startsWith('submit')),
          startsWith('submit:3'),
        );
      },
    );

    test(
      'resubmit sends the saved version; removing the attachment is explicit',
      () async {
        final upload = const UploadInfo(
          id: 'u0',
          fileName: 'old.txt',
          mimeType: 'text/plain',
          sizeBytes: 3,
          path: 'p/u0',
        );
        final repo = FakeAssignmentRepository(
          mine: {'a1': fakeSubmission(version: 1, upload: upload)},
        );
        final c = _sub(
          repo,
          FakeFilePicker(),
          existing: fakeSubmission(version: 1, upload: upload),
        )..setAnswer('new text');
        c.setClearAttachment(true);
        await c.submit();
        expect(
          repo.calls.lastWhere((x) => x.startsWith('submit')),
          'submit:1:-',
        );
        expect(c.existing!.upload, isNull);
      },
    );

    test('deadline conflict is surfaced as an error, not a crash', () async {
      final repo = FakeAssignmentRepository()
        ..submitFailures.add(
          const PostgrestException(
            message: 'The deadline has passed',
            code: 'PT409',
          ),
        );
      final c = _sub(repo, FakeFilePicker())..setAnswer('late');
      await c.submit();
      expect(c.error!.message, 'The deadline has passed');
    });

    test('rapid double tap sends one request', () async {
      final repo = FakeAssignmentRepository()..gate = Completer<void>();
      final c = _sub(repo, FakeFilePicker())..setAnswer('x');
      final a = c.submit();
      final b = c.submit();
      repo.gate!.complete();
      await Future.wait([a, b]);
      expect(repo.submitRequestIds.length, 1);
    });

    test('empty form, oversize and empty files are refused locally', () async {
      final repo = FakeAssignmentRepository();
      final picker = FakeFilePicker()
        ..next = fakeFile(size: maxUploadBytes + 1);
      final c = _sub(repo, picker);
      await c.submit();
      expect(c.error!.kind, AppErrorKind.validation);
      await c.pickFile();
      expect(c.picked, isNull);
      expect(c.error!.message, contains('10 MB'));
      picker.next = fakeFile(size: 0);
      await c.pickFile();
      expect(c.picked, isNull);
      expect(repo.calls, isEmpty);
    });

    test('picker errors (disallowed type) are reported', () async {
      final picker = FakeFilePicker()
        ..error = const AppError(
          AppErrorKind.validation,
          'That file type is not allowed.',
        );
      final c = _sub(FakeAssignmentRepository(), picker);
      await c.pickFile();
      expect(c.error!.message, contains('not allowed'));
    });
  });

  group('SubmissionsController (teacher)', () {
    test('loads submissions; file URL failure is reported', () async {
      final up = const UploadInfo(
        id: 'u',
        fileName: 'a.txt',
        mimeType: 'text/plain',
        sizeBytes: 3,
        path: 'a/b/c/a.txt',
      );
      final repo = FakeAssignmentRepository(
        teacherView: [fakeSubmission(upload: up)],
      );
      final c = SubmissionsController(repo, 'a1');
      await c.load();
      expect(c.submissions.single.studentName, 'Sam');
      expect(await c.urlFor(up), contains('signed/a/b/c/a.txt'));
      repo.urlError = const StorageException('denied', statusCode: '403');
      expect(await c.urlFor(up), isNull);
      expect(c.fileError!.kind, AppErrorKind.forbidden);
    });
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

  group('student assignment page', () {
    testWidgets(
      'submits text with an attached file, then shows the saved version',
      (tester) async {
        final repo = FakeAssignmentRepository();
        final picker = FakeFilePicker()
          ..next = fakeFile(name: 'essay.pdf', size: 2048);
        await pump(
          tester,
          StudentAssignmentPage(
            assignment: fakeAssignment(),
            existing: null,
            services: fakeServices(assignments: repo, picker: picker),
          ),
        );
        expect(find.text('Write about it'), findsOneWidget);
        await tapText(tester, 'Submit');
        await tester.pump();
        expect(find.text('Write an answer or attach a file.'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'My answer');
        await tapText(tester, 'Attach a file');
        await tester.pumpAndSettle();
        expect(find.text('essay.pdf'), findsOneWidget);
        await tapText(tester, 'Submit');
        await tester.pumpAndSettle();
        expect(find.text('Submission saved.'), findsOneWidget);
        expect(repo.uploadedPaths.length, 1);
        expect(find.byKey(const Key('saved-version')), findsOneWidget);
        expect(find.textContaining('version 1'), findsOneWidget);
      },
    );

    testWidgets(
      'offline submit shows an error and a plain retry succeeds with one request id',
      (tester) async {
        final repo = FakeAssignmentRepository()
          ..submitFailures.add(const SocketException('offline'));
        await pump(
          tester,
          StudentAssignmentPage(
            assignment: fakeAssignment(),
            existing: null,
            services: fakeServices(assignments: repo),
          ),
        );
        await tester.enterText(find.byType(TextField), 'Hello');
        await tapText(tester, 'Submit');
        await tester.pumpAndSettle();
        expect(find.textContaining('No connection'), findsOneWidget);
        expect(find.text('Hello'), findsOneWidget); // typed text kept
        await tapText(tester, 'Submit');
        await tester.pumpAndSettle();
        expect(find.text('Submission saved.'), findsOneWidget);
        expect(repo.submitRequestIds.toSet().length, 1);
      },
    );

    testWidgets(
      'after a restart the saved server state is shown and prefilled',
      (tester) async {
        final up = const UploadInfo(
          id: 'u',
          fileName: 'kept.txt',
          mimeType: 'text/plain',
          sizeBytes: 3,
          path: 'p',
        );
        final repo = FakeAssignmentRepository(
          mine: {
            'a1': fakeSubmission(
              answer: 'Saved before restart',
              version: 2,
              upload: up,
            ),
          },
        );
        await pump(
          tester,
          StudentAssignmentPage(
            assignment: fakeAssignment(),
            existing: null,
            services: fakeServices(assignments: repo),
          ),
        );
        expect(find.textContaining('version 2'), findsOneWidget);
        expect(find.text('kept.txt'), findsWidgets);
        expect(find.text('Saved before restart'), findsOneWidget);
        await reveal(tester, find.text('Resubmit'));
        expect(find.text('Resubmit'), findsOneWidget);
      },
    );

    testWidgets('closed assignment hides the form', (tester) async {
      final past = fakeAssignment(dueAt: DateTime(2000));
      await pump(
        tester,
        StudentAssignmentPage(
          assignment: past,
          existing: null,
          services: fakeServices(),
        ),
      );
      expect(find.textContaining('deadline has passed'), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    for (final size in [const Size(320, 568), const Size(320, 480)]) {
      testWidgets(
        'form lays out at ${size.width.toInt()}x${size.height.toInt()} with a long title',
        (tester) async {
          final a = fakeAssignment(
            title:
                'A very long assignment title that should wrap or ellipsize gracefully on small phones',
            instructions: 'I' * 600,
          );
          await pump(
            tester,
            StudentAssignmentPage(
              assignment: a,
              existing: null,
              services: fakeServices(),
            ),
            size: size,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('student section / teacher pages', () {
    testWidgets(
      'student list shows status badges (Submitted / Closed / Not submitted)',
      (tester) async {
        final repo = FakeAssignmentRepository(
          assignments: [
            fakeAssignment(id: 'a1', title: 'Done'),
            fakeAssignment(id: 'a2', title: 'Late', dueAt: DateTime(2000)),
            fakeAssignment(id: 'a3', title: 'Open'),
          ],
          mine: {'a1': fakeSubmission(assignmentId: 'a1')},
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
        expect(find.text('Submitted'), findsOneWidget);
        expect(find.text('Closed'), findsOneWidget);
        expect(find.text('Not submitted'), findsOneWidget);
      },
    );

    testWidgets('teacher creates a draft, publishes it, and sees submissions', (
      tester,
    ) async {
      final repo = FakeAssignmentRepository(
        teacherView: [fakeSubmission(answer: 'Student text')],
      );
      final services = fakeServices(assignments: repo);
      await pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: TeacherAssignmentsSection(
              courseId: 'c1',
              services: services,
              archived: false,
            ),
          ),
        ),
      );
      expect(find.textContaining('No assignments yet'), findsOneWidget);
      await tester.tap(find.text('New assignment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save draft'));
      await tester.pump();
      expect(find.text('Enter a title'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Essay',
      );
      await tester.tap(find.text('Save draft'));
      await tester.pumpAndSettle();
      expect(find.text('Draft'), findsOneWidget);
      await tester.tap(find.text('Essay'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Students cannot see drafts'), findsOneWidget);
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Publish'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, contains('publish:a-new:v1'));
      expect(find.text('Student text'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
    });

    testWidgets('teacher page lays out on a small screen with attachments', (
      tester,
    ) async {
      final up = const UploadInfo(
        id: 'u',
        fileName: 'a-very-long-attachment-file-name-for-layout-testing.docx',
        mimeType: 'x',
        sizeBytes: 90000,
        path: 'p',
      );
      final repo = FakeAssignmentRepository(
        assignments: [fakeAssignment()],
        teacherView: [
          fakeSubmission(
            answer: 'A' * 400,
            upload: up,
            name: 'Student with a very long display name',
          ),
        ],
      );
      final services = fakeServices(assignments: repo);
      final c = AssignmentsController(repo, 'c1');
      await c.load();
      addTearDown(c.dispose);
      await pump(
        tester,
        TeacherAssignmentPage(
          assignmentId: 'a1',
          controller: c,
          services: services,
        ),
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Submissions (1)'), findsOneWidget);
    });
  });
}
