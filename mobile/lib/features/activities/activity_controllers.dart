import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../../core/ids.dart';
import '../../core/paged_controller.dart';
import '../courses/courses_controller.dart' show LoadState;
import '../dashboard/summary_bus.dart';
import 'activity.dart';
import 'activity_repository.dart';

const _activityTopics = {
  SummaryTopic.activities,
  SummaryTopic.progress,
  SummaryTopic.tasks,
};

/// Every activity mutation (teacher and student). Retrying the same content reuses its idempotency key, so a lost
/// response never creates a second record; a confirmed success invalidates exactly the topics it changes.
class ActivityActions extends ChangeNotifier {
  ActivityActions(this._repo, {SummaryBus? summaries, String Function()? newId})
    : _bus = summaries,
      _newId = newId ?? newRequestId;

  final ActivityRepository _repo;
  final SummaryBus? _bus;
  final String Function() _newId;
  final _keys = <String, String>{};
  bool _disposed = false;

  bool busy = false;
  AppError? error;

  String _key(String signature) => _keys.putIfAbsent(signature, _newId);

  Future<bool> _run(
    String signature,
    Future<void> Function(String requestId) call,
  ) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    var ok = false;
    try {
      await call(_key(signature));
      _keys.remove(signature);
      _bus?.invalidate(
        _activityTopics,
      ); // right after the server confirmed, before anything else
      ok = true;
    } on Object catch (e) {
      error = AppError.from(e);
    } finally {
      busy = false;
    }
    notifyListeners();
    return ok;
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<bool> create({
    required String courseId,
    required String title,
    required String description,
    required ActivityPolicy policy,
    required List<int> weekdays,
    required DateTime startDate,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  }) => _run(
    'create|$courseId|$title|$description|${policy.wire}|${weekdays.join()}|${wireDate(startDate)}|${endDate == null ? '' : wireDate(endDate)}|$deadlineMode|$deadlineTime|$timezone',
    (id) => _repo.create(
      courseId: courseId,
      requestId: id,
      title: title.trim(),
      description: description.trim(),
      policy: policy,
      weekdays: weekdays,
      startDate: startDate,
      endDate: endDate,
      deadlineMode: deadlineMode,
      deadlineTime: deadlineTime,
      timezone: timezone,
    ),
  );

  Future<bool> update(
    Activity a, {
    required String title,
    required String description,
  }) => _run(
    'update|${a.id}|${a.version}|$title|$description',
    (id) => _repo.update(
      activityId: a.id,
      requestId: id,
      expectedVersion: a.version,
      title: title.trim(),
      description: description.trim(),
    ),
  );

  Future<bool> addSchedule(
    Activity a, {
    required List<int> weekdays,
    required DateTime effectiveFrom,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  }) => _run(
    'schedule|${a.id}|${a.version}|${weekdays.join()}|${wireDate(effectiveFrom)}|${endDate == null ? '' : wireDate(endDate)}|$deadlineMode|$deadlineTime|$timezone',
    (id) => _repo.addSchedule(
      activityId: a.id,
      requestId: id,
      expectedVersion: a.version,
      weekdays: weekdays,
      effectiveFrom: effectiveFrom,
      endDate: endDate,
      deadlineMode: deadlineMode,
      deadlineTime: deadlineTime,
      timezone: timezone,
    ),
  );

  Future<bool> setStatus(
    Activity a,
    String status, {
    DateTime? effectiveFrom,
  }) => _run(
    'status|${a.id}|${a.version}|$status|${effectiveFrom == null ? '' : wireDate(effectiveFrom)}',
    (id) => _repo.setStatus(
      activityId: a.id,
      requestId: id,
      expectedVersion: a.version,
      status: status,
      effectiveFrom: effectiveFrom,
    ),
  );

  Future<bool> mark(
    String activityId,
    String studentId,
    DateTime date,
    int version, {
    required bool completed,
    String note = '',
  }) => _run(
    'mark|$activityId|$studentId|${wireDate(date)}|$version|$completed|$note',
    (id) => _repo.mark(
      activityId: activityId,
      studentId: studentId,
      date: date,
      requestId: id,
      expectedVersion: version,
      completed: completed,
      note: note.trim(),
    ),
  );

  Future<bool> review(
    PendingVerification p, {
    required bool approve,
    String reason = '',
  }) => _run(
    'review|${p.activityId}|${p.studentId}|${wireDate(p.date)}|${p.version}|$approve|$reason',
    (id) => _repo.review(
      activityId: p.activityId,
      studentId: p.studentId,
      date: p.date,
      requestId: id,
      expectedVersion: p.version,
      approve: approve,
      reason: reason.trim(),
    ),
  );

  Future<bool> reviewCell(
    String activityId,
    String studentId,
    DateTime date,
    int version, {
    required bool approve,
    String reason = '',
  }) => _run(
    'review|$activityId|$studentId|${wireDate(date)}|$version|$approve|$reason',
    (id) => _repo.review(
      activityId: activityId,
      studentId: studentId,
      date: date,
      requestId: id,
      expectedVersion: version,
      approve: approve,
      reason: reason.trim(),
    ),
  );

  Future<bool> complete(ActivityOccurrence o, {String note = ''}) => _run(
    'complete|${o.activityId}|${wireDate(o.date)}|${o.version}|$note',
    (id) => _repo.complete(
      activityId: o.activityId,
      date: o.date,
      requestId: id,
      expectedVersion: o.version,
      note: note.trim(),
    ),
  );

  Future<bool> retract(ActivityOccurrence o) => _run(
    'retract|${o.activityId}|${wireDate(o.date)}|${o.version}',
    (id) => _repo.retract(
      activityId: o.activityId,
      date: o.date,
      requestId: id,
      expectedVersion: o.version,
    ),
  );

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

/// Student: the occurrences of a date window (at most 62 days), optionally for one course.
class StudentActivitiesController extends PagedController<ActivityOccurrence> {
  StudentActivitiesController(
    this._repo, {
    required this.from,
    required this.to,
    this.courseId,
    super.bus,
  }) : super(topic: SummaryTopic.activities);

  final ActivityRepository _repo;
  DateTime from;
  DateTime to;
  final String? courseId;

  @override
  Future<ServerPage<ActivityOccurrence>> fetch(Map<String, dynamic>? cursor) =>
      _repo.myActivities(
        from,
        to,
        courseId: courseId,
        limit: 400,
        cursor: cursor,
      );

  void setWindow(DateTime start, DateTime end) {
    from = start;
    to = end;
    reset();
  }
}

/// Teacher: the verification queue (pages of at most 50, oldest first).
class PendingQueueController extends PagedController<PendingVerification> {
  PendingQueueController(this._repo, {this.courseId, super.bus})
    : super(topic: SummaryTopic.activities);

  final ActivityRepository _repo;
  final String? courseId;

  @override
  Future<ServerPage<PendingVerification>> fetch(Map<String, dynamic>? cursor) =>
      _repo.pending(courseId: courseId, limit: 50, cursor: cursor);
}

/// Teacher: one activity's weekly register. Week changes discard the response of the previous week.
class ActivityRegisterController extends ChangeNotifier {
  ActivityRegisterController(
    this._repo,
    this.activityId, {
    DateTime? weekStart,
    SummaryBus? bus,
  }) : weekStart = weekStart ?? mondayOf(DateTime.now()),
       _bus = bus {
    bus?.addListener(_onBus);
  }

  final ActivityRepository _repo;
  final SummaryBus? _bus;
  final String activityId;
  DateTime weekStart;
  bool _disposed = false;
  int _generation = 0;
  bool active = true;
  bool stale = false;

  LoadState state = LoadState.loading;
  ActivityRegister? data;
  AppError? error;

  static DateTime mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _onBus() {
    if (!(_bus?.lastTopics.contains(SummaryTopic.activities) ?? true)) return;
    stale = true;
    _generation++;
    if (active) load(showSpinner: false);
  }

  void activate() {
    active = true;
    if (stale) load(showSpinner: false);
  }

  void deactivate() => active = false;

  Future<void> load({bool showSpinner = true}) async {
    final generation = ++_generation;
    stale = false;
    if (showSpinner && data == null) {
      state = LoadState.loading;
      notifyListeners();
    }
    try {
      final r = await _repo.register(activityId, weekStart);
      if (generation != _generation) {
        return; // a newer week or mutation superseded this answer
      }
      data = r;
      error = null;
      state = LoadState.ready;
    } on Object catch (e) {
      if (generation != _generation) return;
      error = AppError.from(e);
      state = data == null ? LoadState.error : LoadState.ready;
      stale = data != null;
    }
    notifyListeners();
  }

  void shiftWeeks(int n) {
    weekStart = weekStart.add(Duration(days: 7 * n));
    data = null;
    state = LoadState.loading;
    notifyListeners();
    load();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _bus?.removeListener(_onBus);
    super.dispose();
  }
}
