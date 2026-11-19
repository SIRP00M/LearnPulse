import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.controller, this.presenter = false});

  final AuthController controller;

  /// Presenter Demo entry: the normal Auth sign-in (never a built-in password), then the Teacher lands on the Live Demo console.
  final bool presenter;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(
    text: widget.presenter ? AppConfig.demoPresenterEmail : '',
  );
  final _password = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      widget.controller.presenterIntent = widget.presenter;
      widget.controller.signIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ControllerBuilder(
      controller: widget.controller,
      builder: (context, c) => PopScope<void>(
        canPop: !c.canReturnToWelcome && !widget.presenter,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop || c.busy) return;
          if (widget.presenter) {
            c.showView(SignedOutView.demoSelector);
          } else if (c.canReturnToWelcome) {
            c.showView(SignedOutView.welcome);
          }
        },
        child: AuthScaffold(
          title: widget.presenter ? l.demoPresenter : l.authSignIn,
          signIn: !widget.presenter,
          children: [
            if (widget.presenter) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('presenter-back'),
                  onPressed: c.busy
                      ? null
                      : () => c.showView(SignedOutView.demoSelector),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l.demoBack),
                ),
              ),
              Text(l.demoPresenterSignInSub),
              const SizedBox(height: Space.md),
            ],
            if (!widget.presenter && c.canReturnToWelcome)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('back-to-welcome'),
                  onPressed: c.busy
                      ? null
                      : () => c.showView(SignedOutView.welcome),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l.welcomeBack),
                ),
              ),
            StatusBanner(controller: c),
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(labelText: l.authEmail),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    validator: fieldValidator(validateEmail),
                    errorBuilder: validationErrorBuilder,
                  ),
                  const SizedBox(height: Space.md),
                  TextFormField(
                    controller: _password,
                    decoration: InputDecoration(
                      labelText: l.authPassword,
                      suffixIcon: IconButton(
                        tooltip: _hide
                            ? l.authShowPassword
                            : l.authHidePassword,
                        icon: Icon(
                          _hide ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                    obscureText: _hide,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: fieldValidator(validatePasswordPresent),
                    errorBuilder: validationErrorBuilder,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            BusyButton(label: l.authSignIn, busy: c.busy, onPressed: _submit),
            const SizedBox(height: Space.sm),
            TextButton(
              onPressed: c.busy
                  ? null
                  : () => c.showView(SignedOutView.forgotPassword),
              child: Text(l.authForgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}
