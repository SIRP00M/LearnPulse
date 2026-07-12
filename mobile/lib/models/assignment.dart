class Assignment {
  final String id;
  final String courseId;
  final String? lessonId;
  final String title;
  final String instructions;
  final DateTime? dueAt;
  final double maxScore;
  final bool allowLate;
  final DateTime? publishedAt;

  const Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.instructions,
    required this.maxScore,
    required this.allowLate,
    this.lessonId,
    this.dueAt,
    this.publishedAt,
  });

  bool get isPublished => publishedAt != null;

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      lessonId: map['lesson_id'] as String?,
      title: map['title'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      dueAt: map['due_at'] == null
          ? null
          : DateTime.parse(map['due_at'] as String),
      maxScore: (map['max_score'] as num? ?? 100).toDouble(),
      allowLate: map['allow_late'] as bool? ?? false,
      publishedAt: map['published_at'] == null
          ? null
          : DateTime.parse(map['published_at'] as String),
    );
  }
}
