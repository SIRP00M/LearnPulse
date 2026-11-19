import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/academic.dart';
import 'package:learn_pulse/core/theme.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(320, 640),
  double scale = 1,
  Brightness brightness = Brightness.light,
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
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AcademicSection', () {
    testWidgets(
      'frames heading and rows in one bordered surface with hairlines between rows',
      (tester) async {
        await _pump(
          tester,
          const AcademicSection(
            title: 'Lessons',
            icon: Icons.menu_book_outlined,
            count: '2',
            children: [
              ListTile(title: Text('One')),
              ListTile(title: Text('Two')),
            ],
          ),
        );
        expect(find.text('Lessons'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        // header divider + one between the two rows
        expect(find.byType(Divider), findsNWidgets(2));
        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(AcademicSection),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.shape, isA<RoundedRectangleBorder>());
        expect((material.shape! as RoundedRectangleBorder).side.width, 1);
      },
    );

    testWidgets(
      'padded content has no row dividers; actions wrap instead of overflowing at 320 dp / 300%',
      (tester) async {
        await _pump(
          tester,
          AcademicSection(
            title: 'Attendance',
            padded: true,
            actions: [
              TextButton(onPressed: () {}, child: const Text('Weekly grid')),
              TextButton(onPressed: () {}, child: const Text('Summary')),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('New session'),
              ),
            ],
            children: const [Text('Body A'), Text('Body B')],
          ),
          scale: 3,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(Divider), findsOneWidget); // header only
        expect(find.text('New session'), findsOneWidget);
      },
    );

    testWidgets('title is announced as a header', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AcademicSection(
          title: 'Roster',
          padded: true,
          children: [Text('x')],
        ),
      );
      expect(
        tester.getSemantics(find.text('Roster')).flagsCollection.isHeader,
        isTrue,
      );
      handle.dispose();
    });
  });

  group('SessionSummaryCard', () {
    for (final c in [
      (w: 320.0, scale: 1.0, b: Brightness.light),
      (w: 320.0, scale: 2.0, b: Brightness.light),
      (w: 320.0, scale: 3.0, b: Brightness.dark),
      (w: 1024.0, scale: 1.0, b: Brightness.dark),
    ]) {
      testWidgets(
        'groups title, date, state and unmarked count without overflow at ${c.w}dp ×${c.scale} ${c.b.name}',
        (tester) async {
          await _pump(
            tester,
            const SessionSummaryCard(
              eyebrow: 'Attendance / Session',
              title: 'Studio workshop with a deliberately long session title',
              when: 'Fri 13 Nov 2026, 16:00',
              closed: false,
              unmarked: 11,
            ),
            size: Size(c.w, 900),
            scale: c.scale,
            brightness: c.b,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Attendance / Session'), findsOneWidget);
          expect(find.text('Fri 13 Nov 2026, 16:00'), findsOneWidget);
          expect(find.text('Open'), findsOneWidget);
          expect(find.text('11 unmarked'), findsOneWidget);
          // date, state and count share one inset group
          expect(
            find.descendant(
              of: find.byType(InfoGroup),
              matching: find.text('11 unmarked'),
            ),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets(
      'closed session with everything marked, and unknown count while loading',
      (tester) async {
        await _pump(
          tester,
          const Column(
            children: [
              SessionSummaryCard(
                eyebrow: 'e',
                title: 'Done',
                when: 'w',
                closed: true,
                unmarked: 0,
              ),
              SessionSummaryCard(
                eyebrow: 'e',
                title: 'Loading',
                when: 'w',
                closed: false,
              ),
            ],
          ),
          size: const Size(400, 1200),
        );
        expect(find.text('Closed'), findsOneWidget);
        expect(find.text('All marked'), findsOneWidget);
        expect(find.textContaining('unmarked'), findsNothing);
      },
    );
  });

  testWidgets('InfoGroup and MetadataRow wrap long text instead of clipping it', (
    tester,
  ) async {
    const long =
        'A long piece of metadata that must wrap onto several lines at large text sizes without being cut off';
    await _pump(
      tester,
      const InfoGroup(
        children: [
          MetadataRow(Icons.calendar_today_outlined, long),
          MetadataRow(Icons.people_outline, 'Second'),
        ],
      ),
      scale: 3,
    );
    expect(tester.takeException(), isNull);
    expect(find.text(long), findsOneWidget);
  });

  testWidgets(
    'AcademicSummary framed:false returns bare content and still lays out at 320 dp (no LayoutBuilder)',
    (tester) async {
      await _pump(
        tester,
        const AcademicSection(
          title: 'My attendance',
          children: [
            AcademicSummary(
              framed: false,
              title: 'Attendance rate: 90%',
              stats: [
                (label: 'Present', value: '9'),
                (label: 'Late', value: '1'),
                (label: 'Excused', value: '0'),
                (label: 'Absent', value: '1'),
              ],
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LayoutBuilder), findsNothing);
      expect(find.text('Present'), findsOneWidget);
    },
  );
}
