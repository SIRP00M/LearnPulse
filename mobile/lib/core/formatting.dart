import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../l10n/app_localizations.dart';

/// Loads intl date symbols for every language (en, th, ms); call once at startup (and in tests).
Future<void> initFormatting() => initializeDateFormatting();

/// Locale-aware writing of dates, times and numbers. Language only changes how a value is
/// written: callers keep passing the same server-authoritative DateTime / numbers.
/// Thai prints the Buddhist Era year with the era marker `พ.ศ.` wherever a year is shown.
class AppFormat {
  const AppFormat(this.tag);

  /// intl locale tag: `en`, `th` or `ms`.
  final String tag;

  /// Updated by the app whenever the active locale changes. Context-free helpers (legacy call
  /// sites) read it; prefer [AppFormat.of] so widgets rebuild when the language changes.
  static AppFormat current = const AppFormat('en');

  static AppFormat forLocale(Locale l) => AppFormat(
    const {'th', 'ms'}.contains(l.languageCode) ? l.languageCode : 'en',
  );

  static AppFormat of(BuildContext context) =>
      forLocale(Localizations.localeOf(context));

  bool get buddhist => tag == 'th';

  /// "2026" or "พ.ศ. 2569".
  String year(DateTime d) => buddhist ? 'พ.ศ. ${d.year + 543}' : '${d.year}';

  static bool _ready = false;

  DateFormat _f(String pattern) {
    if (!_ready) {
      // The bundled symbol tables are installed synchronously; safe for pure-Dart callers/tests.
      initializeDateFormatting();
      _ready = true;
    }
    return DateFormat(pattern, tag);
  }

  /// "10 Nov" (no year).
  String dayMonth(DateTime d) => _f('d MMM').format(d);

  /// "Tue 10 Nov" (no year).
  String weekdayDayMonth(DateTime d) => _f('EEE d MMM').format(d);

  /// "10 Nov 2026" / "10 พ.ย. พ.ศ. 2569".
  String date(DateTime d) => '${dayMonth(d)} ${year(d)}';

  /// "Tue 10 Nov 2026".
  String dateLong(DateTime d) => '${weekdayDayMonth(d)} ${year(d)}';

  /// "November 2026" / "พฤศจิกายน พ.ศ. 2569".
  String monthYear(DateTime d) => '${_f('MMMM').format(d)} ${year(d)}';

  /// "9 Nov – 15 Nov 2026".
  String range(DateTime a, DateTime b) =>
      '${dayMonth(a)} – ${dayMonth(b)} ${year(b)}';

  String time(DateTime d) => _f('HH:mm').format(d);

  /// "10 Nov 2026, 14:30".
  String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  /// "Tue 10 Nov 2026, 14:30".
  String dateTimeLong(DateTime d) => '${dateLong(d)}, ${time(d)}';

  /// Upper-case month for compact calendar badges ("NOV"; Thai has no case).
  String monthBadge(DateTime d) => _f('MMM').format(d).toUpperCase();

  /// Weekday abbreviation for ISO weekday 1 (Mon) .. 7 (Sun).
  String weekdayShort(int isoWeekday) =>
      _f('EEE').format(DateTime(2024, 1, isoWeekday)); // 2024-01-01 is a Monday

  /// "2.5 MB" from 1 MB up, otherwise whole KB rounded up ("120 KB").
  String fileSize(int bytes) => bytes >= 1024 * 1024
      ? '${NumberFormat('0.0', tag).format(bytes / (1024 * 1024))} MB'
      : '${NumberFormat('0', tag).format((bytes / 1024).ceil())} KB';

  String number(num v) => NumberFormat.decimalPattern(tag).format(v);

  /// 66.7 -> "66.7%", 100 -> "100%" (the argument is already 0..100).
  String percent(double v) => '${NumberFormat('#,##0.#', tag).format(v)}%';

  /// Today / Tomorrow / Yesterday, otherwise "Mon 16 Nov" (calendar dates, no time zone).
  String relativeDay(AppLocalizations l, DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(n.year, n.month, n.day)).inDays;
    return switch (diff) {
      0 => l.relativeToday,
      1 => l.relativeTomorrow,
      -1 => l.relativeYesterday,
      _ => weekdayDayMonth(d),
    };
  }
}
