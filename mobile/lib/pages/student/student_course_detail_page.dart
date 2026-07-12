import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../widgets/course_section_tab.dart';
import '../../widgets/file_tile.dart';
import 'student_assignment_detail_page.dart';

class StudentCourseDetailPage extends StatefulWidget {
  final Course course;
  const StudentCourseDetailPage({required this.course, super.key});
  @override
  State<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState extends State<StudentCourseDetailPage> {
  int selected = 0;
  final tabs = const [
    ('Overview', Icons.dashboard_outlined),
    ('Posts', Icons.campaign_outlined),
    ('Lessons', Icons.play_lesson_outlined),
    ('Assignments', Icons.assignment_outlined),
    ('Files', Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return Scaffold(
      appBar: AppBar(title: Text(c.code)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(c.icon, color: Colors.white, size: 34),
                const SizedBox(height: 16),
                Text(
                  c.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${c.teacherName} • ${c.code}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: c.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                const SizedBox(height: 7),
                Text(
                  '${(c.progress * 100).round()}% completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => CourseSectionTab(
                icon: tabs[i].$2,
                label: tabs[i].$1,
                selected: selected == i,
                onTap: () => setState(() => selected = i),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _section(),
        ],
      ),
    );
  }

  Widget _section() {
    switch (selected) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course overview',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.assignment_turned_in_outlined),
                      title: Text('Assignments'),
                      trailing: Text('4'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.schedule_rounded),
                      title: Text('Next deadline'),
                      trailing: Text('Today'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.grade_outlined),
                      title: Text('Current grade'),
                      trailing: Text('81/100'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: const [
            Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(child: Text('AH')),
                title: Text('Reminder: Flutter UI Prototype is due tonight.'),
                subtitle: Text('Today, 09:30'),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(child: Text('AH')),
                title: Text('Week 5 materials are now available.'),
                subtitle: Text('Yesterday, 15:10'),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(
                    [
                      'Course introduction',
                      'Widget fundamentals',
                      'Responsive layouts',
                      'Navigation and routing',
                      'State management',
                    ][i],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Video lesson'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
          ),
        );
      case 3:
        return Column(
          children: [
            Card(
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentAssignmentDetailPage(
                      course: widget.course,
                      title: 'Flutter UI Prototype',
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
                leading: const Icon(
                  Icons.assignment_rounded,
                  color: Color(0xFFFF5C66),
                ),
                title: const Text(
                  'Flutter UI Prototype',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Due today • Not submitted'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(14),
                leading: Icon(
                  Icons.assignment_rounded,
                  color: Color(0xFF00A884),
                ),
                title: Text(
                  'Navigation Exercise',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('Graded: 86/100'),
              ),
            ),
          ],
        );
      case 4:
        return const Column(
          children: [
            FileTile(
              name: 'Course syllabus.pdf',
              subtitle: '2.4 MB • Updated 2 July',
              extension: 'pdf',
            ),
            SizedBox(height: 10),
            FileTile(
              name: 'Week 5 slides.pptx',
              subtitle: '8.1 MB • Added yesterday',
              extension: 'pptx',
            ),
            SizedBox(height: 10),
            FileTile(
              name: 'Flutter starter project.zip',
              subtitle: '4.7 MB • Added yesterday',
              extension: 'zip',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
