import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/assignment_card.dart';

class StudentTasksPage extends StatelessWidget {
  const StudentTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'Tasks',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track assignments and due dates.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ...MockData.assignments.map(
            (assignment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AssignmentCard(assignment: assignment, studentView: true),
            ),
          ),
        ],
      ),
    );
  }
}
