import 'package:flutter/material.dart';

import 'states.dart';
import 'theme.dart';
import 'academic.dart';

/// A flat content row; status wraps below the title instead of squeezing it.
class StudioListItem extends StatelessWidget {
  const StudioListItem({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    this.status,
    this.onTap,
    this.flat = false,
  });

  /// Inside an AcademicSection: no card of its own (the section frames and divides the rows).
  final bool flat;
  final String title;
  final String detail;
  final IconData icon;
  final Widget? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    if (flat) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcademicIcon(icon),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScaleCap(max: 2, child: Text(title, style: t.titleMedium)),
                    const SizedBox(height: Space.xs),
                    Text(detail, style: t.bodySmall),
                    if (status != null) ...[
                      const SizedBox(height: Space.sm),
                      status!,
                    ],
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: s.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: s.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcademicIcon(icon),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaleCap(
                        max: 2,
                        child: Text(title, style: t.titleMedium),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(detail, style: t.bodySmall),
                      if (status != null) ...[
                        const SizedBox(height: Space.sm),
                        status!,
                      ],
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled, accessible progress measure; null means no measured data.
class StudioProgress extends StatelessWidget {
  const StudioProgress({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
  });
  final String label;
  final double? value;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Space.sm),
        if (value != null)
          LinearProgressIndicator(
            value: (value! / 100).clamp(0, 1),
            minHeight: Space.sm,
            borderRadius: BorderRadius.circular(Radii.sm),
            semanticsLabel: label,
            semanticsValue: '${value!.round()}%',
          ),
        const SizedBox(height: Space.sm),
        Text(detail, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

/// A compact editorial heading for a learning or teaching workspace.
class StudioHeader extends StatelessWidget {
  const StudioHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.description,
  });
  final String kicker;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: Space.sm),
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Typographic wordmark. There is no logo asset; do not add one without Owner approval.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'LearnPulse',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'Learn',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: 'Pulse',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: size,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

enum Tone { neutral, info, attention, success, danger }

/// Status label: always icon + words, so meaning never depends on colour alone.
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.tone = Tone.neutral,
    this.icon,
  });

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (bg, fg, defaultIcon) = switch (tone) {
      Tone.neutral => (s.surfaceContainerHighest, s.onSurfaceVariant, null),
      Tone.info => (
        s.primaryContainer,
        s.onPrimaryContainer,
        Icons.info_outline,
      ),
      Tone.attention => (
        s.tertiaryContainer,
        s.onTertiaryContainer,
        Icons.schedule,
      ),
      Tone.success => (
        s.secondaryContainer,
        s.onSecondaryContainer,
        Icons.check_circle_outline,
      ),
      Tone.danger => (
        s.errorContainer,
        s.onErrorContainer,
        Icons.error_outline,
      ),
    };
    final ic = icon ?? defaultIcon;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ic != null) ...[
            Icon(ic, size: 16, color: fg),
            const SizedBox(width: Space.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tonal surface holding a list of rows separated by hairlines (instead of one card per row).
class GroupedRows extends StatelessWidget {
  const GroupedRows({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: Space.md, endIndent: Space.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.section, bottom: Space.sm),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Page-sized loading placeholder (framed sections that pulse; static with reduced motion).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) => SkeletonPage(rows: rows);
}

/// A [ListTile] whose trailing widget (a pill, a score) moves under the text at large text sizes instead
/// of taking the whole row.
class TrailingTile extends StatelessWidget {
  const TrailingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stacked =
        trailing != null && MediaQuery.textScalerOf(context).scale(16) > 24;
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: title,
      subtitle: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?subtitle,
                const SizedBox(height: Space.xs),
                trailing!,
              ],
            )
          : subtitle,
      trailing: stacked ? null : trailing,
    );
  }
}
