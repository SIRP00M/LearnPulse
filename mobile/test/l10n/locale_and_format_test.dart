import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/formatting.dart';
import 'package:learn_pulse/core/locale_controller.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/l10n/app_localizations_en.dart';
import 'package:learn_pulse/l10n/app_localizations_ms.dart';
import 'package:learn_pulse/l10n/app_localizations_th.dart';

import '../fakes.dart';

Locale _r(List<Locale> device) =>
    LocaleController.resolve(device, LocaleController.supported);

void main() {
  group('device locale detection', () {
    test('table', () {
      expect(_r(const [Locale('th', 'TH')]).languageCode, 'th');
      expect(_r(const [Locale('ms', 'MY')]).languageCode, 'ms');
      expect(_r(const [Locale('ms')]).languageCode, 'ms');
      expect(_r(const [Locale('ms', 'BN')]).languageCode, 'ms');
      expect(_r(const [Locale('en', 'GB')]).languageCode, 'en');
      expect(_r(const [Locale('id', 'ID')]).languageCode, 'en');
      expect(_r(const [Locale('id')]).languageCode, 'en');
      expect(_r(const [Locale('fr')]).languageCode, 'en');
      expect(_r(const []).languageCode, 'en');
      expect(
        LocaleController.resolve(null, LocaleController.supported).languageCode,
        'en',
      );
    });

    test('first supported device language wins', () {
      expect(
        _r(const [Locale('fr'), Locale('th'), Locale('ms')]).languageCode,
        'th',
      );
      expect(
        _r(const [Locale('id', 'ID'), Locale('ms', 'MY')]).languageCode,
        'ms',
      );
    });
  });

  group('LocaleController', () {
    test('null until chosen; persists across a restart', () async {
      final store = InMemoryPreferenceStore();
      final a = LocaleController(store);
      await a.load();
      expect(a.locale, isNull);
      var notified = 0;
      a.addListener(() => notified++);
      await a.setLanguage(AppLanguage.ms);
      expect(a.locale, const Locale('ms', 'MY'));
      expect(notified, 1);
      expect(store.values['lp_language'], 'ms');

      final b = LocaleController(store);
      await b.load();
      expect(b.language, AppLanguage.ms);
    });

    test('an unsupported saved value is ignored', () async {
      final store = InMemoryPreferenceStore()..values['lp_language'] = 'id';
      final c = LocaleController(store);
      await c.load();
      expect(c.locale, isNull);
    });

    test('sign-out does not clear the language', () async {
      final store = InMemoryPreferenceStore();
      final locale = LocaleController(store);
      await locale.setLanguage(AppLanguage.th);
      final repo = FakeAuthRepository(
        hasSession: true,
        profile: const Profile(role: AppRole.student, fullName: 'Sam'),
      );
      final auth = AuthController(repo);
      await auth.start();
      await auth.signOut();
      expect(auth.stage, AuthStage.signedOut);
      expect(locale.language, AppLanguage.th);
      expect(store.values['lp_language'], 'th');
      auth.dispose();
    });
  });

  group('formatting', () {
    setUpAll(initFormatting);
    final d = DateTime(2026, 11, 10, 14, 30); // a Tuesday

    test('English and Malay are Gregorian', () {
      const en = AppFormat('en');
      const ms = AppFormat('ms');
      expect(en.dateTimeLong(d), 'Tue 10 Nov 2026, 14:30');
      expect(en.monthYear(d), 'November 2026');
      expect(ms.date(d), '10 Nov 2026');
      expect(ms.monthYear(d), contains('2026'));
      expect(ms.monthYear(d), isNot(contains('2569')));
    });

    test(
      'Thai uses the Buddhist Era with the era marker, day-month has no year',
      () {
        const th = AppFormat('th');
        expect(th.year(d), 'พ.ศ. 2569');
        expect(th.date(d), contains('พ.ศ. 2569'));
        expect(th.monthYear(d), 'พฤศจิกายน พ.ศ. 2569');
        expect(th.dateTime(d), endsWith('14:30'));
        expect(th.dayMonth(d), isNot(contains('25')));
        expect(th.weekdayDayMonth(d), isNot(contains('พ.ศ.')));
      },
    );

    test('numbers and percentages', () {
      const en = AppFormat('en');
      expect(en.percent(66.7), '66.7%');
      expect(en.percent(100), '100%');
      expect(en.number(1234), '1,234');
      expect(const AppFormat('th').percent(50), '50%');
    });

    test('relative days', () {
      final now = DateTime(2026, 11, 10, 23, 0);
      const en = AppFormat('en');
      expect(
        en.relativeDay(AppLocalizationsEn(), DateTime(2026, 11, 10), now: now),
        'Today',
      );
      expect(
        en.relativeDay(AppLocalizationsEn(), DateTime(2026, 11, 11), now: now),
        'Tomorrow',
      );
      expect(
        en.relativeDay(AppLocalizationsEn(), DateTime(2026, 11, 9), now: now),
        'Yesterday',
      );
      expect(
        en.relativeDay(AppLocalizationsEn(), DateTime(2026, 11, 16), now: now),
        'Mon 16 Nov',
      );
      expect(
        const AppFormat(
          'th',
        ).relativeDay(AppLocalizationsTh(), DateTime(2026, 11, 11), now: now),
        'พรุ่งนี้',
      );
      expect(
        const AppFormat(
          'ms',
        ).relativeDay(AppLocalizationsMs(), DateTime(2026, 11, 10), now: now),
        'Hari ini',
      );
    });

    test('the instant is never altered by language', () {
      final utc = DateTime.utc(2026, 11, 10, 6, 30);
      const f = AppFormat('th');
      f.dateTime(utc);
      expect(utc, DateTime.utc(2026, 11, 10, 6, 30));
    });
  });
}
