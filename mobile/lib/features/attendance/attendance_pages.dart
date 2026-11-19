import '../../core/formatting.dart';
import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/academic.dart';
import '../../core/states.dart';
import '../../core/theme.dart';
import '../../core/adaptive.dart';
import '../../core/ui.dart';
import '../../core/app_error.dart' show AppError;
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import '../courses/courses_controller.dart' show LoadState;
import 'attendance.dart';
import 'attendance_controllers.dart';
import 'attendance_grid_page.dart';
import 'attendance_scan_page.dart';

String ratePercent(double? rate, {AppLocalizations? l, AppFormat? f}) =>
    rate == null
    ? (l?.atdRateNone ?? 'No rate yet')
    : (f ?? AppFormat.current).percent(rate);

Widget _error(BuildContext context, AppError error) => Padding(
  padding: const EdgeInsets.only(bottom: Space.sm),
  child: Text(
    error.text(context),
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  ),
);

Widget _statusChip(AttendanceStatus s, AppLocalizations l) => switch (s) {
  AttendanceStatus.present => StatusPill(s.text(l), tone: Tone.success),
  AttendanceStatus.late => StatusPill(s.text(l), tone: Tone.attention),
  AttendanceStatus.absent => StatusPill(
    s.text(l),
    tone: Tone.danger,
    icon: Icons.cancel_outlined,
  ),
  AttendanceStatus.excused => StatusPill(s.text(l), tone: Tone.info),
};

String _counts(AttendanceSummaryRow r, AppLocalizations l) =>
    '${l.attPresent} ${r.present} · ${l.attLate} ${r.late} · ${l.attExcused} ${r.excused} · ${l.attAbsent} ${r.absent}';

/// "Attendance" block of the teacher's course page.
class TeacherAttendanceSection extends StatefulWidget {
  const TeacherAttendanceSection({
    super.key,
    required this.courseId,
    required this.services,
    required this.archived,
  });

  final String courseId;
  final AppServices services;
  final bool archived;

  @override
  State<TeacherAttendanceSection> createState() =>
      _TeacherAttendanceSectionState();
}

class _TeacherAttendanceSectionState extends State<TeacherAttendanceSection> {
  late final AttendanceListController _c = AttendanceListController(
    widget.services.attendance,
    widget.courseId,
    summaries: widget.services.summaries,
  );

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

  Future<void> _create() async {
    _c.clearError();
    await showDialog<bool>(
      context: context,
      builder: (_) => _NewSessionDialog(controller: _c),
    );
  }

  Future<void> _open(AttendanceSession s) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSessionPage(
          controller: SessionController(
            widget.services.attendance,
            widget.courseId,
            s,
            summaries: widget.services.summaries,
          ),
          archived: widget.archived,
        ),
      ),
    );
    if (mounted) _c.load(showSpinner: false);
  }

  void _grid() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AttendanceWeekGridPage(
        controller: WeekGridController(
          widget.services.attendance,
          widget.courseId,
        ),
        teacher: true,
      ),
    ),
  );

  void _summary() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AttendanceSummaryPage(
        controller: AttendanceSummaryController(
          widget.services.attendance,
          widget.courseId,
        ),
        teacher: true,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) => AcademicSection(
        title: l.commonAttendance,
        icon: Icons.fact_check_outlined,
        count: _c.state == LoadState.ready ? '${_c.sessions.length}' : null,
        actions: [
          TextButton(onPressed: _grid, child: Text(l.atdWeeklyGrid)),
          TextButton(onPressed: _summary, child: Text(l.atdSummary)),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.atdNewSession),
            onPressed: widget.archived ? null : _create,
          ),
        ],
        children: [
          if (_c.state == LoadState.loading)
            const SkeletonBlock()
          else if (_c.state == LoadState.error)
            ErrorPanel(
              error: _c.loadError!,
              onRetry: _c.load,
              full: false,
              framed: false,
            )
          else if (_c.sessions.isEmpty)
            EmptyPanel(
              icon: Icons.fact_check_outlined,
              title: l.atdNoSessions,
              message: l.atdNoSessionsHint,
              framed: false,
            )
          else
            for (final s in _c.sessions)
              StudioListItem(
                flat: true,
                title: s.title,
                detail: formatSessionTime(s.startsAt, f: f),
                icon: Icons.event_available_outlined,
                status: s.closed
                    ? StatusPill(l.commonClosed, icon: Icons.lock_outline)
                    : StatusPill(
                        l.commonOpen,
                        tone: Tone.info,
                        icon: Icons.radio_button_checked,
                      ),
                onTap: () => _open(s),
              ),
        ],
      ),
    );
  }
}

class _NewSessionDialog extends StatefulWidget {
  const _NewSessionDialog({required this.controller});
  final AttendanceListController controller;

  @override
  State<_NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends State<_NewSessionDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Class');
  late DateTime _when = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 360)),
      lastDate: DateTime.now().add(const Duration(days: 360)),
    );
    if (d != null) {
      setState(
        () =>
            _when = DateTime(d.year, d.month, d.day, _when.hour, _when.minute),
      );
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t != null) {
      setState(
        () => _when = DateTime(
          _when.year,
          _when.month,
          _when.day,
          t.hour,
          t.minute,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await widget.controller.create(_title.text, _when);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => AlertDialog(
        title: Text(l.atdNewDialogTitle),
        content: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.actionError != null) _error(context, c.actionError!),
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: l.commonTitle),
                  textCapitalization: TextCapitalization.sentences,
                  validator: fieldValidator(
                    AttendanceListController.validateTitle,
                  ),
                  errorBuilder: validationErrorBuilder,
                ),
                const SizedBox(height: Space.md),
                Text(formatSessionTime(_when.toUtc(), f: f)),
                Wrap(
                  spacing: Space.sm,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(l.atdDate),
                      onPressed: _pickDate,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(l.atdTime),
                      onPressed: _pickTime,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: c.busy ? null : () => Navigator.of(context).pop(),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: c.busy ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, Space.minTap),
            ),
            child: c.busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.commonCreate),
          ),
        ],
      ),
    );
  }
}

/// Teacher: mark every student of one session, close it, and read the correction history.
class TeacherSessionPage extends StatefulWidget {
  const TeacherSessionPage({
    super.key,
    required this.controller,
    required this.archived,
  });

  final SessionController controller;
  final bool archived;

  @override
  State<TeacherSessionPage> createState() => _TeacherSessionPageState();
}

class _TeacherSessionPageState extends State<TeacherSessionPage> {
  SessionController get _c => widget.controller;

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

  Future<void> _editNote(RosterStudent s) async {
    final rec = _c.records[s.id];
    if (rec == null) return;
    final text = TextEditingController(text: rec.note);
    final l = AppLocalizations.of(context);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.atdNoteFor(s.name)),
        content: TextField(
          controller: text,
          maxLength: maxAttendanceNote,
          maxLines: 3,
          decoration: InputDecoration(labelText: l.atdNote),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, text.text),
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, Space.minTap),
            ),
            child: Text(l.atdSaveNote),
          ),
        ],
      ),
    );
    text.dispose();
    if (saved != null) await _c.mark(s, rec.status, note: saved);
  }

  Future<void> _close() async {
    final l = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.atdCloseTitle),
        content: Text(
          _c.unmarked == 0
              ? l.atdCloseAllMarked
              : l.atdCloseUnmarked(_c.unmarked),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, Space.minTap),
            ),
            child: Text(l.atdCloseSession),
          ),
        ],
      ),
    );
    if (sure == true) await _c.closeSession();
  }

  String _eventLine(AttendanceEvent e, AppLocalizations l, AppFormat f) {
    final who = _c.nameOf(e.studentId, fallback: l.roleStudent);
    final when = formatSessionTime(e.createdAt, f: f);
    return switch (e.action) {
      'closed' => l.atdEventClosed(when),
      'corrected' => l.atdEventCorrected(
        who,
        e.oldStatus?.text(l) ?? '—',
        e.newStatus?.text(l) ?? '—',
        when,
      ),
      _ => l.atdEventMarked(who, e.newStatus?.text(l) ?? '—', when),
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (context, _) {
      final locked = widget.archived;
      final l = AppLocalizations.of(context);
      final f = AppFormat.of(context);
      return Scaffold(
        appBar: AppBar(),
        body: RefreshIndicator(
          onRefresh: _c.load,
          child: StudioPage(
            maxWidth: StudioLayout.maxWorkspace,
            children: [
              SessionSummaryCard(
                eyebrow: l.atdEyebrowSession,
                title: _c.session.title,
                when: formatSessionTime(_c.session.startsAt, f: f),
                closed: _c.session.closed,
                unmarked: _c.state == LoadState.ready ? _c.unmarked : null,
              ),
              const SizedBox(height: Space.md),
              if (_c.actionError != null) _error(context, _c.actionError!),
              if (_c.state == LoadState.loading)
                const SkeletonBlock(framed: true, rows: 4)
              else if (_c.state == LoadState.error)
                ErrorPanel(error: _c.loadError!, onRetry: _c.load, full: false)
              else ...[
                AcademicSection(
                  title: l.atdClassRegister,
                  icon: Icons.fact_check_outlined,
                  count: '${_c.roster.length}',
                  subtitle: l.atdRegisterHint,
                  children: [
                    if (locked)
                      Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Text(l.atdArchivedReadOnly),
                      ),
                    if (_c.roster.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Text(l.atdNoStudents),
                      ),
                    for (final s in _c.roster) _studentCard(context, s, locked),
                  ],
                ),
                const SizedBox(height: Space.md),
                if (!_c.session.closed)
                  FilledButton.icon(
                    icon: const Icon(Icons.lock_outline),
                    label: Text(l.atdCloseSessionN(_c.unmarked)),
                    onPressed: _c.busy || locked ? null : _close,
                  )
                else
                  Text(l.atdSessionClosedNote),
                const SizedBox(height: Space.lg),
                ExpansionTile(
                  title: Text(l.gradeHistory),
                  children: [
                    if (_c.history.isEmpty)
                      ListTile(title: Text(l.atdNoChanges)),
                    for (final e in _c.history)
                      ListTile(dense: true, title: Text(_eventLine(e, l, f))),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _studentCard(BuildContext context, RosterStudent s, bool locked) {
    final l = AppLocalizations.of(context);
    final rec = _c.records[s.id];
    final canEdit = !_c.busy && !locked && (!_c.session.closed || rec != null);
    return Padding(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: StudioColumns(
          primary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.name.isEmpty ? l.roleStudent : s.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (rec != null)
                    IconButton(
                      tooltip: l.atdEditNoteFor(s.name),
                      icon: const Icon(Icons.edit_note),
                      onPressed: canEdit ? () => _editNote(s) : null,
                    ),
                ],
              ),
              if (rec != null && rec.note.isNotEmpty) Text(rec.note),
              if (rec == null) Text(l.atdNotMarkedYet),
            ],
          ),
          secondary: LayoutBuilder(
            builder: (context, c) {
              // Even 2x2 choices; one column once text is scaled up.
              final cols = MediaQuery.textScalerOf(context).scale(16) > 24
                  ? 1
                  : 2;
              final w = (c.maxWidth - Space.sm * (cols - 1)) / cols;
              return Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final st in AttendanceStatus.values)
                    SizedBox(
                      width: w,
                      child: _statusChip(s, rec, st, canEdit, l),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statusChip(
    RosterStudent s,
    AttendanceRecord? rec,
    AttendanceStatus st,
    bool canEdit,
    AppLocalizations l,
  ) => ChoiceChip(
    label: SizedBox(
      width: double.infinity,
      child: Text(st.text(l), textAlign: TextAlign.center),
    ),
    avatar: Icon(switch (st) {
      AttendanceStatus.present => Icons.check_circle_outline,
      AttendanceStatus.absent => Icons.cancel_outlined,
      AttendanceStatus.late => Icons.schedule,
      AttendanceStatus.excused => Icons.event_busy_outlined,
    }, size: 18),
    selected: rec?.status == st,
    onSelected: canEdit
        ? (_) {
            if (rec?.status != st) {
              _c.mark(s, st, note: rec?.note ?? '');
            }
          }
        : null,
  );
}

/// Per-student counts and rates; the teacher sees everyone, a student only themself.
class AttendanceSummaryPage extends StatefulWidget {
  const AttendanceSummaryPage({
    super.key,
    required this.controller,
    required this.teacher,
  });

  final AttendanceSummaryController controller;
  final bool teacher;

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  AttendanceSummaryController get _c => widget.controller;

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
      final f = AppFormat.of(context);
      return Scaffold(
        appBar: AppBar(),
        body: RefreshIndicator(
          onRefresh: _c.load,
          child: StudioPage(
            maxWidth: StudioLayout.reading,
            children: [
              AcademicPageHeader(
                eyebrow: widget.teacher
                    ? l.atdEyebrowTeaching
                    : l.atdEyebrowLearning,
                icon: Icons.fact_check_outlined,
                title: l.atdSummaryTitle,
                description: l.atdSummaryDesc,
              ),
              if (_c.state == LoadState.loading)
                const SkeletonBlock(framed: true, rows: 4)
              else if (_c.state == LoadState.error)
                ErrorPanel(error: _c.loadError!, onRetry: _c.load, full: false)
              else ...[
                Text(
                  l.atdClosedOfTotal(
                    _c.summary.sessionsClosed,
                    _c.summary.sessionsTotal,
                  ),
                ),
                Text(l.atdRateNote),
                const SizedBox(height: Space.sm),
                if (_c.summary.rows.isEmpty)
                  EmptyPanel(
                    icon: Icons.groups_outlined,
                    title: l.actNoStudentsTitle,
                    message: l.atdSummaryEmptyHint,
                  ),
                for (final r in _c.summary.rows)
                  StudioProgress(
                    label: r.name.isEmpty ? l.roleStudent : r.name,
                    value: r.rate,
                    detail:
                        '${ratePercent(r.rate, l: l, f: f)} · ${_counts(r, l)}',
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// "My attendance" block of the student's course page.
class StudentAttendanceSection extends StatefulWidget {
  const StudentAttendanceSection({
    super.key,
    required this.courseId,
    required this.services,
  });

  final String courseId;
  final AppServices services;

  @override
  State<StudentAttendanceSection> createState() =>
      _StudentAttendanceSectionState();
}

class _StudentAttendanceSectionState extends State<StudentAttendanceSection> {
  late final MyAttendanceController _c = MyAttendanceController(
    widget.services.attendance,
    widget.courseId,
  );

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
      final mine = _c.mine;
      final l = AppLocalizations.of(context);
      final f = AppFormat.of(context);
      return AcademicSection(
        title: l.atdMyAttendance,
        icon: Icons.fact_check_outlined,
        actions: [
          FilledButton.icon(
            key: const Key('scan-attendance'),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.scanButton),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => AttendanceScanPage(
                    repository: widget.services.attendance,
                  ),
                ),
              );
              if (changed == true) {
                _c.load();
                widget.services.summaries.invalidate();
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AttendanceWeekGridPage(
                  controller: WeekGridController(
                    widget.services.attendance,
                    widget.courseId,
                  ),
                  teacher: false,
                ),
              ),
            ),
            child: Text(l.atdWeeklyView),
          ),
        ],
        children: [
          if (_c.state == LoadState.loading)
            const SkeletonBlock()
          else if (_c.state == LoadState.error)
            ErrorPanel(
              error: _c.loadError!,
              onRetry: _c.load,
              full: false,
              framed: false,
            )
          else if (_c.records.isEmpty)
            EmptyPanel(
              icon: Icons.fact_check_outlined,
              title: l.atdNoRecords,
              message: l.atdNoRecordsHint,
              framed: false,
            )
          else ...[
            if (mine != null)
              Padding(
                padding: EdgeInsets.zero,
                child: AcademicSummary(
                  framed: false,
                  title: l.atdRateTitle(ratePercent(mine.rate, l: l, f: f)),
                  stats: [
                    (label: l.attPresent, value: '${mine.present}'),
                    (label: l.attLate, value: '${mine.late}'),
                    (label: l.attExcused, value: '${mine.excused}'),
                    (label: l.attAbsent, value: '${mine.absent}'),
                  ],
                  footer: LinearProgressIndicator(
                    value: mine.rate,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
              ),
            for (final r in _c.records)
              StudioListItem(
                flat: true,
                title: r.sessionTitle.isEmpty
                    ? l.classSessionFallback
                    : r.sessionTitle,
                icon: Icons.event_available_outlined,
                detail: [
                  if (r.sessionStartsAt != null)
                    formatSessionTime(r.sessionStartsAt!, f: f),
                  if (r.checkedInAt != null)
                    l.atdTimeIn(f.time(r.checkedInAt!.toLocal())),
                  if (r.checkedOutAt != null)
                    l.atdTimeOut(f.time(r.checkedOutAt!.toLocal())),
                  if (r.note.isNotEmpty) r.note,
                ].join('\n'),
                status: _statusChip(r.status, l),
              ),
          ],
        ],
      );
    },
  );
}
