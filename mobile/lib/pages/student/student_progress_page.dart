import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/stat_card.dart';

class StudentProgressPage extends StatelessWidget {
  const StudentProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'My progress',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'See how you are progressing across courses.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: const [
              StatCard(
                label: 'Overall',
                value: '72%',
                icon: Icons.insights_rounded,
                color: Color(0xFF246BFD),
              ),
              StatCard(
                label: 'Average score',
                value: '81',
                icon: Icons.grade_rounded,
                color: Color(0xFF7C4DFF),
              ),
              StatCard(
                label: 'Completed',
                value: '21',
                icon: Icons.task_alt_rounded,
                color: Color(0xFF00A884),
              ),
              StatCard(
                label: 'Day streak',
                value: '6',
                icon: Icons.local_fire_department_rounded,
                color: Color(0xFFFF9F1C),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Course progress',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...MockData.courses.map(
            (course) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${(course.progress * 100).round()}% completed',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
