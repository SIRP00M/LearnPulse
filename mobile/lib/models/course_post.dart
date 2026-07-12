class CoursePost {
  final String id;
  final String courseId;
  final String authorId;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const CoursePost({
    required this.id,
    required this.courseId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.createdAt,
    this.publishedAt,
  });

  factory CoursePost.fromMap(Map<String, dynamic> map) {
    return CoursePost(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      authorId: map['author_id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      isPinned: map['is_pinned'] as bool? ?? false,
      publishedAt: map['published_at'] == null
          ? null
          : DateTime.parse(map['published_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
