class CourseFile {
  final String id;
  final String courseId;
  final String? lessonId;
  final String? assignmentId;
  final String uploadedBy;
  final String fileName;
  final String storagePath;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;

  const CourseFile({
    required this.id,
    required this.courseId,
    required this.uploadedBy,
    required this.fileName,
    required this.storagePath,
    required this.createdAt,
    this.lessonId,
    this.assignmentId,
    this.mimeType,
    this.sizeBytes,
  });

  factory CourseFile.fromMap(Map<String, dynamic> map) {
    return CourseFile(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      lessonId: map['lesson_id'] as String?,
      assignmentId: map['assignment_id'] as String?,
      uploadedBy: map['uploaded_by'] as String,
      fileName: map['file_name'] as String? ?? '',
      storagePath: map['storage_path'] as String? ?? '',
      mimeType: map['mime_type'] as String?,
      sizeBytes: map['size_bytes'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
