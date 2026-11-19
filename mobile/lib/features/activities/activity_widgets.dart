import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/ui.dart';
import 'activity.dart';

/// "Today", "Tomorrow", "Yesterday" or "Mon 16 Nov", from a calendar date (no time zone involved).
String friendlyDay(
  DateTime d, {
  DateTime? now,
  AppLocalizations? l,
  AppFormat? f,
}) {
  final today = DateTime(
    (now ?? DateTime.now()).year,
    (now ?? DateTime.now()).month,
    (now ?? DateTime.now()).day,
  );
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return l?.relativeToday ?? 'Today';
  if (diff == 1) return l?.relativeTomorrow ?? 'Tomorrow';
  if (diff == -1) return l?.relativeYesterday ?? 'Yesterday';
  return (f ?? AppFormat.current).weekdayDayMonth(day);
}

/// "Mon 16 Nov" - an absolute label for titles that must never read "Today" (e.g. "Week of Mon 16 Nov").
String absoluteDay(DateTime d) => AppFormat.current.weekdayDayMonth(d);

String monthName(DateTime d) => AppFormat.current.monthYear(d);

String clock(DateTime d) {
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// Occurrence state: always icon + words, never colour alone.
class OccurrencePill extends StatelessWidget {
  const OccurrencePill(this.state, {super.key});
  final OccurrenceState state;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (state) {
      OccurrenceState.completed => (Tone.success, Icons.check_circle_outline),
      OccurrenceState.pending => (Tone.info, Icons.hourglass_top),
      OccurrenceState.open => (Tone.attention, Icons.radio_button_unchecked),
      OccurrenceState.rejected => (Tone.attention, Icons.replay),
      OccurrenceState.missed => (Tone.danger, Icons.error_outline),
      OccurrenceState.notDone => (Tone.danger, Icons.cancel_outlined),
      OccurrenceState.upcoming => (Tone.neutral, Icons.schedule),
    };
    return StatusPill(
      state.text(AppLocalizations.of(context)),
      tone: tone,
      icon: icon,
    );
  }
}

/// A single register cell: state icon plus a letter, so the grid reads without colour.
class StateGlyph extends StatelessWidget {
  const StateGlyph(this.state, {super.key, this.size = 22});
  final OccurrenceState? state; // null = not scheduled
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final (icon, color) = switch (state) {
      null => (Icons.remove, s.outline),
      OccurrenceState.completed => (Icons.check_circle, s.primary),
      OccurrenceState.pending => (Icons.hourglass_top, s.tertiary),
      OccurrenceState.open => (
        Icons.radio_button_unchecked,
        s.onSurfaceVariant,
      ),
      OccurrenceState.rejected => (Icons.replay, s.tertiary),
      OccurrenceState.missed => (Icons.error, s.error),
      OccurrenceState.notDone => (Icons.cancel, s.error),
      OccurrenceState.upcoming => (Icons.schedule, s.outline),
    };
    return Semantics(
      label: state?.text(l) ?? l.actStateNotScheduled,
      child: Icon(icon, size: size, color: color),
    );
  }
}

/// "3 day streak" / "Best 7" / "No streak (no deadline)" — a server number, labelled with what it counts.
class StreakChips extends StatelessWidget {
  const StreakChips(this.streak, {super.key, this.noDeadline = false});
  final StreakInfo streak;
  final bool noDeadline;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (streak.current == null) {
      return StatusPill(l.actNoStreak, icon: Icons.all_inclusive);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        StatusPill(
          l.actStreak('${streak.current}${streak.capped ? '+' : ''}'),
          tone: (streak.current ?? 0) > 0 ? Tone.success : Tone.neutral,
          icon: Icons.local_fire_department_outlined,
        ),
        StatusPill(
          l.actBest('${streak.best}${streak.capped ? '+' : ''}'),
          icon: Icons.emoji_events_outlined,
        ),
        if (streak.resolved > 0)
          StatusPill(
            l.actDoneOfResolved(streak.completed, streak.resolved),
            icon: Icons.fact_check_outlined,
          ),
      ],
    );
  }
}

/// Asks for one line of text. The dialog's State owns the controller, so it is disposed only after the route is gone.
/// Returns null when cancelled; when [required] the confirm button stays disabled until something is typed.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirm,
  int maxLength = 500,
  bool required = false,
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => _PromptDialog(
    title: title,
    label: label,
    confirm: confirm,
    maxLength: maxLength,
    required: required,
    initial: initial,
  ),
);

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.confirm,
    required this.maxLength,
    required this.required,
    required this.initial,
  });
  final String title;
  final String label;
  final String confirm;
  final int maxLength;
  final bool required;
  final String initial;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _c,
      maxLength: widget.maxLength,
      maxLines: 3,
      autofocus: true,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: widget.label),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context).commonCancel),
      ),
      FilledButton(
        onPressed: widget.required && _c.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _c.text),
        child: Text(widget.confirm),
      ),
    ],
  );
}

/// Title + description editor (same ownership rule as [askText]).
Future<({String title, String description})?> askDetails(
  BuildContext context, {
  required String title,
  required String description,
}) => showDialog<({String title, String description})>(
  context: context,
  builder: (_) => _DetailsDialog(title: title, description: description),
);

class _DetailsDialog extends StatefulWidget {
  const _DetailsDialog({required this.title, required this.description});
  final String title;
  final String description;

  @override
  State<_DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<_DetailsDialog> {
  late final TextEditingController _t = TextEditingController(
    text: widget.title,
  );
  late final TextEditingController _d = TextEditingController(
    text: widget.description,
  );

  @override
  void dispose() {
    _t.dispose();
    _d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.actEditDetails),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _t,
              maxLength: 120,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l.commonTitle),
            ),
            TextField(
              controller: _d,
              maxLength: 2000,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.actDescription),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _t.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, (
                  title: _t.text,
                  description: _d.text,
                )),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
