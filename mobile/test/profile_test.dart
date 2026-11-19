import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';
import 'package:learn_pulse/core/app_config.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/profile/profile_pages.dart';

import 'fakes.dart';
import 'ui_test_helpers.dart';

Future<(AuthController, FakeAuthRepository)> _open(
  WidgetTester tester,
  AppRole role, {
  Size size = const Size(360, 780),
  double textScale = 1,
  FakeDashboardRepository? dashboard,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final repo = FakeAuthRepository(
    hasSession: true,
    profile: Profile(role: role, fullName: 'Sam Lee'),
  );
  final c = AuthController(repo);
  addTearDown(c.dispose);
  await tester.pumpWidget(
    LearnPulseApp(
      controller: c,
      services: fakeServices(dashboard: dashboard),
    ),
  );
  await c.start();
  await tester.pumpAndSettle();
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
  return (c, repo);
}

void main() {
  test('initials', () {
    expect(initialsOf('Sam Lee'), 'SL');
    expect(initialsOf('  mei  '), 'M');
    expect(initialsOf('Ann Marie Cruz'), 'AC');
    expect(initialsOf(''), '?');
  });

  test('About version equals pubspec', () {
    final v = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(AppConfig.appVersion, v);
  });

  testWidgets('student profile: identity and real figures', (tester) async {
    await _open(tester, AppRole.student);
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.text('Sam Lee'), findsWidgets);
    expect(find.text('fake@example.test'), findsOneWidget);
    expect(find.text('Student'), findsWidgets);
    expect(find.text('Enrolled courses'), findsOneWidget);
    expect(find.text('Assignments done'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Lesson completion is not tracked'),
      200,
    );
    expect(find.text('Awaiting grading'), findsNothing); // teacher-only
  });

  testWidgets('teacher profile: own-course figures only', (tester) async {
    await _open(tester, AppRole.teacher);
    expect(find.text('Teacher'), findsWidgets);
    expect(find.text('Courses owned'), findsOneWidget);
    expect(find.text('Active students'), findsOneWidget);
    expect(find.text('Awaiting grading'), findsOneWidget);
    expect(find.text('Enrolled courses'), findsNothing);
  });

  testWidgets('failed refresh keeps the figures and says so', (tester) async {
    final d = FakeDashboardRepository();
    await _open(tester, AppRole.student, dashboard: d);
    d.error = const AppError(AppErrorKind.network, 'Offline');
    await tester.drag(
      find.byKey(const Key('profile-name')),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not refresh'), findsOneWidget);
    expect(find.text('Enrolled courses'), findsOneWidget);
  });

  testWidgets('edit display name saves, validates, never sends a role', (
    tester,
  ) async {
    final (c, repo) = await _open(tester, AppRole.student);
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    expect(find.text('Registered email'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('display-name')), '   ');
    await tester.tap(find.byKey(const Key('save-name')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name'), findsOneWidget);
    expect(repo.calls.where((x) => x.startsWith('updateName')), isEmpty);
    await tester.enterText(
      find.byKey(const Key('display-name')),
      '  Samantha Lee ',
    );
    await tester.tap(find.byKey(const Key('save-name')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('updateName:Samantha Lee'));
    expect(c.profile!.fullName, 'Samantha Lee');
    expect(c.profile!.role, AppRole.student);
    expect(find.byKey(const Key('account-notice')), findsOneWidget);
  });

  testWidgets('failed save keeps the old name and shows the error', (
    tester,
  ) async {
    final (c, repo) = await _open(tester, AppRole.teacher);
    repo.updateNameError = const AppError(
      AppErrorKind.network,
      'No connection',
    );
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('display-name')), 'New Name');
    await tester.tap(find.byKey(const Key('save-name')));
    await tester.pumpAndSettle();
    expect(c.profile!.fullName, 'Sam Lee');
    expect(find.byKey(const Key('account-error')), findsOneWidget);
  });

  testWidgets('password link uses the registered address', (tester) async {
    final (_, repo) = await _open(tester, AppRole.student);
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('change-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('change-password')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('reset:fake@example.test'));
  });

  testWidgets('sign out asks first; cancel keeps the session', (tester) async {
    final (_, repo) = await _open(tester, AppRole.student);
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sign-out')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(AccountPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('sign-out')));
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.calls, isNot(contains('signOut')));
    expect(find.text('Account & settings'), findsWidgets);
  });

  for (final role in AppRole.values) {
    for (final (size, scale) in [
      (const Size(320, 568), 2.0),
      (const Size(320, 480), 1.0),
    ]) {
      testWidgets(
        'profile and account fit ${size.width.toInt()}x${size.height.toInt()} @${scale}x ($role)',
        (tester) async {
          await _open(tester, role, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          await reveal(tester, find.byKey(const Key('open-account')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('open-account')));
          await tester.pumpAndSettle();
          await reveal(tester, find.byKey(const Key('display-name')));
          expect(find.text('Display name'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
