import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'staff.dart';

/// Staff attendance access: V14 RPCs only. The client never writes tables and never supplies a time:
/// the server clock decides every punch, and only an explicit supervision row can approve anything.
abstract class StaffRepository {
  Future<StaffContext> context();
  Future<void> clockIn(String requestId);
  Future<void> clockOut(String requestId);
  Future<StaffReport> report(DateTime from, DateTime to, {String? staffId});
  Future<List<TeamRow>> team(DateTime from, DateTime to);
  Future<List<StaffRequest>> requests(String scope, {String? status});
  Future<void> submitRequest({
    required String requestId,
    required String kind,
    required DateTime from,
    required DateTime to,
    required String reason,
    DateTime? clockIn,
    DateTime? clockOut,
  });
  Future<void> cancelRequest(String id);
  Future<void> decide({
    required String id,
    required String requestId,
    required bool approve,
    required String note,
  });
}

/// Where staff attendance is not wired (tests, previews): nobody is staff.
class NoStaffRepository implements StaffRepository {
  const NoStaffRepository();
  @override
  Future<StaffContext> context() async => const StaffContext(isStaff: false);
  @override
  Future<void> clockIn(String requestId) async {}
  @override
  Future<void> clockOut(String requestId) async {}
  @override
  Future<StaffReport> report(
    DateTime from,
    DateTime to, {
    String? staffId,
  }) async => const StaffReport(rows: [], totals: StaffTotals());
  @override
  Future<List<TeamRow>> team(DateTime from, DateTime to) async => const [];
  @override
  Future<List<StaffRequest>> requests(String scope, {String? status}) async =>
      const [];
  @override
  Future<void> submitRequest({
    required String requestId,
    required String kind,
    required DateTime from,
    required DateTime to,
    required String reason,
    DateTime? clockIn,
    DateTime? clockOut,
  }) async {}
  @override
  Future<void> cancelRequest(String id) async {}
  @override
  Future<void> decide({
    required String id,
    required String requestId,
    required bool approve,
    required String note,
  }) async {}
}

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this._client);
  final SupabaseClient _client;

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc(fn, params: params);
    } catch (e) {
      throw AppError.from(e);
    }
  }

  Map<String, dynamic> _map(dynamic r) => Map<String, dynamic>.from(r as Map);

  @override
  Future<StaffContext> context() async =>
      StaffContext.fromJson(_map(await _rpc('get_my_staff_context')));

  @override
  Future<void> clockIn(String requestId) async =>
      _rpc('staff_clock_in', {'p_request_id': requestId});

  @override
  Future<void> clockOut(String requestId) async =>
      _rpc('staff_clock_out', {'p_request_id': requestId});

  @override
  Future<StaffReport> report(
    DateTime from,
    DateTime to, {
    String? staffId,
  }) async => StaffReport.fromJson(
    _map(
      await _rpc('get_staff_attendance', {
        'p_from': ymdOf(from),
        'p_to': ymdOf(to),
        'p_staff_id': ?staffId,
      }),
    ),
  );

  @override
  Future<List<TeamRow>> team(DateTime from, DateTime to) async {
    final j = _map(
      await _rpc('get_staff_team_summary', {
        'p_from': ymdOf(from),
        'p_to': ymdOf(to),
      }),
    );
    return [
      for (final s in (j['staff'] as List? ?? const []))
        TeamRow(
          '${(s as Map)['staff_id']}',
          (s['name'] as String?) ?? '',
          StaffTotals.fromJson(Map<String, dynamic>.from(s['totals'] as Map)),
        ),
    ];
  }

  @override
  Future<List<StaffRequest>> requests(String scope, {String? status}) async {
    final r = await _rpc('list_staff_requests', {
      'p_scope': scope,
      'p_status': ?status,
    });
    return [for (final x in (r as List)) StaffRequest.fromJson(_map(x))];
  }

  @override
  Future<void> submitRequest({
    required String requestId,
    required String kind,
    required DateTime from,
    required DateTime to,
    required String reason,
    DateTime? clockIn,
    DateTime? clockOut,
  }) async => _rpc('submit_staff_request', {
    'p_request_id': requestId,
    'p_kind': kind,
    'p_from': ymdOf(from),
    'p_to': ymdOf(to),
    'p_reason': reason,
    'p_clock_in': clockIn?.toUtc().toIso8601String(),
    'p_clock_out': clockOut?.toUtc().toIso8601String(),
  });

  @override
  Future<void> cancelRequest(String id) async =>
      _rpc('cancel_staff_request', {'p_id': id});

  @override
  Future<void> decide({
    required String id,
    required String requestId,
    required bool approve,
    required String note,
  }) async => _rpc('decide_staff_request', {
    'p_id': id,
    'p_request_id': requestId,
    'p_decision': approve ? 'approve' : 'reject',
    'p_note': note,
  });
}
