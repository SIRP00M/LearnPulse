import 'package:flutter/material.dart';
import 'package:learn_pulse/widgets/course_progress_card.dart';
import 'package:learn_pulse/widgets/search_box.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: const [
          Text(
            'My courses',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text(
            'Track lessons and learning progress',
            style: TextStyle(color: Colors.black54),
          ),
          SizedBox(height: 22),
          SearchBox(),
          SizedBox(height: 22),
          CourseProgressCard(
            subject: 'Computer Engineering',
            lesson: 'Digital Signal Processing',
            progress: 0.68,
            completedLessons: 17,
            totalLessons: 25,
            icon: Icons.memory_rounded,
            accentColor: Color(0xFF4666FF),
          ),
          SizedBox(height: 12),
          CourseProgressCard(
            subject: 'Japanese Language',
            lesson: 'JLPT N3 Grammar',
            progress: 0.42,
            completedLessons: 21,
            totalLessons: 50,
            icon: Icons.translate_rounded,
            accentColor: Color(0xFFFF7A59),
          ),
          SizedBox(height: 12),
          CourseProgressCard(
            subject: 'Mobile Application',
            lesson: 'Flutter UI Development',
            progress: 0.24,
            completedLessons: 6,
            totalLessons: 25,
            icon: Icons.phone_android_rounded,
            accentColor: Color(0xFF20A779),
          ),
          SizedBox(height: 12),
          CourseProgressCard(
            subject: 'Artificial Intelligence',
            lesson: 'Computer Vision Fundamentals',
            progress: 0.81,
            completedLessons: 26,
            totalLessons: 32,
            icon: Icons.smart_toy_rounded,
            accentColor: Color(0xFF9B5DE5),
          ),
          SizedBox(height: 20),
          AddCourseButton(),
        ],
      ),
    );
  }
}

class AddCourseButton extends StatelessWidget {
  const AddCourseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add new course'),
    );
  }
}
