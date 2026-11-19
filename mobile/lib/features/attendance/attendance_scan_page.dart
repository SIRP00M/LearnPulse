import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_error.dart' show AppError;
import '../../core/formatting.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'attendance.dart';
import 'attendance_repository.dart';

/// What went wrong with the camera; every case still leaves the typed-code path (same server validation) available.
enum CameraProblem { denied, unavailable, busy }

typedef ScannerBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<String> onCode,
      ValueChanged<CameraProblem> onProblem,
    );

final _codeShape = RegExp(r'^LP1\.[0-9a-f]{32}$');

/// Localized sentence for one server answer (also used by tests).
String scanMessage(ScanOutcome o, AppLocalizations l, AppFormat f) {
  if (!o.ok) {
    return switch (o.reason) {
      'expired' => l.scanReasonExpired,
      'closed' => l.scanReasonClosed,
      'not_member' => l.scanReasonNotMember,
      'too_early' => l.scanReasonTooEarly,
      'too_late' => l.scanReasonTooLate,
      'no_checkin' => l.scanReasonNoCheckin,
      _ => l.scanReasonInvalid,
    };
  }
  if (o.isCheckOut) {
    return o.already
        ? l.scanOutAlready
        : l.scanOutOk(f.time((o.checkedOutAt ?? DateTime.now()).toLocal()));
  }
  final st = (o.status ?? AttendanceStatus.present).text(l);
  return o.already
      ? l.scanAlready(st)
      : l.scanOk(st, f.time((o.checkedInAt ?? DateTime.now()).toLocal()));
}

/// Scans (or accepts a typed) classroom code. The device never decides anything: the code goes to `scan_attendance`.
class AttendanceScanPage extends StatefulWidget {
  const AttendanceScanPage({
    super.key,
    required this.repository,
    this.scannerBuilder,
  });

  final AttendanceRepository repository;

  /// Test seam; the default is the native camera scanner.
  final ScannerBuilder? scannerBuilder;

  @override
  State<AttendanceScanPage> createState() => _AttendanceScanPageState();
}

class _AttendanceScanPageState extends State<AttendanceScanPage> {
  final _manual = TextEditingController();
  bool _busy = false;
  bool _done =
      false; // true after a successful answer: leaving the page refreshes the history
  ScanOutcome? _outcome;
  AppError? _error;
  CameraProblem? _camera;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _submit(String code) async {
    if (_busy || code.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _outcome = null;
    });
    try {
      final o = await widget.repository.scan(code);
      if (!mounted) return;
      setState(() {
        _outcome = o;
        if (o.ok) {
          _done = true;
          _manual.clear();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = AppError.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onCamera(String raw) {
    // The camera sees many things; only a well-formed attendance code is ever sent.
    if (_codeShape.hasMatch(raw.trim())) _submit(raw.trim());
  }

  Widget _cameraBox(AppLocalizations l, ColorScheme s) {
    final problem = _camera;
    if (problem != null) {
      return Container(
        key: const Key('camera-problem'),
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: s.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.no_photography_outlined),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(switch (problem) {
                CameraProblem.denied => l.scanCameraDenied,
                CameraProblem.unavailable => l.scanNoCamera,
                CameraProblem.busy => l.scanCameraBusy,
              }),
            ),
          ],
        ),
      );
    }
    final builder = widget.scannerBuilder ?? nativeScanner;
    return Semantics(
      label: l.scanCameraLabel,
      image: true,
      child: Center(
        child: ConstrainedBox(
          // A square preview, never taller than 320 so the typed-code field stays on screen.
          constraints: const BoxConstraints(maxHeight: 320),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: AspectRatio(
              aspectRatio: 1,
              child: builder(
                context,
                _onCamera,
                (p) => setState(() => _camera = p),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = AppFormat.of(context);
    final s = Theme.of(context).colorScheme;
    final o = _outcome;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_done);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.scanTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              Text(l.scanHint),
              const SizedBox(height: Space.md),
              _cameraBox(l, s),
              const SizedBox(height: Space.md),
              TextField(
                key: const Key('scan-manual'),
                controller: _manual,
                decoration: InputDecoration(
                  labelText: l.scanManualLabel,
                  border: const OutlineInputBorder(),
                ),
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.send,
                onSubmitted: _submit,
              ),
              const SizedBox(height: Space.sm),
              FilledButton.icon(
                key: const Key('scan-submit'),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner),
                label: Text(l.scanSubmit),
                onPressed: _busy ? null : () => _submit(_manual.text),
              ),
              const SizedBox(height: Space.md),
              if (_error != null)
                Text(
                  _error!.text(context),
                  key: const Key('scan-error'),
                  style: TextStyle(color: s.error),
                ),
              if (o != null)
                Semantics(
                  liveRegion: true,
                  child: Container(
                    key: const Key('scan-result'),
                    padding: const EdgeInsets.all(Space.md),
                    decoration: BoxDecoration(
                      color: o.ok
                          ? s.secondaryContainer
                          : s.errorContainer.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          o.ok
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(child: Text(scanMessage(o, l, f))),
                      ],
                    ),
                  ),
                ),
              if (o != null && o.ok)
                TextButton(
                  onPressed: () => setState(() => _outcome = null),
                  child: Text(l.scanAgain),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget nativeScanner(
  BuildContext context,
  ValueChanged<String> onCode,
  ValueChanged<CameraProblem> onProblem,
) => _NativeScanner(onCode: onCode, onProblem: onProblem);

class _NativeScanner extends StatefulWidget {
  const _NativeScanner({required this.onCode, required this.onProblem});
  final ValueChanged<String> onCode;
  final ValueChanged<CameraProblem> onProblem;

  @override
  State<_NativeScanner> createState() => _NativeScannerState();
}

class _NativeScannerState extends State<_NativeScanner> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: (c) {
      for (final b in c.barcodes) {
        final v = b.rawValue;
        if (v != null) widget.onCode(v);
      }
    },
    errorBuilder: (context, e) {
      final p = switch (e.errorCode) {
        MobileScannerErrorCode.permissionDenied => CameraProblem.denied,
        MobileScannerErrorCode.unsupported => CameraProblem.unavailable,
        _ => CameraProblem.busy,
      };
      // Tell the page after this frame; the page then swaps in a plain explanation.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onProblem(p));
      return const SizedBox.shrink();
    },
  );
}
