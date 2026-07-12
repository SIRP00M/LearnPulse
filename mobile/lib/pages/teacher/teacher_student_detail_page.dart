import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../widgets/stat_card.dart';

class TeacherStudentDetailPage extends StatelessWidget {
  final Student student;

  const TeacherStudentDetailPage({required this.student, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                student.name.substring(0, 1),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            student.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            student.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              StatCard(
                label: 'Progress',
                value: '${(student.progress * 100).round()}%',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF246BFD),
              ),
              StatCard(
                label: 'Average score',
                value: student.averageScore.toStringAsFixed(0),
                icon: Icons.grade_rounded,
                color: const Color(0xFF7C4DFF),
              ),
              StatCard(
                label: 'Submitted',
                value:
                    '${student.submittedAssignments}/${student.totalAssignments}',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF00A884),
              ),
              StatCard(
                label: 'Status',
                value: student.atRisk ? 'At risk' : 'On track',
                icon: student.atRisk
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: student.atRisk
                    ? const Color(0xFFFF5C66)
                    : const Color(0xFF00A884),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Teacher notes',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Add a private note about this student...',
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save note'),
          ),
        ],
      ),
    );
  }
}
