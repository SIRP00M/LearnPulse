import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/assignment_card.dart';

class TeacherAssignmentsPage extends StatelessWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Assignments',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Create tasks and review submissions.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ...MockData.assignments.map(
            (assignment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AssignmentCard(assignment: assignment),
            ),
          ),
        ],
      ),
    );
  }
}
