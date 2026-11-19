import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app ships. [code] is what is persisted under `lp_language`.
enum AppLanguage {
  en('en', Locale('en'), 'English'),
  th('th', Locale('th', 'TH'), 'ไทย'),
  ms('ms', Locale('ms', 'MY'), 'Bahasa Melayu');

  const AppLanguage(this.code, this.locale, this.endonym);
  final String code;
  final Locale locale;

  /// Shown in its own language, never translated.
  final String endonym;

  static AppLanguage? fromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }

  static AppLanguage fromLocale(Locale l) => switch (l.languageCode) {
    'th' => th,
    'ms' => ms,
    _ => en,
  };
}

/// Device-level preference store (never Supabase, never cleared on sign-out).
abstract interface class PreferenceStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferenceStore implements PreferenceStore {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }
}

class InMemoryPreferenceStore implements PreferenceStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class LocaleController extends ChangeNotifier {
  LocaleController([PreferenceStore? store])
    : _store = store ?? SharedPreferenceStore();

  static const storageKey = 'lp_language';
  static const supported = [
    Locale('en'),
    Locale('th', 'TH'),
    Locale('ms', 'MY'),
  ];

  final PreferenceStore _store;
  AppLanguage? _language;

  /// Null means "follow the device" (nothing chosen yet).
  Locale? get locale => _language?.locale;
  AppLanguage? get language => _language;

  Future<void> load() async {
    try {
      final saved = AppLanguage.fromCode(await _store.read(storageKey));
      if (saved != _language) {
        _language = saved;
        notifyListeners();
      }
    } on Object {
      // An unreadable preference just means "follow the device".
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    try {
      await _store.write(storageKey, language.code);
    } on Object {
      // Still applied for this run; persistence is best effort.
    }
  }

  /// First supported device language wins; Malay (ms, ms-MY, ms-BN) maps to ms; Indonesian and
  /// everything else fall back to English.
  static Locale resolve(List<Locale>? device, Iterable<Locale> supported) {
    for (final d in device ?? const <Locale>[]) {
      final lang = AppLanguage.fromLocale(d);
      if (d.languageCode == lang.code) {
        for (final s in supported) {
          if (s.languageCode == lang.code) return s;
        }
      }
    }
    return supported.firstWhere(
      (s) => s.languageCode == 'en',
      orElse: () => supported.first,
    );
  }
}
