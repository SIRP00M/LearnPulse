enum AssignmentStatus { active, closed, draft }

class Assignment {
  final String id;
  final String title;
  final String courseName;
  final String dueDate;
  final int submittedCount;
  final int totalStudents;
  final AssignmentStatus status;

  const Assignment({
    required this.id,
    required this.title,
    required this.courseName,
    required this.dueDate,
    required this.submittedCount,
    required this.totalStudents,
    required this.status,
  });
}
