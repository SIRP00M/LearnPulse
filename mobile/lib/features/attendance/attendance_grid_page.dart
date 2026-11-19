import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/academic.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'attendance.dart';
import 'attendance_controllers.dart';
import '../../core/adaptive.dart';

const _nameWidth = 116.0;
const _dayWidth = 92.0;
const _rowHeight = 56.0;

/// Shape + letter + words, so no state depends on colour alone.
({IconData icon, String letter}) _glyph(
  AttendanceStatus s,
  AppLocalizations l,
) => switch (s) {
  AttendanceStatus.present => (
    icon: Icons.check_circle_outline,
    letter: l.atdGlyphPresent,
  ),
  AttendanceStatus.late => (icon: Icons.schedule, letter: l.atdGlyphLate),
  AttendanceStatus.excused => (
    icon: Icons.info_outline,
    letter: l.atdGlyphExcused,
  ),
  AttendanceStatus.absent => (
    icon: Icons.cancel_outlined,
    letter: l.atdGlyphAbsent,
  ),
};

class _Mark extends StatelessWidget {
  const _Mark(this.status);
  final AttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null) return const Icon(Icons.remove, size: 16);
    final g = _glyph(s, AppLocalizations.of(context));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(g.icon, size: 16), Text(g.letter)],
    );
  }
}

/// Read-only weekly attendance grid: students as rows, days as columns. Only attendance is shown.
class AttendanceWeekGridPage extends StatefulWidget {
  const AttendanceWeekGridPage({
    super.key,
    required this.controller,
    required this.teacher,
  });

  final WeekGridController controller;
  final bool teacher;

  @override
  State<AttendanceWeekGridPage> createState() => _AttendanceWeekGridPageState();
}

class _AttendanceWeekGridPageState extends State<AttendanceWeekGridPage> {
  WeekGridController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(),
        body: RefreshIndicator(
          onRefresh: () => _c.load(showSpinner: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Space.md),
            children: [
              AcademicPageHeader(
                eyebrow: l.commonAttendance,
                icon: Icons.calendar_view_week_outlined,
                title: widget.teacher ? l.atdWeeklyAttendance : l.atdMyWeek,
                description: l.atdGridDesc,
              ),
              const SizedBox(height: Space.md),
              WeekGridPanel(controller: _c, teacher: widget.teacher),
            ],
          ),
        ),
      );
    },
  );
}

/// Week navigation, status guide and the grid itself. The caller owns loading and disposing [controller],
/// so the same panel serves the full page and the teacher's class dashboard.
class WeekGridPanel extends StatelessWidget {
  const WeekGridPanel({
    super.key,
    required this.controller,
    required this.teacher,
    this.framed = true,
  });
  final WeekGridController controller;
  final bool teacher;

  /// True on the full page (the table gets its own bordered surface); false when an enclosing
  /// section already frames it.
  final bool framed;

  WeekGridController get _c => controller;

  String _range(AppFormat f) {
    final a = _c.weekStart;
    final b = _c.days.last;
    return f.range(a, b);
  }

  Widget _legend(AppLocalizations l) => Wrap(
    spacing: Space.md,
    runSpacing: Space.xs,
    children: [
      for (final s in AttendanceStatus.values)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_glyph(s, l).icon, size: 16),
            const SizedBox(width: Space.xs),
            Flexible(child: Text('${_glyph(s, l).letter} ${s.text(l)}')),
          ],
        ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove, size: 16),
          const SizedBox(width: Space.xs),
          Flexible(child: Text(l.atdNotMarked)),
        ],
      ),
      Text(l.atdNoSession),
      Text(l.atdTwoSessions),
    ],
  );

  Widget _cell(RosterStudent s, DateTime day, AppLocalizations l, AppFormat f) {
    final sessions = _c.sessionsOn(day);
    final who = s.name.isEmpty ? l.roleStudent : s.name;
    if (sessions.isEmpty) {
      return Semantics(
        label: l.atdCellNoSession(who, f.weekdayDayMonth(day)),
        excludeSemantics: true,
        child: const Center(child: Text('·')),
      );
    }
    final parts = [
      for (final x in sessions)
        '${x.title}: ${_c.statusOf(s.id, x.id)?.text(l) ?? l.atdNotMarked.toLowerCase()}',
    ];
    return Semantics(
      label: '$who, ${f.weekdayDayMonth(day)}, ${parts.join('; ')}',
      excludeSemantics: true,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final x in sessions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _Mark(_c.statusOf(s.id, x.id)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final line = Divider.createBorderSide(context);
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final text = Theme.of(context).textTheme;
    final nameStyle = text.bodyMedium!;
    // Android scales small and large fonts differently; size rows from the cell text.
    final scaler = MediaQuery.textScalerOf(context);
    final names = [
      for (final s in _c.roster) s.name.isEmpty ? l.roleStudent : s.name,
    ];
    final namePainter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: scaler,
    );
    var rowHeight = math.max(
      _rowHeight,
      scaler.scale(text.labelLarge!.fontSize!) *
              (text.labelLarge!.height ?? 1.4) *
              2 +
          Space.md,
    );
    for (final name in names) {
      namePainter.text = TextSpan(text: name, style: nameStyle);
      namePainter.layout(maxWidth: _nameWidth - Space.sm);
      rowHeight = math.max(rowHeight, namePainter.height + Space.sm);
    }
    namePainter.dispose();
    final dayWidth = math.max(
      _dayWidth,
      math.max(
        scaler.scale(text.labelLarge!.fontSize!) * 4 + Space.md,
        _c.days.fold<int>(
              0,
              (count, day) => math.max(count, _c.sessionsOn(day).length),
            ) *
            (20 + scaler.scale(text.bodyMedium!.fontSize!)),
      ),
    );
    final border = BoxDecoration(border: Border(bottom: line));
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideDayWidth =
            constraints.maxWidth >= StudioLayout.expanded &&
                scaler.scale(16) <= 28
            ? math.max(dayWidth, (constraints.maxWidth - _nameWidth) / 7)
            : dayWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frozen name column: stays readable while the days scroll sideways.
            SizedBox(
              width: _nameWidth,
              child: Column(
                children: [
                  Container(
                    height: rowHeight,
                    alignment: Alignment.centerLeft,
                    decoration: border,
                    child: Text(
                      teacher ? l.roleStudent : l.atdMe,
                      style: text.labelLarge,
                    ),
                  ),
                  for (final s in _c.roster)
                    Container(
                      height: rowHeight,
                      alignment: Alignment.centerLeft,
                      decoration: border,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.xs,
                        ),
                        child: Text(
                          s.name.isEmpty ? l.roleStudent : s.name,
                          style: nameStyle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final d in _c.days)
                          Container(
                            width: wideDayWidth,
                            height: rowHeight,
                            alignment: Alignment.center,
                            decoration: border,
                            child: Text(
                              '${f.weekdayShort(d.weekday)}\n${d.day}${_c.sessionsOn(d).length > 1 ? ' ×${_c.sessionsOn(d).length}' : ''}',
                              textAlign: TextAlign.center,
                              style: text.labelLarge,
                            ),
                          ),
                      ],
                    ),
                    for (final s in _c.roster)
                      Row(
                        children: [
                          for (final d in _c.days)
                            Container(
                              width: wideDayWidth,
                              height: rowHeight,
                              decoration: border,
                              child: _cell(s, d, l, f),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _toolbar(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return InfoGroup(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.actPrevWeek,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _c.shiftWeeks(-1),
            ),
            Expanded(
              child: Text(
                _range(f),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: l.actNextWeek,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _c.shiftWeeks(1),
            ),
          ],
        ),
        if (!_c.isCurrentWeek)
          Align(
            child: TextButton(
              onPressed: _c.goToThisWeek,
              child: Text(l.actThisWeek),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final scheme = Theme.of(context).colorScheme;
      final l = AppLocalizations.of(context);
      final table = _c.state == LoadState.ready && _c.roster.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(context),
          const SizedBox(height: Space.md),
          InfoGroup(
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.atdStatusGuide,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              _legend(l),
            ],
          ),
          const SizedBox(height: Space.md),
          if (_c.actionError != null)
            Text(
              _c.actionError!.text(context),
              style: TextStyle(color: scheme.error),
            ),
          if (_c.state == LoadState.loading)
            SkeletonBlock(framed: framed, rows: 4)
          else if (_c.state == LoadState.error)
            ErrorPanel(
              error: _c.loadError!,
              onRetry: _c.load,
              full: false,
              framed: framed,
            )
          else if (_c.roster.isEmpty)
            EmptyPanel(
              icon: Icons.groups_outlined,
              title: l.actNoStudentsTitle,
              message: l.atdGridNoStudentsHint,
              framed: framed,
            )
          else ...[
            if (_c.sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: EmptyPanel(
                  icon: Icons.event_busy_outlined,
                  title: l.atdGridNoSessions,
                  message: l.atdGridNoSessionsHint,
                  framed: framed,
                ),
              ),
            if (table && framed)
              Container(
                key: const Key('week-table'),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: _grid(context),
              )
            else
              _grid(context),
          ],
        ],
      );
    },
  );
}
