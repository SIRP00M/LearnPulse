import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';
import 'package:learn_pulse/core/formatting.dart';
import 'package:learn_pulse/core/language_selector.dart';
import 'package:learn_pulse/core/locale_controller.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/l10n/app_localizations.dart';

/// Add to any `MaterialApp(...)` in a widget test so localized widgets resolve (English by default).
const l10nDelegates = AppLocalizations.localizationsDelegates;
const l10nLocales = AppLocalizations.supportedLocales;

/// Wraps [child] in a localized MaterialApp; [locale] defaults to English.
Widget wrapWithL10n(
  Widget child, {
  Locale locale = const Locale('en'),
  LocaleController? controller,
}) {
  final app = MaterialApp(
    localizationsDelegates: l10nDelegates,
    supportedLocales: l10nLocales,
    locale: locale,
    home: Scaffold(body: child),
  );
  return controller == null
      ? app
      : LocaleScope(controller: controller, child: app);
}

/// Pumps the real app (LearnPulseApp) against an auth controller; returns once settled.
Future<void> pumpApp(
  WidgetTester tester,
  AuthController controller,
  dynamic services, {
  Size size = const Size(360, 780),
  double textScale = 1.0,
}) async {
  await initFormatting();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    LearnPulseApp(controller: controller, services: services),
  );
  await controller.start();
  await tester.pumpAndSettle();
}
