import 'package:flutter/material.dart';
import 'package:learn_pulse/models/task_priority.dart';

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
