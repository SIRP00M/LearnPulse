import 'package:flutter/material.dart';
import '../models/assignment.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final bool studentView;

  const AssignmentCard({
    required this.assignment,
    this.studentView = false,
    super.key,
  });

  Color get statusColor {
    switch (assignment.status) {
      case AssignmentStatus.active:
        return const Color(0xFF246BFD);
      case AssignmentStatus.closed:
        return const Color(0xFF6B7280);
      case AssignmentStatus.draft:
        return const Color(0xFFFF9F1C);
    }
  }

  String get statusText {
    switch (assignment.status) {
      case AssignmentStatus.active:
        return 'Active';
      case AssignmentStatus.closed:
        return 'Closed';
      case AssignmentStatus.draft:
        return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.assignment_rounded, color: statusColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assignment.courseName,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    studentView
                        ? 'Due ${assignment.dueDate}'
                        : '${assignment.submittedCount}/${assignment.totalStudents} submitted • ${assignment.dueDate}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
