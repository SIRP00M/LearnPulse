import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../../core/locale_controller.dart';
import 'demo_repository.dart';

/// What the join form tells the person (resolved to text by the UI, so it follows the language).
enum DemoJoinMessage {
  badCode,
  badName,
  invalid,
  closed,
  full,
  busy,
  signedIn,
  already,
  authFailed,
  rateBusy,
  expired,
  network,
  failed,
}

enum DemoJoinPhase { idle, claiming, signingIn, waiting, done }

/// Extracts the 12-character join code from typed text, a pasted link or a scanned QR payload; null when it is not one.
String? parseJoinCode(String raw) {
  var s = raw.trim();
  final uri = Uri.tryParse(s);
  if (uri != null && uri.queryParameters['t'] != null) s = uri.queryParameters['t']!;
  s = s.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  return RegExp(r'^[A-HJ-NP-Z2-9]{12}$').hasMatch(s) ? s : null;
}

/// Native Student Demo join: claim → sign in → activate. Same backend protocol as the Web page:
/// the browser-bound (here: install-bound) nonce makes a retry return the SAME seat, never a new one.
class DemoJoinController extends ChangeNotifier {
  DemoJoinController(
    this._repo,
    this._prefs, {
    Future<void> Function(Duration)? sleep,
    Random? random,
    this.maxSignInAttempts = 8,
  }) : _sleep = sleep ?? Future<void>.delayed,
       _random = random ?? Random.secure();

  static const nonceKey = 'lp-demo-nonce';

  final DemoRepository _repo;
  final PreferenceStore _prefs;
  final Future<void> Function(Duration) _sleep;
  final Random _random;
  final int maxSignInAttempts;

  DemoJoinPhase phase = DemoJoinPhase.idle;
  DemoJoinMessage? message;
  bool _disposed = false;

  bool get busy =>
      phase == DemoJoinPhase.claiming ||
      phase == DemoJoinPhase.signingIn ||
      phase == DemoJoinPhase.waiting;

  Future<String> _nonce() async {
    final saved = await _prefs.read(nonceKey);
    if (saved != null && RegExp(r'^[A-Za-z0-9_-]{22,64}$').hasMatch(saved)) {
      return saved;
    }
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    final n = base64Url.encode(bytes).replaceAll('=', '');
    await _prefs.write(nonceKey, n);
    return n;
  }

  void _set(DemoJoinPhase p, [DemoJoinMessage? m]) {
    phase = p;
    message = m;
    if (!_disposed) notifyListeners();
  }

  Future<void> join(String codeInput, String name) async {
    if (busy) return; // double taps never send a second claim
    final code = parseJoinCode(codeInput);
    if (code == null) return _set(DemoJoinPhase.idle, DemoJoinMessage.badCode);
    final n = name.trim();
    if (n.isEmpty || n.length > 40 || n.contains(RegExp(r'[<>]'))) {
      return _set(DemoJoinPhase.idle, DemoJoinMessage.badName);
    }
    _set(DemoJoinPhase.claiming);
    final DemoClaim claim;
    try {
      claim = await _repo.claim(code, n, await _nonce());
    } on AppError {
      return _set(DemoJoinPhase.idle, DemoJoinMessage.network);
    }
    final email = claim.email;
    final password = claim.password;
    if (!claim.ok || email == null || password == null) {
      if (claim.alreadyActive) return _set(DemoJoinPhase.idle, DemoJoinMessage.already);
      return _set(
        DemoJoinPhase.idle,
        switch (claim.reason) {
          'invalid' => DemoJoinMessage.invalid,
          'closed' => DemoJoinMessage.closed,
          'full' => DemoJoinMessage.full,
          'busy' => DemoJoinMessage.busy,
          'bad_name' => DemoJoinMessage.badName,
          'already_signed_in' => DemoJoinMessage.signedIn,
          _ => DemoJoinMessage.failed,
        },
      );
    }
    _set(DemoJoinPhase.signingIn);
    var limited = false;
    var signedIn = false;
    for (var i = 0; i < maxSignInAttempts && !signedIn; i++) {
      try {
        await _repo.signIn(email, password);
        signedIn = true;
      } on AppError catch (e) {
        limited = e.kind == AppErrorKind.rateLimited;
        if (!limited) break;
        if (i == maxSignInAttempts - 1) break;
        _set(DemoJoinPhase.waiting);
        // Jittered, bounded back-off: a whole room signing in from one network shares one Auth rate limit.
        await _sleep(
          Duration(milliseconds: 1500 + _random.nextInt(1000 * (i + 2))),
        );
        _set(DemoJoinPhase.signingIn);
      }
    }
    if (!signedIn) {
      return _set(
        DemoJoinPhase.idle,
        limited ? DemoJoinMessage.rateBusy : DemoJoinMessage.authFailed,
      );
    }
    try {
      final a = await _repo.activate();
      if (!a.ok) {
        await _repo.signOutLocal();
        await _prefs.write(nonceKey, '');
        return _set(DemoJoinPhase.idle, DemoJoinMessage.expired);
      }
      await _prefs.write(nonceKey, ''); // the seat is activated: the claim nonce is no longer needed
    } on AppError {
      // The session is valid and AuthGate already shows the Workshop; activation is retried by the next call.
    }
    _set(DemoJoinPhase.done);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Presenter console state for the prepared event. Every action is idempotent on the server, so a retry is safe.
class DemoHostController extends ChangeNotifier {
  DemoHostController(
    this._repo, {
    DateTime Function()? now,
    this.codeRefresh = const Duration(seconds: 60),
  }) : _now = now ?? DateTime.now;

  final DemoRepository _repo;
  final DateTime Function() _now;
  final Duration codeRefresh;

  bool loading = true;
  bool busy = false;
  AppError? error;
  String? sessionId;
  DemoOverview? overview;
  DemoJoinCode? code;
  DateTime? _codeAt;
  DateTime? _fetchedAt;
  bool _disposed = false;
  Timer? _timer;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Polls the overview every 5 s while the console is open (no polling in tests: call [refresh]).
  void startPolling() {
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => unawaited(refresh()));
  }

  Future<void> refresh() async {
    try {
      var id = sessionId;
      if (id == null) {
        final all = await _repo.mySessions();
        final pick = all.where((s) => s.status != 'expired' && s.status != 'deleted');
        id = pick.isNotEmpty ? pick.first.id : (all.isNotEmpty ? all.first.id : null);
        sessionId = id;
      }
      if (id == null) {
        overview = null;
      } else {
        overview = await _repo.overview(id);
        _fetchedAt = _now();
        final o = overview!;
        if (o.live) {
          final stale = _codeAt == null || _now().difference(_codeAt!) >= codeRefresh;
          if (stale) {
            code = await _repo.joinCode(id);
            _codeAt = _now();
          }
        } else {
          code = null;
        }
      }
      error = null;
    } on Object catch (e) {
      error = AppError.from(e);
    }
    loading = false;
    _notify();
  }

  /// Server time now, estimated from the last overview so countdowns do not depend on the phone clock.
  DateTime get serverNow {
    final o = overview;
    final at = _fetchedAt;
    if (o == null || at == null) return _now();
    return o.serverNow.add(_now().difference(at));
  }

  Duration get joinLeft {
    final d = overview?.joinsCloseAt.difference(serverNow) ?? Duration.zero;
    return d.isNegative ? Duration.zero : d;
  }

  Duration get lifeLeft {
    final d = overview?.expiresAt.difference(serverNow) ?? Duration.zero;
    return d.isNegative ? Duration.zero : d;
  }

  Future<void> _act(Future<void> Function(String id) f) async {
    final id = sessionId;
    if (id == null || busy) return; // double taps are ignored
    busy = true;
    _notify();
    try {
      await f(id);
      error = null;
    } on Object catch (e) {
      error = AppError.from(e);
    }
    busy = false;
    _codeAt = null;
    await refresh();
  }

  Future<void> start() => _act(_repo.start);
  Future<void> pause() => _act((id) => _repo.setJoins(id, 'paused'));
  Future<void> resume() => _act((id) => _repo.setJoins(id, 'open'));
  Future<void> closeJoins() => _act((id) => _repo.setJoins(id, 'closed'));
  Future<void> endDemo() => _act(_repo.end);

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
