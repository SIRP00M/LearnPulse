import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// Shown after the user opens a password-recovery link on this device.
class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      widget.controller.setNewPassword(_password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ControllerBuilder(
      controller: widget.controller,
      builder: (context, c) => AuthScaffold(
        title: l.authNewPasswordTitle,
        children: [
          StatusBanner(controller: c),
          Form(
            key: _form,
            child: TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: l.authNewPassword,
                helperText: l.authPasswordHelper,
                helperMaxLines: 2,
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              validator: fieldValidator(validateNewPassword),
              errorBuilder: validationErrorBuilder,
            ),
          ),
          const SizedBox(height: Space.lg),
          BusyButton(
            label: l.authSavePassword,
            busy: c.busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
