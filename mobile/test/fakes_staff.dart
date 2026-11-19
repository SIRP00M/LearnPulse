import 'package:learn_pulse/features/staff/staff.dart';
import 'package:learn_pulse/features/staff/staff_repository.dart';

/// Scriptable in-memory staff repository that records every call (including the request ids).
class FakeStaffRepository implements StaffRepository {
  FakeStaffRepository({
    StaffContext? context,
    StaffReport? report,
    List<StaffRequest>? mine,
    List<StaffRequest>? toDecide,
    List<TeamRow>? team,
  }) : ctx =
           context ??
           const StaffContext(
             isStaff: true,
             hasSupervisor: true,
             schedules: [
               StaffSchedule(
                 id: 's1',
                 label: 'Office',
                 weekdays: [1, 2, 3, 4, 5],
                 start: '08:30',
                 end: '16:30',
                 timezone: 'Asia/Bangkok',
                 graceMinutes: 10,
               ),
             ],
           ),
       rep = report ?? const StaffReport(rows: [], totals: StaffTotals()),
       mine = mine ?? [],
       toDecide = toDecide ?? [],
       teamRows = team ?? [];

  StaffContext ctx;
  StaffReport rep;
  final List<StaffRequest> mine;
  final List<StaffRequest> toDecide;
  final List<TeamRow> teamRows;
  final calls = <String>[];
  Object? failNext; // thrown once by the next mutating call

  void _maybeThrow() {
    final e = failNext;
    if (e != null) {
      failNext = null;
      throw e;
    }
  }

  StaffContext _open(DateTime? since) => StaffContext(
    isStaff: ctx.isStaff,
    isSupervisor: ctx.isSupervisor,
    hasSupervisor: ctx.hasSupervisor,
    schedules: ctx.schedules,
    openSince: since,
    supervisees: ctx.supervisees,
  );

  @override
  Future<StaffContext> context() async => ctx;

  @override
  Future<void> clockIn(String requestId) async {
    calls.add('in:$requestId');
    _maybeThrow();
    ctx = _open(DateTime.utc(2026, 11, 17, 1, 30));
  }

  @override
  Future<void> clockOut(String requestId) async {
    calls.add('out:$requestId');
    _maybeThrow();
    ctx = _open(null);
  }

  @override
  Future<StaffReport> report(
    DateTime from,
    DateTime to, {
    String? staffId,
  }) async => rep;

  @override
  Future<List<TeamRow>> team(DateTime from, DateTime to) async => teamRows;

  @override
  Future<List<StaffRequest>> requests(String scope, {String? status}) async =>
      scope == 'mine' ? List.of(mine) : List.of(toDecide);

  @override
  Future<void> submitRequest({
    required String requestId,
    required String kind,
    required DateTime from,
    required DateTime to,
    required String reason,
    DateTime? clockIn,
    DateTime? clockOut,
  }) async {
    calls.add('submit:$requestId:$kind:$reason');
    _maybeThrow();
    mine.add(
      StaffRequest(
        id: 'r${mine.length + 1}',
        staffName: 'Me',
        kind: kind,
        from: ymdOf(from),
        to: ymdOf(to),
        reason: reason,
        status: 'pending',
      ),
    );
  }

  @override
  Future<void> cancelRequest(String id) async {
    calls.add('cancel:$id');
    _maybeThrow();
    final i = mine.indexWhere((r) => r.id == id);
    final r = mine[i];
    mine[i] = StaffRequest(
      id: r.id,
      staffName: r.staffName,
      kind: r.kind,
      from: r.from,
      to: r.to,
      reason: r.reason,
      status: 'cancelled',
    );
  }

  @override
  Future<void> decide({
    required String id,
    required String requestId,
    required bool approve,
    required String note,
  }) async {
    calls.add('decide:$id:${approve ? 'approve' : 'reject'}:$note');
    _maybeThrow();
    toDecide.removeWhere((r) => r.id == id);
  }
}
