import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/locale_controller.dart' show PreferenceStore;
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../attendance/attendance_scan_page.dart'
    show CameraProblem, ScannerBuilder, nativeScanner;
import '../auth/auth_controller.dart';
import '../auth/auth_widgets.dart';
import 'demo_controllers.dart';
import 'demo_repository.dart';

String demoMessageText(DemoJoinMessage m, AppLocalizations l) => switch (m) {
  DemoJoinMessage.badCode => l.demoMsgBadCode,
  DemoJoinMessage.badName => l.demoMsgBadName,
  DemoJoinMessage.invalid => l.demoMsgInvalid,
  DemoJoinMessage.closed => l.demoMsgClosed,
  DemoJoinMessage.full => l.demoMsgFull,
  DemoJoinMessage.busy => l.demoMsgBusy,
  DemoJoinMessage.signedIn => l.demoMsgSignedIn,
  DemoJoinMessage.already => l.demoMsgAlready,
  DemoJoinMessage.authFailed => l.demoMsgAuthFailed,
  DemoJoinMessage.rateBusy => l.demoMsgRateBusy,
  DemoJoinMessage.expired => l.demoMsgExpired,
  DemoJoinMessage.network => l.demoMsgNetwork,
  DemoJoinMessage.failed => l.demoMsgFailed,
};

/// Signed-out chooser: Student Demo or Presenter Demo (neither signs anyone into a privileged account).
class DemoSelectorPage extends StatelessWidget {
  const DemoSelectorPage({super.key, required this.controller});
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (_, _) => controller.showView(SignedOutView.welcome),
      child: AuthScaffold(
        title: l.demoSelectorTitle,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('demo-back'),
              onPressed: () => controller.showView(SignedOutView.welcome),
              icon: const Icon(Icons.arrow_back),
              label: Text(l.demoBack),
            ),
          ),
          Text(l.demoSelectorSub),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            key: const Key('demo-student'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Space.minTap)),
            onPressed: () => controller.showView(SignedOutView.demoJoin),
            icon: const Icon(Icons.school_outlined),
            label: Text(l.demoStudent),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(l.demoStudentText, style: Theme.of(context).textTheme.bodySmall),
          ),
          FilledButton.tonalIcon(
            key: const Key('demo-presenter'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Space.minTap)),
            onPressed: () => controller.showView(SignedOutView.presenter),
            icon: const Icon(Icons.co_present_outlined),
            label: Text(l.demoPresenter),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(l.demoPresenterText, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(
            key: const Key('demo-regular'),
            onPressed: () => controller.showView(SignedOutView.signIn),
            child: Text(l.demoRegularSignIn),
          ),
        ],
      ),
    );
  }
}

/// Native Student Demo join. The code is typed, pasted, or scanned from the presenter's QR; the person never sees an email or password.
class DemoJoinPage extends StatefulWidget {
  const DemoJoinPage({
    super.key,
    required this.controller,
    required this.repository,
    required this.prefs,
    this.join,
    this.scannerBuilder,
  });
  final AuthController controller;
  final DemoRepository repository;
  final PreferenceStore prefs;

  /// Tests inject a controller; the app builds its own so the form state survives rebuilds of the auth gate.
  final DemoJoinController? join;
  final ScannerBuilder? scannerBuilder;

  @override
  State<DemoJoinPage> createState() => _DemoJoinPageState();
}

class _DemoJoinPageState extends State<DemoJoinPage> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  late final DemoJoinController _join =
      widget.join ?? DemoJoinController(widget.repository, widget.prefs);
  bool _scanning = false;
  bool _cameraProblem = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    if (widget.join == null) _join.dispose();
    super.dispose();
  }

  void _onCode(String raw) {
    final c = parseJoinCode(raw);
    if (c == null) return; // not a join QR (for example an attendance QR): ignore silently
    setState(() {
      _code.text = c;
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final builder = widget.scannerBuilder ?? nativeScanner;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (_, _) {
        if (!_join.busy) widget.controller.showView(SignedOutView.demoSelector);
      },
      child: ListenableBuilder(
        listenable: _join,
        builder: (context, _) {
          final j = _join;
          final m = j.message;
          return AuthScaffold(
            title: l.demoJoinTitle,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('demo-back'),
                  onPressed: j.busy ? null : () => widget.controller.showView(SignedOutView.demoSelector),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l.demoBack),
                ),
              ),
              Text(l.demoJoinSub),
              const SizedBox(height: Space.md),
              if (m != null)
                Semantics(
                  liveRegion: true,
                  child: Container(
                    key: const Key('demo-message'),
                    padding: const EdgeInsets.all(Space.md),
                    margin: const EdgeInsets.only(bottom: Space.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Text(
                      demoMessageText(m, l),
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              if (j.phase == DemoJoinPhase.waiting)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Text(l.demoWaiting, key: const Key('demo-waiting')),
                ),
              TextField(
                key: const Key('demo-code'),
                controller: _code,
                enabled: !j.busy,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: l.demoCodeLabel, helperText: l.demoCodeHint),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Space.sm),
              OutlinedButton.icon(
                key: const Key('demo-scan'),
                onPressed: j.busy ? null : () => setState(() => _scanning = !_scanning),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l.demoScan),
              ),
              if (_scanning)
                Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: _cameraProblem
                      ? Text(l.demoCameraProblem, key: const Key('demo-camera-problem'))
                      : Column(
                          children: [
                            SizedBox(
                              height: 240,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Radii.md),
                                child: builder(context, _onCode, (CameraProblem _) {
                                  if (mounted) setState(() => _cameraProblem = true);
                                }),
                              ),
                            ),
                            Text(l.demoScanHint, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                ),
              const SizedBox(height: Space.md),
              TextField(
                key: const Key('demo-name'),
                controller: _name,
                enabled: !j.busy,
                maxLength: 40,
                decoration: InputDecoration(labelText: l.demoNameLabel, helperText: l.demoNameHint),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => j.join(_code.text, _name.text),
              ),
              const SizedBox(height: Space.md),
              FilledButton(
                key: const Key('demo-join'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Space.minTap)),
                onPressed: j.busy ? null : () => j.join(_code.text, _name.text),
                child: j.busy
                    ? Text(j.phase == DemoJoinPhase.claiming ? l.demoJoining : l.demoSigningIn)
                    : Text(l.demoJoinButton),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _clock(Duration d) {
  final s = d.inSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  return h > 0
      ? '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}'
      : '$m:${sec.toString().padLeft(2, '0')}';
}

/// Native presenter console for the prepared Live Demo (same RPCs as the Web console).
class DemoHostPage extends StatefulWidget {
  const DemoHostPage({super.key, required this.repository, this.joinBaseUrl = 'https://learnpulse-staging.pages.dev'});
  final DemoRepository repository;
  final String joinBaseUrl;

  @override
  State<DemoHostPage> createState() => _DemoHostPageState();
}

class _DemoHostPageState extends State<DemoHostPage> {
  late final DemoHostController _c = DemoHostController(widget.repository);
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _c.refresh();
    _c.startPolling();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String text, String yes) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(key: const Key('demo-confirm-yes'), onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.demoHostTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            if (_c.loading) return const Center(child: CircularProgressIndicator());
            final o = _c.overview;
            if (o == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Text(_c.error?.localizedMessage(l) ?? l.demoHostNone, key: const Key('demo-host-none')),
                ),
              );
            }
            final join = o.joinWindow.inMinutes;
            final life = (o.lifetime.inMinutes / 60).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
            final status = switch (o.status) {
              'provisioning' => l.demoStatusReady,
              'open' => l.demoStatusOpen,
              'paused' => l.demoStatusPaused,
              'closed' => l.demoStatusClosed,
              _ => l.demoStatusEnded,
            };
            final code = _c.code;
            final url = code == null ? null : '${widget.joinBaseUrl}/demo?t=${code.token}';
            return ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                Text(o.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Space.sm),
                Text(status, key: const Key('demo-status'), style: Theme.of(context).textTheme.titleMedium),
                if (o.live) ...[
                  Text(l.demoJoinsLeft(_clock(_c.joinLeft)), key: const Key('demo-join-left')),
                  Text(l.demoLifeLeft(_clock(_c.lifeLeft))),
                ],
                if (_c.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: Text(_c.error!.localizedMessage(l), key: const Key('demo-host-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: Space.md),
                if (o.status == 'provisioning') ...[
                  Text(l.demoReadyText(join, life)),
                  const SizedBox(height: Space.md),
                  FilledButton(
                    key: const Key('demo-start'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Space.minTap)),
                    onPressed: _c.busy
                        ? null
                        : () async {
                            if (await _confirm(l.demoStartConfirm(join, life), l.demoStart)) {
                              await _c.start();
                            }
                          },
                    child: Text(l.demoStart),
                  ),
                ],
                if (o.live && code != null) ...[
                  Center(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(Space.md),
                      child: QrImageView(key: const Key('demo-qr'), data: url!, size: 260, semanticsLabel: code.display),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Center(child: SelectableText(code.display, key: const Key('demo-code-text'), style: Theme.of(context).textTheme.headlineMedium)),
                  Center(child: Text(l.demoProjectHint, textAlign: TextAlign.center)),
                  const SizedBox(height: Space.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: Space.sm,
                    children: [
                      OutlinedButton.icon(key: const Key('demo-copy-code'), onPressed: () => _copy(code.token), icon: const Icon(Icons.copy), label: Text(_copied ? l.demoCopied : l.demoCopyCode)),
                      OutlinedButton.icon(key: const Key('demo-copy-link'), onPressed: () => _copy(url), icon: const Icon(Icons.link), label: Text(l.demoCopyLink)),
                    ],
                  ),
                ],
                if (o.live && _c.joinLeft == Duration.zero) Text(l.demoJoinWindowOver),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    if (o.status == 'open') OutlinedButton(key: const Key('demo-pause'), onPressed: _c.busy ? null : _c.pause, child: Text(l.demoPause)),
                    if (o.status == 'paused') OutlinedButton(key: const Key('demo-resume'), onPressed: _c.busy || _c.joinLeft == Duration.zero ? null : _c.resume, child: Text(l.demoResume)),
                    if (o.live) OutlinedButton(key: const Key('demo-close-joins'), onPressed: _c.busy ? null : _c.closeJoins, child: Text(l.demoCloseJoins)),
                    if (o.live || o.status == 'closed')
                      FilledButton(
                        key: const Key('demo-end'),
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
                        onPressed: _c.busy
                            ? null
                            : () async {
                                if (await _confirm(l.demoEndConfirm, l.demoEnd)) await _c.endDemo();
                              },
                        child: Text(l.demoEnd),
                      ),
                  ],
                ),
                if (o.status == 'expired') Padding(padding: const EdgeInsets.only(top: Space.md), child: Text(l.demoEndedNotice)),
                const Divider(height: Space.xl),
                Text('${l.demoSeatsTotal}: ${o.seats} · ${l.demoSeatsAvailable}: ${o.count('available')} · ${l.demoSeatsClaimed}: ${o.count('claimed')} · ${l.demoSeatsActive}: ${o.count('active')}', key: const Key('demo-seats')),
                Text(l.demoRecent(o.claims, o.refused), style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          },
        ),
      ),
    );
  }
}
