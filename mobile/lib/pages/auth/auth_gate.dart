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
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final session = authService.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return FutureBuilder<UserProfile?>(
          future: authService.getMyProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingPage();
            }

            if (profileSnapshot.hasError) {
              return _ProfileErrorPage(
                message: profileSnapshot.error.toString(),
                onRetry: () {
                  setState(() {});
                },
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return _ProfileErrorPage(
                message: 'Profile was not found.',
                onRetry: () {
                  setState(() {});
                },
              );
            }

            if (profile.role == 'teacher') {
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

  const _ProfileErrorPage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 52),
                const SizedBox(height: 14),
                const Text(
                  'Unable to load profile',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
