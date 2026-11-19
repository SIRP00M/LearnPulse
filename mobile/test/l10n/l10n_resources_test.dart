import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> _messages(String lang) => {
  for (final e in _arb(lang).entries)
    if (!e.key.startsWith('@')) e.key: e.value as String,
};

/// Names used as `{name}` arguments or plural selectors (ICU keywords excluded).
Set<String> _placeholders(String v) => RegExp(
  r'\{([A-Za-z_]\w*)\s*[,}]',
).allMatches(v).map((m) => m.group(1)!).toSet();

void main() {
  final en = _messages('en');
  final th = _messages('th');
  final ms = _messages('ms');

  test('en, th and ms define exactly the same keys', () {
    expect(th.keys.toSet(), en.keys.toSet());
    expect(ms.keys.toSet(), en.keys.toSet());
  });

  test('placeholders match per key', () {
    for (final k in en.keys) {
      final p = _placeholders(en[k]!)..remove('plural');
      expect(_placeholders(th[k]!)..remove('plural'), p, reason: 'th $k');
      expect(_placeholders(ms[k]!)..remove('plural'), p, reason: 'ms $k');
    }
  });

  test('template documents every key', () {
    final raw = _arb('en');
    for (final k in en.keys) {
      expect(raw['@$k'], isNotNull, reason: 'missing @$k');
      expect((raw['@$k'] as Map)['description'], isNotEmpty);
    }
  });

  test('no empty values', () {
    for (final m in [en, th, ms]) {
      for (final e in m.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    }
  });

  test('Thai values contain Thai script when English has letters', () {
    final thai = RegExp(r'[฀-๿]');
    for (final k in en.keys) {
      final literal = en[k]!.replaceAll(RegExp(r'\{[^{}]*\}'), '');
      if (RegExp(r'[A-Za-z]').hasMatch(literal) && k != 'appTitle') {
        // Brand-only strings are the one exception.
        expect(thai.hasMatch(th[k]!), isTrue, reason: k);
      }
    }
  });

  test('Malay stays Malaysian (no Indonesian vocabulary)', () {
    final banned = RegExp(
      r'\b(kata sandi|sandi|unggah|unduh|berkas|surel|silakan|tugas akhir|pengguna|mohon maaf)\b',
      caseSensitive: false,
    );
    for (final e in ms.entries) {
      expect(banned.hasMatch(e.value), isFalse, reason: '${e.key}: ${e.value}');
    }
    // Spot-check the approved Malaysian terms are what the app really uses.
    expect(ms['authPassword'], 'Kata laluan');
    expect(ms['authEmail'], 'E-mel');
    expect(ms['authSignIn'], 'Log masuk');
    expect(ms['navTasks'], 'Tugasan');
    expect(ms['navCourses'], 'Kursus');
  });
}
