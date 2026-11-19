import 'package:flutter/material.dart';

import 'core/formatting.dart';
import 'core/language_selector.dart';
import 'core/locale_controller.dart';
import 'core/states.dart';
import 'l10n/app_localizations.dart';

import 'core/app_error.dart';
import 'core/theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_widgets.dart';
import 'features/auth/confirm_email_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/set_password_page.dart';
import 'features/auth/sign_in_page.dart';
import 'features/auth/sign_up_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/demo/demo_pages.dart';
import 'app_services.dart';
import 'features/home/role_home.dart';

class LearnPulseApp extends StatelessWidget {
  const LearnPulseApp({
    super.key,
    required this.controller,
    required this.services,
  });

  final AuthController controller;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final locale = services.locale;
    return LocaleScope(
      controller: locale,
      child: ListenableBuilder(
        listenable: locale,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => 'LearnPulse',
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: LocaleController.supported,
          locale: locale.locale,
          localeListResolutionCallback: LocaleController.resolve,
          // The OS "remove animations" setting turns page transitions off.
          builder: (context, child) {
            // Context-free date helpers read this; widgets use AppFormat.of(context).
            AppFormat.current = AppFormat.of(context);
            if (!MediaQuery.disableAnimationsOf(context)) return child!;
            final brightness = Theme.of(context).brightness;
            return Theme(
              data: buildTheme(brightness, reduceMotion: true),
              child: child!,
            );
          },
          home: AuthGate(controller: controller, services: services),
        ),
      ),
    );
  }
}

/// Routes purely on [AuthStage]; the Teacher/Student split uses the server-loaded profile.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.controller, required this.services});

  final AuthController controller;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        switch (controller.stage) {
          case AuthStage.starting:
          case AuthStage.loadingProfile:
            return Scaffold(
              body: Center(
                child: Semantics(
                  label: AppLocalizations.of(context).commonLoading,
                  child: const CircularProgressIndicator(),
                ),
              ),
            );
          case AuthStage.signedOut:
            if (controller.sessionExpired) {
              return SessionExpiredPage(controller: controller);
            }
            return switch (controller.view) {
              SignedOutView.welcome => WelcomePage(controller: controller),
              SignedOutView.signIn => SignInPage(controller: controller),
              SignedOutView.signUp => SignUpPage(controller: controller),
              SignedOutView.forgotPassword => ForgotPasswordPage(
                controller: controller,
              ),
              SignedOutView.demoSelector => DemoSelectorPage(
                controller: controller,
              ),
              SignedOutView.demoJoin => DemoJoinPage(
                controller: controller,
                repository: services.demo,
                prefs: services.prefs,
              ),
              SignedOutView.presenter => SignInPage(
                controller: controller,
                presenter: true,
              ),
            };
          case AuthStage.awaitingConfirmation:
            return ConfirmEmailPage(controller: controller);
          case AuthStage.recovery:
            return SetPasswordPage(controller: controller);
          case AuthStage.profileError:
            return _ProfileError(controller: controller);
          case AuthStage.signedIn:
            return SessionScope(
              onSignInAgain: controller.signOut,
              child: RoleHome(
                controller: controller,
                profile: controller.profile!,
                services: services,
              ),
            );
        }
      },
    );
  }
}

/// Shown when the server ended the session: explains why and offers the way back in.
class SessionExpiredPage extends StatelessWidget {
  const SessionExpiredPage({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.authSessionExpiredTitle,
      children: [
        StatePanel(
          icon: Icons.lock_clock_outlined,
          title: l.authSignedOutTitle,
          message: l.authSessionEnded,
          full: false,
          framed: false,
        ),
        BusyButton(
          label: l.commonSignInAgain,
          busy: controller.busy,
          onPressed: controller.backToSignIn,
        ),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final offline = controller.error?.kind == AppErrorKind.network;
    return AuthScaffold(
      title: offline ? l.authCantReach : l.authAccountNotReady,
      children: [
        StatusBanner(controller: controller),
        BusyButton(
          label: l.commonTryAgain,
          busy: controller.busy,
          onPressed: controller.retryProfile,
        ),
        const SizedBox(height: Space.sm),
        OutlinedButton(
          onPressed: controller.busy ? null : controller.signOut,
          child: Text(l.commonSignOut),
        ),
      ],
    );
  }
}

/// Shown instead of the app when the build configuration is unusable (never reaches the network).
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.problem, this.locale});

  final String problem;
  final LocaleController? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: LocaleController.supported,
      locale: locale?.locale,
      localeListResolutionCallback: LocaleController.resolve,
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Center(
                child: Text(
                  '${AppLocalizations.of(context).configErrorTitle}\n\n$problem',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
