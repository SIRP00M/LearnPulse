import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';
import 'package:learn_pulse/core/formatting.dart';
import 'package:learn_pulse/core/locale_controller.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/auth_repository.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/auth/set_password_page.dart';
import 'package:learn_pulse/features/auth/sign_in_page.dart';
import 'package:learn_pulse/features/auth/welcome_page.dart';
import 'package:learn_pulse/features/home/role_home.dart';
import 'package:learn_pulse/l10n/app_localizations.dart';

import 'fakes.dart';
import 'l10n_helpers.dart';

class _DelayedProfile extends FakeAuthRepository {
  _DelayedProfile() : super(hasSession: true);
  final gate = Completer<Profile>();
  @override
  Future<Profile> loadProfile() => gate.future;
}

void main() {
  testWidgets('guest starts on Welcome; CTA and Android back preserve locale', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    final auth = AuthController(repo);
    final locale = LocaleController(InMemoryPreferenceStore());
    addTearDown(auth.dispose);
    addTearDown(locale.dispose);
    await pumpApp(tester, auth, fakeServices(locale: locale));
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);
    expect(find.text('Create a student account'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-th')).last);
    await tester.pumpAndSettle();
    expect(locale.language, AppLanguage.th);
    await tester.ensureVisible(find.byKey(const Key('welcome-sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
    expect(auth.canReturnToWelcome, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(locale.language, AppLanguage.th);
    expect(repo.calls, isEmpty);
  });

  for (final role in AppRole.values) {
    testWidgets('delayed $role restoration never renders Welcome', (
      tester,
    ) async {
      await initFormatting();
      final repo = _DelayedProfile();
      final auth = AuthController(repo);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        LearnPulseApp(controller: auth, services: fakeServices()),
      );
      final restored = auth.start();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(WelcomePage), findsNothing);
      repo.gate.complete(Profile(role: role, fullName: 'Test learner'));
      await restored;
      await tester.pumpAndSettle();
      expect(find.byType(RoleHome), findsOneWidget);
      expect(find.byType(WelcomePage), findsNothing);
      expect(auth.profile!.role, role);
    });
  }

  testWidgets('recovery event bypasses Welcome and sign-out keeps Sign In', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    final auth = AuthController(repo);
    addTearDown(auth.dispose);
    await pumpApp(tester, auth, fakeServices());
    repo.emit(AuthChange.passwordRecovery);
    await tester.pumpAndSettle();
    expect(find.byType(SetPasswordPage), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
    expect(auth.canReturnToWelcome, isFalse);
  });

  test(
    'password-reset success keeps the existing direct Sign In destination',
    () async {
      final auth = AuthController(FakeAuthRepository());
      addTearDown(auth.dispose);
      await auth.start();
      auth.showView(SignedOutView.signIn);
      expect(auth.canReturnToWelcome, isTrue);
      await auth.requestPasswordReset('test@example.test');
      expect(auth.view, SignedOutView.signIn);
      expect(auth.canReturnToWelcome, isFalse);
    },
  );

  for (final lang in AppLanguage.values) {
    for (final width in [320.0, 430.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        for (final brightness in Brightness.values) {
          testWidgets('Welcome ${lang.code} ${width}dp x$scale $brightness', (
            tester,
          ) async {
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            final locale = LocaleController(InMemoryPreferenceStore());
            await locale.setLanguage(lang);
            final auth = AuthController(FakeAuthRepository());
            addTearDown(auth.dispose);
            addTearDown(locale.dispose);
            await pumpApp(
              tester,
              auth,
              fakeServices(locale: locale),
              size: Size(width, 780),
              textScale: scale,
            );
            final l = AppLocalizations.of(
              tester.element(find.byType(WelcomePage)),
            );
            expect(find.text(l.welcomeTitle), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(
              find.byKey(const Key('welcome-sign-in')),
            );
            await tester.pumpAndSettle();
            final buttonSize = tester.getSize(
              find.byKey(const Key('welcome-sign-in')),
            );
            expect(buttonSize.height, greaterThanOrEqualTo(48));
            await tester.tap(find.byKey(const Key('welcome-sign-in')));
            await tester.pumpAndSettle();
            expect(find.byType(SignInPage), findsOneWidget);
            await tester.ensureVisible(
              find.byKey(const Key('back-to-welcome')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('back-to-welcome')));
            await tester.pumpAndSettle();
            expect(find.byType(WelcomePage), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
