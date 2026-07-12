import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService authService = AuthService();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'student';
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> signUp() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage('Please complete all fields.');
      return;
    }

    if (password.length < 6) {
      showMessage('Password must contain at least 6 characters.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: selectedRole,
      );

      if (!mounted) return;

      if (response.session != null) {
        Navigator.of(context).pop();
      } else {
        showMessage('Account created. Please confirm your email.');
      }
    } on AuthException catch (error) {
      showMessage(error.message);
    } catch (error) {
      showMessage('Something went wrong: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Join Learn Pulse',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create an account and choose your role.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: fullNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Account role',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'student',
                icon: Icon(Icons.person_rounded),
                label: Text('Student'),
              ),
              ButtonSegment(
                value: 'teacher',
                icon: Icon(Icons.school_rounded),
                label: Text('Teacher'),
              ),
            ],
            selected: {selectedRole},
            onSelectionChanged: (selection) {
              setState(() {
                selectedRole = selection.first;
              });
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: isLoading ? null : signUp,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_rounded),
            label: Text(isLoading ? 'Creating account...' : 'Create account'),
          ),
        ],
      ),
    );
  }
}
