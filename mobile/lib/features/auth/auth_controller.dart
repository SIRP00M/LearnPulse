import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../../l10n/app_localizations.dart';
import 'auth_repository.dart';
import 'profile.dart';

enum AuthStage {
  starting,
  signedOut,
  awaitingConfirmation,
  loadingProfile,
  signedIn,
  profileError,
  recovery,
}

/// A one-line success message; resolved to text at render time so it follows the language.
enum AuthNotice {
  confirmationSent,
  resetSent,
  passwordUpdated,
  nameSaved,
  passwordLinkSent,
}

/// What the signed-out area shows.
enum SignedOutView {
  welcome,
  signIn,
  signUp,
  forgotPassword,
  demoSelector,
  demoJoin,
  presenter,
}

/// Single source of truth for authentication state. The role comes only from the server
/// (`AuthRepository.loadProfile`), never from tokens or user metadata.
class AuthController extends ChangeNotifier {
  AuthController(
    this._repo, {
    DateTime Function()? now,
    this.resendCooldown = const Duration(seconds: 60),
  }) : _now = now ?? DateTime.now;

  final AuthRepository _repo;
  final DateTime Function() _now;
  final Duration resendCooldown;
  StreamSubscription<AuthChange>? _sub;
  bool _disposed = false;
  bool _loadingProfile = false;

  AuthStage stage = AuthStage.starting;
  SignedOutView view = SignedOutView.welcome;
  bool canReturnToWelcome = false;

  /// Set by the Presenter Demo sign-in so a Teacher lands on the Live Demo console after signing in.
  bool presenterIntent = false;
  Profile? profile;
  String? pendingEmail;
  AppError? error;
  AuthNotice? noticeKind;
  String? _noticeEmail;

  /// English text of the current notice (logs and tests); UI uses [noticeText].
  String? get notice => switch (noticeKind) {
    null => null,
    AuthNotice.confirmationSent => 'Confirmation email sent to $_noticeEmail.',
    AuthNotice.resetSent =>
      'If an account exists for that address, a reset link is on its way.',
    AuthNotice.passwordUpdated => 'Password updated.',
    AuthNotice.nameSaved => 'Display name saved.',
    AuthNotice.passwordLinkSent =>
      'A password reset link is on its way to $_noticeEmail.',
  };

  String? noticeText(AppLocalizations l) => switch (noticeKind) {
    null => null,
    AuthNotice.confirmationSent => l.noticeConfirmationSent(_noticeEmail ?? ''),
    AuthNotice.resetSent => l.noticeResetSent,
    AuthNotice.passwordUpdated => l.noticePasswordUpdated,
    AuthNotice.nameSaved => l.noticeNameSaved,
    AuthNotice.passwordLinkSent => l.noticePasswordLinkSent(_noticeEmail ?? ''),
  };

  void _notice(AuthNotice k, [String? email]) {
    noticeKind = k;
    _noticeEmail = email;
  }

  bool busy = false;

  /// True when the server ended a signed-in session (not a sign-out the user chose); UI only.
  bool sessionExpired = false;
  bool _signingOut = false;
  DateTime? _resendAt;

  Duration get resendRemaining {
    final at = _resendAt;
    if (at == null) return Duration.zero;
    final left = at.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> start() async {
    _sub ??= _repo.changes.listen(_onChange);
    if (_repo.hasSession) {
      await _loadProfile();
    } else {
      _set(AuthStage.signedOut);
    }
  }

  void _onChange(AuthChange change) {
    switch (change) {
      case AuthChange.signedIn:
        // Fired by sign-in, session restore and the email-confirmation deep link.
        if (stage != AuthStage.signedIn) unawaited(_loadProfile());
      case AuthChange.signedOut:
        if (stage == AuthStage.signedIn && !_signingOut) sessionExpired = true;
        profile = null;
        pendingEmail = null;
        view = SignedOutView.signIn;
        canReturnToWelcome = false;
        _set(AuthStage.signedOut);
      case AuthChange.passwordRecovery:
        _set(AuthStage.recovery);
    }
  }

  void showView(SignedOutView v) {
    if (view == SignedOutView.welcome) {
      canReturnToWelcome = v == SignedOutView.signIn;
    }
    if (v == SignedOutView.welcome) canReturnToWelcome = false;
    view = v;
    sessionExpired = false;
    error = null;
    noticeKind = null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) => _run(() async {
    sessionExpired = false;
    try {
      await _repo.signIn(email: email.trim(), password: password);
    } on Object catch (e) {
      final err = AppError.from(e);
      if (err.kind == AppErrorKind.emailNotConfirmed) {
        pendingEmail = email.trim();
        _set(AuthStage.awaitingConfirmation);
        return;
      }
      rethrow;
    }
    await _loadProfile();
  });

  Future<void> signUp(String email, String password, String fullName) =>
      _run(() async {
        final outcome = await _repo.signUp(
          email: email.trim(),
          password: password,
          fullName: fullName.trim(),
        );
        if (outcome.needsConfirmation) {
          pendingEmail = email.trim();
          _resendAt = _now().add(resendCooldown);
          _set(AuthStage.awaitingConfirmation);
        } else {
          await _loadProfile();
        }
      });

  Future<void> resendConfirmation() => _run(() async {
    final email = pendingEmail;
    if (email == null || resendRemaining > Duration.zero) return;
    await _repo.resendConfirmation(email);
    _resendAt = _now().add(resendCooldown);
    _notice(AuthNotice.confirmationSent, email);
  });

  Future<void> requestPasswordReset(String email) => _run(() async {
    await _repo.requestPasswordReset(email.trim());
    // Same message whether or not the address is registered.
    _notice(AuthNotice.resetSent);
    view = SignedOutView.signIn;
    canReturnToWelcome = false;
  });

  Future<void> setNewPassword(String password) => _run(() async {
    await _repo.updatePassword(password);
    _notice(AuthNotice.passwordUpdated);
    await _loadProfile();
  });

  String? get email => _repo.email;

  /// The photo pointer changed on the server (upload or removal); mirror it so every avatar updates at once.
  void applyAvatarPath(String? path) {
    final p = profile;
    if (p == null) return;
    profile = Profile(role: p.role, fullName: p.fullName, avatarPath: path);
    notifyListeners();
  }

  /// Saves the display name; the role never changes here.
  Future<void> updateDisplayName(String name) => _run(() async {
    final p = profile;
    if (p == null) return;
    final v = name.trim();
    await _repo.updateDisplayName(v);
    profile = Profile(role: p.role, fullName: v, avatarPath: p.avatarPath);
    _notice(AuthNotice.nameSaved);
  });

  /// Emails a reset link to the registered address (same flow as "Forgot password").
  Future<void> sendPasswordChangeLink() => _run(() async {
    final e = _repo.email;
    if (e == null) return;
    await _repo.requestPasswordReset(e);
    _notice(AuthNotice.passwordLinkSent, e);
  });

  Future<void> signOut() => _run(() async {
    _signingOut = true;
    try {
      await _repo.signOut();
    } finally {
      _signingOut = false;
    }
    profile = null;
    pendingEmail = null;
    view = SignedOutView.signIn;
    canReturnToWelcome = false;
    _set(AuthStage.signedOut);
  });

  void backToSignIn() {
    sessionExpired = false;
    pendingEmail = null;
    view = SignedOutView.signIn;
    canReturnToWelcome = false;
    error = null;
    noticeKind = null;
    _set(AuthStage.signedOut);
  }

  Future<void> retryProfile() => _run(_loadProfile);

  Future<void> _loadProfile() async {
    if (_loadingProfile) {
      return; // sign-in and the auth event can both ask; load once
    }
    _loadingProfile = true;
    stage = AuthStage.loadingProfile;
    error = null;
    notifyListeners();
    try {
      profile = await _repo.loadProfile();
      _set(AuthStage.signedIn);
    } on Object catch (e) {
      profile = null;
      error = AppError.from(e);
      _set(AuthStage.profileError);
    } finally {
      _loadingProfile = false;
    }
  }

  /// Serialises user actions (double taps are ignored) and turns failures into [error].
  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    noticeKind = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (e) {
      error = AppError.from(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _set(AuthStage s) {
    stage = s;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
