import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/course_card.dart';
import '../../widgets/section_title.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Alex',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Keep your learning pulse going.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              CircleAvatar(child: Text('A')),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF173B7A),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall progress',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text(
                  '72%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.72,
                  minHeight: 9,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF73E0B1)),
                ),
                SizedBox(height: 12),
                Text(
                  'You are ahead of 68% of your classmates.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Continue learning'),
          const SizedBox(height: 10),
          ...MockData.courses
              .take(2)
              .map(
                (course) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CourseCard(course: course, teacherView: false),
                ),
              ),
          const SizedBox(height: 12),
          const SectionTitle(title: 'Upcoming tasks'),
          const SizedBox(height: 10),
          ...MockData.assignments
              .take(2)
              .map(
                (assignment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AssignmentCard(
                    assignment: assignment,
                    studentView: true,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
