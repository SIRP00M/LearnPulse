import 'package:flutter/material.dart';

import '../../core/academic.dart';
import '../../core/app_error.dart' show AppError;
import '../../core/formatting.dart';
import '../../core/ids.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'staff.dart';
import 'staff_repository.dart';

Widget _statePill(StaffState s, AppLocalizations l) => switch (s) {
  StaffState.onTime => StatusPill(l.staffOnTime, tone: Tone.success),
  StaffState.late => StatusPill(l.staffLate, tone: Tone.attention),
  StaffState.missingCheckout => StatusPill(
    l.staffMissingCheckout,
    tone: Tone.danger,
    icon: Icons.error_outline,
  ),
  StaffState.inProgress => StatusPill(l.staffInProgress, tone: Tone.info),
  StaffState.absent => StatusPill(
    l.staffAbsent,
    tone: Tone.danger,
    icon: Icons.cancel_outlined,
  ),
  StaffState.leave => StatusPill(l.staffLeave, tone: Tone.info),
  StaffState.unscheduled => StatusPill(l.staffUnscheduled),
  StaffState.upcoming => StatusPill(l.staffUpcoming),
};

String _status(String s, AppLocalizations l) => switch (s) {
  'approved' => l.staffStApproved,
  'rejected' => l.staffStRejected,
  'cancelled' => l.staffStCancelled,
  _ => l.staffStPending,
};

String _day(AppFormat f, String ymd) {
  final d = DateTime.tryParse(ymd);
  return d == null ? ymd : f.dateLong(d);
}

/// Clock in/out, history, requests, and (for explicitly assigned supervisors) approvals.
/// All times shown are server instants; the device clock never decides anything.
class StaffAttendancePage extends StatefulWidget {
  const StaffAttendancePage({
    super.key,
    required this.repository,
    this.newId = newRequestId,
  });

  final StaffRepository repository;
  final String Function() newId;

  @override
  State<StaffAttendancePage> createState() => _StaffAttendancePageState();
}

class _StaffAttendancePageState extends State<StaffAttendancePage> {
  StaffContext? _ctx;
  StaffReport? _report;
  List<StaffRequest> _mine = const [];
  List<StaffRequest> _toDecide = const [];
  List<TeamRow> _team = const [];
  AppError? _loadError;
  AppError? _actionError;
  bool _loading = true;
  bool _busy = false;
  String? _notice;
  String?
  _pendingId; // one request id per intended action, reused on retry so the server replays

  StaffRepository get _repo => widget.repository;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final ctx = await _repo.context();
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 13));
      final report = ctx.isStaff ? await _repo.report(from, now) : null;
      final mine = ctx.isStaff
          ? await _repo.requests('mine')
          : const <StaffRequest>[];
      final decide = ctx.isSupervisor
          ? await _repo.requests('decide', status: 'pending')
          : const <StaffRequest>[];
      final team = ctx.isSupervisor
          ? await _repo.team(from, now)
          : const <TeamRow>[];
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        _report = report;
        _mine = mine;
        _toDecide = decide;
        _team = team;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = AppError.from(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<void> Function(String id) run, String notice) async {
    if (_busy) return;
    final id = _pendingId ??= widget.newId();
    setState(() {
      _busy = true;
      _actionError = null;
      _notice = null;
    });
    try {
      await run(id);
      _pendingId = null;
      _notice = notice;
      await _load();
    } catch (e) {
      if (mounted) setState(() => _actionError = AppError.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final body = _loading && _ctx == null
        ? const Padding(
            padding: EdgeInsets.all(Space.md),
            child: SkeletonBlock(),
          )
        : _loadError != null && _ctx == null
        ? ErrorPanel(
            error: _loadError!,
            onRetry: _load,
            full: false,
            framed: false,
          )
        : !(_ctx?.isStaff ?? false)
        ? EmptyPanel(
            icon: Icons.badge_outlined,
            title: l.staffTitle,
            message: l.staffSubtitle,
            framed: false,
          )
        : _content(l, f, _ctx!);
    return Scaffold(
      appBar: AppBar(title: Text(l.staffTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [body],
          ),
        ),
      ),
    );
  }

  Widget _content(AppLocalizations l, AppFormat f, StaffContext c) {
    final scheme = Theme.of(context).colorScheme;
    final r = _report;
    final open = c.openSince;
    String days(List<int> w) => w.map((d) => _dayName(l, d)).join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_notice != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(_notice!, key: const Key('staff-notice')),
            ),
          ),
        if (_actionError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Text(
              _actionError!.text(context),
              key: const Key('staff-error'),
              style: TextStyle(color: scheme.error),
            ),
          ),
        AcademicSection(
          title: l.staffToday,
          icon: Icons.badge_outlined,
          padded: true,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                open == null
                    ? l.staffStatusOut
                    : l.staffStatusIn(f.time(open.toLocal())),
                key: const Key('staff-status'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (open != null && c.openLateMinutes > 0)
              StatusPill(
                l.staffStatusLate('${c.openLateMinutes}'),
                tone: Tone.attention,
              ),
            const SizedBox(height: Space.sm),
            if (open == null)
              FilledButton.icon(
                key: const Key('staff-clock-in'),
                icon: const Icon(Icons.login),
                label: Text(l.staffClockIn),
                onPressed: _busy
                    ? null
                    : () => _act((id) => _repo.clockIn(id), l.staffClockedIn),
              )
            else
              FilledButton.icon(
                key: const Key('staff-clock-out'),
                icon: const Icon(Icons.logout),
                label: Text(l.staffClockOut),
                onPressed: _busy
                    ? null
                    : () => _act((id) => _repo.clockOut(id), l.staffClockedOut),
              ),
            const SizedBox(height: Space.sm),
            Text(
              l.staffServerTime,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Space.sm),
            Text(
              l.staffSchedule,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (c.schedules.isEmpty)
              Text(l.staffNoSchedule)
            else
              for (final s in c.schedules)
                Text(
                  '${s.label.isEmpty ? l.staffSchedule : s.label}: ${l.staffScheduleLine(days(s.weekdays), s.start, s.end, s.timezone, '${s.graceMinutes}')}',
                ),
          ],
        ),
        const SizedBox(height: Space.md),
        AcademicSection(
          title: l.staffHistory,
          icon: Icons.history,
          children: [
            if (r == null || r.rows.isEmpty)
              EmptyPanel(
                icon: Icons.event_busy_outlined,
                title: l.staffNoRows,
                message: '',
                framed: false,
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                child: Text(
                  l.staffWorked(
                    f.number(
                      double.parse(
                        (r.totals.workedMinutes / 60).toStringAsFixed(1),
                      ),
                    ),
                  ),
                  key: const Key('staff-worked'),
                ),
              ),
              for (final row in r.rows)
                StudioListItem(
                  flat: true,
                  title: _day(f, row.day),
                  icon: Icons.event_available_outlined,
                  detail: [
                    if (row.start != null) '${row.start}–${row.end ?? ''}',
                    if (row.clockIn != null)
                      l.atdTimeIn(f.time(row.clockIn!.toLocal())),
                    if (row.clockOut != null)
                      l.atdTimeOut(f.time(row.clockOut!.toLocal())),
                  ].join(' · '),
                  status: _statePill(row.state, l),
                ),
            ],
          ],
        ),
        const SizedBox(height: Space.md),
        AcademicSection(
          title: l.staffRequests,
          icon: Icons.inbox_outlined,
          padded: true,
          actions: [
            OutlinedButton.icon(
              key: const Key('staff-new-leave'),
              icon: const Icon(Icons.beach_access_outlined),
              label: Text(l.staffNewLeave),
              onPressed: () => _openRequest('leave'),
            ),
            OutlinedButton.icon(
              key: const Key('staff-new-correction'),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(l.staffNewCorrection),
              onPressed: () => _openRequest('correction'),
            ),
          ],
          children: [
            Text(
              c.hasSupervisor ? l.staffSelfNote : l.staffNoSupervisor,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_mine.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: Text(l.staffNoRequests),
              ),
            for (final q in _mine) _requestTile(q, l, f, mine: true),
          ],
        ),
        if (c.isSupervisor) ...[
          const SizedBox(height: Space.md),
          AcademicSection(
            title: l.staffManager,
            icon: Icons.supervisor_account_outlined,
            padded: true,
            children: [
              Text(l.staffTeam, style: Theme.of(context).textTheme.titleSmall),
              if (_team.isEmpty) Text(l.staffNoTeam),
              for (final t in _team)
                Text(
                  l.staffTeamLine(
                    t.name,
                    '${t.totals.onTime}',
                    '${t.totals.late}',
                    '${t.totals.missingCheckout}',
                    '${t.totals.absent}',
                  ),
                ),
              const SizedBox(height: Space.sm),
              Text(
                l.staffToDecide,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_toDecide.isEmpty) Text(l.staffNoneToDecide),
              for (final q in _toDecide) _requestTile(q, l, f, mine: false),
            ],
          ),
        ],
      ],
    );
  }

  Widget _requestTile(
    StaffRequest q,
    AppLocalizations l,
    AppFormat f, {
    required bool mine,
  }) {
    final range = q.from == q.to
        ? _day(f, q.from)
        : '${_day(f, q.from)} – ${_day(f, q.to)}';
    return Card(
      key: Key('request-${q.id}'),
      margin: const EdgeInsets.only(top: Space.sm),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${mine ? '' : '${q.staffName} · '}${q.kind == 'leave' ? l.staffKindLeave : l.staffKindCorrection} · $range',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (q.kind == 'correction')
              Text(
                '${q.proposedIn == null ? '—' : l.atdTimeIn(f.time(q.proposedIn!.toLocal()))} · ${q.proposedOut == null ? '—' : l.atdTimeOut(f.time(q.proposedOut!.toLocal()))}',
              ),
            Text(q.reason),
            if (q.decisionNote.isNotEmpty)
              Text(l.staffDecisionNote(q.decisionNote)),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  _status(q.status, l),
                  tone: q.status == 'approved'
                      ? Tone.success
                      : q.status == 'rejected'
                      ? Tone.danger
                      : Tone.info,
                ),
                if (mine && q.pending)
                  TextButton(
                    key: Key('cancel-${q.id}'),
                    onPressed: _busy
                        ? null
                        : () => _act(
                            (_) => _repo.cancelRequest(q.id),
                            l.staffCancelled,
                          ),
                    child: Text(l.staffCancelRequest),
                  ),
                if (!mine && q.pending) ...[
                  FilledButton(
                    key: Key('approve-${q.id}'),
                    onPressed: _busy ? null : () => _decide(q, true),
                    child: Text(l.staffApprove),
                  ),
                  OutlinedButton(
                    key: Key('reject-${q.id}'),
                    onPressed: _busy ? null : () => _decide(q, false),
                    child: Text(l.staffReject),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _decide(StaffRequest q, bool approve) async {
    final l = AppLocalizations.of(context);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _DecisionDialog(request: q, approve: approve),
    );
    if (note == null || !mounted) return;
    await _act(
      (id) =>
          _repo.decide(id: q.id, requestId: id, approve: approve, note: note),
      l.staffDecided,
    );
  }

  Future<void> _openRequest(String kind) async {
    final l = AppLocalizations.of(context);
    final made = await showDialog<bool>(
      context: context,
      builder: (_) => _RequestDialog(
        kind: kind,
        onSubmit: (v) => _act(
          (id) => _repo.submitRequest(
            requestId: id,
            kind: kind,
            from: v.from,
            to: v.to,
            reason: v.reason,
            clockIn: v.clockIn,
            clockOut: v.clockOut,
          ),
          l.staffSubmitted,
        ),
      ),
    );
    if (made == true) _pendingId = null;
  }

  static String _dayName(AppLocalizations l, int d) => switch (d) {
    1 => l.staffD1,
    2 => l.staffD2,
    3 => l.staffD3,
    4 => l.staffD4,
    5 => l.staffD5,
    6 => l.staffD6,
    _ => l.staffD7,
  };
}

class _RequestValues {
  const _RequestValues(
    this.from,
    this.to,
    this.reason,
    this.clockIn,
    this.clockOut,
  );
  final DateTime from, to;
  final String reason;
  final DateTime? clockIn, clockOut;
}

class _RequestDialog extends StatefulWidget {
  const _RequestDialog({required this.kind, required this.onSubmit});
  final String kind;
  final Future<void> Function(_RequestValues) onSubmit;

  @override
  State<_RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<_RequestDialog> {
  final _reason = TextEditingController();
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  TimeOfDay? _in;
  TimeOfDay? _out;
  String? _error;

  bool get _leave => widget.kind == 'leave';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool from) async {
    final today = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: today.subtract(const Duration(days: 366)),
      lastDate: _leave ? today.add(const Duration(days: 366)) : today,
    );
    if (d != null) {
      setState(() {
        if (from) {
          _from = d;
          if (_to.isBefore(d) || !_leave) _to = d;
        } else {
          _to = d;
        }
      });
    }
  }

  DateTime? _at(TimeOfDay? t) => t == null
      ? null
      : DateTime(_from.year, _from.month, _from.day, t.hour, t.minute);

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    String? err;
    if (_reason.text.trim().length < 3) {
      err = l.staffNeedReason;
    } else if (_to.isBefore(_from)) {
      err = l.staffFixDates;
    } else if (!_leave && _in == null && _out == null) {
      err = l.staffNeedTime;
    }
    setState(() => _error = err);
    if (err != null) return;
    await widget.onSubmit(
      _RequestValues(
        _from,
        _leave ? _to : _from,
        _reason.text.trim(),
        _at(_in),
        _at(_out),
      ),
    );
    if (mounted) nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return AlertDialog(
      title: Text(_leave ? l.staffNewLeave : l.staffNewCorrection),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              key: const Key('req-from'),
              onPressed: () => _pickDate(true),
              child: Text(
                '${_leave ? l.staffFromDate : l.staffCorrectDate}: ${f.date(_from)}',
              ),
            ),
            if (_leave)
              OutlinedButton(
                key: const Key('req-to'),
                onPressed: () => _pickDate(false),
                child: Text('${l.staffToDate}: ${f.date(_to)}'),
              ),
            if (!_leave) ...[
              OutlinedButton(
                key: const Key('req-in'),
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _in ?? TimeOfDay.now(),
                    helpText: l.staffPickTime,
                  );
                  if (t != null) setState(() => _in = t);
                },
                child: Text(
                  '${l.staffCorrectIn}: ${_in?.format(context) ?? '—'}',
                ),
              ),
              OutlinedButton(
                key: const Key('req-out'),
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _out ?? TimeOfDay.now(),
                    helpText: l.staffPickTime,
                  );
                  if (t != null) setState(() => _out = t);
                },
                child: Text(
                  '${l.staffCorrectOut}: ${_out?.format(context) ?? '—'}',
                ),
              ),
            ],
            TextField(
              key: const Key('req-reason'),
              controller: _reason,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.staffReason),
            ),
            if (_error != null)
              Text(
                _error!,
                key: const Key('req-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: const Key('req-submit'),
          onPressed: _submit,
          child: Text(l.staffSubmit),
        ),
      ],
    );
  }
}

/// Owns its text controller so the dialog's exit animation never touches a disposed one.
class _DecisionDialog extends StatefulWidget {
  const _DecisionDialog({required this.request, required this.approve});
  final StaffRequest request;
  final bool approve;

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = widget.approve ? l.staffApprove : l.staffReject;
    return AlertDialog(
      title: Text('$label · ${widget.request.staffName}'),
      content: TextField(
        key: const Key('decision-note'),
        controller: _note,
        maxLength: 500,
        decoration: InputDecoration(labelText: l.staffNoteOptional),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: const Key('decision-confirm'),
          onPressed: () => Navigator.pop(context, _note.text.trim()),
          child: Text(label),
        ),
      ],
    );
  }
}
