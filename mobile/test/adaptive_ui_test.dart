import 'sdk_fonts.dart';
import 'l10n_helpers.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/core/adaptive.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/home/role_home.dart';
import 'package:learn_pulse/features/courses/courses_page.dart';
import 'package:learn_pulse/features/attendance/attendance_grid_page.dart';
import 'package:learn_pulse/features/attendance/attendance_controllers.dart';
import '../tool/studio_preview.dart' show createPreviewRoutes;
import 'fakes.dart';
import 'ui_test_helpers.dart';

const _capture = bool.fromEnvironment('CAPTURE_ADAPTIVE');
const _surface = Key('adaptive-capture');
const _captureDirectory = String.fromEnvironment(
  'CAPTURE_DIR',
  defaultValue: 'adaptive',
);

/// Screens reached by pushing a route (they show a Back arrow); the rest are root destinations.
const _nestedRoutes = {
  'student-course',
  'teacher-course',
  'teacher-class',
  'teacher-class-empty',
  'teacher-class-nosessions',
  'assignment',
  'teacher-assignment',
  'lesson',
  'lesson-editor',
  'grading',
  'attendance',
  'week',
  'account',
};
const _sizes = [
  Size(320, 568),
  Size(360, 640),
  Size(393, 852),
  Size(430, 932),
  Size(600, 960),
  Size(800, 1280),
  Size(1024, 768),
  Size(1280, 800),
  Size(800, 360),
];

Future<void> _pump(
  WidgetTester tester,
  Widget page,
  Size size, {
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool nested = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    RepaintBoundary(
      key: _surface,
      child: MaterialApp(
        localizationsDelegates: l10nDelegates,
        supportedLocales: l10nLocales,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness, reduceMotion: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: nested ? NestedHost(page: page) : page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _picture(WidgetTester tester, String name) async {
  if (_capture) {
    await expectLater(
      find.byKey(_surface),
      matchesGoldenFile(
        '../../docs/codex_ui_screenshots/$_captureDirectory/$name.png',
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    // Use the SDK's installed Android font so visual evidence is readable.
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      final bytes = File('${sdkFonts()}/roboto-$weight.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('${sdkFonts()}/materialicons-regular.otf').readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
  });

  for (final size in _sizes) {
    for (final scale in [1.0, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'shell ${size.width}x${size.height} text $scale ${brightness.name}',
          (tester) async {
            addTearDown(tester.view.reset);
            for (final role in AppRole.values) {
              final profile = Profile(
                role: role,
                fullName:
                    'Alexandria Longname Learner With A Complete Identity',
              );
              final auth = AuthController(
                FakeAuthRepository(hasSession: true, profile: profile),
              );
              await auth.start();
              await _pump(
                tester,
                RoleHome(
                  controller: auth,
                  profile: profile,
                  services: fakeServices(),
                ),
                size,
                scale: scale,
                brightness: brightness,
              );
              expect(find.text('Hello, ${profile.fullName}'), findsOneWidget);
              final greeting = tester.widget<Text>(
                find.text('Hello, ${profile.fullName}'),
              );
              expect(greeting.maxLines, isNull);
              expect(greeting.overflow, isNot(TextOverflow.ellipsis));
              expect(
                find.byType(size.width < 600 ? NavigationBar : NavigationRail),
                findsOneWidget,
              );
              // Follow the actual dashboard action; the selected tab survives resizing.
              await reveal(tester, find.text('Open courses').first);
              await tester.tap(find.text('Open courses').first);
              await tester.pumpAndSettle();
              expect(find.byType(FloatingActionButton), findsNothing);
              final action = find.text(
                role == AppRole.teacher ? 'New course' : 'Join a course',
              );
              await reveal(tester, action);
              expect(
                tester
                    .getSize(
                      find
                          .ancestor(
                            of: action,
                            matching: find.byType(FilledButton),
                          )
                          .first,
                    )
                    .height,
                greaterThanOrEqualTo(48),
              );
              await tester.tap(action);
              await tester.pumpAndSettle();
              expect(find.byType(Dialog), findsOneWidget);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
              auth.dispose();
            }
          },
        );
      }
    }
  }

  final cases = [
    (size: const Size(393, 852), scale: 1.0, brightness: Brightness.light),
    (size: const Size(600, 960), scale: 1.0, brightness: Brightness.light),
    (size: const Size(1280, 800), scale: 1.0, brightness: Brightness.light),
    (size: const Size(1024, 768), scale: 1.0, brightness: Brightness.dark),
    (size: const Size(320, 568), scale: 2.0, brightness: Brightness.light),
    (size: const Size(800, 360), scale: 2.0, brightness: Brightness.dark),
    (size: const Size(430, 932), scale: 3.0, brightness: Brightness.light),
  ];
  for (final c in cases) {
    testWidgets('complex pages ${c.size} text ${c.scale} ${c.brightness.name}', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      final routes = await createPreviewRoutes(onDispose: addTearDown);
      for (final route in [
        'student',
        'teacher',
        'student-courses',
        'teacher-courses',
        'student-course',
        'teacher-course',
        'teacher-class',
        'teacher-class-empty',
        'teacher-class-nosessions',
        'assignment',
        'teacher-assignment',
        'lesson',
        'lesson-editor',
        'grading',
        'attendance',
        'week',
        'profile',
        'account',
        'sign-in',
        'sign-up',
        'recovery',
      ]) {
        await _pump(
          tester,
          Builder(builder: routes['/$route']!),
          c.size,
          scale: c.scale,
          brightness: c.brightness,
          nested: _nestedRoutes.contains(route),
        );
        final expected = <String, String>{
          'student': 'Hello, Sam Learner',
          'teacher': 'Hello, Ms Tester',
          'student-courses': 'Your courses',
          'teacher-courses': 'Your courses',
          'student-course': 'Learning workspace',
          'teacher-course': 'Your class',
          'teacher-class': 'Weekly attendance',
          'teacher-class-empty': 'Invite your first students',
          'teacher-class-nosessions': 'No attendance sessions yet',
          'assignment': 'Your workspace',
          'teacher-assignment': 'Assignment brief',
          'lesson': 'Understanding motion',
          'lesson-editor': 'Learning content',
          'grading': 'Student answer',
          'attendance': 'Class register',
          'week': 'Weekly attendance',
          'profile': 'Sam Learner',
          'account': 'Account & settings',
          'sign-in': 'Sign in',
          'sign-up': 'Create your account',
          'recovery': 'Reset your password',
        };
        expect(
          find.textContaining(expected[route]!, findRichText: true),
          findsWidgets,
          reason: 'Expected route /$route',
        );
        await _picture(
          tester,
          '$route-${c.size.width.toInt()}x${c.size.height.toInt()}-${c.brightness.name}-text${(c.scale * 100).round()}',
        );
        if (route == 'week' && c.scale >= 2) {
          await reveal(tester, find.text('Sam Learner'));
          await _picture(
            tester,
            'week-${c.size.width.toInt()}x${c.size.height.toInt()}-text${(c.scale * 100).round()}-names',
          );
        }
        final scrolls = find.byType(Scrollable);
        if (scrolls.evaluate().isNotEmpty) {
          // Traverse all vertical content so offscreen errors are also checked.
          for (var i = 0; i < 8; i++) {
            final vertical = find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            );
            if (vertical.evaluate().isEmpty) break;
            await tester.drag(vertical.first, const Offset(0, -500));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$route scroll $i');
          }
        }
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets(
    'draft answer and grading inputs survive window resize and keyboard',
    (tester) async {
      addTearDown(tester.view.reset);
      final routes = await createPreviewRoutes(onDispose: addTearDown);
      for (final route in [
        'assignment',
        'grading',
        'lesson-editor',
        'account',
        'sign-in',
      ]) {
        await _pump(
          tester,
          Builder(builder: routes['/$route']!),
          const Size(393, 852),
        );
        final field = find
            .byWidgetPredicate((w) => w is EditableText && !w.readOnly)
            .first;
        await reveal(tester, field);
        await tester.enterText(
          field,
          route == 'grading' ? '85' : 'Draft retained across rotation',
        );
        final state = tester.state(field);
        tester.view.physicalSize = const Size(1280, 800);
        await tester.pumpAndSettle();
        expect(
          tester.state(field),
          same(state),
          reason: '$route element retained',
        );
        expect(
          tester.widget<EditableText>(field).controller.text,
          route == 'grading' ? '85' : 'Draft retained across rotation',
        );
        tester.view.physicalSize = const Size(320, 568);
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        await tester.pumpAndSettle();
        await reveal(tester, field);
        expect(tester.takeException(), isNull);
        await _picture(tester, '$route-320x568-keyboard');
        final labels = {
          'assignment': 'Submit',
          'grading': 'Save grade',
          'lesson-editor': 'Save changes',
          'account': 'Save name',
          'sign-in': 'Sign in',
        };
        final action = find.widgetWithText(FilledButton, labels[route]!);
        await reveal(tester, action);
        expect(
          action.hitTestable(),
          findsOneWidget,
          reason: '$route primary action reachable with keyboard',
        );
        expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(308));
        await _picture(tester, '$route-320x568-keyboard-action');
        tester.view.resetViewInsets();
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets(
    'selected tab and course state survive crossing navigation breakpoints',
    (tester) async {
      addTearDown(tester.view.reset);
      final routes = await createPreviewRoutes(onDispose: addTearDown);
      await _pump(
        tester,
        Builder(builder: routes['/student']!),
        const Size(393, 852),
      );
      await reveal(tester, find.text('Open courses'));
      await tester.tap(find.text('Open courses'));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(CoursesPage));
      for (final size in [
        const Size(600, 960),
        const Size(1280, 800),
        const Size(800, 360),
        const Size(320, 568),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(CoursesPage)), same(state));
        expect(find.text('Your courses'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('long weekly names remain complete at 300% while dates scroll', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    const name = 'Alexandria Montgomery Longname Learner';
    final repo = FakeAttendanceRepository(
      sessions: [fakeSession()],
      students: [(id: 's1', name: name)],
    );
    await _pump(
      tester,
      AttendanceWeekGridPage(
        controller: WeekGridController(
          repo,
          'c1',
          today: DateTime(2026, 11, 13),
        ),
        teacher: true,
      ),
      const Size(320, 568),
      scale: 3,
    );
    final label = find.text(name);
    await reveal(tester, label);
    final widget = tester.widget<Text>(label);
    expect(widget.maxLines, isNull);
    expect(widget.overflow, isNot(TextOverflow.ellipsis));
    final style = DefaultTextStyle.of(
      tester.element(label),
    ).style.merge(widget.style);
    final painter = TextPainter(
      text: TextSpan(text: name, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(3),
    )..layout(maxWidth: tester.getSize(label).width);
    expect(tester.getSize(label).height, greaterThanOrEqualTo(painter.height));
    painter.dispose();
    final before = tester.getTopLeft(label).dx;
    final dates = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    await tester.drag(dates, const Offset(-160, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(label).dx, before);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'adaptive page exposes separate accessible body paragraphs and inputs',
    (tester) async {
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        const Scaffold(
          body: StudioPage(
            secondary: [
              TextField(
                decoration: InputDecoration(labelText: 'Accessible answer'),
              ),
            ],
            children: [Text('Read the complete assignment instructions.')],
          ),
        ),
        const Size(393, 852),
      );
      expect(
        tester
            .getSemantics(
              find.text('Read the complete assignment instructions.'),
            )
            .label,
        'Read the complete assignment instructions.',
      );
      expect(find.bySemanticsLabel('Accessible answer'), findsOneWidget);
      semantics.dispose();
    },
  );
}
