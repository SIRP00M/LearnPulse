import 'package:flutter/material.dart';
import 'package:learn_pulse/core/theme/app_theme.dart';
import 'package:learn_pulse/pages/main_shell.dart';

class LearnPulseApp extends StatelessWidget {
  const LearnPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learn Pulse',
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}
