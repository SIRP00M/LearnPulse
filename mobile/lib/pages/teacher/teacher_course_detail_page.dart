import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/course.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/section_title.dart';
import 'teacher_student_detail_page.dart';

class TeacherCourseDetailPage extends StatelessWidget {
  final Course course;

  const TeacherCourseDetailPage({
    required this.course,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course.code)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            course.title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.studentCount} students • ${course.assignmentCount} assignments',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average progress',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(course.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: course.progress, minHeight: 9),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Students', actionText: 'View all'),
          const SizedBox(height: 10),
          ...MockData.students.take(3).map(
                (student) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherStudentDetailPage(
                            student: student,
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      child: Text(student.name.substring(0, 1)),
                    ),
                    title: Text(student.name),
                    subtitle: Text(
                      '${(student.progress * 100).round()}% progress • ${student.averageScore.toStringAsFixed(0)} avg.',
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
          const SizedBox(height: 20),
          const SectionTitle(title: 'Assignments'),
          const SizedBox(height: 10),
          ...MockData.assignments.take(2).map(
                (assignment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AssignmentCard(assignment: assignment),
                ),
              ),
        ],
      ),
    );
  }
}
