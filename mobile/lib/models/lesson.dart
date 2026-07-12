class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String content;
  final int position;
  final DateTime? publishedAt;

  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.content,
    required this.position,
    this.publishedAt,
  });

  bool get isPublished => publishedAt != null;

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      content: map['content'] as String? ?? '',
      position: map['position'] as int? ?? 0,
      publishedAt: map['published_at'] == null
          ? null
          : DateTime.parse(map['published_at'] as String),
    );
  }
}
