import 'sdk_fonts.dart';
import 'l10n_helpers.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app_services.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/features/courses/class_overview.dart';

import '../tool/studio_preview.dart' show createPreviewRoutes;
import 'fakes.dart';
import 'ui_test_helpers.dart';

const _capture = bool.fromEnvironment('CAPTURE_ADAPTIVE');
const _dir = String.fromEnvironment(
  'CAPTURE_DIR',
  defaultValue: 'claude-class',
);
const _surface = Key('class-capture');

Future<void> _pump(
  WidgetTester tester,
  WidgetBuilder page,
  Size size, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
        home: NestedHost(page: Builder(builder: page)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _picture(WidgetTester tester, String name) async {
  if (!_capture) return;
  await expectLater(
    find.byKey(_surface),
    matchesGoldenFile('../../docs/codex_ui_screenshots/$_dir/$name.png'),
  );
}

void main() {
  _scrollRegression();
  setUpAll(() async {
    final fonts = sdkFonts();
    final roboto = FontLoader('Roboto');
    for (final w in ['regular', 'medium', 'bold']) {
      roboto.addFont(
        Future.value(
          ByteData.sublistView(File('$fonts/roboto-$w.ttf').readAsBytesSync()),
        ),
      );
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('$fonts/materialicons-regular.otf').readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
  });

  testWidgets(
    'class dashboard with real fixtures: figures, latest session, completion, recent work',
    (tester) async {
      final routes = await createPreviewRoutes(onDispose: addTearDown);
      await _pump(tester, routes['/teacher-class']!, const Size(393, 2600));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('class-header')), findsOneWidget);
      // Header figures come from the roster, the open-session count and the server's course row.
      final header = tester.widget<ClassHeader>(find.byType(ClassHeader));
      expect((header.students, header.openSessions, header.toGrade), (5, 2, 1));
      // Latest session is the newest real one, with explicit not-marked count.
      expect(find.text('Latest session'), findsOneWidget);
      expect(find.textContaining('Studio workshop'), findsWidgets);
      expect(find.text('Not marked 2'), findsOneWidget);
      // Class rate = (Present+Late)/(Present+Late+Absent) over the class: 15 of 17 = 88.2%.
      expect(find.text('Class rate 88.2%'), findsOneWidget);
      expect(find.text('Submissions received'), findsOneWidget);
      expect(find.textContaining('3 of 5 submitted'), findsWidgets);
      expect(find.textContaining('Priya Patel · Essay'), findsOneWidget);
      expect(find.text('Attendance by student'), findsOneWidget);
      await _picture(tester, 'teacher-class-phone-full-393x2600');
    },
  );

  testWidgets('two sessions on one day are never collapsed in the weekly table', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final routes = await createPreviewRoutes(onDispose: addTearDown);
    await _pump(tester, routes['/teacher-class']!, const Size(1280, 1500));
    expect(find.text('Wed\n11 ×2'), findsOneWidget);
    // One cell announces both sessions with their own status; nothing is merged into a single result.
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'Priya Patel, Wed 11 Nov, Problem set lab: Present; Quiz: Absent',
        ),
      ),
      findsOneWidget,
    );
    // Not marked and no session are distinct, announced states.
    expect(
      find.bySemanticsLabel(RegExp(r'Tue 10 Nov: no session')),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Fri 13 Nov, Studio workshop: not marked')),
      findsWidgets,
    );
    expect(
      find.text('×2 = two sessions that day, in time order'),
      findsOneWidget,
    );
    await _picture(tester, 'teacher-class-tablet-full-1280x1500');
    semantics.dispose();
  });

  testWidgets('week navigation moves the table; an empty week says so', (
    tester,
  ) async {
    final routes = await createPreviewRoutes(onDispose: addTearDown);
    await _pump(tester, routes['/teacher-class']!, const Size(1280, 1500));
    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.text('2 Nov – 8 Nov 2026'), findsOneWidget);
    expect(find.text('No attendance sessions this week'), findsOneWidget);
    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(find.text('9 Nov – 15 Nov 2026'), findsOneWidget);
  });

  testWidgets('empty class explains the next step and invents no figures', (
    tester,
  ) async {
    final routes = await createPreviewRoutes(onDispose: addTearDown);
    await _pump(tester, routes['/teacher-class-empty']!, const Size(393, 2000));
    expect(tester.takeException(), isNull);
    expect(find.text('Invite your first students'), findsOneWidget);
    expect(find.text('No students enrolled yet'), findsWidgets);
    final header = tester.widget<ClassHeader>(find.byType(ClassHeader));
    expect(header.students, 0);
    expect(find.textContaining('Class rate'), findsNothing);
    await _picture(tester, 'teacher-class-phone-empty-393x2000');
  });

  testWidgets('students but no sessions: explicit empty attendance, no rate', (
    tester,
  ) async {
    final routes = await createPreviewRoutes(onDispose: addTearDown);
    await _pump(
      tester,
      routes['/teacher-class-nosessions']!,
      const Size(393, 2200),
    );
    expect(
      find.descendant(
        of: find.byType(ClassAttendanceCard),
        matching: find.textContaining('No attendance sessions yet'),
      ),
      findsOneWidget,
    );
    expect(find.text('No sessions'), findsOneWidget);
    expect(find.textContaining('Class rate'), findsNothing);
    expect(find.text('No attendance sessions this week'), findsOneWidget);
    await _picture(tester, 'teacher-class-phone-no-sessions-393x2200');
  });

  testWidgets('a failing attendance read only affects the attendance card', (
    tester,
  ) async {
    final services = fakeServices(
      attendance: FakeAttendanceRepository()
        ..loadError = const AppError(
          AppErrorKind.network,
          'No connection to the server.',
        ),
      assignments: FakeAssignmentRepository(
        assignments: [fakeAssignment(title: 'Essay')],
      ),
    );
    await _pump(
      tester,
      (_) => ClassScope(services: services),
      const Size(393, 1400),
    );
    expect(find.text('No connection to the server.'), findsOneWidget);
    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('1 of 0 submitted'), findsNothing);
  });

  for (final c in [
    (
      size: const Size(320, 3600),
      scale: 2.0,
      brightness: Brightness.light,
      tag: '320-text200-light',
    ),
    (
      size: const Size(430, 6000),
      scale: 3.0,
      brightness: Brightness.light,
      tag: '430-text300-light',
    ),
    (
      size: const Size(393, 2600),
      scale: 1.0,
      brightness: Brightness.dark,
      tag: '393-dark',
    ),
    (
      size: const Size(1024, 1500),
      scale: 1.0,
      brightness: Brightness.dark,
      tag: '1024-dark',
    ),
    (
      size: const Size(800, 900),
      scale: 2.0,
      brightness: Brightness.light,
      tag: '800x900-text200-landscape',
    ),
  ]) {
    testWidgets('class dashboard fits ${c.tag} without overflow', (
      tester,
    ) async {
      final routes = await createPreviewRoutes(onDispose: addTearDown);
      await _pump(
        tester,
        routes['/teacher-class']!,
        c.size,
        scale: c.scale,
        brightness: c.brightness,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('class-week-grid')), findsOneWidget);
      await _picture(tester, 'teacher-class-${c.tag}');
    });
  }
}

/// Loads only the class overview cards for one set of fake services (no course page chrome).
class ClassScope extends StatefulWidget {
  const ClassScope({super.key, required this.services});
  final AppServices services;

  @override
  State<ClassScope> createState() => _ClassScopeState();
}

class _ClassScopeState extends State<ClassScope> {
  late final c = ClassOverviewController(widget.services, 'c1');

  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListenableBuilder(
      listenable: c,
      builder: (context, _) => ListView(
        children: [
          ClassAttendanceCard(c: c),
          ClassWorkCard(c: c),
        ],
      ),
    ),
  );
}

void _scrollRegression() {
  testWidgets('class dashboard survives scrolling on a phone-sized screen', (
    tester,
  ) async {
    final semantics = tester
        .ensureSemantics(); // on a device, accessibility/UiAutomator turns this on
    final routes = await createPreviewRoutes(onDispose: addTearDown);
    await _pump(tester, routes['/teacher-class']!, const Size(360, 640));
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 14; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -280));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final e = tester.takeException();
      expect(e, isNull, reason: 'exception after scroll step $i');
    }
    semantics.dispose();
  });
}
