import 'package:flutter/material.dart';

void main() {
  runApp(const LearnPulseApp());
}

class LearnPulseApp extends StatelessWidget {
  const LearnPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF4666FF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learn Pulse',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    CoursesPage(),
    TasksPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Dashboard
// ============================================================

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

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            'LP',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              SizedBox(height: 2),
              Text(
                'Let’s keep learning!',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
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
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () {},
      decoration: const InputDecoration(
        hintText: 'Search courses, tasks or lessons',
        prefixIcon: Icon(Icons.search_rounded),
        suffixIcon: Icon(Icons.tune_rounded),
      ),
    );
  }
}

class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF25347A);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly progress',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              ProgressChangeBadge(),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '68%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF90F4BE)),
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ProgressStat(value: '12', label: 'Tasks done'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ProgressStat(value: '8.5h', label: 'Study time'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ProgressStat(value: '4', label: 'Day streak'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressChangeBadge extends StatelessWidget {
  const ProgressChangeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF90F4BE)),
          SizedBox(width: 5),
          Text(
            '+12%',
            style: TextStyle(
              color: Color(0xFF90F4BE),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressStat extends StatelessWidget {
  final String value;
  final String label;

  const ProgressStat({required this.value, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

// ============================================================
// Shared widgets
// ============================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;

  const SectionHeader({required this.title, this.actionText, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        if (actionText != null)
          TextButton(onPressed: () {}, child: Text(actionText!)),
      ],
    );
  }
}

class CourseProgressCard extends StatelessWidget {
  final String subject;
  final String lesson;
  final double progress;
  final int completedLessons;
  final int totalLessons;
  final IconData icon;
  final Color accentColor;

  const CourseProgressCard({
    required this.subject,
    required this.lesson,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.icon,
    required this.accentColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: accentColor.withAlpha(25),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$completedLessons/$totalLessons',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

enum TaskPriority { high, medium, low }

class TaskCard extends StatelessWidget {
  final String title;
  final String course;
  final String dueDate;
  final TaskPriority priority;

  const TaskCard({
    required this.title,
    required this.course,
    required this.dueDate,
    required this.priority,
    super.key,
  });

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFF5C66);
      case TaskPriority.medium:
        return const Color(0xFFFFA62B);
      case TaskPriority.low:
        return const Color(0xFF4CB782);
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(value: false, onChanged: (_) {}),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            dueDate,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Courses page
// ============================================================

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

// ============================================================
// Tasks page
// ============================================================

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int selectedFilter = 0;

  final List<String> filters = const ['All', 'Today', 'Upcoming', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'Tasks',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Stay focused on what matters today',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ChoiceChip(
                  label: Text(filters[index]),
                  selected: selectedFilter == index,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = index;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: '3 tasks remaining'),
          const SizedBox(height: 12),
          const TaskCard(
            title: 'Submit mobile app wireframe',
            course: 'Senior Project',
            dueDate: 'Today, 11:59 PM',
            priority: TaskPriority.high,
          ),
          const SizedBox(height: 10),
          const TaskCard(
            title: 'Review Chapter 4 vocabulary',
            course: 'Japanese Language',
            dueDate: 'Tomorrow, 8:00 PM',
            priority: TaskPriority.medium,
          ),
          const SizedBox(height: 10),
          const TaskCard(
            title: 'Complete DSP worksheet',
            course: 'Digital Signal Processing',
            dueDate: '14 July',
            priority: TaskPriority.low,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Create task'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Profile page
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                'LP',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Learn Pulse User',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Student',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 28),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal information',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  trailingText: 'English',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help and support',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Learn Pulse',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(trailingText!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}
