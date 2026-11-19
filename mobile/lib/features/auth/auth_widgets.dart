import 'package:flutter/material.dart';

import '../../core/adaptive.dart';
import '../../core/theme.dart';
import '../../core/language_selector.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import '../../core/academic.dart';
import 'auth_controller.dart';

/// Scrollable, width-limited page body that works from 320 px up and with the keyboard open.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.signIn = false,
  });

  final String title;
  final List<Widget> children;

  /// The sign-in screen shows the welcome headline and omits the duplicate card title.
  final bool signIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(StudioLayout.gutter(constraints.maxWidth)),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories,
                          color: scheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: Space.sm),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Wordmark(size: 26),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xl),
                    StudioColumns(
                      primary: Container(
                        padding: const EdgeInsets.all(Space.lg),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.secondary,
                              Color.lerp(scheme.secondary, Colors.teal, .25)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(Radii.lg + 4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.authPortalEyebrow,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: Space.lg),
                            Semantics(
                              header: true,
                              // Capped so "LearnPulse." never breaks mid-word at large text sizes.
                              child: ScaleCap(
                                max: 1.6,
                                child: Text(
                                  signIn ? l.authWelcomeTitle : title,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(color: scheme.onSecondary),
                                ),
                              ),
                            ),
                            const SizedBox(height: Space.md),
                            Text(
                              l.authTagline,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondary: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: Space.maxFormWidth,
                          ),
                          child: AcademicCard(
                            children: [
                              const LanguageSelector(),
                              const SizedBox(height: Space.md),
                              if (signIn) ...[
                                Text(
                                  l.authSignIn,
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: Space.md),
                              ],
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the controller's current error / notice above a form.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final error = controller.error;
    final text = error?.localizedMessage(l) ?? controller.noticeText(l);
    if (text == null) return const SizedBox.shrink();
    final isError = error != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: isError ? scheme.errorContainer : scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isError
                  ? scheme.onErrorContainer
                  : scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary button that shows progress and ignores taps while the controller is busy.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// Convenience: rebuilds [builder] whenever the controller changes.
class ControllerBuilder extends StatelessWidget {
  const ControllerBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  final AuthController controller;
  final Widget Function(BuildContext, AuthController) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (c, _) => builder(c, controller),
  );
}
