import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/course_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/stat_card.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Good afternoon, Dr. Amelia',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Badge(
                  smallSize: 8,
                  child: Icon(Icons.notifications_none_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: const [
              StatCard(
                label: 'Courses',
                value: '3',
                icon: Icons.menu_book_rounded,
                color: AppTheme.primary,
              ),
              StatCard(
                label: 'Students',
                value: '84',
                icon: Icons.groups_rounded,
                color: Color(0xFF00A884),
              ),
              StatCard(
                label: 'Pending',
                value: '41',
                icon: Icons.pending_actions_rounded,
                color: Color(0xFFFF9F1C),
                helperText: 'Needs review',
              ),
              StatCard(
                label: 'At risk',
                value: '6',
                icon: Icons.warning_amber_rounded,
                color: Color(0xFFFF5C66),
                helperText: 'Needs attention',
              ),
            ],
          ),
          const SizedBox(height: 26),
          const SectionTitle(title: 'Course performance', actionText: 'View all'),
          const SizedBox(height: 12),
          ...MockData.courses.take(2).map(
                (course) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CourseCard(course: course),
                ),
              ),
          const SizedBox(height: 14),
          const SectionTitle(
            title: 'Recent assignments',
            actionText: 'Manage',
          ),
          const SizedBox(height: 12),
          ...MockData.assignments.take(2).map(
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
