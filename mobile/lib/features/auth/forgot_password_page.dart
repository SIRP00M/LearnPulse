import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      widget.controller.requestPasswordReset(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ControllerBuilder(
      controller: widget.controller,
      builder: (context, c) => AuthScaffold(
        title: l.authResetTitle,
        children: [
          StatusBanner(controller: c),
          Form(
            key: _form,
            child: TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l.authEmail),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: fieldValidator(validateEmail),
              errorBuilder: validationErrorBuilder,
            ),
          ),
          const SizedBox(height: Space.lg),
          BusyButton(
            label: l.authSendResetLink,
            busy: c.busy,
            onPressed: _submit,
          ),
          const SizedBox(height: Space.sm),
          TextButton(
            onPressed: c.busy ? null : () => c.showView(SignedOutView.signIn),
            child: Text(l.authBackToSignIn),
          ),
        ],
      ),
    );
  }
}
