import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/locale_controller.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/profile/profile_pages.dart';

import '../fakes.dart';
import '../l10n_helpers.dart';

const _signIn = {'en': 'Sign in', 'th': 'เข้าสู่ระบบ', 'ms': 'Log masuk'};
const _email = {'en': 'Email', 'th': 'อีเมล', 'ms': 'E-mel'};
const _emailRequired = {
  'en': 'Enter your email address',
  'th': 'กรอกที่อยู่อีเมลของคุณ',
  'ms': 'Masukkan alamat e-mel anda',
};

Future<(AuthController, LocaleController)> _signedOut(
  WidgetTester tester, {
  Size size = const Size(360, 780),
  double scale = 1,
  AppLanguage? start,
  FakeAuthRepository? repo,
}) async {
  final store = InMemoryPreferenceStore();
  final locale = LocaleController(store);
  if (start != null) await locale.setLanguage(start);
  final auth = AuthController(repo ?? FakeAuthRepository());
  addTearDown(auth.dispose);
  await pumpApp(
    tester,
    auth,
    fakeServices(locale: locale),
    size: size,
    textScale: scale,
  );
  if (auth.stage == AuthStage.signedOut) {
    await tester.ensureVisible(find.byKey(const Key('welcome-sign-in')));
    await tester.tap(find.byKey(const Key('welcome-sign-in')));
    await tester.pumpAndSettle();
  }
  return (auth, locale);
}

void main() {
  for (final lang in AppLanguage.values) {
    testWidgets('sign-in renders in ${lang.code}', (tester) async {
      await _signedOut(tester, start: lang);
      expect(find.text(_signIn[lang.code]!), findsWidgets);
      expect(find.text(_email[lang.code]!), findsWidgets);
    });
  }

  testWidgets('selector switches immediately and keeps typed text', (
    tester,
  ) async {
    final (_, locale) = await _signedOut(tester);
    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('language-selector')));
    await tester.tap(find.byKey(const Key('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-th')).last);
    await tester.pumpAndSettle();
    expect(locale.language, AppLanguage.th);
    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    expect(find.text('a@b.co'), findsOneWidget);
  });

  testWidgets('a visible validation message re-translates on switch', (
    tester,
  ) async {
    final (_, locale) = await _signedOut(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text(_emailRequired['en']!), findsOneWidget);
    await locale.setLanguage(AppLanguage.ms);
    await tester.pumpAndSettle();
    expect(find.text(_emailRequired['en']!), findsNothing);
    expect(find.text(_emailRequired['ms']!), findsOneWidget);
    await locale.setLanguage(AppLanguage.th);
    await tester.pumpAndSettle();
    expect(find.text(_emailRequired['th']!), findsOneWidget);
  });

  testWidgets('a server error re-translates on switch', (tester) async {
    final repo = FakeAuthRepository()
      ..signInError = Exception('SocketException: x');
    final (auth, locale) = await _signedOut(tester, repo: repo);
    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.enterText(find.byType(TextFormField).last, 'pw');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection'), findsOneWidget);
    expect(
      auth.error!.message,
      contains('No connection'),
    ); // English kept for logs
    await locale.setLanguage(AppLanguage.ms);
    await tester.pumpAndSettle();
    expect(find.textContaining('Tiada sambungan'), findsOneWidget);
  });

  testWidgets('Profile selector works and the choice survives sign-out', (
    tester,
  ) async {
    final store = InMemoryPreferenceStore();
    final locale = LocaleController(store);
    final auth = AuthController(
      FakeAuthRepository(
        hasSession: true,
        profile: const Profile(role: AppRole.student, fullName: 'Sam Lee'),
      ),
    );
    addTearDown(auth.dispose);
    await pumpApp(tester, auth, fakeServices(locale: locale));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('language-selector')));
    await tester.tap(find.byKey(const Key('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-ms')).last);
    await tester.pumpAndSettle();
    expect(find.text('Kursus'), findsWidgets); // bottom navigation
    expect(find.text('Profil'), findsWidgets);
    expect(store.values['lp_language'], 'ms');
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Log masuk'), findsWidgets);
    expect(store.values['lp_language'], 'ms');
  });

  // Overflow checks: no layout exception at any width / text scale / language.
  for (final w in [320.0, 360.0, 393.0, 430.0]) {
    for (final s in [1.0, 2.0, 3.0]) {
      for (final lang in AppLanguage.values) {
        testWidgets('sign-in fits ${w.toInt()}dp x$s ${lang.code}', (
          tester,
        ) async {
          await _signedOut(tester, size: Size(w, 780), scale: s, start: lang);
          expect(tester.takeException(), isNull);
        });
        testWidgets('profile fits ${w.toInt()}dp x$s ${lang.code}', (
          tester,
        ) async {
          final locale = LocaleController(InMemoryPreferenceStore());
          await locale.setLanguage(lang);
          final auth = AuthController(
            FakeAuthRepository(
              hasSession: true,
              profile: const Profile(
                role: AppRole.teacher,
                fullName: 'Sam Lee',
              ),
            ),
          );
          addTearDown(auth.dispose);
          await pumpApp(
            tester,
            auth,
            fakeServices(locale: locale),
            size: Size(w, 780),
            textScale: s,
          );
          await tester.tap(find.byIcon(Icons.account_circle_outlined));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byKey(const Key('open-account')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('open-account')));
          await tester.pumpAndSettle();
          expect(find.byType(AccountPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
