import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/academic.dart';
import 'package:learn_pulse/core/theme.dart';

import '../tool/studio_preview.dart' show createPreviewRoutes;
import 'ui_test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(393, 852),
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: l10nDelegates,
      supportedLocales: l10nLocales,
      theme: buildTheme(brightness, reduceMotion: true),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: home,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // root screens keep a loading animation running; a few frames are enough
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
}

void main() {
  group('AcademicPageHeader', () {
    for (final c in [
      (w: 320.0, scale: 1.0, b: Brightness.light),
      (w: 320.0, scale: 3.0, b: Brightness.light),
      (w: 393.0, scale: 2.0, b: Brightness.dark),
      (w: 1024.0, scale: 1.0, b: Brightness.light),
    ]) {
      testWidgets(
        'keeps a long title, context and metadata whole at ${c.w}dp ×${c.scale} ${c.b.name}',
        (tester) async {
          const title =
              'Understanding the relationship between motion and measurement';
          await _pump(
            tester,
            Scaffold(
              appBar: AppBar(),
              body: ListView(
                children: [
                  AcademicPageHeader(
                    eyebrow: 'Algebra · Lesson',
                    icon: Icons.menu_book_outlined,
                    title: title,
                    description: 'Read, explore, then put it into practice.',
                    meta: const [
                      MetadataRow(Icons.schedule, 'Due Fri 13 Nov 2026, 16:00'),
                    ],
                    actions: [
                      FilledButton(onPressed: () {}, child: const Text('Save')),
                    ],
                  ),
                ],
              ),
            ),
            size: Size(c.w, 900),
            scale: c.scale,
            brightness: c.b,
          );
          expect(tester.takeException(), isNull);
          expect(find.text(title), findsOneWidget);
          expect(find.text('Algebra · Lesson'), findsOneWidget);
          expect(find.text('Due Fri 13 Nov 2026, 16:00'), findsOneWidget);
          expect(find.byType(LayoutBuilder), findsNothing);
          // the title is not clipped to a single line
          final t = tester.widget<Text>(find.text(title));
          expect(t.maxLines, isNull);
          expect(t.overflow, isNull);
        },
      );
    }

    testWidgets('announces the title as a header', (tester) async {
      final h = tester.ensureSemantics();
      await _pump(
        tester,
        const Scaffold(body: AcademicPageHeader(title: 'Weekly attendance')),
      );
      expect(
        tester
            .getSemantics(find.text('Weekly attendance'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      h.dispose();
    });
  });

  group('navigation', () {
    testWidgets(
      'nested screens have a Back arrow of at least 48 dp that returns to the previous route',
      (tester) async {
        final routes = await createPreviewRoutes(onDispose: addTearDown);
        for (final route in [
          'lesson',
          'week',
          'account',
          'grading',
          'student-course',
          'teacher-class',
        ]) {
          await _pump(
            tester,
            Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: routes['/$route']!),
                    ),
                    child: Text('open-$route'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('open-$route'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
          final back = find.byType(BackButton);
          expect(back, findsOneWidget, reason: '$route shows a Back arrow');
          final size = tester.getSize(
            find.descendant(of: back, matching: find.byType(IconButton)),
          );
          expect(size.width, greaterThanOrEqualTo(48), reason: route);
          expect(size.height, greaterThanOrEqualTo(48), reason: route);
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(
            find.text('open-$route'),
            findsOneWidget,
            reason: '$route returned to the previous route',
          );
          // the system back path behaves the same
          await tester.tap(find.text('open-$route'));
          await tester.pumpAndSettle();
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(
            find.text('open-$route'),
            findsOneWidget,
            reason: '$route system back',
          );
        }
      },
    );

    testWidgets(
      'root destinations driven by bottom navigation have no Back arrow',
      (tester) async {
        final routes = await createPreviewRoutes(onDispose: addTearDown);
        for (final route in ['student', 'teacher']) {
          await _pump(
            tester,
            Builder(builder: routes['/$route']!),
            settle: false,
          );
          expect(find.byType(BackButton), findsNothing, reason: route);
          expect(find.byType(NavigationBar), findsOneWidget);
        }
      },
    );

    testWidgets(
      'lesson viewer shows its title once, framed, with course context',
      (tester) async {
        final routes = await createPreviewRoutes(onDispose: addTearDown);
        await _pump(
          tester,
          NestedHost(page: Builder(builder: routes['/lesson']!)),
        );
        expect(find.text('Understanding motion'), findsOneWidget);
        expect(find.byKey(const Key('page-header')), findsOneWidget);
        expect(find.text('Learning content'), findsOneWidget);
        expect(find.text('Files'), findsOneWidget);
      },
    );

    testWidgets(
      'popping back keeps the previous screen state (typed text survives)',
      (tester) async {
        final controller = TextEditingController(text: 'draft kept');
        addTearDown(controller.dispose);
        await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextField(controller: controller),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(),
                          body: const AcademicPageHeader(title: 'Nested'),
                        ),
                      ),
                    ),
                    child: const Text('go'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(controller.text, 'draft kept');
        expect(find.text('draft kept'), findsOneWidget);
      },
    );
  });
}
