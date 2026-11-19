import 'package:flutter/material.dart';

import '../../core/adaptive.dart';
import '../../core/language_selector.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';

/// Guest introduction; AuthGate decides only after session restoration completes.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final features = [
      (Icons.menu_book_outlined, l.navCourses),
      (Icons.checklist_rtl, l.navTasks),
      (Icons.insights_outlined, l.welcomeProgress),
    ];
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    return Scaffold(
      body: SafeArea(
        child: StudioPage(
          maxWidth: 520,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories, size: 30, color: s.primary),
                const SizedBox(width: Space.sm),
                const Flexible(child: Wordmark(size: 28)),
              ],
            ),
            const SizedBox(height: Space.xl),
            Text(
              l.authPortalEyebrow,
              style: theme.textTheme.labelMedium?.copyWith(color: s.primary),
            ),
            const SizedBox(height: Space.md),
            Semantics(
              header: true,
              child: Text(
                l.welcomeTitle,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: Space.md),
            Text(
              l.welcomeDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: s.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.lg),
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: s.surfaceContainerLowest,
                border: Border.all(color: s.outlineVariant),
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.welcomeFeatures,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  if (largeText)
                    for (final feature in features)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.sm),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: Icon(feature.$1, color: s.primary),
                            ),
                            const SizedBox(width: Space.md),
                            Expanded(child: Text(feature.$2)),
                          ],
                        ),
                      )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final feature in features)
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(Space.md),
                                  decoration: BoxDecoration(
                                    color: s.primaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      Radii.md,
                                    ),
                                  ),
                                  child: ExcludeSemantics(
                                    child: Icon(
                                      feature.$1,
                                      color: s.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Space.sm),
                                Text(
                                  feature.$2,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelLarge,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            const LanguageSelector(),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              key: const Key('welcome-sign-in'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(Space.minTap),
              ),
              onPressed: () => controller.showView(SignedOutView.signIn),
              icon: const Icon(Icons.login),
              label: Text(l.authSignIn),
            ),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              key: const Key('welcome-try-demo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(Space.minTap),
              ),
              onPressed: () => controller.showView(SignedOutView.demoSelector),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l.demoTry),
            ),
          ],
        ),
      ),
    );
  }
}
