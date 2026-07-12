import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../student/student_shell.dart';
import '../teacher/teacher_shell.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  Future<UserProfile?>? _profileFuture;

  void _loadProfile() {
    _profileFuture = _authService.getMyProfile();
  }

  @override
  void initState() {
    super.initState();

    if (_authService.currentSession != null) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final session = _authService.currentSession;

        if (session == null) {
          _profileFuture = null;
          return const LoginPage();
        }

        _profileFuture ??= _authService.getMyProfile();

        return FutureBuilder<UserProfile?>(
          future: _profileFuture,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingPage();
            }

            if (profileSnapshot.hasError) {
              return _ProfileErrorPage(
                message: profileSnapshot.error.toString(),
                onRetry: () {
                  setState(() {
                    _loadProfile();
                  });
                },
                onSignOut: _authService.signOut,
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return _ProfileErrorPage(
                message: 'Your account profile could not be found.',
                onRetry: () {
                  setState(() {
                    _loadProfile();
                  });
                },
                onSignOut: _authService.signOut,
              );
            }

            if (profile.isTeacher) {
              return const TeacherShell();
            }

            return const StudentShell();
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  const _ProfileErrorPage({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 58),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: onRetry, child: const Text('Retry')),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSignOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
