/// Staff attendance models (V14). Every instant is a server UTC timestamp; nothing here is computed on the device.
enum StaffState {
  onTime('on_time'),
  late('late'),
  missingCheckout('missing_checkout'),
  inProgress('in_progress'),
  absent('absent'),
  leave('leave'),
  unscheduled('unscheduled'),
  upcoming('upcoming');

  const StaffState(this.wire);
  final String wire;

  static StaffState parse(Object? v) =>
      values.firstWhere((s) => s.wire == v, orElse: () => StaffState.upcoming);
}

DateTime? _t(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toUtc();
int _i(Object? v) => (v as num?)?.toInt() ?? 0;

class StaffSchedule {
  const StaffSchedule({
    required this.id,
    required this.label,
    required this.weekdays,
    required this.start,
    required this.end,
    required this.timezone,
    required this.graceMinutes,
  });
  final String id;
  final String label;
  final List<int> weekdays; // ISO 1 = Monday
  final String start; // HH:mm
  final String end;
  final String timezone;
  final int graceMinutes;

  static StaffSchedule fromJson(Map<String, dynamic> j) => StaffSchedule(
    id: '${j['id']}',
    label: (j['label'] as String?) ?? '',
    weekdays: [for (final d in (j['weekdays'] as List? ?? const [])) _i(d)],
    start: '${j['start_time']}'.padRight(5).substring(0, 5),
    end: '${j['end_time']}'.padRight(5).substring(0, 5),
    timezone: (j['timezone'] as String?) ?? 'Asia/Bangkok',
    graceMinutes: _i(j['late_grace_minutes']),
  );
}

class StaffPerson {
  const StaffPerson(this.id, this.name);
  final String id;
  final String name;
}

class StaffContext {
  const StaffContext({
    required this.isStaff,
    this.isSupervisor = false,
    this.hasSupervisor = false,
    this.schedules = const [],
    this.openSince,
    this.openLateMinutes = 0,
    this.supervisees = const [],
  });
  final bool isStaff;
  final bool isSupervisor;
  final bool hasSupervisor;
  final List<StaffSchedule> schedules;
  final DateTime? openSince; // non-null while clocked in
  final int openLateMinutes;
  final List<StaffPerson> supervisees;

  static StaffContext fromJson(Map<String, dynamic> j) {
    final open = j['open_punch'];
    return StaffContext(
      isStaff: j['is_staff'] == true,
      isSupervisor: j['is_supervisor'] == true,
      hasSupervisor: ((j['supervisors'] as List?) ?? const []).isNotEmpty,
      schedules: [
        for (final s in (j['schedules'] as List? ?? const []))
          StaffSchedule.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      openSince: open is Map ? _t(open['clock_in_at']) : null,
      openLateMinutes: open is Map ? _i(open['late_minutes']) : 0,
      supervisees: [
        for (final p in (j['supervisees'] as List? ?? const []))
          StaffPerson('${(p as Map)['id']}', (p['name'] as String?) ?? ''),
      ],
    );
  }
}

class StaffTotals {
  const StaffTotals({
    this.onTime = 0,
    this.late = 0,
    this.missingCheckout = 0,
    this.absent = 0,
    this.leave = 0,
    this.workedMinutes = 0,
  });
  final int onTime, late, missingCheckout, absent, leave, workedMinutes;

  static StaffTotals fromJson(Map<String, dynamic> j) => StaffTotals(
    onTime: _i(j['on_time']),
    late: _i(j['late']),
    missingCheckout: _i(j['missing_checkout']),
    absent: _i(j['absent']),
    leave: _i(j['leave']),
    workedMinutes: _i(j['worked_minutes']),
  );
}

class StaffRow {
  const StaffRow({
    required this.day,
    required this.state,
    this.start,
    this.end,
    this.clockIn,
    this.clockOut,
    this.lateMinutes = 0,
  });
  final String day; // yyyy-MM-dd, the working date in the schedule's zone
  final StaffState state;
  final String? start;
  final String? end;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final int lateMinutes;

  static StaffRow fromJson(Map<String, dynamic> j) => StaffRow(
    day: '${j['day']}',
    state: StaffState.parse(j['state']),
    start: (j['start_time'] as String?)?.substring(0, 5),
    end: (j['end_time'] as String?)?.substring(0, 5),
    clockIn: _t(j['clock_in_at']),
    clockOut: _t(j['clock_out_at']),
    lateMinutes: _i(j['late_minutes']),
  );
}

class StaffReport {
  const StaffReport({required this.rows, required this.totals});
  final List<StaffRow> rows;
  final StaffTotals totals;

  static StaffReport fromJson(Map<String, dynamic> j) => StaffReport(
    rows: [
      for (final r in (j['rows'] as List? ?? const []))
        StaffRow.fromJson(Map<String, dynamic>.from(r as Map)),
    ],
    totals: StaffTotals.fromJson(
      Map<String, dynamic>.from((j['totals'] as Map?) ?? const {}),
    ),
  );
}

class TeamRow {
  const TeamRow(this.staffId, this.name, this.totals);
  final String staffId;
  final String name;
  final StaffTotals totals;
}

class StaffRequest {
  const StaffRequest({
    required this.id,
    required this.staffName,
    required this.kind,
    required this.from,
    required this.to,
    required this.reason,
    required this.status,
    this.proposedIn,
    this.proposedOut,
    this.decisionNote = '',
  });
  final String id;
  final String staffName;
  final String kind; // leave | correction
  final String from; // yyyy-MM-dd
  final String to;
  final String reason;
  final String status; // pending | approved | rejected | cancelled
  final DateTime? proposedIn;
  final DateTime? proposedOut;
  final String decisionNote;

  bool get pending => status == 'pending';

  static StaffRequest fromJson(Map<String, dynamic> j) => StaffRequest(
    id: '${j['id']}',
    staffName: (j['staff_name'] as String?) ?? '',
    kind: '${j['kind']}',
    from: '${j['date_from']}',
    to: '${j['date_to']}',
    reason: (j['reason'] as String?) ?? '',
    status: '${j['status']}',
    proposedIn: _t(j['proposed_clock_in']),
    proposedOut: _t(j['proposed_clock_out']),
    decisionNote: (j['decision_note'] as String?) ?? '',
  );
}

String ymdOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
