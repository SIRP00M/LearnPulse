import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'pages/auth/auth_gate.dart';

class LearnPulseApp extends StatelessWidget {
  const LearnPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learn Pulse',
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
