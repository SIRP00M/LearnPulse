import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'locale_controller.dart';

/// Gives widgets (signed in or out) access to the device language preference.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}

/// Compact language dropdown. Labels are endonyms (never translated), each drawn with its own
/// locale so Thai and Malay pick the right font. Changing it applies immediately with no restart,
/// and does not rebuild navigation or clear text fields (only Localizations changes).
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.showLabel = true});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final current =
        controller.language ??
        AppLanguage.fromLocale(Localizations.localeOf(context));
    return Semantics(
      container: true,
      label: l.languageSelectorLabel,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: showLabel ? l.languageTitle : null,
          prefixIcon: const Icon(Icons.language),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AppLanguage>(
            key: const Key('language-selector'),
            isExpanded: true,
            value: current,
            onChanged: (v) {
              if (v != null) controller.setLanguage(v);
            },
            items: [
              for (final lang in AppLanguage.values)
                DropdownMenuItem(
                  key: Key('language-${lang.code}'),
                  value: lang,
                  child: Text(
                    lang.endonym,
                    locale: lang.locale,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
