import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/app_error.dart';
import 'profile.dart';

enum AuthChange { signedIn, signedOut, passwordRecovery }

class SignUpOutcome {
  const SignUpOutcome({required this.needsConfirmation});
  final bool needsConfirmation;
}

/// The only place that talks to Supabase Auth and `profiles`. Clients never write tables:
/// the role is read from the server, and the display name travels as signup metadata.
abstract class AuthRepository {
  bool get hasSession;
  Stream<AuthChange> get changes;
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> resendConfirmation(String email);
  Future<void> requestPasswordReset(String email);
  Future<void> updatePassword(String newPassword);

  /// Registered email of the signed-in user (read-only in the app).
  String? get email;

  /// Updates only `profiles.full_name` (the one client-writable column; RLS limits it to the own row).
  Future<void> updateDisplayName(String name);

  /// Returns the signed-in user's profile, or throws [AppError] (profileMissing when absent).
  Future<Profile> loadProfile();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;
  GoTrueClient get _auth => _client.auth;

  @override
  bool get hasSession => _auth.currentSession != null;

  @override
  Stream<AuthChange> get changes => _auth.onAuthStateChange
      .map(
        (s) => switch (s.event) {
          AuthChangeEvent.signedIn => AuthChange.signedIn,
          AuthChangeEvent.signedOut => AuthChange.signedOut,
          AuthChangeEvent.passwordRecovery => AuthChange.passwordRecovery,
          _ => null,
        },
      )
      .where((e) => e != null)
      .cast<AuthChange>();

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: AppConfig.authRedirect,
    );
    // A registered address answers like a new one (no account enumeration); either way the
    // user must act on an email, unless the project auto-confirms (then a session exists).
    return SignUpOutcome(needsConfirmation: response.session == null);
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> resendConfirmation(String email) => _auth.resend(
    type: OtpType.signup,
    email: email,
    emailRedirectTo: AppConfig.authRedirect,
  );

  @override
  Future<void> requestPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email, redirectTo: AppConfig.authRedirect);

  @override
  Future<void> updatePassword(String newPassword) =>
      _auth.updateUser(UserAttributes(password: newPassword));

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Future<void> updateDisplayName(String name) async {
    final uid = _auth.currentUser?.id;
    if (uid == null) {
      throw const AppError(
        AppErrorKind.unknown,
        'You are not signed in.',
        AppErrorCode.notSignedIn,
      );
    }
    final rows = await _client
        .from('profiles')
        .update({'full_name': name})
        .eq('id', uid)
        .select('id');
    if (rows.isEmpty) {
      throw const AppError(
        AppErrorKind.unknown,
        'Your name could not be saved.',
        AppErrorCode.nameNotSaved,
      );
    }
  }

  @override
  Future<Profile> loadProfile() async {
    final uid = _auth.currentUser?.id;
    if (uid == null) {
      throw const AppError(
        AppErrorKind.unknown,
        'You are not signed in.',
        AppErrorCode.notSignedIn,
      );
    }
    final row = await _client
        .from('profiles')
        .select('role, full_name, avatar_path')
        .eq('id', uid)
        .maybeSingle();
    final profile = Profile.fromRow(row);
    if (profile == null) {
      throw const AppError(
        AppErrorKind.profileMissing,
        'Your account is not ready yet. Please try again in a moment.',
        AppErrorCode.profileNotReady,
      );
    }
    return profile;
  }
}
