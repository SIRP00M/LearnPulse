import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_config.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/validators.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _jwt(Map<String, dynamic> claims) {
  String enc(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc(claims)}.sig';
}

void main() {
  group('AppConfig', () {
    test('accepts https url with an anon JWT or a publishable key', () {
      expect(
        AppConfig(
          supabaseUrl: 'https://x.supabase.co',
          publishableKey: _jwt({'role': 'anon'}),
        ).validate(),
        isNull,
      );
      expect(
        const AppConfig(
          supabaseUrl: 'https://x.supabase.co',
          publishableKey: 'sb_publishable_abc',
        ).validate(),
        isNull,
      );
    });

    test('refuses service_role JWTs and sb_secret keys', () {
      expect(
        AppConfig(
          supabaseUrl: 'https://x.supabase.co',
          publishableKey: _jwt({'role': 'service_role'}),
        ).validate(),
        contains('service_role'),
      );
      expect(
        const AppConfig(
          supabaseUrl: 'https://x.supabase.co',
          publishableKey: 'sb_secret_abc',
        ).validate(),
        contains('secret'),
      );
    });

    test(
      'rejects missing values and insecure remote urls, allows local http',
      () {
        expect(
          const AppConfig(supabaseUrl: '', publishableKey: 'k').validate(),
          isNotNull,
        );
        expect(
          const AppConfig(
            supabaseUrl: 'https://x.supabase.co',
            publishableKey: '',
          ).validate(),
          isNotNull,
        );
        expect(
          const AppConfig(
            supabaseUrl: 'http://x.supabase.co',
            publishableKey: 'k',
          ).validate(),
          isNotNull,
        );
        expect(
          const AppConfig(
            supabaseUrl: 'http://10.0.2.2:54321',
            publishableKey: 'k',
          ).validate(),
          isNull,
        );
      },
    );
  });

  group('validators', () {
    test('email', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('nope'), isNotNull);
      expect(validateEmail(' a@b.co '), isNull);
    });
    test('password policy mirrors the server', () {
      expect(validateNewPassword('Short1a'), isNotNull);
      expect(validateNewPassword('alllowercase123'), isNotNull);
      expect(validateNewPassword('ALLUPPERCASE123'), isNotNull);
      expect(validateNewPassword('NoDigitsHereAtAll'), isNotNull);
      expect(validateNewPassword('GoodPassword1'), isNull);
    });
    test('name', () {
      expect(validateFullName('  '), isNotNull);
      expect(validateFullName('A' * 121), isNotNull);
      expect(validateFullName('Ada'), isNull);
    });
  });

  group('Profile.fromRow', () {
    test('parses only known roles', () {
      expect(
        Profile.fromRow({'role': 'teacher', 'full_name': 'T'})!.role,
        AppRole.teacher,
      );
      expect(
        Profile.fromRow({'role': 'student', 'full_name': null})!.fullName,
        '',
      );
      expect(Profile.fromRow({'role': 'admin'}), isNull);
      expect(Profile.fromRow(null), isNull);
    });
  });

  group('AppError.from', () {
    test('maps auth, rate-limit and network failures', () {
      expect(
        AppError.from(
          const AuthApiException('x', code: 'invalid_credentials'),
        ).kind,
        AppErrorKind.invalidCredentials,
      );
      expect(
        AppError.from(
          const AuthApiException('x', code: 'email_not_confirmed'),
        ).kind,
        AppErrorKind.emailNotConfirmed,
      );
      expect(
        AppError.from(const AuthApiException('x', code: 'weak_password')).kind,
        AppErrorKind.weakPassword,
      );
      expect(
        AppError.from(
          const AuthApiException('x', code: 'signup_disabled'),
        ).kind,
        AppErrorKind.signupDisabled,
      );
      expect(
        AppError.from(const AuthApiException('x', statusCode: '429')).kind,
        AppErrorKind.rateLimited,
      );
      expect(
        AppError.from(const SocketException('down')).kind,
        AppErrorKind.network,
      );
      expect(
        AppError.from(TimeoutException('slow')).kind,
        AppErrorKind.timeout,
      );
      expect(AppError.from(StateError('boom')).kind, AppErrorKind.unknown);
    });

    test('never leaks raw exception text', () {
      expect(
        AppError.from(StateError('secret-token-123')).message,
        isNot(contains('secret-token-123')),
      );
    });
  });
}
