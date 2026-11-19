import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';

/// Server answer to one seat claim. The temporary credentials exist only in memory for the sign-in that follows;
/// they are never stored, logged or shown.
class DemoClaim {
  const DemoClaim({
    required this.ok,
    this.reason,
    this.email,
    this.password,
    this.alreadyActive = false,
  });
  final bool ok;
  final String? reason;
  final String? email;
  final String? password;
  final bool alreadyActive;

  factory DemoClaim.fromJson(Map<String, dynamic> j) => DemoClaim(
    ok: j['ok'] == true,
    reason: j['reason'] as String?,
    email: j['email'] as String?,
    password: j['password'] as String?,
    alreadyActive: j['already_active'] == true,
  );

  @override
  String toString() => 'DemoClaim(ok: $ok, reason: $reason)'; // never prints credentials
}

class DemoActivation {
  const DemoActivation({required this.ok, this.courseId});
  final bool ok;
  final String? courseId;
}

class DemoSummary {
  const DemoSummary({required this.id, required this.status});
  final String id;
  final String status;
}

class DemoOverview {
  const DemoOverview({
    required this.id,
    required this.status,
    required this.title,
    required this.capacity,
    required this.seats,
    required this.joinsCloseAt,
    required this.expiresAt,
    required this.serverNow,
    required this.joinWindow,
    required this.lifetime,
    required this.counts,
    required this.claims,
    required this.refused,
  });
  final String id;
  final String status;
  final String title;
  final int capacity;
  final int seats;
  final DateTime joinsCloseAt;
  final DateTime expiresAt;
  final DateTime serverNow;
  final Duration joinWindow;
  final Duration lifetime;
  final Map<String, int> counts;
  final int claims;
  final int refused;

  int count(String state) => counts[state] ?? 0;
  bool get live => status == 'open' || status == 'paused';

  factory DemoOverview.fromJson(Map<String, dynamic> j) {
    final recent = (j['recent'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DemoOverview(
      id: j['id'] as String,
      status: j['status'] as String,
      title: (j['workshop_title'] ?? j['label'] ?? '') as String,
      capacity: (j['capacity'] as num).toInt(),
      seats: (j['seats'] as num).toInt(),
      joinsCloseAt: DateTime.parse(j['joins_close_at'] as String),
      expiresAt: DateTime.parse(j['expires_at'] as String),
      serverNow: DateTime.parse(j['server_now'] as String),
      joinWindow: Duration(seconds: (j['join_window_seconds'] as num).toInt()),
      lifetime: Duration(seconds: (j['lifetime_seconds'] as num).toInt()),
      counts: {
        for (final e in ((j['counts'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      },
      claims: (recent['claims'] as num?)?.toInt() ?? 0,
      refused: (recent['refused'] as num?)?.toInt() ?? 0,
    );
  }
}

class DemoJoinCode {
  const DemoJoinCode({required this.token, required this.display});
  final String token;
  final String display;
}

/// Everything the demo UI needs from the backend: the SAME RPCs the Web app uses. No second lifecycle exists.
abstract class DemoRepository {
  /// Anonymous: reserves one seat for [nonce] (or returns the same seat again for the same nonce).
  Future<DemoClaim> claim(String code, String name, String nonce);

  /// Signs in with the claimed temporary account. Throws [AppError] (kind rateLimited on HTTP 429).
  Future<void> signIn(String email, String password);
  Future<DemoActivation> activate();
  Future<void> signOutLocal();

  Future<List<DemoSummary>> mySessions();
  Future<DemoOverview> overview(String id);
  Future<DemoJoinCode> joinCode(String id);
  Future<void> start(String id);
  Future<void> setJoins(String id, String mode);
  Future<void> end(String id);
}

/// Where the demo is not wired (tests/previews that do not care).
class NoDemoRepository implements DemoRepository {
  const NoDemoRepository();
  static const _unavailable = AppError(
    AppErrorKind.unknown,
    'The demo is not available in this build.',
  );
  @override
  Future<DemoClaim> claim(String code, String name, String nonce) async =>
      const DemoClaim(ok: false, reason: 'failed');
  @override
  Future<void> signIn(String email, String password) async =>
      throw _unavailable;
  @override
  Future<DemoActivation> activate() async =>
      const DemoActivation(ok: false);
  @override
  Future<void> signOutLocal() async {}
  @override
  Future<List<DemoSummary>> mySessions() async => const [];
  @override
  Future<DemoOverview> overview(String id) async => throw _unavailable;
  @override
  Future<DemoJoinCode> joinCode(String id) async => throw _unavailable;
  @override
  Future<void> start(String id) async => throw _unavailable;
  @override
  Future<void> setJoins(String id, String mode) async => throw _unavailable;
  @override
  Future<void> end(String id) async => throw _unavailable;
}

class SupabaseDemoRepository implements DemoRepository {
  SupabaseDemoRepository(this._client);
  final SupabaseClient _client;

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc(fn, params: params);
    } on Object catch (e) {
      throw AppError.from(e);
    }
  }

  Map<String, dynamic> _map(dynamic v) => (v as Map).cast<String, dynamic>();

  @override
  Future<DemoClaim> claim(String code, String name, String nonce) async {
    try {
      final r = await _client.rpc(
        'demo_claim_seat',
        params: {'p_join_token': code, 'p_name': name, 'p_client_nonce': nonce},
      );
      return DemoClaim.fromJson(_map(r));
    } on Object catch (e) {
      final err = AppError.from(e);
      if (err.kind == AppErrorKind.network || err.kind == AppErrorKind.timeout) {
        throw err;
      }
      return const DemoClaim(ok: false, reason: 'failed');
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on Object catch (e) {
      throw AppError.from(e);
    }
  }

  @override
  Future<DemoActivation> activate() async {
    final r = _map(await _rpc('demo_activate_seat'));
    return DemoActivation(
      ok: r['ok'] == true,
      courseId: r['workshop_course_id'] as String?,
    );
  }

  @override
  Future<void> signOutLocal() => _client.auth.signOut(scope: SignOutScope.local);

  @override
  Future<List<DemoSummary>> mySessions() async {
    final r = await _rpc('demo_my_sessions') as List;
    return [
      for (final e in r)
        DemoSummary(
          id: _map(e)['id'] as String,
          status: _map(e)['status'] as String,
        ),
    ];
  }

  @override
  Future<DemoOverview> overview(String id) async =>
      DemoOverview.fromJson(_map(await _rpc('demo_session_overview', {'p_session': id})));

  @override
  Future<DemoJoinCode> joinCode(String id) async {
    final r = _map(await _rpc('demo_join_token', {'p_session': id}));
    return DemoJoinCode(
      token: r['token'] as String,
      display: r['display'] as String,
    );
  }

  @override
  Future<void> start(String id) => _rpc('demo_start_session', {'p_session': id});

  @override
  Future<void> setJoins(String id, String mode) =>
      _rpc('demo_set_joins', {'p_session': id, 'p_mode': mode});

  @override
  Future<void> end(String id) => _rpc('demo_end_session', {'p_session': id});
}
