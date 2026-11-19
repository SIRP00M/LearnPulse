import 'sdk_fonts.dart';
import 'l10n_helpers.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/states.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/auth_repository.dart';
import 'package:learn_pulse/features/auth/profile.dart';

import 'fakes.dart';

// Screenshots of the loading / empty / error / session states:
//   flutter test test/states_capture_test.dart --update-goldens --dart-define=CAPTURE_ADAPTIVE=true
const _capture = bool.fromEnvironment('CAPTURE_ADAPTIVE');
const _surface = Key('state-capture');

Future<void> _shot(
  WidgetTester tester,
  String name,
  Widget child, {
  Size size = const Size(393, 640),
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: l10nDelegates,
      supportedLocales: l10nLocales,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brightness, reduceMotion: true),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: RepaintBoundary(
        key: _surface,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull, reason: name);
  await expectLater(
    find.byKey(_surface),
    matchesGoldenFile(
      '../../docs/codex_ui_screenshots/claude-states/$name.png',
    ),
  );
}

void main() {
  WidgetsApp.debugAllowBannerOverride = false;
  setUpAll(() async {
    final fonts = sdkFonts();
    final roboto = FontLoader('Roboto');
    for (final w in ['regular', 'medium', 'bold']) {
      roboto.addFont(
        Future.value(
          ByteData.sublistView(File('$fonts/roboto-$w.ttf').readAsBytesSync()),
        ),
      );
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('$fonts/materialicons-regular.otf').readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
  });

  if (!_capture) {
    test('captures run only with CAPTURE_ADAPTIVE', () {}, skip: true);
    return;
  }

  testWidgets('error and recovery states', (tester) async {
    for (final e in {
      'error-offline': const AppError(
        AppErrorKind.network,
        'No connection to the server. Check your network and try again.',
      ),
      'error-timeout': const AppError(
        AppErrorKind.timeout,
        'The server took too long to answer. Try again in a moment.',
      ),
      'error-denied': const AppError(AppErrorKind.forbidden, 'x'),
      'error-not-found': const AppError(AppErrorKind.notFound, 'x'),
      'error-unexpected': const AppError(
        AppErrorKind.unknown,
        'Something went wrong. Please try again.',
      ),
    }.entries) {
      await _shot(
        tester,
        e.key,
        ErrorPanel(error: e.value, onRetry: () {}, onBack: () {}),
      );
    }
    await _shot(
      tester,
      'error-session-expired',
      SessionScope(
        onSignInAgain: () {},
        child: ErrorPanel(
          error: const AppError(AppErrorKind.invalidCredentials, 'x'),
          onRetry: () {},
        ),
      ),
    );
    await _shot(
      tester,
      'error-offline-320-x3',
      ErrorPanel(
        error: const AppError(
          AppErrorKind.network,
          'No connection to the server. Check your network and try again.',
        ),
        onRetry: () {},
        onBack: () {},
      ),
      size: const Size(320, 900),
      scale: 3,
    );
    await _shot(
      tester,
      'error-offline-dark',
      ErrorPanel(
        error: const AppError(AppErrorKind.network, 'No connection.'),
        onRetry: () {},
      ),
      brightness: Brightness.dark,
    );
  });

  testWidgets('empty and loading states', (tester) async {
    await _shot(
      tester,
      'empty-lessons',
      const EmptyPanel(
        full: true,
        icon: Icons.menu_book_outlined,
        title: 'No lessons yet',
        message: 'Your teacher has not published any lessons for this course.',
      ),
    );
    await _shot(
      tester,
      'empty-assignments-teacher',
      const EmptyPanel(
        full: true,
        icon: Icons.assignment_outlined,
        title: 'No assignments yet',
        message: 'Create a draft, then publish it for students.',
      ),
    );
    await _shot(tester, 'loading-page', const SkeletonPage());
    await _shot(
      tester,
      'loading-page-dark',
      const SkeletonPage(),
      brightness: Brightness.dark,
    );
  });

  testWidgets('session expired page', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    final repo = FakeAuthRepository(
      hasSession: true,
      profile: const Profile(role: AppRole.student, fullName: 'Sam'),
    );
    final c = AuthController(repo);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _surface,
        child: LearnPulseApp(controller: c, services: fakeServices()),
      ),
    );
    await c.start();
    await tester.pumpAndSettle();
    repo.emit(AuthChange.signedOut);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_surface),
      matchesGoldenFile(
        '../../docs/codex_ui_screenshots/claude-states/session-expired-page.png',
      ),
    );
  });
}
