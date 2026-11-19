enum AssignmentStatus { draft, published }

enum SubmissionStatus { submitted, graded, returned }

const maxFeedbackLength = 5000;

/// File types the server accepts (extension -> MIME). The server re-validates everything.
const allowedUploadTypes = <String, String>{
  'pdf': 'application/pdf',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'zip': 'application/zip',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'txt': 'text/plain',
};
const maxUploadBytes = 10 * 1024 * 1024;

String? mimeForFileName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return null;
  return allowedUploadTypes[name.substring(dot + 1).toLowerCase()];
}

class Assignment {
  const Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.instructions,
    required this.maxScore,
    required this.dueAt,
    required this.status,
    required this.version,
  });

  final String id;
  final String courseId;
  final String title;
  final String instructions;
  final int maxScore;
  final DateTime? dueAt;
  final AssignmentStatus status;
  final int version;

  bool get published => status == AssignmentStatus.published;
  bool isClosed(DateTime now) => dueAt != null && now.isAfter(dueAt!);

  static Assignment? fromRow(Map<String, dynamic> r) {
    final status = switch (r['status']) {
      'draft' => AssignmentStatus.draft,
      'published' => AssignmentStatus.published,
      _ => null,
    };
    if (status == null || r['id'] is! String || r['title'] is! String) {
      return null;
    }
    return Assignment(
      id: r['id'] as String,
      courseId: (r['course_id'] as String?) ?? '',
      title: r['title'] as String,
      instructions: (r['instructions'] as String?) ?? '',
      maxScore: (r['max_score'] as num?)?.toInt() ?? 100,
      dueAt: DateTime.tryParse((r['due_at'] as String?) ?? ''),
      status: status,
      version: (r['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class UploadInfo {
  const UploadInfo({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.path,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String path;

  static UploadInfo? fromRow(Object? r) {
    if (r is! Map || r['id'] is! String) return null;
    return UploadInfo(
      id: r['id'] as String,
      fileName: (r['file_name'] as String?) ?? 'file',
      mimeType: (r['mime_type'] as String?) ?? '',
      sizeBytes: (r['size_bytes'] as num?)?.toInt() ?? 0,
      path: (r['storage_path'] as String?) ?? '',
    );
  }
}

class Submission {
  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.answer,
    required this.version,
    required this.submittedAt,
    required this.upload,
    this.status = SubmissionStatus.submitted,
    this.score,
    this.feedback,
    this.gradedAt,
  });

  final String id;
  final String assignmentId;
  final String studentId;
  final String? studentName;
  final String answer;
  final int version;
  final DateTime submittedAt;
  final UploadInfo? upload;
  final SubmissionStatus status;
  final int? score;
  final String? feedback;
  final DateTime? gradedAt;

  static Submission? fromRow(Map<String, dynamic> r) {
    if (r['id'] is! String) return null;
    final student = r['student'];
    return Submission(
      id: r['id'] as String,
      assignmentId: (r['assignment_id'] as String?) ?? '',
      studentId: (r['student_id'] as String?) ?? '',
      studentName: student is Map ? student['full_name'] as String? : null,
      answer: (r['answer'] as String?) ?? '',
      version: (r['version'] as num?)?.toInt() ?? 1,
      submittedAt:
          DateTime.tryParse((r['submitted_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      upload: UploadInfo.fromRow(r['upload']),
      status: switch (r['status']) {
        'graded' => SubmissionStatus.graded,
        'returned' => SubmissionStatus.returned,
        _ => SubmissionStatus.submitted,
      },
      score: (r['score'] as num?)?.toInt(),
      feedback: r['feedback'] as String?,
      gradedAt: DateTime.tryParse((r['graded_at'] as String?) ?? ''),
    );
  }
}

class UploadTicket {
  const UploadTicket({required this.uploadId, required this.path});
  final String uploadId;
  final String path;
}

class PickedFile {
  const PickedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });
  final String name;
  final String mimeType;
  final List<int> bytes;
  int get size => bytes.length;
}

/// One row of the append-only grading history (teacher-only).
class GradeEvent {
  const GradeEvent({
    required this.action,
    required this.score,
    required this.feedback,
    required this.versionAfter,
    required this.createdAt,
  });

  final String action; // graded | returned
  final int? score;
  final String feedback;
  final int versionAfter;
  final DateTime createdAt;

  static GradeEvent? fromRow(Map<String, dynamic> r) {
    final action = r['action'];
    if (action is! String) return null;
    return GradeEvent(
      action: action,
      score: (r['score'] as num?)?.toInt(),
      feedback: (r['feedback'] as String?) ?? '',
      versionAfter: (r['version_after'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((r['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
