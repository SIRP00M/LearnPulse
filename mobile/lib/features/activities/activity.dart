import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';

/// Domain types of the Daily Activity Tracker. The server (V9 RPCs) decides eligibility, deadlines, states and streaks;
/// these types only carry and label what it returns. Dates are calendar dates in the schedule's own timezone; instants
/// (`dueAt`) are UTC on the wire and rendered in device-local time.
enum ActivityPolicy {
  teacherMarked(
    'teacher_marked',
    'Teacher marked',
    'Your teacher records completion.',
  ),
  selfReported('self_reported', 'Self-reported', 'You mark it done yourself.'),
  teacherVerified(
    'teacher_verified',
    'Teacher verified',
    'You submit it and your teacher confirms.',
  );

  const ActivityPolicy(this.wire, this.label, this.hint);
  final String wire;
  final String label;
  final String hint;

  String text(AppLocalizations l) => switch (this) {
    teacherMarked => l.actPolicyTeacherMarked,
    selfReported => l.actPolicySelfReported,
    teacherVerified => l.actPolicyTeacherVerified,
  };

  String hintText(AppLocalizations l) => switch (this) {
    teacherMarked => l.actPolicyHintTeacherMarked,
    selfReported => l.actPolicyHintSelfReported,
    teacherVerified => l.actPolicyHintTeacherVerified,
  };

  /// Teacher-facing explanation shown on the create form.
  String detailText(AppLocalizations l) => switch (this) {
    teacherMarked => l.actPolicyDetailTeacherMarked,
    selfReported => l.actPolicyDetailSelfReported,
    teacherVerified => l.actPolicyDetailTeacherVerified,
  };

  static ActivityPolicy parse(Object? v) => ActivityPolicy.values.firstWhere(
    (p) => p.wire == v,
    orElse: () => ActivityPolicy.selfReported,
  );
}

/// Occurrence state as computed by the server (`private.occurrence_state`).
enum OccurrenceState {
  upcoming('Upcoming'),
  open('To do'),
  pending('Awaiting review'),
  completed('Done'),
  rejected('Needs another try'),
  notDone('Not done'),
  missed('Missed');

  const OccurrenceState(this.label);
  final String label;

  String text(AppLocalizations l) => switch (this) {
    upcoming => l.actStateUpcoming,
    open => l.actStateOpen,
    pending => l.actStatePending,
    completed => l.actStateCompleted,
    rejected => l.actStateRejected,
    notDone => l.actStateNotDone,
    missed => l.actStateMissed,
  };

  static OccurrenceState parse(Object? v) => switch (v) {
    'upcoming' => OccurrenceState.upcoming,
    'pending' => OccurrenceState.pending,
    'completed' => OccurrenceState.completed,
    'rejected' => OccurrenceState.rejected,
    'not_done' => OccurrenceState.notDone,
    'missed' => OccurrenceState.missed,
    _ => OccurrenceState.open,
  };
}

DateTime parseDate(Object? v) {
  final s = '$v';
  final p = s.split('-');
  if (p.length < 3) return DateTime(1970);
  return DateTime(
    int.parse(p[0]),
    int.parse(p[1]),
    int.parse(p[2].substring(0, 2)),
  );
}

DateTime? parseInstant(Object? v) =>
    v == null ? null : DateTime.tryParse('$v')?.toLocal();

String wireDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int _i(Object? v) => (v as num?)?.toInt() ?? 0;

const weekdayLetters = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Common IANA zones offered by the schedule form (the server validates any name; no extra dependency needed).
const commonTimezones = <String, String>{
  'Asia/Bangkok': 'Bangkok (UTC+7)',
  'Asia/Singapore': 'Singapore (UTC+8)',
  'Asia/Tokyo': 'Tokyo (UTC+9)',
  'Asia/Kolkata': 'India (UTC+5:30)',
  'Asia/Dubai': 'Dubai (UTC+4)',
  'Europe/London': 'London',
  'Europe/Paris': 'Paris / Berlin',
  'America/New_York': 'New York',
  'America/Chicago': 'Chicago',
  'America/Los_Angeles': 'Los Angeles',
  'Australia/Sydney': 'Sydney',
  'Pacific/Auckland': 'Auckland',
  'UTC': 'UTC',
};

String timezoneText(String zone, AppLocalizations l) => switch (zone) {
  'Asia/Bangkok' => l.actTzBangkok,
  'Asia/Singapore' => l.actTzSingapore,
  'Asia/Tokyo' => l.actTzTokyo,
  'Asia/Kolkata' => l.actTzIndia,
  'Asia/Dubai' => l.actTzDubai,
  'Europe/London' => l.actTzLondon,
  'Europe/Paris' => l.actTzParisBerlin,
  'America/New_York' => l.actTzNewYork,
  'America/Chicago' => l.actTzChicago,
  'America/Los_Angeles' => l.actTzLosAngeles,
  'Australia/Sydney' => l.actTzSydney,
  'Pacific/Auckland' => l.actTzAuckland,
  'UTC' => l.actTzUtc,
  _ => zone,
};

class ActivitySchedule {
  const ActivitySchedule({
    required this.versionNo,
    required this.weekdays,
    required this.effectiveFrom,
    this.endDate,
    this.deadlineMode = 'day_end',
    this.deadlineTime,
    this.timezone = 'Asia/Bangkok',
  });

  final int versionNo;
  final List<int> weekdays; // ISO 1 = Monday .. 7 = Sunday; empty = paused
  final DateTime effectiveFrom;
  final DateTime? endDate;
  final String deadlineMode; // day_end | time | none
  final String? deadlineTime; // HH:mm[:ss]
  final String timezone;

  bool get paused => weekdays.isEmpty;

  String get weekdaysLabel {
    if (weekdays.isEmpty) return 'Paused';
    final days = [...weekdays]..sort();
    if (days.length == 7) return 'Every day';
    if (days.join() == '12345') return 'Weekdays';
    return days.map((d) => weekdayLetters[d - 1]).join(', ');
  }

  String weekdaysText(AppLocalizations l, AppFormat f) {
    if (weekdays.isEmpty) return l.actPaused;
    final days = [...weekdays]..sort();
    if (days.length == 7) return l.actEveryDay;
    if (days.join() == '12345') return l.actWeekdays;
    return days.map(f.weekdayShort).join(', ');
  }

  String deadlineText(AppLocalizations l) => switch (deadlineMode) {
    'time' => l.actDeadlineAtTime(
      (deadlineTime ?? '').split(':').take(2).join(':'),
      timezone,
    ),
    'none' => l.asgNoDeadline,
    _ => l.actDeadlineDayEnd(timezone),
  };

  String get deadlineLabel => switch (deadlineMode) {
    'time' =>
      'Due ${(deadlineTime ?? '').split(':').take(2).join(':')} ($timezone)',
    'none' => 'No deadline',
    _ => 'Due at the end of the day ($timezone)',
  };

  static ActivitySchedule? fromJson(Object? j) {
    if (j is! Map) return null;
    return ActivitySchedule(
      versionNo: _i(j['version_no']),
      weekdays: [for (final w in (j['weekdays'] as List? ?? const [])) _i(w)],
      effectiveFrom: parseDate(j['effective_from']),
      endDate: j['end_date'] == null ? null : parseDate(j['end_date']),
      deadlineMode: (j['deadline_mode'] as String?) ?? 'day_end',
      deadlineTime: j['deadline_time'] as String?,
      timezone: (j['timezone'] as String?) ?? 'Asia/Bangkok',
    );
  }
}

class ActivityToday {
  const ActivityToday({
    required this.date,
    required this.scheduled,
    required this.expected,
    required this.completed,
    required this.pending,
  });

  final DateTime date;
  final bool scheduled;
  final int expected;
  final int completed;
  final int pending;

  static ActivityToday fromJson(Object? j) {
    final m = (j as Map?) ?? const {};
    return ActivityToday(
      date: parseDate(m['date'] ?? '1970-01-01'),
      scheduled: m['scheduled'] == true,
      expected: _i(m['expected']),
      completed: _i(m['completed']),
      pending: _i(m['pending']),
    );
  }
}

/// A course's activity as the teacher sees it (overview row).
class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.policy,
    required this.status,
    required this.version,
    required this.schedule,
    required this.today,
    required this.pendingTotal,
  });

  final String id;
  final String title;
  final String description;
  final ActivityPolicy policy;
  final String status; // active | inactive | archived
  final int version;
  final ActivitySchedule? schedule;
  final ActivityToday today;
  final int pendingTotal;

  bool get archived => status == 'archived';
  bool get active => status == 'active';

  static Activity fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'] as String,
    title: (j['title'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    policy: ActivityPolicy.parse(j['policy']),
    status: (j['status'] as String?) ?? 'active',
    version: _i(j['version']),
    schedule: ActivitySchedule.fromJson(j['schedule']),
    today: ActivityToday.fromJson(j['today']),
    pendingTotal: _i(j['pending_total']),
  );
}

/// One scheduled occurrence for the signed-in student.
class ActivityOccurrence {
  const ActivityOccurrence({
    required this.activityId,
    required this.courseId,
    required this.courseTitle,
    required this.title,
    required this.policy,
    required this.date,
    required this.state,
    required this.version,
    this.dueAt,
    this.deadlineMode = 'day_end',
    this.timezone = 'UTC',
    this.note = '',
    this.reason = '',
    this.completionStatus,
  });

  final String activityId;
  final String courseId;
  final String courseTitle;
  final String title;
  final ActivityPolicy policy;
  final DateTime date;
  final OccurrenceState state;
  final int version; // 0 = nothing recorded yet
  final DateTime? dueAt;
  final String deadlineMode;
  final String timezone;
  final String note;
  final String reason;
  final String? completionStatus;

  /// Whether the student may act now (server still re-checks).
  bool get canComplete =>
      policy != ActivityPolicy.teacherMarked &&
      (state == OccurrenceState.open ||
          state == OccurrenceState.rejected ||
          (state == OccurrenceState.notDone && version > 0));
  bool get canWithdraw =>
      (completionStatus == 'self_reported' || completionStatus == 'pending') &&
      (dueAt == null || DateTime.now().isBefore(dueAt!));

  static ActivityOccurrence fromJson(Map<String, dynamic> j) =>
      ActivityOccurrence(
        activityId: j['activity_id'] as String,
        courseId: (j['course_id'] as String?) ?? '',
        courseTitle: (j['course_title'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        policy: ActivityPolicy.parse(j['policy']),
        date: parseDate(j['occurrence_date']),
        state: OccurrenceState.parse(j['state']),
        version: _i(j['version']),
        dueAt: parseInstant(j['due_at']),
        deadlineMode: (j['deadline_mode'] as String?) ?? 'day_end',
        timezone: (j['timezone'] as String?) ?? 'UTC',
        note: (j['note'] as String?) ?? '',
        reason: (j['reason'] as String?) ?? '',
        completionStatus: j['completion_status'] as String?,
      );
}

class StreakInfo {
  const StreakInfo({
    this.current,
    this.best,
    this.completed = 0,
    this.resolved = 0,
    this.capped = false,
  });

  /// Null for deadline-free activities (no streak is defined).
  final int? current;
  final int? best;
  final int completed;
  final int resolved;
  final bool capped;

  double? get rate => resolved == 0 ? null : completed / resolved;

  static StreakInfo fromJson(Object? j) {
    final m = (j as Map?) ?? const {};
    return StreakInfo(
      current: (m['current'] as num?)?.toInt(),
      best: (m['best'] as num?)?.toInt(),
      completed: _i(m['completed']),
      resolved: _i(m['resolved']),
      capped: m['capped'] == true,
    );
  }
}

class ActivityStreak {
  const ActivityStreak({
    required this.activityId,
    required this.title,
    required this.policy,
    required this.status,
    required this.streak,
  });

  final String activityId;
  final String title;
  final ActivityPolicy policy;
  final String status;
  final StreakInfo streak;

  static ActivityStreak fromJson(Map<String, dynamic> j) => ActivityStreak(
    activityId: j['activity_id'] as String,
    title: (j['title'] as String?) ?? '',
    policy: ActivityPolicy.parse(j['policy']),
    status: (j['status'] as String?) ?? 'active',
    streak: StreakInfo.fromJson(j['streak']),
  );
}

class RegisterCell {
  const RegisterCell({
    required this.date,
    required this.state,
    required this.version,
    this.completionStatus,
    this.note = '',
    this.reason = '',
  });

  final DateTime date;
  final OccurrenceState state;
  final int version;
  final String? completionStatus;
  final String note;
  final String reason;
}

class RegisterStudent {
  const RegisterStudent({
    required this.studentId,
    required this.name,
    required this.cells,
  });
  final String studentId;
  final String name;
  final List<RegisterCell> cells;
}

/// One activity x active students x one week (only the activity's scheduled days).
class ActivityRegister {
  const ActivityRegister({
    required this.activityId,
    required this.title,
    required this.policy,
    required this.weekStart,
    required this.days,
    required this.students,
  });

  final String activityId;
  final String title;
  final ActivityPolicy policy;
  final DateTime weekStart;
  final List<DateTime> days;
  final List<RegisterStudent> students;

  static ActivityRegister fromJson(Map<String, dynamic> j) => ActivityRegister(
    activityId: j['activity_id'] as String,
    title: (j['title'] as String?) ?? '',
    policy: ActivityPolicy.parse(j['policy']),
    weekStart: parseDate(j['week_start']),
    days: [
      for (final d in (j['days'] as List? ?? const []))
        parseDate((d as Map)['date']),
    ],
    students: [
      for (final s in (j['students'] as List? ?? const []))
        RegisterStudent(
          studentId: (s as Map)['student_id'] as String,
          name: (s['full_name'] as String?) ?? '',
          cells: [
            for (final c in (s['cells'] as List? ?? const []))
              RegisterCell(
                date: parseDate((c as Map)['date']),
                state: OccurrenceState.parse(c['state']),
                version: _i(c['version']),
                completionStatus: c['completion_status'] as String?,
                note: (c['note'] as String?) ?? '',
                reason: (c['reason'] as String?) ?? '',
              ),
          ],
        ),
    ],
  );
}

class PendingVerification {
  const PendingVerification({
    required this.activityId,
    required this.courseId,
    required this.courseTitle,
    required this.activityTitle,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.version,
    this.submittedAt,
    this.note = '',
  });

  final String activityId;
  final String courseId;
  final String courseTitle;
  final String activityTitle;
  final String studentId;
  final String studentName;
  final DateTime date;
  final int version;
  final DateTime? submittedAt;
  final String note;

  static PendingVerification fromJson(Map<String, dynamic> j) =>
      PendingVerification(
        activityId: j['activity_id'] as String,
        courseId: (j['course_id'] as String?) ?? '',
        courseTitle: (j['course_title'] as String?) ?? '',
        activityTitle: (j['activity_title'] as String?) ?? '',
        studentId: j['student_id'] as String,
        studentName: (j['full_name'] as String?) ?? '',
        date: parseDate(j['occurrence_date']),
        version: _i(j['version']),
        submittedAt: parseInstant(j['submitted_at']),
        note: (j['note'] as String?) ?? '',
      );
}

/// A page of server rows plus the keyset cursor of the next page (null = last page).
class ServerPage<T> {
  const ServerPage(this.items, this.next, {this.total});
  final List<T> items;
  final Map<String, dynamic>? next;
  final int? total;
}
