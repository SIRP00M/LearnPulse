import 'package:flutter/material.dart';

class StudentTasksPage extends StatelessWidget {
  const StudentTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Tasks',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
