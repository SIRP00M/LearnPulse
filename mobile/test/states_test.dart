import 'l10n_helpers.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/states.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/auth_repository.dart';
import 'package:learn_pulse/features/auth/profile.dart';

import 'fakes.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 393,
  double scale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: l10nDelegates,
      supportedLocales: l10nLocales,
      theme: buildTheme(Brightness.light),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduceMotion,
        ),
        child: c!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

void main() {
  group('ErrorPanel', () {
    const cases = <AppErrorKind, String>{
      AppErrorKind.network: 'You are offline',
      AppErrorKind.timeout: 'This is taking too long',
      AppErrorKind.invalidCredentials: 'Session expired',
      AppErrorKind.forbidden: 'Access denied',
      AppErrorKind.notFound: 'Not found',
      AppErrorKind.unknown: 'Could not load this',
    };
    for (final e in cases.entries) {
      testWidgets('${e.key.name} shows "${e.value}" at 320 dp and 300%', (
        tester,
      ) async {
        await _pump(
          tester,
          ErrorPanel(
            error: AppError(e.key, 'Specific detail.'),
            onRetry: () {},
          ),
          width: 320,
          scale: 3,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(e.value), findsOneWidget);
      });
    }

    testWidgets('retry runs the callback; denied and missing do not offer it', (
      tester,
    ) async {
      var n = 0;
      await _pump(
        tester,
        ErrorPanel(
          error: const AppError(AppErrorKind.network, 'Offline.'),
          onRetry: () => n++,
        ),
      );
      await tester.tap(find.text('Try again'));
      expect(n, 1);
      await _pump(
        tester,
        ErrorPanel(
          error: const AppError(AppErrorKind.forbidden, 'No.'),
          onRetry: () {},
          onBack: () {},
        ),
      );
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Go back'), findsOneWidget);
    });

    testWidgets('an expired session offers Sign in again when a scope exists', (
      tester,
    ) async {
      var signedIn = 0;
      await _pump(
        tester,
        SessionScope(
          onSignInAgain: () => signedIn++,
          child: ErrorPanel(
            error: const AppError(AppErrorKind.invalidCredentials, 'x'),
            onRetry: () {},
          ),
        ),
      );
      await tester.tap(find.text('Sign in again'));
      expect(signedIn, 1);
    });
  });

  group('EmptyPanel', () {
    testWidgets('names the empty thing and the next step at 320 dp ×3', (
      tester,
    ) async {
      await _pump(
        tester,
        ListView(
          children: const [
            EmptyPanel(
              icon: Icons.menu_book_outlined,
              title: 'No lessons yet',
              message:
                  'Create a draft, add files, then publish it for students.',
            ),
          ],
        ),
        width: 320,
        scale: 3,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No lessons yet'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('skeletons pulse normally and stay still with reduced motion', (
      tester,
    ) async {
      await _pump(tester, const SkeletonBlock(framed: true));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
      await _pump(
        tester,
        const SkeletonBlock(framed: true),
        reduceMotion: true,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a slow load adds a calm "still working" line', (tester) async {
      await _pump(tester, const SkeletonBlock());
      expect(find.textContaining('Still working'), findsNothing);
      await tester.pump(const Duration(seconds: 9));
      expect(find.textContaining('Still working'), findsOneWidget);
    });

    testWidgets('retry button shows progress and ignores taps while busy', (
      tester,
    ) async {
      var n = 0;
      await _pump(tester, RetryButton(onPressed: () => n++, busy: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(n, 0);
    });

    testWidgets('page skeleton fits 320 dp at 300%', (tester) async {
      await _pump(tester, const SkeletonPage(), width: 320, scale: 3);
      expect(tester.takeException(), isNull);
    });
  });

  group('session expired', () {
    Future<AuthController> start(
      WidgetTester tester,
      FakeAuthRepository repo,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = AuthController(repo);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        LearnPulseApp(controller: c, services: fakeServices()),
      );
      await c.start();
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets(
      'a server-ended session explains itself; Sign in again returns to sign-in',
      (tester) async {
        final repo = FakeAuthRepository(
          hasSession: true,
          profile: const Profile(role: AppRole.student, fullName: 'Sam'),
        );
        await start(tester, repo);
        repo.emit(AuthChange.signedOut);
        await tester.pumpAndSettle();
        expect(find.text('You were signed out'), findsOneWidget);
        await tester.tap(find.text('Sign in again'));
        await tester.pumpAndSettle();
        expect(find.text('You were signed out'), findsNothing);
        expect(find.text('Forgot password?'), findsOneWidget);
      },
    );

    testWidgets('a sign-out the user chose goes straight to sign-in', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        hasSession: true,
        profile: const Profile(role: AppRole.student, fullName: 'Sam'),
      );
      final c = await start(tester, repo);
      unawaited(c.signOut());
      await tester.pumpAndSettle();
      expect(find.text('You were signed out'), findsNothing);
      expect(find.text('Forgot password?'), findsOneWidget);
    });
  });
}
