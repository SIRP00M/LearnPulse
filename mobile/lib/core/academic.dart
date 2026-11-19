import '../l10n/app_localizations.dart';
import 'formatting.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'ui.dart';

/// Academic records and forms share one quiet, bordered surface.
class AcademicCard extends StatelessWidget {
  const AcademicCard({
    super.key,
    required this.children,
    this.padding = Space.md,
    this.tint,
  });
  final List<Widget> children;
  final double padding;

  /// Optional emphasis surface (e.g. a priority card); defaults to white.
  final Color? tint;

  @override
  Widget build(BuildContext context) => Material(
    color: tint ?? Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.lg),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: EdgeInsets.all(padding),
      child: Semantics(
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class AcademicIcon extends StatelessWidget {
  const AcademicIcon(this.icon, {super.key, this.category = 0});
  final IconData icon;
  final int category;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (background, foreground) = switch (category % 4) {
      1 => (s.tertiaryContainer, s.onTertiaryContainer),
      2 => (s.secondaryContainer, s.onSecondaryContainer),
      3 => (s.surfaceContainerHigh, s.onSurfaceVariant),
      _ => (s.primaryContainer, s.onPrimaryContainer),
    };
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: foreground.withValues(alpha: .12)),
        ),
        child: Icon(icon, size: 22, color: foreground),
      ),
    );
  }
}

typedef HeroStat = ({String value, String label});

class AcademicHero extends StatelessWidget {
  const AcademicHero({
    super.key,
    required this.title,
    required this.role,
    required this.detail,
    required this.onOpenCourses,
    this.stats = const [],
  });
  final String title;
  final String role;

  /// Plain-language summary; read by screen readers in place of the stat tiles.
  final String detail;
  final VoidCallback? onOpenCourses;
  final List<HeroStat> stats;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg + 4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [s.secondary, Color.lerp(s.secondary, Colors.teal, .25)!],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -12,
            child: ExcludeSemantics(
              child: Icon(
                Icons.auto_stories,
                size: 120,
                color: s.onSecondary.withValues(alpha: .08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    key: const Key('role-chip'),
                    backgroundColor: Color.alphaBlend(
                      s.onSecondary.withValues(alpha: .12),
                      s.secondary,
                    ),
                    side: BorderSide(
                      color: s.onSecondary.withValues(alpha: .3),
                    ),
                    labelStyle: t.labelMedium?.copyWith(color: s.onSecondary),
                    avatar: Icon(
                      Icons.school_outlined,
                      size: 16,
                      color: s.onSecondary,
                    ),
                    label: Text(role),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Semantics(
                  header: true,
                  child: ScaleCap(
                    max: 1.5,
                    child: Text(
                      title,
                      style: t.headlineMedium?.copyWith(
                        color: s.onSecondary,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.md),
                if (stats.isEmpty)
                  Text(
                    detail,
                    style: t.bodyMedium?.copyWith(color: s.onSecondary),
                  )
                else
                  Semantics(
                    container: true,
                    label: detail,
                    excludeSemantics: true,
                    child: ScaleCap(max: 1.3, child: HeroStatTiles(stats)),
                  ),
                const SizedBox(height: Space.md),
                FilledButton.icon(
                  onPressed: onOpenCourses,
                  style: FilledButton.styleFrom(
                    backgroundColor: s.onSecondary,
                    foregroundColor: s.secondary,
                  ),
                  label: Text(AppLocalizations.of(context).dashOpenCourses),
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  iconAlignment: IconAlignment.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figures stack to one column at large text so no label clips.
class HeroStatTiles extends StatelessWidget {
  const HeroStatTiles(this.stats, {super.key});
  final List<HeroStat> stats;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        // Capped scale keeps all figures side by side, so the hero stays short.
        final w = (c.maxWidth - 8 * (stats.length - 1)) / stats.length;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in stats)
              Container(
                width: w,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: s.onSecondary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: s.onSecondary.withValues(alpha: .2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      x.value,
                      style: t.titleLarge?.copyWith(
                        color: s.onSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      x.label,
                      style: t.labelSmall?.copyWith(
                        color: s.onSecondary.withValues(alpha: .85),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Calendar-style day marker for deadline rows.
class DateBadge extends StatelessWidget {
  const DateBadge(this.date, {super.key, this.overdue = false});
  final DateTime? date;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final d = date?.toLocal();
    final fg = overdue ? s.onTertiaryContainer : s.onPrimaryContainer;
    // A calendar glyph stays compact; the row text beside it carries the full date.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    return ExcludeSemantics(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: overdue ? s.tertiaryContainer : s.primaryContainer,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: d == null
              ? Icon(Icons.event_busy_outlined, color: fg, size: 22)
              : FittedBox(
                  // Thai glyphs are taller than Latin; scale down instead of overflowing.
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppFormat.of(context).monthBadge(d),
                        style: t.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${d.day}',
                        style: t.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Secondary figures stay one tap away so they do not compete with priorities.
class MoreFigures extends StatelessWidget {
  const MoreFigures({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Material(
      color: s.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: s.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          leading: const AcademicIcon(Icons.insights_outlined, category: 3),
          childrenPadding: const EdgeInsets.fromLTRB(
            Space.md,
            0,
            Space.md,
            Space.md,
          ),
          children: children,
        ),
      ),
    );
  }
}

typedef AcademicService = ({
  String label,
  String detail,
  IconData icon,
  VoidCallback? onTap,
});

/// Measure real labels before choosing service columns; large text can stack.
class AcademicServices extends StatelessWidget {
  const AcademicServices({super.key, required this.services});
  final List<AcademicService> services;

  @override
  Widget build(BuildContext context) => ScaleCap(
    max: 1.8,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final t = Theme.of(context).textTheme;
        final s = Theme.of(context).colorScheme;
        final scaler = MediaQuery.textScalerOf(context);
        var columns = (constraints.maxWidth / 108).floor().clamp(1, 4);
        double measure(
          String text,
          TextStyle style,
          double width, {
          int? lines,
        }) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: lines,
          )..layout(maxWidth: width);
          final result = painter.didExceedMaxLines
              ? double.infinity
              : painter.height;
          painter.dispose();
          return result;
        }

        double width() => (constraints.maxWidth - (columns - 1) * 8) / columns;
        while (columns > 1 &&
            services.any(
              (item) => !measure(
                item.label,
                t.labelLarge!,
                width() - 16,
                lines: 2,
              ).isFinite,
            )) {
          columns--;
        }
        if (services.length == 4 && columns == 3) columns = 2;
        final tileWidth = width();
        final labelHeight = services.fold<double>(
          0,
          (height, item) => math.max(
            height,
            measure(item.label, t.labelLarge!, tileWidth - 16),
          ),
        );
        final detailHeight = services.fold<double>(
          0,
          (height, item) => math.max(
            height,
            measure(item.detail, t.bodySmall!, tileWidth - 16),
          ),
        );
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < services.length; i++)
              SizedBox(
                width: tileWidth,
                height: 42 + labelHeight + detailHeight + 40,
                child: Material(
                  color: s.surfaceContainerLow,
                  elevation: 1,
                  shadowColor: Colors.black12,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    side: BorderSide(color: s.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: services[i].onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          AcademicIcon(services[i].icon, category: i),
                          const SizedBox(height: 8),
                          Text(
                            services[i].label,
                            textAlign: TextAlign.center,
                            style: t.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            services[i].detail,
                            textAlign: TextAlign.center,
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// Large plain page title with a one-line subtitle (Ref2/Ref3 page heads).
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: ScaleCap(
            max: 1.6,
            child: Text(title, style: t.headlineMedium),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: Space.xs),
          Text(
            subtitle!,
            style: t.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

typedef SummaryStat = ({String label, String value});

/// Ref3 summary: title with a status pill, then label-over-value figures on one white card.
class AcademicSummary extends StatelessWidget {
  const AcademicSummary({
    super.key,
    required this.title,
    required this.stats,
    this.status,
    this.footer,
    this.framed = true,
  });

  /// False inside an AcademicSection: the section already frames the content.
  final bool framed;
  final String title;
  final Widget? status;
  final List<SummaryStat> stats;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final content = [
      Wrap(
        spacing: Space.sm,
        runSpacing: Space.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(title, style: t.titleMedium),
          ?status,
        ],
      ),
      const SizedBox(height: Space.md),
      // No LayoutBuilder: the column count only depends on text scale, and a data-driven card rebuilt
      // while scrolling tripped a LayoutBuilder layout-callback assertion on a real device.
      if (MediaQuery.textScalerOf(context).scale(16) > 24)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final x in stats)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: _summaryStat(t, x),
              ),
          ],
        )
      else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var k = 0; k < stats.length; k++) ...[
              if (k > 0) const SizedBox(width: Space.md),
              Expanded(child: _summaryStat(t, stats[k])),
            ],
          ],
        ),
      if (footer != null) ...[const SizedBox(height: Space.md), footer!],
    ];
    return framed
        ? AcademicCard(children: content)
        : Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          );
  }
}

Widget _summaryStat(TextTheme t, SummaryStat x) => Semantics(
  container: true,
  label: '${x.label}: ${x.value}',
  excludeSemantics: true,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(x.label, style: t.bodySmall),
      Text(x.value, style: t.titleLarge),
    ],
  ),
);

/// Section heading with a pastel icon and optional count, used above grouped records.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.md, bottom: Space.sm),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: Space.sm),
        ],
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

/// Caps text scaling for display headings only: a 3x heading is wider than the screen and
/// breaks inside words. Body text and controls keep the user's full scale.
class ScaleCap extends StatelessWidget {
  const ScaleCap({super.key, required this.max, required this.child});
  final double max;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: max),
    ),
    child: child,
  );
}

/// Level 1 containment: one white bordered section with a heading band and its content inside.
/// Rows are separated by hairlines; pass [padded] for free-form content instead of rows.
/// No LayoutBuilder: shared containers must not depend on constraints (see the AcademicSummary device bug).
class AcademicSection extends StatelessWidget {
  const AcademicSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.count,
    this.actions = const [],
    this.padded = false,
  });
  final String title;
  final IconData? icon;
  final String? subtitle;

  /// Small figure beside the title, e.g. the number of items.
  final String? count;

  /// Section-level actions (buttons) shown under the title; they wrap rather than overflow.
  final List<Widget> actions;
  final List<Widget> children;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Material(
      color: s.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: s.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, 14, Space.md, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: s.primary),
                      const SizedBox(width: Space.sm),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: ScaleCap(
                          max: 2,
                          child: Text(title, style: t.titleMedium),
                        ),
                      ),
                    ),
                    if (count != null)
                      Text(
                        count!,
                        style: t.labelLarge?.copyWith(
                          color: s.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(subtitle!, style: t.bodySmall),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: Space.xs),
                  Wrap(spacing: Space.sm, children: actions),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: s.outlineVariant),
          if (padded)
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            )
          else
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: Space.md,
                  endIndent: Space.md,
                  color: s.outlineVariant,
                ),
              children[i],
            ],
        ],
      ),
    );
  }
}

/// Level 2 containment: a tinted inset panel for related facts inside a section or card.
class InfoGroup extends StatelessWidget {
  const InfoGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(Radii.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: Space.sm),
          children[i],
        ],
      ],
    ),
  );
}

/// Level 3: an icon and one line (or wrapped lines) of metadata. Text keeps the user's full scale.
class MetadataRow extends StatelessWidget {
  const MetadataRow(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: ExcludeSemantics(
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(width: Space.sm),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

/// A session at a glance: eyebrow, title, then date, state and unmarked count grouped in one panel.
class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.when,
    required this.closed,
    this.unmarked,
  });
  final String eyebrow;
  final String title;
  final String when;
  final bool closed;

  /// Null while the register is still loading.
  final int? unmarked;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return AcademicCard(
      children: [
        Row(
          children: [
            const AcademicIcon(Icons.event_available_outlined),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                eyebrow,
                style: t.labelMedium?.copyWith(color: s.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        Semantics(
          header: true,
          child: ScaleCap(max: 1.6, child: Text(title, style: t.headlineSmall)),
        ),
        const SizedBox(height: Space.md),
        InfoGroup(
          children: [
            MetadataRow(Icons.calendar_today_outlined, when),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                StatusPill(
                  closed ? l.commonClosed : l.commonOpen,
                  tone: closed ? Tone.neutral : Tone.info,
                  icon: closed
                      ? Icons.lock_outline
                      : Icons.radio_button_checked,
                ),
                if (unmarked != null)
                  StatusPill(
                    unmarked == 0
                        ? l.atdAllMarked
                        : l.atdUnmarkedCount(unmarked!),
                    tone: unmarked == 0 ? Tone.success : Tone.attention,
                    icon: Icons.people_outline,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Level 1 page identity for nested screens: a framed header with a teal accent edge, the contextual
/// eyebrow, a prominent title that wraps naturally, an optional description and grouped metadata.
/// The Back arrow stays the AppBar's (system back, predictive back and history all keep working);
/// this widget only carries the identity, so no duplicate title is needed in the AppBar.
class AcademicPageHeader extends StatelessWidget {
  const AcademicPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.icon,
    this.category = 0,
    this.meta = const [],
    this.actions = const [],
  });
  final String title;
  final String? eyebrow;
  final String? description;
  final IconData? icon;
  final int category;

  /// Level 3 facts (MetadataRow / StatusPill) grouped in an inset panel.
  final List<Widget> meta;

  /// Page-level actions, full width.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Material(
      key: const Key('page-header'),
      color: s.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: s.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: s.secondary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.md + 5,
              Space.md,
              Space.md,
              Space.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (eyebrow != null || icon != null)
                  Row(
                    children: [
                      if (icon != null) ...[
                        AcademicIcon(icon!, category: category),
                        const SizedBox(width: Space.md),
                      ],
                      if (eyebrow != null)
                        Expanded(
                          child: ScaleCap(
                            max: 1.6,
                            child: Text(
                              eyebrow!,
                              style: t.labelLarge?.copyWith(color: s.primary),
                            ),
                          ),
                        ),
                    ],
                  ),
                if (eyebrow != null || icon != null)
                  const SizedBox(height: Space.sm),
                Semantics(
                  header: true,
                  child: ScaleCap(
                    max: 1.6,
                    child: Text(title, style: t.headlineMedium),
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: Space.xs),
                  Text(
                    description!,
                    style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  InfoGroup(children: meta),
                ],
                for (final a in actions) ...[
                  const SizedBox(height: Space.md),
                  a,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
