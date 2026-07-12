import 'package:flutter/material.dart';

class TeacherAssignmentsPage extends StatelessWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Assignments',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
