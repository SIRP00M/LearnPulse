import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_error.dart';
import 'theme.dart';

/// Lets a failed load offer "Sign in again" without every page knowing about auth.
class SessionScope extends InheritedWidget {
  const SessionScope({
    super.key,
    required this.onSignInAgain,
    required super.child,
  });

  final VoidCallback onSignInAgain;

  static SessionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>();

  @override
  bool updateShouldNotify(SessionScope old) => false;
}

/// Icon, title and plain sentence for a failed load (in the active language). Forbidden and
/// not-found stay separate screens, but neither says whether a hidden item exists.
({IconData icon, String title, String message}) errorLook(
  AppLocalizations l,
  AppError e,
) => switch (e.kind) {
  AppErrorKind.network => (
    icon: Icons.wifi_off_outlined,
    title: l.stateOfflineTitle,
    message: l.stateOfflineMessage,
  ),
  AppErrorKind.timeout => (
    icon: Icons.hourglass_empty,
    title: l.stateTimeoutTitle,
    message: l.stateTimeoutMessage,
  ),
  AppErrorKind.invalidCredentials => (
    icon: Icons.lock_clock_outlined,
    title: l.stateExpiredTitle,
    message: l.stateExpiredMessage,
  ),
  AppErrorKind.forbidden => (
    icon: Icons.lock_outline,
    title: l.stateForbiddenTitle,
    message: l.stateForbiddenMessage,
  ),
  AppErrorKind.notFound => (
    icon: Icons.search_off,
    title: l.stateNotFoundTitle,
    message: l.stateNotFoundMessage,
  ),
  AppErrorKind.conflict => (
    icon: Icons.sync_problem,
    title: l.stateConflictTitle,
    message: l.stateConflictMessage,
  ),
  _ => (
    icon: Icons.error_outline,
    title: l.stateUnknownTitle,
    message: l.stateUnknownMessage,
  ),
};

/// A calm, framed message with an icon, an explanation and up to two actions. [full] centres it on a
/// page-sized area (scrolling if the text is large); otherwise it sits inline in a list.
class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.primary,
    this.secondary,
    this.full = true,
    this.framed = true,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? primary;
  final Widget? secondary;
  final bool full;

  /// False inside an [AcademicSection], which already supplies the frame.
  final bool framed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final content = Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: danger
                    ? scheme.errorContainer
                    : scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: danger
                    ? scheme.onErrorContainer
                    : scheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Semantics(
            header: true,
            liveRegion: danger,
            child: Text(
              title,
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (primary != null) ...[const SizedBox(height: Space.lg), primary!],
          if (secondary != null) ...[
            const SizedBox(height: Space.sm),
            secondary!,
          ],
        ],
      ),
    );
    final card = framed
        ? Material(
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: content,
          )
        : content;
    final bounded = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: card,
    );
    if (!full) return Center(child: bounded);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.page),
        child: bounded,
      ),
    );
  }
}

/// Filled "Try again" button that shows progress while the retry runs.
class RetryButton extends StatelessWidget {
  const RetryButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.label,
  });

  final VoidCallback? onPressed;
  final bool busy;

  /// Defaults to the localized "Try again".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      label: Text(busy ? l.commonTryingAgain : (label ?? l.commonTryAgain)),
    );
  }
}

/// Failed load: the right message for the failure kind, Retry, and (for an expired session) Sign in again.
/// [onBack] adds a secondary "Go back" / "Back to dashboard" action where the caller has one.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
    this.full = true,
    this.framed = true,
    this.onBack,
    this.backLabel,
  });

  final AppError error;
  final VoidCallback onRetry;
  final bool full;
  final bool framed;
  final VoidCallback? onBack;

  /// Defaults to the localized "Go back".
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final look = errorLook(l, error);
    // Network, timeout and unexpected failures carry the controller's own specific sentence.
    final useOwn =
        error.kind == AppErrorKind.network ||
        error.kind == AppErrorKind.timeout ||
        error.kind == AppErrorKind.unknown;
    final expired = error.kind == AppErrorKind.invalidCredentials;
    final signIn = expired ? SessionScope.maybeOf(context) : null;
    final retryable =
        !(error.kind == AppErrorKind.forbidden ||
            error.kind == AppErrorKind.notFound);
    final back = onBack == null
        ? null
        : OutlinedButton(
            onPressed: onBack,
            child: Text(backLabel ?? l.commonBack),
          );
    return StatePanel(
      icon: look.icon,
      title: look.title,
      message: useOwn ? error.localizedMessage(l) : look.message,
      full: full,
      framed: framed,
      danger: !expired && error.kind == AppErrorKind.unknown,
      primary: signIn != null
          ? FilledButton(
              onPressed: signIn.onSignInAgain,
              child: Text(l.commonSignInAgain),
            )
          : (retryable ? RetryButton(onPressed: onRetry) : back),
      secondary: signIn != null || retryable ? back : null,
    );
  }
}

/// A list or section with nothing in it yet: what it is, and what happens next.
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.full = false,
    this.framed = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool full;
  final bool framed;

  @override
  Widget build(BuildContext context) => StatePanel(
    icon: icon,
    title: title,
    message: message,
    primary: action,
    full: full,
    framed: framed,
  );
}

/// Shared pulse for skeletons; static when the OS asks to reduce motion. After [slowAfter] it adds a
/// polite "still working" line so a slow network never looks like a freeze.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({
    super.key,
    required this.child,
    this.slowAfter = const Duration(seconds: 8),
  });

  final Widget child;
  final Duration slowAfter;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context).commonLoading,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: FadeTransition(
              opacity: Tween(begin: 0.5, end: 1.0).animate(_c),
              child: widget.child,
            ),
          ),
          if (_slow)
            Padding(
              padding: const EdgeInsets.only(top: Space.md),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  AppLocalizations.of(context).commonStillWorking,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One grey placeholder bar.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({super.key, this.height = 14, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Radii.sm),
    ),
  );
}

/// A framed section with a heading bar and [rows] placeholder rows: matches loaded sections, lists
/// and tables, so the page does not jump when data arrives.
class SkeletonSection extends StatelessWidget {
  const SkeletonSection({super.key, this.rows = 3, this.framed = true});

  final int rows;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Padding(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (framed) const SkeletonBar(height: 18, width: 140),
          for (var i = 0; i < rows; i++) ...[
            const SizedBox(height: Space.md),
            const SkeletonBar(height: 40),
          ],
        ],
      ),
    );
    if (!framed) return body;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: body,
    );
  }
}

/// Page-sized loading: a header block plus framed sections.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key, this.sections = 2, this.rows = 3});

  final int sections;
  final int rows;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(Space.page),
    children: [
      SkeletonScope(
        child: Column(
          children: [
            const SkeletonSection(rows: 1),
            for (var i = 0; i < sections; i++) ...[
              const SizedBox(height: Space.md),
              SkeletonSection(rows: rows),
            ],
          ],
        ),
      ),
    ],
  );
}

/// Inline loading for part of a page (a list, a table); unframed by default because it normally sits
/// inside a framed section.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.rows = 3, this.framed = false});

  final int rows;
  final bool framed;

  @override
  Widget build(BuildContext context) => SkeletonScope(
    child: SkeletonSection(rows: rows, framed: framed),
  );
}
