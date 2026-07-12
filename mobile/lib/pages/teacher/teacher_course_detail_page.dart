import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/course.dart';
import '../../widgets/course_section_tab.dart';
import '../../widgets/file_tile.dart';
import 'teacher_student_detail_page.dart';

class TeacherCourseDetailPage extends StatefulWidget {
  final Course course;
  const TeacherCourseDetailPage({required this.course, super.key});
  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  int selected = 0;
  final tabs = const [
    ('Overview', Icons.dashboard_outlined),
    ('Posts', Icons.campaign_outlined),
    ('Lessons', Icons.play_lesson_outlined),
    ('Assignments', Icons.assignment_outlined),
    ('Students', Icons.groups_outlined),
    ('Files', Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return Scaffold(
      appBar: AppBar(title: Text(c.code)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMenu(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
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
                  '${c.studentCount} students • ${c.assignmentCount} assignments',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(c.progress * 100).round()}% average progress',
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
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: const [
            _Stat(
              value: '23/32',
              label: 'Submitted',
              icon: Icons.assignment_turned_in_rounded,
            ),
            _Stat(
              value: '4',
              label: 'At risk',
              icon: Icons.warning_amber_rounded,
            ),
            _Stat(
              value: '81',
              label: 'Average grade',
              icon: Icons.grade_rounded,
            ),
            _Stat(
              value: '68%',
              label: 'Completion',
              icon: Icons.insights_rounded,
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Post an announcement...',
                    suffixIcon: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(child: Text('AH')),
                title: Text('Reminder: Flutter UI Prototype is due tonight.'),
                subtitle: Text('Today, 09:30'),
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
                  subtitle: const Text('Published'),
                  trailing: const Icon(Icons.drag_handle_rounded),
                ),
              ),
            ),
          ),
        );
      case 3:
        return const Column(
          children: [
            Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(14),
                leading: Icon(Icons.assignment_rounded),
                title: Text(
                  'Flutter UI Prototype',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('23/32 submitted • Due today'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(14),
                leading: Icon(Icons.assignment_rounded),
                title: Text(
                  'Navigation Exercise',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('32/32 submitted • Graded'),
              ),
            ),
          ],
        );
      case 4:
        return Column(
          children: MockData.students
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherStudentDetailPage(student: s),
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        child: Text(s.name.substring(0, 1)),
                      ),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${(s.progress * 100).round()}% progress • ${s.averageScore.toStringAsFixed(0)} avg.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      case 5:
        return const Column(
          children: [
            FileTile(
              name: 'Course syllabus.pdf',
              subtitle: 'Visible to all students',
              extension: 'pdf',
            ),
            SizedBox(height: 10),
            FileTile(
              name: 'Week 5 slides.pptx',
              subtitle: 'Visible to all students',
              extension: 'pptx',
            ),
            SizedBox(height: 10),
            FileTile(
              name: 'Flutter starter project.zip',
              subtitle: 'Visible to all students',
              extension: 'zip',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Create in course',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.campaign_rounded)),
              title: Text('Announcement'),
              subtitle: Text('Post to the class'),
            ),
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.play_lesson_rounded)),
              title: Text('Lesson'),
              subtitle: Text('Add content or video'),
            ),
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.assignment_rounded)),
              title: Text('Assignment'),
              subtitle: Text('Create work and deadline'),
            ),
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.upload_file_rounded)),
              title: Text('File'),
              subtitle: Text('Upload a resource'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _Stat({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
