class Course {
  final String id;
  final String title;
  final String courseCode;
  final String description;
  final String overview;
  final String? coverUrl;
  final String status;
  final String teacherName;
  final DateTime createdAt;

  const Course({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.description,
    required this.overview,
    required this.status,
    required this.teacherName,
    required this.createdAt,
    this.coverUrl,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    final teacherData = map['teacher'];

    String teacherName = 'Unknown teacher';

    if (teacherData is Map<String, dynamic>) {
      teacherName = teacherData['full_name'] as String? ?? 'Unknown teacher';
    } else if (teacherData is List && teacherData.isNotEmpty) {
      final teacher = teacherData.first;

      if (teacher is Map<String, dynamic>) {
        teacherName = teacher['full_name'] as String? ?? 'Unknown teacher';
      }
    }

    return Course(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled course',
      courseCode: map['course_code'] as String? ?? '',
      description: map['description'] as String? ?? '',
      overview: map['overview'] as String? ?? '',
      coverUrl: map['cover_url'] as String?,
      status: map['status'] as String? ?? 'draft',
      teacherName: teacherName,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
