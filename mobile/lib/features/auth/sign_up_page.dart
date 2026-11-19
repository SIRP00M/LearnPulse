import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

/// Public registration. There is deliberately no role selector: everyone starts as a Student;
/// a Teacher is promoted by the server after confirming an invited email address.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.controller});

  final AuthController controller;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      widget.controller.signUp(_email.text, _password.text, _name.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ControllerBuilder(
      controller: widget.controller,
      builder: (context, c) => AuthScaffold(
        title: l.authCreateYourAccount,
        children: [
          StatusBanner(controller: c),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l.authFullName),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: fieldValidator(validateFullName),
                  errorBuilder: validationErrorBuilder,
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(labelText: l.authEmail),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: fieldValidator(validateEmail),
                  errorBuilder: validationErrorBuilder,
                ),
                const SizedBox(height: Space.md),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: l.authPassword,
                    helperText: l.authPasswordHelper,
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      tooltip: _hide ? l.authShowPassword : l.authHidePassword,
                      icon: Icon(
                        _hide ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  obscureText: _hide,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: fieldValidator(validateNewPassword),
                  errorBuilder: validationErrorBuilder,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(l.authTeacherNote, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Space.lg),
          BusyButton(
            label: l.authCreateAccount,
            busy: c.busy,
            onPressed: _submit,
          ),
          const SizedBox(height: Space.sm),
          TextButton(
            onPressed: c.busy ? null : () => c.showView(SignedOutView.signIn),
            child: Text(l.authHaveAccount),
          ),
        ],
      ),
    );
  }
}
