import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/locale_controller.dart';
import 'package:learn_pulse/features/attendance/attendance_scan_page.dart' show CameraProblem;
import 'package:learn_pulse/features/auth/auth_controller.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/auth/sign_in_page.dart';
import 'package:learn_pulse/features/auth/welcome_page.dart';
import 'package:learn_pulse/features/demo/demo_controllers.dart';
import 'package:learn_pulse/features/demo/demo_pages.dart';
import 'package:learn_pulse/features/demo/demo_repository.dart';
import 'package:learn_pulse/l10n/app_localizations.dart';

import 'fakes.dart';
import 'l10n_helpers.dart';

class FakeDemoRepository implements DemoRepository {
  DemoClaim claimResult = const DemoClaim(ok: true, email: 'seat@demo.example.test', password: 'Dm1-secret-password-value');
  final List<Object> signInFailures = [];
  DemoActivation activation = const DemoActivation(ok: true, courseId: 'c1');
  Object? claimError;
  final calls = <String>[];
  final nonces = <String>[];
  String status = 'provisioning';
  int starts = 0;
  DateTime now = DateTime.utc(2026, 11, 18, 10);
  DateTime? joinsCloseAt;
  DateTime? expiresAt;

  @override
  Future<DemoClaim> claim(String code, String name, String nonce) async {
    calls.add('claim');
    nonces.add(nonce);
    if (claimError != null) throw claimError!;
    return claimResult;
  }

  @override
  Future<void> signIn(String email, String password) async {
    calls.add('signIn');
    if (signInFailures.isNotEmpty) throw signInFailures.removeAt(0);
  }

  @override
  Future<DemoActivation> activate() async {
    calls.add('activate');
    return activation;
  }

  @override
  Future<void> signOutLocal() async => calls.add('signOutLocal');

  @override
  Future<List<DemoSummary>> mySessions() async => [DemoSummary(id: 'ev', status: status)];

  @override
  Future<DemoOverview> overview(String id) async => DemoOverview(
    id: id,
    status: status,
    title: 'LearnPulse Live Workshop',
    capacity: 40,
    seats: 48,
    joinsCloseAt: joinsCloseAt ?? now.add(const Duration(minutes: 20)),
    expiresAt: expiresAt ?? now.add(const Duration(hours: 2)),
    serverNow: now,
    joinWindow: const Duration(minutes: 20),
    lifetime: const Duration(hours: 2),
    counts: {'available': status == 'provisioning' ? 48 : 40, 'claimed': 3, 'active': 5},
    claims: 8,
    refused: 1,
  );

  @override
  Future<DemoJoinCode> joinCode(String id) async => const DemoJoinCode(token: 'ABCDEFGHJKLM', display: 'ABCD-EFGH-JKLM');

  @override
  Future<void> start(String id) async {
    calls.add('start');
    if (status == 'provisioning') {
      starts++;
      status = 'open';
    }
  }

  @override
  Future<void> setJoins(String id, String mode) async {
    calls.add('joins:$mode');
    status = mode;
  }

  @override
  Future<void> end(String id) async {
    calls.add('end');
    status = 'expired';
  }
}

const rate = AppError(AppErrorKind.rateLimited, 'busy', AppErrorCode.rateLimited);

DemoJoinController joinController(FakeDemoRepository repo, InMemoryPreferenceStore prefs, {List<Duration>? sleeps}) =>
    DemoJoinController(repo, prefs, sleep: (d) async => sleeps?.add(d), random: Random(1));

void main() {
  group('parseJoinCode', () {
    test('accepts a typed code, a grouped code and a QR link; rejects look-alikes', () {
      expect(parseJoinCode('abcd-efgh-jklm'), 'ABCDEFGHJKLM');
      expect(parseJoinCode('https://learnpulse-staging.pages.dev/demo?t=ABCDEFGHJKLM'), 'ABCDEFGHJKLM');
      expect(parseJoinCode('LP1.0123456789abcdef0123456789abcdef'), isNull); // an ATTENDANCE QR is never a join code
      expect(parseJoinCode('ABCDEFGHJKL'), isNull);
      expect(parseJoinCode('ABCDEFGHJKL0'), isNull); // 0/1/I/O are not in the alphabet
    });
  });

  group('DemoJoinController', () {
    test('claim -> sign in -> activate; the nonce is cleared and no credential is stored', () async {
      final repo = FakeDemoRepository();
      final prefs = InMemoryPreferenceStore();
      final c = joinController(repo, prefs);
      await c.join('ABCD-EFGH-JKLM', 'Aiman');
      expect(repo.calls, ['claim', 'signIn', 'activate']);
      expect(c.phase, DemoJoinPhase.done);
      expect(await prefs.read(DemoJoinController.nonceKey), '');
      for (final k in ['lp-demo-nonce', 'email', 'password']) {
        final v = await prefs.read(k);
        expect(v == null || v.isEmpty, isTrue, reason: k);
      }
    });

    test('invalid code or name never reaches the server', () async {
      final repo = FakeDemoRepository();
      final c = joinController(repo, InMemoryPreferenceStore());
      await c.join('short', 'Aiman');
      expect(c.message, DemoJoinMessage.badCode);
      await c.join('ABCDEFGHJKLM', '   ');
      expect(c.message, DemoJoinMessage.badName);
      await c.join('ABCDEFGHJKLM', 'a<b');
      expect(c.message, DemoJoinMessage.badName);
      expect(repo.calls, isEmpty);
    });

    for (final e in {
      'invalid': DemoJoinMessage.invalid,
      'closed': DemoJoinMessage.closed,
      'full': DemoJoinMessage.full,
      'busy': DemoJoinMessage.busy,
      'already_signed_in': DemoJoinMessage.signedIn,
      'whatever': DemoJoinMessage.failed,
    }.entries) {
      test('server reason ${e.key} -> ${e.value.name}', () async {
        final repo = FakeDemoRepository()..claimResult = DemoClaim(ok: false, reason: e.key);
        final c = joinController(repo, InMemoryPreferenceStore());
        await c.join('ABCDEFGHJKLM', 'Aiman');
        expect(c.message, e.value);
        expect(repo.calls, ['claim']);
      });
    }

    test('already-active browser/device is told credentials are not shown again', () async {
      final repo = FakeDemoRepository()..claimResult = const DemoClaim(ok: false, alreadyActive: true);
      final c = joinController(repo, InMemoryPreferenceStore());
      await c.join('ABCDEFGHJKLM', 'Aiman');
      expect(c.message, DemoJoinMessage.already);
    });

    test('HTTP 429 retries with bounded jittered back-off, then succeeds', () async {
      final repo = FakeDemoRepository()..signInFailures.addAll([rate, rate]);
      final sleeps = <Duration>[];
      final c = joinController(repo, InMemoryPreferenceStore(), sleeps: sleeps);
      await c.join('ABCDEFGHJKLM', 'Aiman');
      expect(repo.calls, ['claim', 'signIn', 'signIn', 'signIn', 'activate']);
      expect(sleeps.length, 2);
      expect(sleeps.every((d) => d >= const Duration(milliseconds: 1500) && d < const Duration(seconds: 8)), isTrue);
      expect(c.phase, DemoJoinPhase.done);
    });

    test('persistent 429 stops after the cap with an honest message (no infinite retry)', () async {
      final repo = FakeDemoRepository()..signInFailures.addAll(List.filled(20, rate));
      final c = joinController(repo, InMemoryPreferenceStore());
      await c.join('ABCDEFGHJKLM', 'Aiman');
      expect(repo.calls.where((x) => x == 'signIn').length, 8);
      expect(c.message, DemoJoinMessage.rateBusy);
      expect(c.phase, DemoJoinPhase.idle);
    });

    test('auth failure after a successful claim keeps the SAME nonce, so Join again recovers the same seat', () async {
      final repo = FakeDemoRepository()..signInFailures.add(const AppError(AppErrorKind.network, 'x', AppErrorCode.network));
      final c = joinController(repo, InMemoryPreferenceStore());
      await c.join('ABCDEFGHJKLM', 'Aiman');
      expect(c.message, DemoJoinMessage.authFailed);
      await c.join('ABCDEFGHJKLM', 'Aiman');
      expect(c.phase, DemoJoinPhase.done);
      expect(repo.nonces.length, 2);
      expect(repo.nonces[0], repo.nonces[1]);
      expect(repo.nonces[0], matches(RegExp(r'^[A-Za-z0-9_-]{22,64}$')));
    });

    test('a session that ended during sign-in signs the temporary user out and says so', () async {
      final repo = FakeDemoRepository()..activation = const DemoActivation(ok: false);
      final c = joinController(repo, InMemoryPreferenceStore());
      await c.join('ABCDEFGHJKLM', 'Aiman');
      expect(repo.calls, ['claim', 'signIn', 'activate', 'signOutLocal']);
      expect(c.message, DemoJoinMessage.expired);
    });

    test('network failure on claim is reported, double taps send one claim', () async {
      final repo = FakeDemoRepository()..claimError = const AppError(AppErrorKind.network, 'x', AppErrorCode.network);
      final c = joinController(repo, InMemoryPreferenceStore());
      await Future.wait([c.join('ABCDEFGHJKLM', 'Aiman'), c.join('ABCDEFGHJKLM', 'Aiman')]);
      expect(c.message, DemoJoinMessage.network);
      expect(repo.calls.where((x) => x == 'claim').length, 1);
    });

    test('toString of a claim never prints credentials', () {
      expect(const DemoClaim(ok: true, email: 'a@b', password: 'Dm1-xyz').toString(), isNot(contains('Dm1')));
    });
  });

  group('DemoHostController', () {
    test('Start once, repeat taps ignored, status/code follow the server', () async {
      final repo = FakeDemoRepository();
      final c = DemoHostController(repo, now: () => repo.now);
      await c.refresh();
      expect(c.overview!.status, 'provisioning');
      expect(c.code, isNull); // no join code before Start
      await Future.wait([c.start(), c.start()]);
      expect(repo.starts, 1);
      expect(c.overview!.status, 'open');
      expect(c.code!.display, 'ABCD-EFGH-JKLM');
      await c.pause();
      expect(c.overview!.status, 'paused');
      await c.resume();
      await c.endDemo();
      expect(c.overview!.status, 'expired');
      expect(c.code, isNull);
      c.dispose();
    });

    test('countdowns use the server clock, never below zero', () async {
      final repo = FakeDemoRepository()..status = 'open';
      var t = repo.now.add(const Duration(minutes: 5)); // the phone clock is 5 minutes ahead of the server
      final c = DemoHostController(repo, now: () => t);
      repo.now = DateTime.utc(2026, 11, 18, 10);
      await c.refresh();
      t = t.add(const Duration(minutes: 3));
      expect(c.joinLeft, const Duration(minutes: 17));
      t = t.add(const Duration(hours: 5));
      expect(c.joinLeft, Duration.zero);
      expect(c.lifeLeft, Duration.zero);
      c.dispose();
    });
  });

  group('screens', () {
    testWidgets('Welcome offers Try Demo -> selector -> Student join and Presenter sign-in', (tester) async {
      final auth = AuthController(FakeAuthRepository());
      addTearDown(auth.dispose);
      await pumpApp(tester, auth, fakeServices(demo: FakeDemoRepository()));
      expect(find.byType(WelcomePage), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('welcome-try-demo')));
      await tester.tap(find.byKey(const Key('welcome-try-demo')));
      await tester.pumpAndSettle();
      expect(find.byType(DemoSelectorPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('demo-student')));
      await tester.pumpAndSettle();
      expect(find.byType(DemoJoinPage), findsOneWidget);
      await tester.binding.handlePopRoute(); // Android back goes to the selector
      await tester.pumpAndSettle();
      expect(find.byType(DemoSelectorPage), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('demo-presenter')));
      await tester.tap(find.byKey(const Key('demo-presenter')));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byKey(const Key('presenter-back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('presenter-back')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('demo-regular')));
      await tester.tap(find.byKey(const Key('demo-regular')));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('join page shows a friendly error and the QR scanner fills the code (and ignores an attendance QR)', (tester) async {
      final repo = FakeDemoRepository()..claimResult = const DemoClaim(ok: false, reason: 'full');
      final auth = AuthController(FakeAuthRepository());
      addTearDown(auth.dispose);
      void Function(String)? deliver;
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrapWithL10n(
          DemoJoinPage(
            controller: auth,
            repository: repo,
            prefs: InMemoryPreferenceStore(),
            scannerBuilder: (context, onCode, onProblem) {
              deliver = onCode;
              return const SizedBox.expand(key: Key('fake-scanner'));
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('demo-scan')));
      await tester.pump();
      expect(find.byKey(const Key('fake-scanner')), findsOneWidget);
      deliver!('LP1.0123456789abcdef0123456789abcdef');
      await tester.pump();
      expect(find.byKey(const Key('fake-scanner')), findsOneWidget); // still scanning
      deliver!('https://learnpulse-staging.pages.dev/demo?t=ABCDEFGHJKLM');
      await tester.pump();
      expect(find.byKey(const Key('fake-scanner')), findsNothing);
      expect(tester.widget<TextField>(find.byKey(const Key('demo-code'))).controller!.text, 'ABCDEFGHJKLM');
      await tester.enterText(find.byKey(const Key('demo-name')), 'Aiman');
      await tester.ensureVisible(find.byKey(const Key('demo-join')));
      await tester.tap(find.byKey(const Key('demo-join')));
      await tester.pumpAndSettle();
      expect(find.text('All seats are taken.'), findsOneWidget);
    });

    testWidgets('a camera problem falls back to typing the code', (tester) async {
      final auth = AuthController(FakeAuthRepository());
      addTearDown(auth.dispose);
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrapWithL10n(
          DemoJoinPage(
            controller: auth,
            repository: FakeDemoRepository(),
            prefs: InMemoryPreferenceStore(),
            scannerBuilder: (context, onCode, onProblem) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onProblem(CameraProblem.denied));
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('demo-scan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('demo-camera-problem')), findsOneWidget);
      expect(find.byKey(const Key('demo-code')), findsOneWidget);
    });

    for (final lang in const ['en', 'ms', 'th']) {
      testWidgets('presenter console end-to-end in $lang: confirm Start, QR + code, pause/resume, confirm End', (tester) async {
        final repo = FakeDemoRepository();
        await tester.binding.setSurfaceSize(const Size(360, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(wrapWithL10n(DemoHostPage(repository: repo), locale: Locale(lang)));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('demo-start')), findsOneWidget);
        expect(find.byKey(const Key('demo-qr')), findsNothing);
        await tester.tap(find.byKey(const Key('demo-start')));
        await tester.pumpAndSettle();
        expect(repo.starts, 0); // nothing happens until the presenter confirms
        await tester.tap(find.byKey(const Key('demo-confirm-yes')));
        await tester.pumpAndSettle();
        expect(repo.starts, 1);
        expect(find.byKey(const Key('demo-qr')), findsOneWidget);
        expect(find.byKey(const Key('demo-code-text')), findsOneWidget);
        expect(find.byKey(const Key('demo-start')), findsNothing);
        await tester.ensureVisible(find.byKey(const Key('demo-pause')));
        await tester.tap(find.byKey(const Key('demo-pause')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('demo-resume')));
        await tester.tap(find.byKey(const Key('demo-resume')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('demo-end')));
        await tester.tap(find.byKey(const Key('demo-end')));
        await tester.pumpAndSettle();
        expect(repo.calls.contains('end'), isFalse); // End also needs confirmation
        await tester.tap(find.byKey(const Key('demo-confirm-yes')));
        await tester.pumpAndSettle();
        expect(repo.status, 'expired');
        expect(find.byKey(const Key('demo-qr')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a Teacher sees the Live Demo entry; a Student does not', (tester) async {
      for (final role in AppRole.values) {
        final repo = FakeAuthRepository(hasSession: true, profile: Profile(role: role, fullName: 'X'));
        final auth = AuthController(repo);
        addTearDown(auth.dispose);
        await pumpApp(tester, auth, fakeServices(demo: FakeDemoRepository()));
        expect(find.byKey(const Key('open-demo-host')), role == AppRole.teacher ? findsOneWidget : findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('Presenter Demo sign-in sends a Teacher straight to the console', (tester) async {
      final repo = FakeAuthRepository(profile: const Profile(role: AppRole.teacher, fullName: 'Demo Instructor'));
      final auth = AuthController(repo);
      addTearDown(auth.dispose);
      await pumpApp(tester, auth, fakeServices(demo: FakeDemoRepository()));
      auth.showView(SignedOutView.presenter);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'demo.teacher.2026@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'anything-long-enough');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(DemoHostPage), findsOneWidget);
    });
  });

  test('every demo string exists in all three languages', () async {
    for (final l in const ['en', 'ms', 'th']) {
      final t = await AppLocalizations.delegate.load(Locale(l));
      expect(t.demoStart.isNotEmpty && t.demoEnd.isNotEmpty && t.demoTry.isNotEmpty, isTrue);
    }
    expect((await AppLocalizations.delegate.load(const Locale('ms'))).demoStart, 'Mulakan Demo');
    expect((await AppLocalizations.delegate.load(const Locale('ms'))).demoEnd, 'Tamatkan Demo');
    expect((await AppLocalizations.delegate.load(const Locale('ms'))).demoTry, 'Cuba Demo LearnPulse');
  });
}
