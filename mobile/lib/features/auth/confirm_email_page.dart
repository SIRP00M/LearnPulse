import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// Shown after sign-up (or an unconfirmed sign-in). Opening the email link on this device
/// signs the user in through the deep link; otherwise they confirm elsewhere and sign in.
class ConfirmEmailPage extends StatefulWidget {
  const ConfirmEmailPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends State<ConfirmEmailPage> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerBuilder(
      controller: widget.controller,
      builder: (context, c) {
        final l = AppLocalizations.of(context);
        final wait = c.resendRemaining.inSeconds;
        final canResend = !c.busy && wait <= 0;
        return AuthScaffold(
          title: l.authCheckEmailTitle,
          children: [
            StatusBanner(controller: c),
            Text(
              l.authConfirmSent(c.pendingEmail ?? l.authYourEmailAddress),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.lg),
            OutlinedButton(
              onPressed: canResend ? c.resendConfirmation : null,
              child: Text(
                canResend ? l.authResendEmail : l.authResendEmailIn(wait),
              ),
            ),
            const SizedBox(height: Space.sm),
            TextButton(
              onPressed: c.busy ? null : c.backToSignIn,
              child: Text(l.authConfirmedSignIn),
            ),
          ],
        );
      },
    );
  }
}
