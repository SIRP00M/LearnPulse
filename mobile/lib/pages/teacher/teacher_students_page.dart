import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import 'teacher_student_detail_page.dart';

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'Students',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Monitor performance across all courses.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search students',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          ...MockData.students.map(
            (student) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TeacherStudentDetailPage(student: student),
                    ),
                  );
                },
                leading: CircleAvatar(
                  child: Text(student.name.substring(0, 1)),
                ),
                title: Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${(student.progress * 100).round()}% progress • ${student.submittedAssignments}/${student.totalAssignments} submitted',
                  ),
                ),
                trailing: student.atRisk
                    ? const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF5C66),
                      )
                    : const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
