import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/activities/activity.dart';
import 'package:learn_pulse/features/activities/activity_repository.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/progress/progress.dart';
import 'package:learn_pulse/features/progress/progress_repository.dart';
import 'package:learn_pulse/features/tasks/task.dart';
import 'package:learn_pulse/features/tasks/task_repository.dart';

import 'fakes.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class FakeSchedule {
  FakeSchedule({
    required this.effectiveFrom,
    required this.weekdays,
    this.end,
    this.mode = 'day_end',
    this.time,
    this.timezone = 'Asia/Bangkok',
  });
  final DateTime effectiveFrom;
  final List<int> weekdays;
  final DateTime? end;
  final String mode;
  final String? time;
  final String timezone;
}

class FakeActivity {
  FakeActivity({
    required this.id,
    required this.courseId,
    required this.title,
    this.description = '',
    required this.policy,
    required this.schedules,
    this.status = 'active',
    this.version = 1,
  });
  final String id;
  final String courseId;
  String title;
  String description;
  final ActivityPolicy policy;
  final List<FakeSchedule> schedules; // ascending by effectiveFrom
  String status;
  int version;
}

class FakeCompletion {
  FakeCompletion(
    this.status, {
    this.version = 1,
    this.note = '',
    this.reason = '',
    this.dueAt,
  });
  String
  status; // teacher_marked | self_reported | pending | approved | rejected | not_done
  int version;
  String note;
  String reason;
  DateTime? dueAt;
}

/// In-memory activity backend that applies the same rules as the V9 RPCs: immutable schedule versions, per-policy
/// completion, server-clock deadlines, versions (PT409) and the streak definition. [now] is the fake server clock.
class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({
    DateTime Function()? now,
    List<({String id, String name})>? students,
    this.courseTitle = 'Algebra',
  }) : _now = now ?? DateTime.now,
       students =
           students ??
           [(id: 's1', name: 'Student One'), (id: 's2', name: 'Student Two')];

  final DateTime Function() _now;
  final List<({String id, String name})> students;
  final String courseTitle;
  final activities = <FakeActivity>[];
  final completions = <String, FakeCompletion>{};
  final calls = <String>[];
  String me = 's1';
  Object? error; // thrown by the next call
  int _seq = 0;

  DateTime get now => _now();

  void _enter(String call) {
    calls.add(call);
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
  }

  static String _k(String a, String s, DateTime d) => '$a|$s|${wireDate(d)}';

  FakeActivity _act(String id) => activities.firstWhere(
    (a) => a.id == id,
    orElse: () =>
        throw const AppError(AppErrorKind.notFound, 'Activity not found'),
  );

  FakeSchedule? _scheduleFor(FakeActivity a, DateTime d) {
    FakeSchedule? s;
    for (final x in a.schedules) {
      if (!x.effectiveFrom.isAfter(d)) s = x;
    }
    return s;
  }

  /// Eligible occurrences between two dates (inclusive), exactly as `private.activity_occurrences`.
  List<({DateTime date, FakeSchedule schedule, DateTime? due})> occurrences(
    FakeActivity a,
    DateTime from,
    DateTime to,
  ) {
    final out = <({DateTime date, FakeSchedule schedule, DateTime? due})>[];
    for (
      var d = _day(from);
      !d.isAfter(_day(to));
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final s = _scheduleFor(a, d);
      if (s == null ||
          (s.end != null && d.isAfter(s.end!)) ||
          !s.weekdays.contains(d.weekday)) {
        continue;
      }
      final due = switch (s.mode) {
        'time' => DateTime(
          d.year,
          d.month,
          d.day,
          int.parse(s.time!.split(':')[0]),
          int.parse(s.time!.split(':')[1]),
        ),
        'day_end' => DateTime(d.year, d.month, d.day + 1),
        _ => null,
      };
      out.add((date: d, schedule: s, due: due));
    }
    return out;
  }

  OccurrenceState _state(
    String? completion,
    DateTime date,
    String mode,
    DateTime? due,
  ) {
    final open = mode == 'none' || (due != null && !now.isAfter(due));
    return switch (completion) {
      'self_reported' ||
      'teacher_marked' ||
      'approved' => OccurrenceState.completed,
      'pending' => OccurrenceState.pending,
      'not_done' => OccurrenceState.notDone,
      'rejected' => open ? OccurrenceState.rejected : OccurrenceState.missed,
      _ =>
        date.isAfter(_day(now))
            ? OccurrenceState.upcoming
            : (open ? OccurrenceState.open : OccurrenceState.missed),
    };
  }

  OccurrenceState stateOf(String activityId, String studentId, DateTime date) {
    final a = _act(activityId);
    final o = occurrences(a, date, date).firstOrNull;
    if (o == null) throw StateError('not scheduled');
    final c = completions[_k(activityId, studentId, date)];
    return _state(c?.status, date, o.schedule.mode, c?.dueAt ?? o.due);
  }

  StreakInfo streakOf(FakeActivity a, String studentId) {
    final today = _day(now);
    final first = a.schedules.first.effectiveFrom;
    final from = first.isAfter(today.subtract(const Duration(days: 61)))
        ? first
        : today.subtract(const Duration(days: 61));
    final list = occurrences(a, from, today).reversed.toList();
    var current = 0, best = 0, run = 0, done = 0, resolved = 0;
    var broken = false;
    for (final o in list) {
      final c = completions[_k(a.id, studentId, o.date)];
      final st = _state(c?.status, o.date, o.schedule.mode, c?.dueAt ?? o.due);
      if (st == OccurrenceState.completed) {
        done++;
        resolved++;
        run++;
        if (!broken) current++;
        if (run > best) best = run;
      } else if (st == OccurrenceState.missed ||
          st == OccurrenceState.notDone) {
        resolved++;
        broken = true;
        run = 0;
      }
    }
    final none = a.schedules.last.mode == 'none';
    return StreakInfo(
      current: none ? null : current,
      best: none ? null : best,
      completed: done,
      resolved: resolved,
      capped:
          first.isBefore(today.subtract(const Duration(days: 61))) && !broken,
    );
  }

  // ------------------------------------------------------------ teacher
  @override
  Future<List<Activity>> overview(String courseId) async {
    _enter('overview');
    final today = _day(now);
    return [
      for (final a in activities.where((x) => x.courseId == courseId))
        Activity(
          id: a.id,
          title: a.title,
          description: a.description,
          policy: a.policy,
          status: a.status,
          version: a.version,
          schedule: ActivitySchedule(
            versionNo: a.schedules.length,
            weekdays: a.schedules.last.weekdays,
            effectiveFrom: a.schedules.last.effectiveFrom,
            endDate: a.schedules.last.end,
            deadlineMode: a.schedules.last.mode,
            deadlineTime: a.schedules.last.time,
            timezone: a.schedules.last.timezone,
          ),
          today: ActivityToday(
            date: today,
            scheduled: occurrences(a, today, today).isNotEmpty,
            expected: occurrences(a, today, today).isEmpty
                ? 0
                : students.length,
            completed: [
              for (final s in students)
                if (occurrences(a, today, today).isNotEmpty &&
                    stateOf(a.id, s.id, today) == OccurrenceState.completed)
                  s,
            ].length,
            pending: [
              for (final s in students)
                if (occurrences(a, today, today).isNotEmpty &&
                    stateOf(a.id, s.id, today) == OccurrenceState.pending)
                  s,
            ].length,
          ),
          pendingTotal: completions.entries
              .where(
                (e) =>
                    e.key.startsWith('${a.id}|') && e.value.status == 'pending',
              )
              .length,
        ),
    ];
  }

  @override
  Future<String> create({
    required String courseId,
    required String requestId,
    required String title,
    required String description,
    required ActivityPolicy policy,
    required List<int> weekdays,
    required DateTime startDate,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  }) async {
    _enter('create:$requestId');
    if (title.trim().isEmpty) {
      throw const AppError(
        AppErrorKind.validation,
        'Title must be 1-120 characters',
      );
    }
    if (_day(startDate).isBefore(_day(now))) {
      throw const AppError(
        AppErrorKind.validation,
        'Start date must be today or within the next year',
      );
    }
    if (activities
            .where((a) => a.courseId == courseId && a.status == 'active')
            .length >=
        25) {
      throw const AppError(
        AppErrorKind.conflict,
        'This course reached the 25 active activity limit',
      );
    }
    final id = 'act${++_seq}';
    activities.add(
      FakeActivity(
        id: id,
        courseId: courseId,
        title: title,
        description: description,
        policy: policy,
        schedules: [
          FakeSchedule(
            effectiveFrom: _day(startDate),
            weekdays: weekdays,
            end: endDate,
            mode: deadlineMode,
            time: deadlineTime,
            timezone: timezone,
          ),
        ],
      ),
    );
    return id;
  }

  @override
  Future<void> update({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required String title,
    required String description,
  }) async {
    _enter('update');
    final a = _act(activityId);
    if (a.version != expectedVersion) {
      throw const AppError(
        AppErrorKind.conflict,
        'This activity changed; reload',
      );
    }
    a
      ..title = title
      ..description = description
      ..version += 1;
  }

  @override
  Future<void> addSchedule({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required List<int> weekdays,
    required DateTime effectiveFrom,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  }) async {
    _enter('addSchedule');
    final a = _act(activityId);
    if (a.version != expectedVersion) {
      throw const AppError(
        AppErrorKind.conflict,
        'This activity changed; reload',
      );
    }
    if (!_day(effectiveFrom).isAfter(_day(now)) ||
        !effectiveFrom.isAfter(a.schedules.last.effectiveFrom)) {
      throw const AppError(
        AppErrorKind.conflict,
        'A schedule change starts tomorrow or later, after the previous change',
      );
    }
    a.schedules.add(
      FakeSchedule(
        effectiveFrom: _day(effectiveFrom),
        weekdays: weekdays,
        end: endDate,
        mode: deadlineMode,
        time: deadlineTime,
        timezone: timezone,
      ),
    );
    a.version++;
  }

  @override
  Future<void> setStatus({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required String status,
    DateTime? effectiveFrom,
  }) async {
    _enter('setStatus:$status');
    final a = _act(activityId);
    if (a.version != expectedVersion) {
      throw const AppError(
        AppErrorKind.conflict,
        'This activity changed; reload',
      );
    }
    final last = a.schedules.last;
    if (status == 'inactive' && a.status == 'active') {
      a.schedules.add(
        FakeSchedule(
          effectiveFrom: _day(effectiveFrom!),
          weekdays: const [],
          mode: last.mode,
          time: last.time,
          timezone: last.timezone,
        ),
      );
    } else if (status == 'active') {
      final prev = a.schedules.lastWhere((s) => s.weekdays.isNotEmpty);
      a.schedules.add(
        FakeSchedule(
          effectiveFrom: _day(effectiveFrom!),
          weekdays: prev.weekdays,
          mode: prev.mode,
          time: prev.time,
          timezone: prev.timezone,
        ),
      );
    }
    a
      ..status = status
      ..version += 1;
  }

  @override
  Future<ActivityRegister> register(
    String activityId,
    DateTime weekStart,
  ) async {
    _enter('register');
    final a = _act(activityId);
    final occ = occurrences(
      a,
      weekStart,
      weekStart.add(const Duration(days: 6)),
    );
    return ActivityRegister(
      activityId: a.id,
      title: a.title,
      policy: a.policy,
      weekStart: weekStart,
      days: [for (final o in occ) o.date],
      students: [
        for (final s in students)
          RegisterStudent(
            studentId: s.id,
            name: s.name,
            cells: [
              for (final o in occ)
                RegisterCell(
                  date: o.date,
                  state: stateOf(a.id, s.id, o.date),
                  version: completions[_k(a.id, s.id, o.date)]?.version ?? 0,
                  completionStatus: completions[_k(a.id, s.id, o.date)]?.status,
                  note: completions[_k(a.id, s.id, o.date)]?.note ?? '',
                  reason: completions[_k(a.id, s.id, o.date)]?.reason ?? '',
                ),
            ],
          ),
      ],
    );
  }

  @override
  Future<void> mark({
    required String activityId,
    required String studentId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    required bool completed,
    String note = '',
  }) async {
    _enter('mark:$studentId:${wireDate(date)}:$completed');
    final a = _act(activityId);
    final o = occurrences(a, date, date).firstOrNull;
    if (o == null) {
      throw const AppError(
        AppErrorKind.conflict,
        'Not a scheduled day for this activity',
      );
    }
    if (date.isAfter(_day(now))) {
      throw const AppError(
        AppErrorKind.conflict,
        'This occurrence is in the future',
      );
    }
    final key = _k(activityId, studentId, date);
    final c = completions[key];
    if ((c?.version ?? 0) != expectedVersion) {
      throw const AppError(AppErrorKind.conflict, 'This item changed; reload');
    }
    final status = completed ? 'teacher_marked' : 'not_done';
    if (c == null) {
      completions[key] = FakeCompletion(status, note: note, dueAt: o.due);
    } else {
      c
        ..status = status
        ..note = note
        ..reason = ''
        ..version += 1;
    }
  }

  @override
  Future<void> review({
    required String activityId,
    required String studentId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    required bool approve,
    String reason = '',
  }) async {
    _enter('review:$studentId:${wireDate(date)}:$approve');
    final c = completions[_k(activityId, studentId, date)];
    if (c == null) {
      throw const AppError(AppErrorKind.notFound, 'Submission not found');
    }
    if (c.version != expectedVersion) {
      throw const AppError(AppErrorKind.conflict, 'This item changed; reload');
    }
    if (c.status != 'pending') {
      throw const AppError(
        AppErrorKind.conflict,
        'Only a pending submission can be reviewed',
      );
    }
    if (!approve && reason.trim().isEmpty) {
      throw const AppError(
        AppErrorKind.validation,
        'Give a reason (1-500 characters) when rejecting',
      );
    }
    c
      ..status = approve ? 'approved' : 'rejected'
      ..reason = reason
      ..version += 1;
  }

  @override
  Future<ServerPage<PendingVerification>> pending({
    String? courseId,
    int limit = 50,
    Map<String, dynamic>? cursor,
  }) async {
    _enter('pending');
    final rows = <PendingVerification>[];
    for (final e in completions.entries) {
      if (e.value.status != 'pending') continue;
      final p = e.key.split('|');
      final a = _act(p[0]);
      if (courseId != null && a.courseId != courseId) continue;
      rows.add(
        PendingVerification(
          activityId: a.id,
          courseId: a.courseId,
          courseTitle: courseTitle,
          activityTitle: a.title,
          studentId: p[1],
          studentName: students.firstWhere((s) => s.id == p[1]).name,
          date: parseDate(p[2]),
          version: e.value.version,
          submittedAt: now,
          note: e.value.note,
        ),
      );
    }
    rows.sort(
      (x, y) => '${x.activityId}${x.studentId}${wireDate(x.date)}'.compareTo(
        '${y.activityId}${y.studentId}${wireDate(y.date)}',
      ),
    );
    var start = 0;
    if (cursor != null) {
      final after =
          '${cursor['activity_id']}${cursor['student_id']}${cursor['date']}';
      start = rows.indexWhere(
        (r) =>
            '${r.activityId}${r.studentId}${wireDate(r.date)}'.compareTo(
              after,
            ) >
            0,
      );
      if (start < 0) start = rows.length;
    }
    final page = rows.skip(start).take(limit).toList();
    final more = start + page.length < rows.length;
    return ServerPage(
      page,
      more
          ? {
              'activity_id': page.last.activityId,
              'student_id': page.last.studentId,
              'date': wireDate(page.last.date),
            }
          : null,
      total: rows.length,
    );
  }

  // ------------------------------------------------------------ student
  @override
  Future<ServerPage<ActivityOccurrence>> myActivities(
    DateTime from,
    DateTime to, {
    String? courseId,
    int limit = 200,
    Map<String, dynamic>? cursor,
  }) async {
    _enter('myActivities:${wireDate(from)}:${wireDate(to)}');
    if (to.difference(from).inDays + 1 > 62) {
      throw const AppError(
        AppErrorKind.validation,
        'The date window must be 1-62 days',
      );
    }
    final rows = <ActivityOccurrence>[];
    for (final a in activities.where(
      (x) =>
          x.status != 'archived' &&
          (courseId == null || x.courseId == courseId),
    )) {
      for (final o in occurrences(a, from, to)) {
        final c = completions[_k(a.id, me, o.date)];
        rows.add(
          ActivityOccurrence(
            activityId: a.id,
            courseId: a.courseId,
            courseTitle: courseTitle,
            title: a.title,
            policy: a.policy,
            date: o.date,
            state: _state(
              c?.status,
              o.date,
              o.schedule.mode,
              c?.dueAt ?? o.due,
            ),
            version: c?.version ?? 0,
            dueAt: c?.dueAt ?? o.due,
            deadlineMode: o.schedule.mode,
            timezone: o.schedule.timezone,
            note: c?.note ?? '',
            reason: c?.reason ?? '',
            completionStatus: c?.status,
          ),
        );
      }
    }
    rows.sort(
      (x, y) => '${wireDate(x.date)}${x.activityId}'.compareTo(
        '${wireDate(y.date)}${y.activityId}',
      ),
    );
    var start = 0;
    if (cursor != null) {
      final after = '${cursor['date']}${cursor['activity_id']}';
      start = rows.indexWhere(
        (r) => '${wireDate(r.date)}${r.activityId}'.compareTo(after) > 0,
      );
      if (start < 0) start = rows.length;
    }
    final page = rows.skip(start).take(limit).toList();
    final more = start + page.length < rows.length;
    return ServerPage(
      page,
      more
          ? {
              'date': wireDate(page.last.date),
              'activity_id': page.last.activityId,
            }
          : null,
    );
  }

  @override
  Future<void> complete({
    required String activityId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    String note = '',
  }) async {
    _enter('complete:${wireDate(date)}:$requestId');
    final a = _act(activityId);
    if (a.policy == ActivityPolicy.teacherMarked) {
      throw const AppError(
        AppErrorKind.forbidden,
        'Your teacher records this activity',
      );
    }
    final o = occurrences(a, date, date).firstOrNull;
    if (o == null) {
      throw const AppError(
        AppErrorKind.conflict,
        'Not a scheduled day for this activity',
      );
    }
    if (date.isAfter(_day(now))) {
      throw const AppError(
        AppErrorKind.conflict,
        'This occurrence is in the future',
      );
    }
    if (o.due != null && now.isAfter(o.due!)) {
      throw const AppError(AppErrorKind.conflict, 'The deadline has passed');
    }
    final key = _k(activityId, me, date);
    final c = completions[key];
    if ((c?.version ?? 0) != expectedVersion) {
      throw const AppError(AppErrorKind.conflict, 'This item changed; reload');
    }
    final status = a.policy == ActivityPolicy.selfReported
        ? 'self_reported'
        : 'pending';
    if (c == null) {
      completions[key] = FakeCompletion(status, note: note, dueAt: o.due);
    } else {
      if (c.status != 'rejected' && c.status != 'not_done') {
        throw const AppError(
          AppErrorKind.conflict,
          'This occurrence is already recorded',
        );
      }
      c
        ..status = status
        ..note = note
        ..reason = ''
        ..dueAt = o.due
        ..version += 1;
    }
  }

  @override
  Future<void> retract({
    required String activityId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
  }) async {
    _enter('retract:${wireDate(date)}');
    final key = _k(activityId, me, date);
    final c = completions[key];
    if (c == null) {
      throw const AppError(
        AppErrorKind.notFound,
        'Nothing recorded for this occurrence',
      );
    }
    if (c.version != expectedVersion) {
      throw const AppError(AppErrorKind.conflict, 'This item changed; reload');
    }
    if (c.status != 'self_reported' && c.status != 'pending') {
      throw const AppError(
        AppErrorKind.conflict,
        'Only your own unreviewed entry can be withdrawn',
      );
    }
    completions.remove(key);
  }

  @override
  Future<List<ActivityStreak>> streaks(
    String courseId, {
    String? studentId,
  }) async {
    _enter('streaks');
    final target = studentId ?? me;
    return [
      for (final a in activities.where(
        (x) => x.courseId == courseId && x.status != 'archived',
      ))
        ActivityStreak(
          activityId: a.id,
          title: a.title,
          policy: a.policy,
          status: a.status,
          streak: streakOf(a, target),
        ),
    ];
  }
}

/// Derives progress from the same fake repositories the mutations change (no hardcoded figures).
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({
    required this.assignments,
    required this.attendance,
    required this.activities,
    this.courseId = 'c1',
    this.courseTitle = 'Algebra',
  });

  final FakeAssignmentRepository assignments;
  final FakeAttendanceRepository attendance;
  final FakeActivityRepository activities;
  final String courseId;
  final String courseTitle;
  Object? error;
  int calls = 0;

  Future<StudentProgress> _build(String studentId) async {
    calls++;
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    final name = activities.students
        .firstWhere(
          (s) => s.id == studentId,
          orElse: () => (id: studentId, name: 'Student'),
        )
        .name;
    final subs = studentId == activities.me
        ? assignments.mine
        : {
            for (final s in assignments.teacherView.where(
              (x) => x.studentId == studentId,
            ))
              s.assignmentId: s,
          };
    final pub = assignments.assignments
        .where((a) => a.status == AssignmentStatus.published)
        .toList();
    int count(SubmissionStatus s) =>
        pub.where((a) => subs[a.id]?.status == s).length;
    final graded = pub
        .where(
          (a) =>
              subs[a.id]?.status == SubmissionStatus.graded &&
              subs[a.id]?.score != null,
        )
        .toList();
    final now = activities.now;
    String statusOf(Assignment a) {
      final s = subs[a.id]?.status;
      if (s == SubmissionStatus.returned) return 'needs_revision';
      if (s == SubmissionStatus.graded) return 'graded';
      if (s == SubmissionStatus.submitted) return 'awaiting_review';
      return a.dueAt != null && a.dueAt!.isBefore(now) ? 'overdue' : 'todo';
    }

    final records = attendance.records.values
        .where((r) => r.studentId == studentId)
        .toList();
    int rc(AttendanceStatus s) => records.where((r) => r.status == s).length;
    final counted =
        rc(AttendanceStatus.present) +
        rc(AttendanceStatus.late) +
        rc(AttendanceStatus.absent);
    return StudentProgress(
      courseId: courseId,
      courseTitle: courseTitle,
      courseArchived: false,
      studentId: studentId,
      studentName: name,
      enrollmentStatus: 'active',
      joinedAt: DateTime(2030, 1, 1),
      attendance: AttendanceProgress(
        total: attendance.sessions.length,
        closed: attendance.sessions.where((s) => s.closed).length,
        present: rc(AttendanceStatus.present),
        late: rc(AttendanceStatus.late),
        excused: rc(AttendanceStatus.excused),
        absent: rc(AttendanceStatus.absent),
        unmarked: attendance.sessions.length - records.length,
        rate: counted == 0
            ? null
            : 100.0 *
                  (rc(AttendanceStatus.present) + rc(AttendanceStatus.late)) /
                  counted,
        recent: const [],
      ),
      assignments: AssignmentProgress(
        published: pub.length,
        done:
            count(SubmissionStatus.submitted) + count(SubmissionStatus.graded),
        awaitingReview: count(SubmissionStatus.submitted),
        graded: count(SubmissionStatus.graded),
        needsRevision: count(SubmissionStatus.returned),
        notStarted: pub.where((a) => subs[a.id] == null).length,
        overdue: pub
            .where(
              (a) =>
                  subs[a.id] == null &&
                  a.dueAt != null &&
                  a.dueAt!.isBefore(now),
            )
            .length,
        averagePercent: graded.isEmpty
            ? null
            : graded
                      .map((a) => 100.0 * subs[a.id]!.score! / a.maxScore)
                      .reduce((x, y) => x + y) /
                  graded.length,
        itemsTotal: pub.length,
        items: [
          for (final a in pub)
            AssignmentEntry(
              id: a.id,
              title: a.title,
              status: statusOf(a),
              dueAt: a.dueAt,
              maxScore: a.maxScore,
              score: subs[a.id]?.score,
            ),
        ],
      ),
      activities: ActivityProgress(
        activities: await activities.streaks(courseId, studentId: studentId),
        pendingVerification: activities.completions.entries
            .where(
              (e) =>
                  e.key.contains('|$studentId|') && e.value.status == 'pending',
            )
            .length,
      ),
    );
  }

  @override
  Future<StudentProgress> forStudent(String courseId, String studentId) =>
      _build(studentId);

  @override
  Future<StudentProgress> mine(String courseId) => _build(activities.me);
}

/// Derives the unified task list from the assignment and activity fakes with the server's status rules.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    required this.assignments,
    required this.activities,
    this.courseId = 'c1',
    this.courseTitle = 'Algebra',
  });

  final FakeAssignmentRepository assignments;
  final FakeActivityRepository activities;
  final String courseId;
  final String courseTitle;
  Object? error;
  int calls = 0;
  final calendarCalls = <String>[];

  List<TaskItem> _pool() {
    final now = activities.now;
    final out = <TaskItem>[];
    for (final a in assignments.assignments.where(
      (x) => x.status == AssignmentStatus.published,
    )) {
      final s = assignments.mine[a.id]?.status;
      final status = switch (s) {
        SubmissionStatus.returned => 'needs_revision',
        SubmissionStatus.graded => 'graded',
        SubmissionStatus.submitted => 'awaiting_review',
        _ => a.dueAt != null && a.dueAt!.isBefore(now) ? 'overdue' : 'todo',
      };
      out.add(
        TaskItem(
          kind: TaskKind.assignment,
          id: a.id,
          key2: '',
          courseId: courseId,
          courseTitle: courseTitle,
          title: a.title,
          status: status,
          taskAt: a.dueAt,
          dueAt: a.dueAt,
        ),
      );
    }
    final today = _day(now);
    for (final a in activities.activities.where(
      (x) => x.status != 'archived',
    )) {
      for (final o in activities.occurrences(
        a,
        today.subtract(const Duration(days: 61)),
        today.add(const Duration(days: 61)),
      )) {
        final st = activities.stateOf(a.id, activities.me, o.date);
        out.add(
          TaskItem(
            kind: TaskKind.activity,
            id: a.id,
            key2: wireDate(o.date),
            courseId: courseId,
            courseTitle: courseTitle,
            title: a.title,
            status: switch (st) {
              OccurrenceState.completed => 'done',
              OccurrenceState.pending => 'awaiting_review',
              OccurrenceState.rejected => 'needs_revision',
              OccurrenceState.open => 'todo',
              OccurrenceState.upcoming => 'upcoming',
              _ => 'missed',
            },
            taskAt: o.due ?? o.date,
            dueAt: o.due,
            occurrenceDate: o.date,
            policy: a.policy,
            version:
                activities
                    .completions[FakeActivityRepository._k(
                      a.id,
                      activities.me,
                      o.date,
                    )]
                    ?.version ??
                0,
          ),
        );
      }
    }
    return out;
  }

  @override
  Future<ServerPage<TaskItem>> myTasks(
    TaskView view, {
    DateTime? from,
    DateTime? to,
    int limit = 100,
    Map<String, dynamic>? cursor,
  }) async {
    calls++;
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    final now = activities.now;
    var rows = _pool().where((t) {
      switch (view) {
        case TaskView.range:
          if (t.kind == TaskKind.activity) {
            return !t.occurrenceDate!.isBefore(_day(from!)) &&
                t.occurrenceDate!.isBefore(_day(to!));
          }
          return t.taskAt != null &&
              !t.taskAt!.isBefore(from!) &&
              t.taskAt!.isBefore(to!);
        case TaskView.upcoming:
          return ['todo', 'needs_revision', 'upcoming'].contains(t.status) &&
              (t.kind == TaskKind.activity ||
                  t.taskAt == null ||
                  !t.taskAt!.isBefore(now) ||
                  t.status == 'needs_revision');
        case TaskView.overdue:
          return t.status == 'overdue' || t.status == 'missed';
        case TaskView.completed:
          return ['done', 'graded', 'awaiting_review'].contains(t.status);
      }
    }).toList();
    String key(TaskItem t) =>
        '${(t.taskAt ?? DateTime(9999)).toIso8601String()}|${t.kind.name}|${t.id}|${t.key2}';
    rows.sort(
      (x, y) => view == TaskView.completed
          ? key(y).compareTo(key(x))
          : key(x).compareTo(key(y)),
    );
    var start = 0;
    if (cursor != null) {
      final c = cursor['key'] as String;
      start = rows.indexWhere(
        (r) => view == TaskView.completed
            ? key(r).compareTo(c) < 0
            : key(r).compareTo(c) > 0,
      );
      if (start < 0) start = rows.length;
    }
    rows = rows.skip(start).toList();
    final page = rows.take(limit).toList();
    return ServerPage(
      page,
      rows.length > limit ? {'key': key(page.last)} : null,
    );
  }

  @override
  Future<CalendarPage> teacherCalendar(
    DateTime from,
    DateTime to, {
    int limit = 100,
    Map<String, dynamic>? cursor,
  }) async {
    calendarCalls.add('${wireDate(from)}..${wireDate(to)}');
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
    final items = <CalendarItem>[
      for (final a in assignments.assignments.where(
        (x) =>
            x.status == AssignmentStatus.published &&
            x.dueAt != null &&
            !x.dueAt!.isBefore(from) &&
            x.dueAt!.isBefore(to),
      ))
        CalendarItem(
          kind: 'assignment_due',
          id: a.id,
          key2: '',
          courseId: courseId,
          courseTitle: courseTitle,
          title: a.title,
          status: 'due',
          taskAt: a.dueAt,
          received: assignments.teacherView
              .where((s) => s.assignmentId == a.id)
              .length,
          expected: activities.students.length,
        ),
    ];
    final pending = activities.completions.values
        .where((c) => c.status == 'pending')
        .length;
    return CalendarPage(items, null, pending);
  }
}

/// Three activities (one per completion policy) with a week of history, for previews and screenshots.
FakeActivityRepository seededActivities({DateTime Function()? now}) {
  final repo = FakeActivityRepository(
    now: now,
    students: [
      (id: 's1', name: 'Sam Learner'),
      (id: 's2', name: 'Sue Learner'),
      (id: 's3', name: 'Tom Nguyen'),
    ],
  );
  final today = DateTime(
    (now ?? DateTime.now)().year,
    (now ?? DateTime.now)().month,
    (now ?? DateTime.now)().day,
  );
  FakeSchedule weekly({String mode = 'day_end'}) => FakeSchedule(
    effectiveFrom: today.subtract(const Duration(days: 9)),
    weekdays: const [1, 2, 3, 4, 5, 6, 7],
    mode: mode,
    time: mode == 'time' ? '20:00' : null,
  );
  repo.activities.addAll([
    FakeActivity(
      id: 'act-read',
      courseId: 'c1',
      title: 'Reading Practice',
      description: 'Read for 20 minutes and note one new word.',
      policy: ActivityPolicy.selfReported,
      schedules: [weekly()],
    ),
    FakeActivity(
      id: 'act-journal',
      courseId: 'c1',
      title: 'Research Journal',
      description: 'One paragraph on what you found today.',
      policy: ActivityPolicy.teacherVerified,
      schedules: [weekly()],
    ),
    FakeActivity(
      id: 'act-lab',
      courseId: 'c1',
      title: 'Laboratory Preparation',
      policy: ActivityPolicy.teacherMarked,
      schedules: [weekly(mode: 'time')],
    ),
  ]);
  for (var i = 1; i <= 4; i++) {
    final d = today.subtract(Duration(days: i));
    repo.completions['act-read|s1|${wireDate(d)}'] = FakeCompletion(
      'self_reported',
    );
    repo.completions['act-journal|s1|${wireDate(d)}'] = FakeCompletion(
      'approved',
    );
    if (i != 2) {
      repo.completions['act-lab|s1|${wireDate(d)}'] = FakeCompletion(
        'teacher_marked',
      );
    }
  }
  repo.completions['act-journal|s2|${wireDate(today)}'] = FakeCompletion(
    'pending',
    note: 'Notes on chapter three.',
  );
  return repo;
}
