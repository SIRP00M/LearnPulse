import 'package:flutter/foundation.dart';

import '../dashboard/summary_bus.dart';

import '../../core/app_error.dart';
import '../../core/ids.dart';
import '../../core/validators.dart' show ValidationIssue;
import '../courses/courses_controller.dart' show LoadState;
import 'attendance.dart';
import 'attendance_repository.dart';

/// Shared load plumbing: spinner on first load, quiet refresh afterwards, safe after dispose.
abstract class _LoadingController extends ChangeNotifier {
  bool _disposed = false;
  LoadState state = LoadState.loading;
  AppError? loadError;
  AppError? actionError;
  bool busy = false;

  Future<void> fetch();

  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      state = LoadState.loading;
      notifyListeners();
    }
    try {
      await fetch();
      loadError = null;
      state = LoadState.ready;
    } on Object catch (e) {
      loadError = AppError.from(e);
      // A failed refresh keeps showing the data already on screen.
      state = showSpinner || state == LoadState.loading
          ? LoadState.error
          : LoadState.ready;
      if (state == LoadState.ready) actionError = loadError;
    }
    notifyListeners();
  }

  void clearError() {
    actionError = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Teacher: the sessions of one course and session creation. Creating twice with unchanged input reuses
/// the idempotency key, so a lost response never produces a duplicate session.
class AttendanceListController extends _LoadingController {
  AttendanceListController(
    this._repo,
    this.courseId, {
    String Function()? newId,
    this.summaries,
  }) : _newId = newId ?? newRequestId;

  final AttendanceRepository _repo;

  /// Told after each confirmed mutation so the dashboard and profile summaries reload.
  final SummaryBus? summaries;
  final String courseId;
  final String Function() _newId;

  List<AttendanceSession> sessions = const [];
  String? _sig;
  String _requestId = '';

  @override
  Future<void> fetch() async => sessions = await _repo.listSessions(courseId);

  static ValidationIssue? validateTitle(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return ValidationIssue.titleRequired;
    if (t.length > 120) return ValidationIssue.titleLong;
    return null;
  }

  Future<bool> create(String title, DateTime startsAt) async {
    if (busy) return false;
    final sig = '${title.trim()}|${startsAt.toUtc().toIso8601String()}';
    if (sig != _sig) {
      _sig = sig;
      _requestId = _newId();
    }
    busy = true;
    actionError = null;
    notifyListeners();
    var ok = false;
    try {
      await _repo.createSession(
        courseId: courseId,
        requestId: _requestId,
        title: title.trim(),
        startsAt: startsAt,
      );
      summaries?.invalidate();
      _sig = null;
      await load(showSpinner: false);
      ok = true;
    } on Object catch (e) {
      actionError = AppError.from(e);
    } finally {
      busy = false;
      notifyListeners();
    }
    return ok;
  }
}

class RosterStudent {
  const RosterStudent(this.id, this.name);
  final String id;
  final String name;
}

/// Teacher: one session. Roster comes from the server summary (active students only), records and the
/// correction history from RLS reads. A retry of the same mark reuses its key; a stale version refreshes.
class SessionController extends _LoadingController {
  SessionController(
    this._repo,
    this.courseId,
    this.session, {
    String Function()? newId,
    this.summaries,
  }) : _newId = newId ?? newRequestId;

  final AttendanceRepository _repo;

  /// Told after each confirmed mutation so the dashboard and profile summaries reload.
  final SummaryBus? summaries;
  final String courseId;
  final String Function() _newId;

  AttendanceSession session;
  List<RosterStudent> roster = const [];
  Map<String, AttendanceRecord> records = const {};
  List<AttendanceEvent> history = const [];
  final _keys = <String, ({String sig, String id})>{};
  String? _closeKey;

  int get unmarked => roster.where((s) => !records.containsKey(s.id)).length;

  String nameOf(String? studentId, {String fallback = 'Student'}) {
    for (final s in roster) {
      if (s.id == studentId) return s.name.isEmpty ? fallback : s.name;
    }
    return fallback;
  }

  @override
  Future<void> fetch() async {
    final results = await Future.wait<Object?>([
      _repo.summary(courseId),
      _repo.listRecords(session.id),
      _repo.listEvents(session.id),
      _repo.getSession(session.id),
    ]);
    roster = [
      for (final r in (results[0]! as AttendanceSummary).rows)
        RosterStudent(r.studentId, r.name),
    ];
    records = {
      for (final r in results[1]! as List<AttendanceRecord>) r.studentId: r,
    };
    history = results[2]! as List<AttendanceEvent>;
    session = (results[3] as AttendanceSession?) ?? session;
  }

  Future<bool> mark(
    RosterStudent student,
    AttendanceStatus status, {
    String note = '',
  }) async {
    if (busy) return false;
    final current = records[student.id];
    final version = current?.version ?? 0;
    final cleaned = note.trim();
    if (cleaned.length > maxAttendanceNote) {
      actionError = const AppError(
        AppErrorKind.validation,
        'Note is too long (500 characters maximum).',
        AppErrorCode.noteTooLong,
      );
      notifyListeners();
      return false;
    }
    final sig = '${status.wire}|$cleaned|v$version';
    final prev = _keys[student.id];
    final id = prev != null && prev.sig == sig ? prev.id : _newId();
    _keys[student.id] = (sig: sig, id: id);
    return _act(() async {
      await _repo.mark(
        sessionId: session.id,
        studentId: student.id,
        requestId: id,
        expectedVersion: version,
        status: status,
        note: cleaned,
      );
      summaries?.invalidate();
      _keys.remove(student.id);
    });
  }

  Future<bool> closeSession() async {
    if (busy || session.closed) return false;
    _closeKey ??= _newId();
    return _act(() async {
      await _repo.close(
        sessionId: session.id,
        requestId: _closeKey!,
        expectedVersion: session.version,
      );
      summaries?.invalidate();
      _closeKey = null;
    });
  }

  Future<bool> _act(Future<void> Function() action) async {
    busy = true;
    actionError = null;
    notifyListeners();
    var ok = false;
    try {
      await action();
      await fetch();
      loadError = null;
      state = LoadState.ready;
      ok = true;
    } on Object catch (e) {
      final err = AppError.from(e);
      actionError = err.kind == AppErrorKind.conflict
          ? const AppError(
              AppErrorKind.conflict,
              'This record changed elsewhere. The latest values are shown; try again.',
              AppErrorCode.recordChanged,
            )
          : err;
      if (err.kind == AppErrorKind.conflict) {
        _closeKey = null;
        try {
          await fetch();
        } on Object catch (_) {
          // keep what is on screen; the conflict message already tells the user to retry
        }
      }
    } finally {
      busy = false;
      notifyListeners();
    }
    return ok;
  }
}

/// Role-aware summary (teacher: all active students, student: self) for the summary page.
class AttendanceSummaryController extends _LoadingController {
  AttendanceSummaryController(this._repo, this.courseId);

  final AttendanceRepository _repo;
  final String courseId;
  AttendanceSummary summary = const AttendanceSummary(
    sessionsTotal: 0,
    sessionsClosed: 0,
    rows: [],
  );

  @override
  Future<void> fetch() async => summary = await _repo.summary(courseId);
}

/// Student: own summary plus the list of own records for one course.
class MyAttendanceController extends _LoadingController {
  MyAttendanceController(this._repo, this.courseId);

  final AttendanceRepository _repo;
  final String courseId;
  AttendanceSummary summary = const AttendanceSummary(
    sessionsTotal: 0,
    sessionsClosed: 0,
    rows: [],
  );
  List<AttendanceRecord> records = const [];

  AttendanceSummaryRow? get mine =>
      summary.rows.isEmpty ? null : summary.rows.first;

  @override
  Future<void> fetch() async {
    final results = await Future.wait<Object>([
      _repo.summary(courseId),
      _repo.listMyRecords(courseId),
    ]);
    summary = results[0] as AttendanceSummary;
    records = results[1] as List<AttendanceRecord>;
  }
}

/// Local Monday 00:00 of the week containing [d] (device zone; a course timezone arrives with V6.5).
DateTime mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// Read-only weekly grid. Teacher: every active student; student: only themself (RLS + role-aware summary).
/// Pure attendance: it never reads activity data. Rapid week changes cannot show a stale week.
class WeekGridController extends _LoadingController {
  WeekGridController(this._repo, this.courseId, {DateTime? today})
    : weekStart = mondayOf(today ?? DateTime.now()),
      _thisWeek = mondayOf(today ?? DateTime.now());

  final AttendanceRepository _repo;
  final String courseId;
  final DateTime _thisWeek;

  DateTime weekStart;
  List<RosterStudent> roster = const [];
  List<AttendanceSession> sessions = const [];
  Map<String, Map<String, AttendanceStatus>> _status = const {};

  List<DateTime> get days => [
    for (var i = 0; i < 7; i++)
      DateTime(weekStart.year, weekStart.month, weekStart.day + i),
  ];
  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
  bool get isCurrentWeek => weekStart == _thisWeek;

  List<AttendanceSession> sessionsOn(DateTime day) => [
    for (final s in sessions)
      if (_sameDay(s.startsAt.toLocal(), day)) s,
  ];

  AttendanceStatus? statusOf(String studentId, String sessionId) =>
      _status[studentId]?[sessionId];

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<void> fetch() async {
    final week = weekStart;
    final summary = await _repo.summary(courseId);
    final found = await _repo.listSessionsBetween(
      courseId,
      week,
      DateTime(week.year, week.month, week.day + 7),
    );
    final records = await _repo.listRecordsForSessions([
      for (final s in found) s.id,
    ]);
    if (week != weekStart) {
      return; // the user already moved on; drop the stale answer
    }
    roster = [for (final r in summary.rows) RosterStudent(r.studentId, r.name)];
    sessions = found;
    final map = <String, Map<String, AttendanceStatus>>{};
    for (final r in records) {
      (map[r.studentId] ??= {})[r.sessionId] = r.status;
    }
    _status = map;
  }

  Future<void> shiftWeeks(int n) {
    weekStart = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7 * n,
    );
    return load();
  }

  Future<void> goToThisWeek() {
    weekStart = _thisWeek;
    return load();
  }
}
