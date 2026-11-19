import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';
import 'package:learn_pulse/features/profile/profile_pages.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';
import 'ui_test_helpers.dart';

Future<AuthController> _pump(
  WidgetTester tester,
  FakeAuthRepository repo, {
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = AuthController(repo);
  addTearDown(c.dispose);
  await tester.pumpWidget(
    LearnPulseApp(controller: c, services: fakeServices()),
  );
  await c.start();
  await tester.pumpAndSettle();
  if (c.view == SignedOutView.welcome && !repo.hasSession) {
    await tester.ensureVisible(find.byKey(const Key('welcome-sign-in')));
    await tester.tap(find.byKey(const Key('welcome-sign-in')));
    await tester.pumpAndSettle();
  }
  return c;
}

void main() {
  testWidgets(
    'shows sign-in and forgot-password without advertising closed registration',
    (tester) async {
      await _pump(tester, FakeAuthRepository());
      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Create a student account'), findsNothing);
      expect(
        find.textContaining('Teacher'),
        findsNothing,
      ); // no role selector anywhere
    },
  );

  testWidgets('sign-in validates fields before calling the server', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await _pump(tester, repo);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('teacher and student are routed from the server profile', (
    tester,
  ) async {
    for (final p in [
      const Profile(role: AppRole.teacher, fullName: 'Tia'),
      const Profile(role: AppRole.student, fullName: 'Sam'),
    ]) {
      await _pump(tester, FakeAuthRepository(hasSession: true, profile: p));
      final chip = tester.widget<Chip>(find.byKey(const Key('role-chip')));
      expect(
        (chip.label as Text).data,
        p.role == AppRole.teacher ? 'Teacher' : 'Student',
      );
      expect(find.text('Hello, ${p.fullName}'), findsOneWidget);
    }
  });

  testWidgets('sign-in error is shown and the form stays usable', (
    tester,
  ) async {
    final repo = FakeAuthRepository()
      ..signInError = const AuthApiException('x', code: 'invalid_credentials');
    await _pump(tester, repo);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'a@b.co',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'whatever',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'sign-up flow ends on the confirmation page with resend cooldown',
    (tester) async {
      final repo = FakeAuthRepository();
      final c = await _pump(tester, repo);
      c.showView(SignedOutView.signUp);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'New Person',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'n@x.co',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'weak',
      );
      await reveal(tester, find.widgetWithText(FilledButton, 'Create account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();
      expect(find.text('Use at least 10 characters'), findsOneWidget);
      expect(repo.calls, isEmpty);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'GoodPassword1',
      );
      await reveal(tester, find.widgetWithText(FilledButton, 'Create account'));
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('n@x.co'), findsOneWidget);
      expect(find.textContaining('Resend email in'), findsOneWidget);
      // Unmount the page so its periodic timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('offline profile load shows a retry state, then recovers', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      hasSession: true,
      profile: const Profile(role: AppRole.student, fullName: 'Sam'),
    )..profileFailures.add(AuthRetryableFetchException());
    await _pump(tester, repo);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Sam'), findsOneWidget);
  });

  testWidgets('sign out returns to sign-in', (tester) async {
    await _pump(
      tester,
      FakeAuthRepository(
        hasSession: true,
        profile: const Profile(role: AppRole.teacher, fullName: 'Tia'),
      ),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sign-out')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(AccountPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('sign-out')));
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(320, 480)]) {
    testWidgets(
      'auth pages do not overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final c = await _pump(tester, FakeAuthRepository(), size: size);
        expect(tester.takeException(), isNull);
        c.showView(SignedOutView.signUp);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        c.showView(SignedOutView.forgotPassword);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('large system font still lays out', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await _pump(tester, FakeAuthRepository(), size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
