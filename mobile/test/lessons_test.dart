import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/courses/courses_controller.dart'
    show LoadState;
import 'package:learn_pulse/features/lessons/lesson.dart';
import 'package:learn_pulse/features/lessons/lessons_controller.dart';
import 'package:learn_pulse/features/lessons/lessons_pages.dart';

import 'fakes.dart';
import 'ui_test_helpers.dart';

LessonsController _ctl(FakeLessonRepository repo) =>
    LessonsController(repo, 'c1');

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: l10nDelegates,
  supportedLocales: l10nLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('models', () {
    test('Lesson.fromRow rejects malformed rows', () {
      expect(Lesson.fromRow({'id': 'a', 'title': 't', 'status': 'x'}), isNull);
      expect(
        Lesson.fromRow({'id': 1, 'title': 't', 'status': 'draft'}),
        isNull,
      );
      final l = Lesson.fromRow({
        'id': 'a',
        'title': 't',
        'status': 'published',
      });
      expect(l!.published, isTrue);
      expect(l.version, 1);
    });

    test('LessonResource label falls back to the file name', () {
      final r = LessonResource.fromRow({
        'id': 'r',
        'lesson_id': 'l',
        'file_name': 'a.pdf',
        'storage_path': 'p',
        'status': 'attached',
      });
      expect(r!.label, 'a.pdf');
      expect(r.attached, isTrue);
      expect(LessonResource.fromRow({'id': 'r'}), isNull);
    });
  });

  group('LessonsController', () {
    test('loads lessons and only attached files', () async {
      final repo = FakeLessonRepository(
        lessons: [fakeLesson()],
        resources: [
          fakeResource(),
          LessonResource(
            id: 'r2',
            lessonId: 'l1',
            title: '',
            fileName: 'half.pdf',
            sizeBytes: 1,
            path: 'p',
            attached: false,
          ),
        ],
      );
      final c = _ctl(repo);
      await c.load();
      expect(c.state, LoadState.ready);
      expect(c.filesOf('l1').map((r) => r.id), ['r1']);
    });

    test('load failure surfaces an error and retry recovers', () async {
      final repo = FakeLessonRepository(lessons: [fakeLesson()])
        ..loadError = const AppError(AppErrorKind.network, 'offline');
      final c = _ctl(repo);
      await c.load();
      expect(c.state, LoadState.error);
      expect(c.loadError!.message, 'offline');
      repo.loadError = null;
      await c.load();
      expect(c.state, LoadState.ready);
      expect(c.lessons, hasLength(1));
    });

    test(
      'create, edit, publish and unpublish go through the repository',
      () async {
        final repo = FakeLessonRepository();
        final c = _ctl(repo);
        await c.load();
        expect(await c.create('  Intro  ', 'text'), isTrue);
        final l = c.lessons.single;
        expect(l.title, 'Intro');
        expect(l.published, isFalse);
        expect(await c.update(l, 'Intro 2', 'more'), isTrue);
        expect(await c.setPublished(c.lessons.single, true), isTrue);
        expect(c.lessons.single.published, isTrue);
        expect(c.lessons.single.version, 3);
        expect(await c.setPublished(c.lessons.single, false), isTrue);
        expect(c.lessons.single.published, isFalse);
      },
    );

    test(
      'a version conflict reports the error and reloads the newer state',
      () async {
        final repo = FakeLessonRepository(
          lessons: [fakeLesson(published: false)],
        );
        final c = _ctl(repo);
        await c.load();
        repo.error = const AppError(AppErrorKind.conflict, 'Lesson changed');
        final stale = c.lessons.single;
        repo.lessons[0] = fakeLesson(
          title: 'Changed elsewhere',
          version: 2,
          published: false,
        );
        expect(await c.update(stale, 'Mine', 'x'), isFalse);
        expect(c.actionError!.kind, AppErrorKind.conflict);
        expect(c.lessons.single.title, 'Changed elsewhere');
        expect(c.busy, isFalse);
      },
    );

    test('attach uploads and finalizes once', () async {
      final repo = FakeLessonRepository(lessons: [fakeLesson()]);
      final c = _ctl(repo);
      await c.load();
      expect(
        await c.attach(c.lessons.single, fakeFile(name: 'notes.pdf')),
        isTrue,
      );
      expect(repo.calls, ['prepare:notes.pdf', 'upload:r1', 'finalize:r1']);
      expect(c.filesOf('l1').single.fileName, 'notes.pdf');
    });

    test('retry after a failed upload reuses the same ticket', () async {
      final repo = FakeLessonRepository(lessons: [fakeLesson()])
        ..uploadError = const AppError(AppErrorKind.network, 'offline');
      final c = _ctl(repo);
      await c.load();
      final file = fakeFile(name: 'notes.pdf');
      expect(await c.attach(c.lessons.single, file), isFalse);
      expect(c.actionError!.kind, AppErrorKind.network);
      expect(await c.attach(c.lessons.single, file), isTrue);
      expect(repo.calls.where((x) => x.startsWith('prepare')), hasLength(1));
      expect(repo.resources, hasLength(1));
    });

    test('a different file after a failure gets its own ticket', () async {
      final repo = FakeLessonRepository(lessons: [fakeLesson()])
        ..uploadError = const AppError(AppErrorKind.network, 'offline');
      final c = _ctl(repo);
      await c.load();
      await c.attach(c.lessons.single, fakeFile(name: 'a.pdf'));
      await c.attach(c.lessons.single, fakeFile(name: 'b.pdf'));
      expect(repo.calls.where((x) => x.startsWith('prepare')), hasLength(2));
    });

    test('files over 10 MB are refused before any server call', () async {
      final repo = FakeLessonRepository(lessons: [fakeLesson()]);
      final c = _ctl(repo);
      await c.load();
      final ok = await c.attach(
        c.lessons.single,
        fakeFile(name: 'big.pdf', size: 10 * 1024 * 1024 + 1),
      );
      expect(ok, isFalse);
      expect(c.actionError!.kind, AppErrorKind.validation);
      expect(repo.calls, isEmpty);
    });

    test('delete resource and delete lesson', () async {
      final repo = FakeLessonRepository(
        lessons: [fakeLesson()],
        resources: [fakeResource()],
      );
      final c = _ctl(repo);
      await c.load();
      expect(await c.deleteResource(c.filesOf('l1').single), isTrue);
      expect(c.filesOf('l1'), isEmpty);
      expect(await c.delete(c.lessons.single), isTrue);
      expect(c.lessons, isEmpty);
    });

    test('urlFor returns a signed url', () async {
      final repo = FakeLessonRepository(
        lessons: [fakeLesson()],
        resources: [fakeResource()],
      );
      final c = _ctl(repo);
      await c.load();
      expect(
        await c.urlFor(c.filesOf('l1').single),
        contains('c1/l1/r1/notes.pdf'),
      );
    });
  });

  group('UI', () {
    testWidgets('teacher section: empty state, validation, create draft', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeLessonRepository();
      await tester.pumpWidget(
        _wrap(
          TeacherLessonsSection(
            courseId: 'c1',
            services: fakeServices(lessons: repo),
            archived: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No lessons yet'), findsOneWidget);
      await tester.tap(find.text('New lesson'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create draft'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a title'), findsOneWidget);
      expect(repo.calls, isEmpty);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Waves',
      );
      await tester.tap(find.text('Create draft'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['create:Waves']);
      expect(find.text('Waves'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('teacher section is read-only on an archived course', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TeacherLessonsSection(
            courseId: 'c1',
            services: fakeServices(lessons: FakeLessonRepository()),
            archived: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final btn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'New lesson'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('teacher lesson page: attach a picked file, then publish', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeLessonRepository(
        lessons: [fakeLesson(published: false)],
      );
      final picker = FakeFilePicker()..next = fakeFile(name: 'slides.pdf');
      final services = fakeServices(lessons: repo, picker: picker);
      final c = LessonsController(repo, 'c1');
      await c.load();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: TeacherLessonPage(
            lessonId: 'l1',
            controller: c,
            services: services,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('No files attached.'));
      expect(find.text('No files attached.'), findsOneWidget);
      await tapText(tester, 'Attach file');
      await tester.pumpAndSettle();
      expect(find.text('slides.pdf'), findsWidgets);
      expect(
        repo.calls,
        containsAllInOrder(['prepare:slides.pdf', 'upload:r1', 'finalize:r1']),
      );
      await tester.scrollUntilVisible(
        find.text('Publish'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      expect(repo.lessons.single.published, isTrue);
      expect(find.text('Unpublish'), findsOneWidget);
    });

    testWidgets('conflict keeps the typed text and shows the message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeLessonRepository(
        lessons: [fakeLesson(published: false)],
      );
      final c = LessonsController(repo, 'c1');
      await c.load();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: TeacherLessonPage(
            lessonId: 'l1',
            controller: c,
            services: fakeServices(lessons: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'My edit',
      );
      repo.error = const AppError(
        AppErrorKind.conflict,
        'Lesson changed; reload and retry',
      );
      await tapText(tester, 'Save changes');
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Lesson changed; reload and retry'));
      expect(find.text('Lesson changed; reload and retry'), findsOneWidget);
      expect(find.text('My edit'), findsOneWidget);
    });

    testWidgets(
      'student section shows lessons and their files; error state retries',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo =
            FakeLessonRepository(
                lessons: [fakeLesson()],
                resources: [fakeResource()],
              )
              ..loadError = const AppError(
                AppErrorKind.network,
                'No connection right now.',
              );
        await tester.pumpWidget(
          _wrap(
            StudentLessonsSection(
              courseId: 'c1',
              services: fakeServices(lessons: repo),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No connection right now.'), findsOneWidget);
        repo.loadError = null;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Motion'), findsOneWidget);
        expect(find.text('1 file'), findsOneWidget);
        await tester.tap(find.text('Motion'));
        await tester.pumpAndSettle();
        expect(find.text('Newton'), findsOneWidget);
        expect(find.text('Notes'), findsOneWidget);
        expect(find.byTooltip('Open Notes'), findsOneWidget);
      },
    );

    testWidgets('student empty state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          StudentLessonsSection(
            courseId: 'c1',
            services: fakeServices(lessons: FakeLessonRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('has not published any'), findsOneWidget);
    });
  });
}
