class Student {
  final String id;
  final String name;
  final String email;
  final double progress;
  final int submittedAssignments;
  final int totalAssignments;
  final double averageScore;
  final bool atRisk;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.progress,
    required this.submittedAssignments,
    required this.totalAssignments,
    required this.averageScore,
    required this.atRisk,
  });
}
