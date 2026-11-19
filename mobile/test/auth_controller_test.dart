import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/auth_repository.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

const _student = Profile(role: AppRole.student, fullName: 'Sam');
const _teacher = Profile(role: AppRole.teacher, fullName: 'Tia');

void main() {
  test('no stored session -> signed out', () async {
    final c = AuthController(FakeAuthRepository());
    await c.start();
    expect(c.stage, AuthStage.signedOut);
  });

  test(
    'session restore loads the server profile (student and teacher)',
    () async {
      for (final p in [_student, _teacher]) {
        final repo = FakeAuthRepository(hasSession: true, profile: p);
        final c = AuthController(repo);
        await c.start();
        expect(c.stage, AuthStage.signedIn);
        expect(c.profile!.role, p.role);
        expect(repo.calls, ['loadProfile']);
      }
    },
  );

  test('sign-in success loads the profile exactly once', () async {
    final repo = FakeAuthRepository(profile: _teacher);
    final c = AuthController(repo);
    await c.start();
    final done = c.signIn(' t@x.co ', 'pw');
    repo.emit(AuthChange.signedIn); // the auth event races the explicit load
    await done;
    expect(c.stage, AuthStage.signedIn);
    expect(c.profile!.role, AppRole.teacher);
    expect(repo.calls.where((x) => x == 'loadProfile').length, 1);
    expect(repo.calls.first, 'signIn:t@x.co');
  });

  test('wrong password keeps the user signed out with a clear error', () async {
    final repo = FakeAuthRepository()
      ..signInError = const AuthApiException(
        'bad',
        code: 'invalid_credentials',
      );
    final c = AuthController(repo);
    await c.start();
    await c.signIn('a@b.co', 'pw');
    expect(c.stage, AuthStage.signedOut);
    expect(c.error!.kind, AppErrorKind.invalidCredentials);
    expect(c.busy, isFalse);
  });

  test(
    'unconfirmed email routes to the confirmation page, not an error',
    () async {
      final repo = FakeAuthRepository()
        ..signInError = const AuthApiException(
          'x',
          code: 'email_not_confirmed',
        );
      final c = AuthController(repo);
      await c.start();
      await c.signIn('a@b.co', 'pw');
      expect(c.stage, AuthStage.awaitingConfirmation);
      expect(c.pendingEmail, 'a@b.co');
      expect(c.error, isNull);
    },
  );

  test(
    'network failure during sign-in surfaces a retryable network error',
    () async {
      final repo = FakeAuthRepository()
        ..signInError = const SocketException('offline');
      final c = AuthController(repo);
      await c.start();
      await c.signIn('a@b.co', 'pw');
      expect(c.error!.kind, AppErrorKind.network);
      expect(c.stage, AuthStage.signedOut);
    },
  );

  test(
    'sign-up requires confirmation; no profile or role is assumed',
    () async {
      final repo = FakeAuthRepository();
      final c = AuthController(repo);
      await c.start();
      await c.signUp('n@x.co', 'GoodPassword1', 'New Person');
      expect(c.stage, AuthStage.awaitingConfirmation);
      expect(c.profile, isNull);
      expect(repo.calls, ['signUp:n@x.co:New Person']);
    },
  );

  test('resend honours the cooldown and reports success', () async {
    var now = DateTime(2030);
    final repo = FakeAuthRepository();
    final c = AuthController(repo, now: () => now);
    await c.start();
    await c.signUp('n@x.co', 'GoodPassword1', 'N');
    expect(c.resendRemaining, const Duration(seconds: 60));
    await c.resendConfirmation(); // too early: ignored
    expect(repo.calls.where((x) => x.startsWith('resend')), isEmpty);
    now = now.add(const Duration(seconds: 61));
    await c.resendConfirmation();
    expect(repo.calls.where((x) => x.startsWith('resend')).length, 1);
    expect(c.notice, contains('n@x.co'));
    expect(c.resendRemaining, greaterThan(Duration.zero));
  });

  test('rapid double submit runs only once', () async {
    final repo = FakeAuthRepository(profile: _student)
      ..signInGate = Completer<void>();
    final c = AuthController(repo);
    await c.start();
    final a = c.signIn('a@b.co', 'pw');
    final b = c.signIn('a@b.co', 'pw');
    expect(c.busy, isTrue);
    repo.signInGate!.complete();
    await Future.wait([a, b]);
    expect(repo.calls.where((x) => x.startsWith('signIn')).length, 1);
  });

  test('profile load failure is retryable', () async {
    final repo = FakeAuthRepository(hasSession: true, profile: _student)
      ..profileFailures.add(const SocketException('offline'));
    final c = AuthController(repo);
    await c.start();
    expect(c.stage, AuthStage.profileError);
    expect(c.error!.kind, AppErrorKind.network);
    await c.retryProfile();
    expect(c.stage, AuthStage.signedIn);
    expect(c.profile!.role, AppRole.student);
  });

  test('missing profile row is an error state, never a default role', () async {
    final repo = FakeAuthRepository(hasSession: true)
      ..profileFailures.add(
        const AppError(AppErrorKind.profileMissing, 'not ready'),
      );
    final c = AuthController(repo);
    await c.start();
    expect(c.stage, AuthStage.profileError);
    expect(c.profile, isNull);
  });

  test('email-confirmation deep link (auth event) signs the user in', () async {
    final repo = FakeAuthRepository(profile: _teacher);
    final c = AuthController(repo);
    await c.start();
    await c.signUp('t@x.co', 'GoodPassword1', 'T');
    expect(c.stage, AuthStage.awaitingConfirmation);
    repo.emit(AuthChange.signedIn);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.stage, AuthStage.signedIn);
    expect(c.profile!.role, AppRole.teacher);
  });

  test('sign out clears the profile and returns to sign-in', () async {
    final repo = FakeAuthRepository(hasSession: true, profile: _teacher);
    final c = AuthController(repo);
    await c.start();
    await c.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(c.stage, AuthStage.signedOut);
    expect(c.profile, isNull);
  });

  test(
    'password recovery link opens the set-password stage, then signs in',
    () async {
      final repo = FakeAuthRepository(profile: _student);
      final c = AuthController(repo);
      await c.start();
      repo.emit(AuthChange.passwordRecovery);
      await Future<void>.delayed(Duration.zero);
      expect(c.stage, AuthStage.recovery);
      await c.setNewPassword('GoodPassword1');
      expect(c.stage, AuthStage.signedIn);
      expect(repo.calls, contains('updatePassword'));
    },
  );

  test('password reset gives the same notice for any address', () async {
    final repo = FakeAuthRepository();
    final c = AuthController(repo);
    await c.start();
    await c.requestPasswordReset('whoever@x.co');
    expect(c.notice, contains('If an account exists'));
    expect(c.view, SignedOutView.signIn);
  });
}
