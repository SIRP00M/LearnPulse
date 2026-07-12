import 'package:flutter/material.dart';

class StudentProgressPage extends StatelessWidget {
  const StudentProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Progress',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
