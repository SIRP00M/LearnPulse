import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/core/ui.dart';
import 'package:learn_pulse/features/courses/course_widgets.dart';
import 'package:learn_pulse/features/dashboard/dashboard_pages.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
  localizationsDelegates: l10nDelegates,
  supportedLocales: l10nLocales,
  theme: buildTheme(Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets(
    'StatusPill always carries words and an icon for non-neutral tones',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              StatusPill('Graded 40/50', tone: Tone.success),
              StatusPill('Overdue', tone: Tone.danger),
              StatusPill('Awaiting grading', tone: Tone.attention),
            ],
          ),
        ),
      );
      expect(find.text('Graded 40/50'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    },
  );

  testWidgets('GroupedRows puts hairlines between rows only', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GroupedRows(children: [Text('one'), Text('two'), Text('three')]),
      ),
    );
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('Wordmark is announced as LearnPulse', (tester) async {
    await tester.pumpWidget(_wrap(const Wordmark()));
    expect(find.bySemanticsLabel('LearnPulse'), findsOneWidget);
  });

  group('ErrorState', () {
    Future<void> show(WidgetTester t, AppErrorKind k, String msg) async {
      await t.pumpWidget(
        _wrap(ErrorState(error: AppError(k, msg), onRetry: () {})),
      );
    }

    testWidgets('offline, signed-out and conflict each get their own title', (
      tester,
    ) async {
      await show(tester, AppErrorKind.network, 'x');
      expect(find.text('You are offline'), findsOneWidget);
      await show(tester, AppErrorKind.invalidCredentials, 'x');
      expect(find.text('Session expired'), findsOneWidget);
      await show(tester, AppErrorKind.conflict, 'x');
      expect(find.text('This changed elsewhere'), findsOneWidget);
      await show(tester, AppErrorKind.unknown, 'x');
      expect(find.text('Could not load this'), findsOneWidget);
    });

    testWidgets(
      'forbidden and not found are separate and never confirm a hidden item',
      (tester) async {
        await show(tester, AppErrorKind.forbidden, 'm');
        expect(find.text('Access denied'), findsOneWidget);
        await show(tester, AppErrorKind.notFound, 'm');
        expect(find.text('Not found'), findsOneWidget);
        expect(
          find.textContaining('may have been removed, or you may no longer'),
          findsOneWidget,
        );
      },
    );

    testWidgets('retry callback fires', (tester) async {
      var n = 0;
      await tester.pumpWidget(
        _wrap(
          ErrorState(
            error: const AppError(AppErrorKind.network, 'm'),
            onRetry: () => n++,
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      expect(n, 1);
    });
  });

  testWidgets(
    'SkeletonList stops animating when the OS asks for reduced motion',
    (tester) async {
      await tester.pumpWidget(_wrap(const SkeletonList(), reduceMotion: true));
      await tester
          .pumpAndSettle(); // would never settle if the pulse still looped
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    },
  );

  testWidgets(
    'empty and error states scroll instead of overflowing at 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          theme: buildTheme(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No courses yet',
                hint:
                    'Open the Courses tab and enter the join code from your teacher.',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('metric grid is two columns normally and one at large text', (
    tester,
  ) async {
    Future<double> cellWidth(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          theme: buildTheme(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SizedBox(
                width: 400,
                child: metricGrid(const [
                  MetricCard('1', 'A'),
                  MetricCard('2', 'B'),
                ]),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(MetricCard).first).width;
    }

    expect(await cellWidth(1), lessThan(200));
    expect(await cellWidth(2), greaterThan(300));
  });

  test('theme keeps the brand seed, one shape scale and fade transition', () {
    final t = buildTheme(Brightness.light);
    expect(Radii.sm < Radii.md && Radii.md < Radii.lg, isTrue);
    expect(t.cardTheme.elevation, 0);
    final card = t.cardTheme.shape! as RoundedRectangleBorder;
    expect(card.borderRadius, BorderRadius.circular(Radii.lg));
    expect(
      t.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<FadeForwardsPageTransitionsBuilder>(),
    );
    final reduced = buildTheme(Brightness.light, reduceMotion: true);
    expect(
      reduced.pageTransitionsTheme.builders[TargetPlatform.android],
      isNot(isA<FadeForwardsPageTransitionsBuilder>()),
    );
  });
}
