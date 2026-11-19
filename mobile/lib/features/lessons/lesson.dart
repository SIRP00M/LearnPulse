enum LessonStatus { draft, published }

const maxLessonBody = 20000;

class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.body,
    required this.status,
    required this.version,
  });

  final String id;
  final String courseId;
  final String title;
  final String body;
  final LessonStatus status;
  final int version;

  bool get published => status == LessonStatus.published;

  static Lesson? fromRow(Map<String, dynamic> r) {
    final status = switch (r['status']) {
      'draft' => LessonStatus.draft,
      'published' => LessonStatus.published,
      _ => null,
    };
    if (status == null || r['id'] is! String || r['title'] is! String) {
      return null;
    }
    return Lesson(
      id: r['id'] as String,
      courseId: (r['course_id'] as String?) ?? '',
      title: r['title'] as String,
      body: (r['body'] as String?) ?? '',
      status: status,
      version: (r['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class LessonResource {
  const LessonResource({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.fileName,
    required this.sizeBytes,
    required this.path,
    required this.attached,
  });

  final String id;
  final String lessonId;
  final String title;
  final String fileName;
  final int sizeBytes;
  final String path;
  final bool attached;

  static LessonResource? fromRow(Map<String, dynamic> r) {
    if (r['id'] is! String ||
        r['lesson_id'] is! String ||
        r['file_name'] is! String ||
        r['storage_path'] is! String) {
      return null;
    }
    return LessonResource(
      id: r['id'] as String,
      lessonId: r['lesson_id'] as String,
      title: (r['title'] as String?) ?? '',
      fileName: r['file_name'] as String,
      sizeBytes: (r['size_bytes'] as num?)?.toInt() ?? 0,
      path: r['storage_path'] as String,
      attached: r['status'] == 'attached',
    );
  }

  String get label => title.isEmpty ? fileName : title;
}

/// Server-issued upload ticket for one resource file.
class ResourceTicket {
  const ResourceTicket({required this.resourceId, required this.path});
  final String resourceId;
  final String path;
}
