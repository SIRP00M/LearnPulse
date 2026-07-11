import 'package:flutter/material.dart';
import 'package:learn_pulse/models/task_priority.dart';
import 'package:learn_pulse/widgets/section_header.dart';
import 'package:learn_pulse/widgets/task_card.dart';

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
