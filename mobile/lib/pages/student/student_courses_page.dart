import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/course_card.dart';
import 'student_course_detail_page.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

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
                  'My courses',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showJoinCourse(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Join'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'View lessons, assignments, files, and progress.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ...MockData.courses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourseCard(
                course: course,
                teacherView: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentCourseDetailPage(course: course),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinCourse(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join a course',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                labelText: 'Course code',
                hintText: 'Example: MAD-401',
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: null, child: Text('Join course')),
            ),
          ],
        ),
      ),
    );
  }
}
