import 'package:flutter/material.dart';
import 'package:learn_pulse/models/task_priority.dart';
import 'package:learn_pulse/widgets/course_progress_card.dart';
import 'package:learn_pulse/widgets/dashboard_header.dart';
import 'package:learn_pulse/widgets/search_box.dart';
import 'package:learn_pulse/widgets/section_header.dart';
import 'package:learn_pulse/widgets/task_card.dart';
import 'package:learn_pulse/widgets/weekly_progress_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: const [
          DashboardHeader(),
          SizedBox(height: 24),
          SearchBox(),
          SizedBox(height: 20),
          WeeklyProgressCard(),
          SizedBox(height: 28),
          SectionHeader(title: 'Continue learning', actionText: 'View all'),
          SizedBox(height: 12),
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
          SizedBox(height: 28),
          SectionHeader(title: 'Upcoming tasks', actionText: 'See calendar'),
          SizedBox(height: 12),
          TaskCard(
            title: 'Submit mobile app wireframe',
            course: 'Senior Project',
            dueDate: 'Today, 11:59 PM',
            priority: TaskPriority.high,
          ),
          SizedBox(height: 10),
          TaskCard(
            title: 'Review Chapter 4 vocabulary',
            course: 'Japanese Language',
            dueDate: 'Tomorrow, 8:00 PM',
            priority: TaskPriority.medium,
          ),
          SizedBox(height: 10),
          TaskCard(
            title: 'Complete DSP worksheet',
            course: 'Digital Signal Processing',
            dueDate: '14 July',
            priority: TaskPriority.low,
          ),
        ],
      ),
    );
  }
}
