import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/core/formatting.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_scan_page.dart';
import 'package:learn_pulse/features/staff/staff.dart';
import 'package:learn_pulse/features/staff/staff_page.dart';
import 'package:learn_pulse/l10n/app_localizations.dart';

import 'fakes_attendance.dart';
import 'fakes_staff.dart';
import 'l10n_helpers.dart';

const _code = 'LP1.0123456789abcdef0123456789abcdef';

/// Captures the callbacks the page hands to the camera so a test can "see" a code or a camera failure.
class _Cam {
  ValueChanged<String>? onCode;
  ValueChanged<CameraProblem>? onProblem;
  Widget build(
    BuildContext c,
    ValueChanged<String> code,
    ValueChanged<CameraProblem> problem,
  ) {
    onCode = code;
    onProblem = problem;
    return const ColoredBox(color: Colors.black, key: Key('fake-camera'));
  }
}

Future<void> _pumpScan(
  WidgetTester t,
  FakeAttendanceRepository repo,
  _Cam cam, {
  Locale locale = const Locale('en'),
}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    wrapWithL10n(
      Builder(
        builder: (c) => Center(
          child: FilledButton(
            key: const Key('open'),
            onPressed: () => Navigator.of(c).push(
              MaterialPageRoute<bool>(
                builder: (_) => AttendanceScanPage(
                  repository: repo,
                  scannerBuilder: cam.build,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      locale: locale,
    ),
  );
  await t.tap(find.byKey(const Key('open')));
  await t.pumpAndSettle();
}

void main() {
  group('models keep history honest', () {
    test(
      'historical rows have no invented times; QR rows carry the server instants',
      () {
        final old = AttendanceRecord.fromRow({
          'session_id': 's',
          'student_id': 'u',
          'status': 'present',
          'note': '',
          'version': 1,
        })!;
        expect(old.checkedInAt, isNull);
        expect(old.checkedOutAt, isNull);
        expect(old.source, isNull);
        final qr = AttendanceRecord.fromRow({
          'session_id': 's',
          'student_id': 'u',
          'status': 'late',
          'note': '',
          'version': 1,
          'checked_in_at': '2026-11-17T02:10:00+00:00',
          'checked_out_at': '2026-11-17T03:00:00+00:00',
          'source': 'qr',
        })!;
        expect(qr.checkedInAt, DateTime.utc(2026, 11, 17, 2, 10));
        expect(qr.checkedOutAt, DateTime.utc(2026, 11, 17, 3));
        expect(qr.source, 'qr');
        expect(qr.status, AttendanceStatus.late);
      },
    );

    test('ScanOutcome parses success, replay and refusal', () {
      final ok = ScanOutcome.fromJson({
        'ok': true,
        'action': 'in',
        'already': false,
        'status': 'present',
        'checked_in_at': '2026-11-17T02:00:00Z',
      });
      expect(
        ok.ok && !ok.already && ok.status == AttendanceStatus.present,
        isTrue,
      );
      final no = ScanOutcome.fromJson({'ok': false, 'reason': 'expired'});
      expect(no.ok, isFalse);
      expect(no.reason, 'expired');
      expect(
        ScanOutcome.fromJson({'ok': true, 'action': 'out'}).isCheckOut,
        isTrue,
      );
    });
  });

  group('scan messages exist and differ in every language', () {
    final outcomes = <ScanOutcome>[
      for (final r in [
        'invalid',
        'expired',
        'closed',
        'not_member',
        'too_early',
        'too_late',
        'no_checkin',
      ])
        ScanOutcome(ok: false, reason: r),
      ScanOutcome(
        ok: true,
        action: 'in',
        status: AttendanceStatus.late,
        checkedInAt: DateTime.utc(2026, 11, 17, 2),
      ),
      const ScanOutcome(
        ok: true,
        action: 'in',
        already: true,
        status: AttendanceStatus.present,
      ),
      ScanOutcome(
        ok: true,
        action: 'out',
        checkedOutAt: DateTime.utc(2026, 11, 17, 3),
      ),
      const ScanOutcome(ok: true, action: 'out', already: true),
    ];
    test(
      'every outcome yields a non-empty sentence per locale, with no leftover placeholder',
      () {
        final seen = <String, Set<String>>{};
        for (final loc in ['en', 'ms', 'th']) {
          final l = lookupAppLocalizations(Locale(loc));
          final f = AppFormat.forLocale(Locale(loc));
          for (final o in outcomes) {
            final m = scanMessage(o, l, f);
            expect(m.trim(), isNotEmpty);
            expect(m.contains('{'), isFalse, reason: '$loc: $m');
            (seen[o.reason ?? o.action ?? ''] ??= {}).add(m);
          }
        }
        // English, Malay and Thai are all different for the refusal reasons
        for (final r in [
          'invalid',
          'expired',
          'closed',
          'not_member',
          'too_early',
          'too_late',
          'no_checkin',
        ]) {
          expect(seen[r]!.length, 3, reason: r);
        }
      },
    );
  });

  group('AttendanceScanPage', () {
    testWidgets(
      'a well-formed camera code is sent once; garbage is never sent',
      (t) async {
        final repo = FakeAttendanceRepository();
        final cam = _Cam();
        await _pumpScan(t, repo, cam);
        cam.onCode!('https://example.com/not-ours');
        cam.onCode!('hello');
        await t.pump();
        expect(repo.scans, isEmpty);
        cam.onCode!(_code);
        await t.pumpAndSettle();
        expect(repo.scans, [_code]);
        expect(find.byKey(const Key('scan-result')), findsOneWidget);
        expect(find.textContaining('Checked in as Present'), findsOneWidget);
      },
    );

    testWidgets(
      'the typed-code path uses the same server call and shows refusals',
      (t) async {
        final repo = FakeAttendanceRepository()
          ..scanOutcome = const ScanOutcome(ok: false, reason: 'expired');
        await _pumpScan(t, repo, _Cam());
        await t.enterText(find.byKey(const Key('scan-manual')), _code);
        await t.tap(find.byKey(const Key('scan-submit')));
        await t.pumpAndSettle();
        expect(repo.scans, [_code]);
        expect(
          find.text('That code has expired. Ask for the current code.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('a replay is explained, not treated as an error', (t) async {
      final repo = FakeAttendanceRepository()
        ..scanOutcome = const ScanOutcome(
          ok: true,
          action: 'in',
          already: true,
          status: AttendanceStatus.late,
        );
      await _pumpScan(t, repo, _Cam());
      await t.enterText(find.byKey(const Key('scan-manual')), _code);
      await t.tap(find.byKey(const Key('scan-submit')));
      await t.pumpAndSettle();
      expect(find.text('You were already recorded as Late.'), findsOneWidget);
    });

    testWidgets(
      'a server/network failure shows a localized error and keeps the page usable',
      (t) async {
        final repo = FakeAttendanceRepository()
          ..error = const AppError(
            AppErrorKind.network,
            'offline',
            AppErrorCode.network,
          );
        await _pumpScan(t, repo, _Cam());
        await t.enterText(find.byKey(const Key('scan-manual')), _code);
        await t.tap(find.byKey(const Key('scan-submit')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('scan-error')), findsOneWidget);
        await t.tap(find.byKey(const Key('scan-submit')));
        await t.pumpAndSettle();
        expect(
          find.byKey(const Key('scan-result')),
          findsOneWidget,
        ); // second try succeeds
      },
    );

    for (final (problem, text) in [
      (CameraProblem.denied, 'Camera access is off'),
      (CameraProblem.unavailable, 'no usable camera'),
      (CameraProblem.busy, 'could not start'),
    ]) {
      testWidgets(
        'camera $problem: plain explanation, typed code still works',
        (t) async {
          final repo = FakeAttendanceRepository();
          final cam = _Cam();
          await _pumpScan(t, repo, cam);
          cam.onProblem!(problem);
          await t.pumpAndSettle();
          expect(find.byKey(const Key('camera-problem')), findsOneWidget);
          expect(find.textContaining(text), findsOneWidget);
          await t.enterText(find.byKey(const Key('scan-manual')), _code);
          await t.tap(find.byKey(const Key('scan-submit')));
          await t.pumpAndSettle();
          expect(repo.scans, [_code]);
        },
      );
    }

    testWidgets(
      'leaving after success reports a change so the history reloads',
      (t) async {
        final repo = FakeAttendanceRepository();
        final result = ValueNotifier<bool?>(null);
        await t.pumpWidget(
          wrapWithL10n(
            Builder(
              builder: (c) => FilledButton(
                key: const Key('open'),
                onPressed: () async =>
                    result.value = await Navigator.of(c).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => AttendanceScanPage(
                          repository: repo,
                          scannerBuilder: _Cam().build,
                        ),
                      ),
                    ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await t.tap(find.byKey(const Key('open')));
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const Key('scan-manual')), _code);
        await t.tap(find.byKey(const Key('scan-submit')));
        await t.pumpAndSettle();
        await t.pageBack();
        await t.pumpAndSettle();
        expect(result.value, isTrue);
      },
    );
  });

  group('StaffAttendancePage', () {
    Future<void> pump(
      WidgetTester t,
      FakeStaffRepository repo, {
      Locale locale = const Locale('en'),
    }) async {
      var n = 0;
      t.view.physicalSize = const Size(400, 2600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        wrapWithL10n(
          StaffAttendancePage(
            key: UniqueKey(),
            repository: repo,
            newId: () => 'id-${++n}',
          ),
          locale: locale,
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('clock in then out; each action carries a request id', (
      t,
    ) async {
      final repo = FakeStaffRepository();
      await pump(t, repo);
      expect(find.text('You are not clocked in.'), findsOneWidget);
      expect(find.textContaining('Office'), findsOneWidget);
      await t.tap(find.byKey(const Key('staff-clock-in')));
      await t.pumpAndSettle();
      expect(repo.calls, ['in:id-1']);
      expect(find.textContaining('Clocked in since'), findsOneWidget);
      expect(find.byKey(const Key('staff-clock-out')), findsOneWidget);
      await t.tap(find.byKey(const Key('staff-clock-out')));
      await t.pumpAndSettle();
      expect(repo.calls.last, startsWith('out:'));
      expect(find.text('You are not clocked in.'), findsOneWidget);
    });

    testWidgets(
      'a failed clock-in retries with the SAME request id (server replays instead of repeating)',
      (t) async {
        final repo = FakeStaffRepository()
          ..failNext = const AppError(
            AppErrorKind.network,
            'offline',
            AppErrorCode.network,
          );
        await pump(t, repo);
        await t.tap(find.byKey(const Key('staff-clock-in')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('staff-error')), findsOneWidget);
        await t.tap(find.byKey(const Key('staff-clock-in')));
        await t.pumpAndSettle();
        expect(repo.calls, ['in:id-1', 'in:id-1']);
        expect(find.byKey(const Key('staff-error')), findsNothing);
      },
    );

    testWidgets(
      'leave request: validation first, then one submit; own requests have no approve button',
      (t) async {
        final repo = FakeStaffRepository();
        await pump(t, repo);
        await t.tap(find.byKey(const Key('staff-new-leave')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('req-submit')));
        await t.pumpAndSettle();
        expect(
          find.text('Give a reason of at least 3 characters.'),
          findsOneWidget,
        );
        expect(repo.calls, isEmpty);
        await t.enterText(find.byKey(const Key('req-reason')), 'Family event');
        await t.tap(find.byKey(const Key('req-submit')));
        await t.pumpAndSettle();
        expect(repo.calls.single, startsWith('submit:'));
        expect(repo.calls.single, endsWith(':leave:Family event'));
        expect(find.text('Pending'), findsOneWidget);
        expect(
          find.textContaining('Approve'),
          findsNothing,
        ); // staff can never decide their own request
        expect(find.byKey(const Key('cancel-r1')), findsOneWidget);
        await t.tap(find.byKey(const Key('cancel-r1')));
        await t.pumpAndSettle();
        expect(find.text('Cancelled'), findsOneWidget);
      },
    );

    testWidgets('a correction needs a time before it can be sent', (t) async {
      final repo = FakeStaffRepository();
      await pump(t, repo);
      await t.tap(find.byKey(const Key('staff-new-correction')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const Key('req-reason')),
        'Forgot to clock out',
      );
      await t.tap(find.byKey(const Key('req-submit')));
      await t.pumpAndSettle();
      expect(
        find.text('Give the correct clock-in or clock-out time.'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
    });

    testWidgets(
      'supervisor tools exist only for an assigned supervisor and can decide',
      (t) async {
        final staffOnly = FakeStaffRepository();
        await pump(t, staffOnly);
        expect(find.byIcon(Icons.supervisor_account_outlined), findsNothing);

        final repo = FakeStaffRepository(
          context: const StaffContext(
            isStaff: true,
            isSupervisor: true,
            hasSupervisor: false,
          ),
          toDecide: [
            const StaffRequest(
              id: 'q1',
              staffName: 'Staff X',
              kind: 'leave',
              from: '2026-11-18',
              to: '2026-11-19',
              reason: 'Conference',
              status: 'pending',
            ),
          ],
          team: [
            const TeamRow('x', 'Staff X', StaffTotals(onTime: 3, late: 1)),
          ],
        );
        await pump(t, repo);
        expect(find.byIcon(Icons.supervisor_account_outlined), findsOneWidget);
        expect(
          find.textContaining('Staff X: on time 3, late 1'),
          findsOneWidget,
        );
        await t.tap(find.byKey(const Key('approve-q1')));
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const Key('decision-note')), 'Enjoy');
        await t.tap(find.byKey(const Key('decision-confirm')));
        await t.pumpAndSettle();
        expect(repo.calls.single, 'decide:q1:approve:Enjoy');
      },
    );

    testWidgets('a non-staff account sees an explanation, not clock buttons', (
      t,
    ) async {
      final repo = FakeStaffRepository(
        context: const StaffContext(isStaff: false),
      );
      await pump(t, repo);
      expect(find.byKey(const Key('staff-clock-in')), findsNothing);
    });

    for (final loc in ['ms', 'th']) {
      testWidgets('renders in $loc without untranslated placeholders', (
        t,
      ) async {
        final repo = FakeStaffRepository();
        await pump(t, repo, locale: Locale(loc));
        expect(find.byKey(const Key('staff-status')), findsOneWidget);
        expect(find.textContaining('{'), findsNothing);
        expect(find.text('You are not clocked in.'), findsNothing);
      });
    }
  });
}
