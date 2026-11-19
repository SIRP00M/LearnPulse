import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'assignment.dart';

/// Assignment and submission access: RLS-scoped reads and the V3 RPCs only. Files go to the private
/// `submission-files` bucket through a server-issued ticket path; the client never writes tables.
abstract class AssignmentRepository {
  Future<List<Assignment>> listAssignments(String courseId);
  Future<void> createAssignment({
    required String courseId,
    required String title,
    required String instructions,
    required int maxScore,
    DateTime? dueAt,
  });
  Future<void> updateAssignment(
    String assignmentId,
    int expectedVersion, {
    String? title,
    String? instructions,
    int? maxScore,
    DateTime? dueAt,
    bool clearDue = false,
  });
  Future<void> publishAssignment(String assignmentId, int expectedVersion);

  /// The signed-in student's own submissions (RLS returns nothing else).
  Future<List<Submission>> listMySubmissions();
  Future<List<Submission>> listSubmissions(String assignmentId);

  Future<UploadTicket> prepareUpload(String assignmentId, PickedFile file);
  Future<void> uploadBytes(UploadTicket ticket, PickedFile file);
  Future<Submission> submit({
    required String assignmentId,
    required String requestId,
    required String answer,
    String? uploadId,
    int? expectedVersion,
    bool clearAttachment = false,
  });
  Future<String> signedUrl(String path);

  /// Teacher grading. [requestId] makes retries after a lost response idempotent.
  Future<Submission> gradeSubmission({
    required String submissionId,
    required String requestId,
    required int expectedVersion,
    required int score,
    String feedback = '',
  });
  Future<Submission> returnSubmission({
    required String submissionId,
    required String requestId,
    required int expectedVersion,
    required String feedback,
  });
  Future<List<GradeEvent>> listEvents(String submissionId);
}

abstract class FilePickerService {
  /// Returns the chosen file (bytes in memory, max 10 MiB) or null when cancelled.
  Future<PickedFile?> pick();
}

class SystemFilePicker implements FilePickerService {
  @override
  Future<PickedFile?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedUploadTypes.keys.toList(),
      withData: true,
    );
    final f = result?.files.single;
    if (f == null) return null;
    final bytes = f.bytes;
    final mime = mimeForFileName(f.name);
    if (bytes == null || mime == null) {
      throw const AppError(
        AppErrorKind.validation,
        'That file type is not allowed. Use pdf, docx, zip, png, jpg, webp or txt.',
        AppErrorCode.fileTypeList,
      );
    }
    return PickedFile(name: f.name, mimeType: mime, bytes: bytes);
  }
}

class SupabaseAssignmentRepository implements AssignmentRepository {
  SupabaseAssignmentRepository(this._client);

  final SupabaseClient _client;
  static const _bucket = 'submission-files';

  static const _subSelect =
      'id, assignment_id, student_id, answer, version, submitted_at, status, score, feedback, graded_at, '
      'upload:submission_uploads!submissions_upload_id_fkey(id, file_name, mime_type, size_bytes, storage_path), '
      'student:profiles!submissions_student_id_fkey(full_name)';

  @override
  Future<List<Assignment>> listAssignments(String courseId) async {
    final rows = await _client
        .from('assignments')
        .select(
          'id, course_id, title, instructions, max_score, due_at, status, version',
        )
        .eq('course_id', courseId)
        .order('created_at', ascending: true);
    return [for (final r in rows) ?Assignment.fromRow(r)];
  }

  @override
  Future<void> createAssignment({
    required String courseId,
    required String title,
    required String instructions,
    required int maxScore,
    DateTime? dueAt,
  }) async {
    await _rpc('create_assignment', {
      'p_course_id': courseId,
      'p_title': title,
      'p_instructions': instructions,
      'p_max_score': maxScore,
      'p_due_at': ?dueAt?.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updateAssignment(
    String assignmentId,
    int expectedVersion, {
    String? title,
    String? instructions,
    int? maxScore,
    DateTime? dueAt,
    bool clearDue = false,
  }) async {
    await _rpc('update_assignment', {
      'p_assignment_id': assignmentId,
      'p_expected_version': expectedVersion,
      'p_title': ?title,
      'p_instructions': ?instructions,
      'p_max_score': ?maxScore,
      'p_due_at': ?dueAt?.toUtc().toIso8601String(),
      'p_clear_due': clearDue,
    });
  }

  @override
  Future<void> publishAssignment(String assignmentId, int expectedVersion) =>
      _rpc('publish_assignment', {
        'p_assignment_id': assignmentId,
        'p_expected_version': expectedVersion,
      });

  @override
  Future<List<Submission>> listMySubmissions() async {
    final rows = await _client.from('submissions').select(_subSelect);
    return [for (final r in rows) ?Submission.fromRow(r)];
  }

  @override
  Future<List<Submission>> listSubmissions(String assignmentId) async {
    final rows = await _client
        .from('submissions')
        .select(_subSelect)
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);
    return [for (final r in rows) ?Submission.fromRow(r)];
  }

  @override
  Future<UploadTicket> prepareUpload(
    String assignmentId,
    PickedFile file,
  ) async {
    final json = await _rpc('prepare_submission_upload', {
      'p_assignment_id': assignmentId,
      'p_file_name': file.name,
      'p_mime_type': file.mimeType,
      'p_size_bytes': file.size,
    });
    return UploadTicket(
      uploadId: json['upload_id'] as String,
      path: json['path'] as String,
    );
  }

  @override
  Future<void> uploadBytes(UploadTicket ticket, PickedFile file) async {
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            ticket.path,
            Uint8List.fromList(file.bytes),
            fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
          );
    } on StorageException catch (e) {
      // A retry after a lost response finds the object already stored (409): the server verifies
      // size and type when the submission is saved, so this is safe to treat as done.
      if (e.statusCode == '409' || e.message.contains('already exists')) return;
      throw AppError.from(e);
    }
  }

  @override
  Future<Submission> submit({
    required String assignmentId,
    required String requestId,
    required String answer,
    String? uploadId,
    int? expectedVersion,
    bool clearAttachment = false,
  }) async {
    final json = await _rpc('submit_assignment', {
      'p_assignment_id': assignmentId,
      'p_request_id': requestId,
      'p_answer': answer,
      'p_upload_id': ?uploadId,
      'p_expected_version': ?expectedVersion,
      'p_clear_attachment': clearAttachment,
    });
    return Submission(
      id: json['submission_id'] as String,
      assignmentId: assignmentId,
      studentId: '',
      studentName: null,
      answer: (json['answer'] as String?) ?? '',
      version: (json['version'] as num).toInt(),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      upload: null,
    );
  }

  @override
  Future<String> signedUrl(String path) async {
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, 600);
    } on StorageException {
      throw const AppError(
        AppErrorKind.forbidden,
        'You do not have access to this file.',
        AppErrorCode.fileNoAccess,
      );
    }
  }

  @override
  Future<Submission> gradeSubmission({
    required String submissionId,
    required String requestId,
    required int expectedVersion,
    required int score,
    String feedback = '',
  }) async => _gradingResult(
    await _rpc('grade_submission', {
      'p_submission_id': submissionId,
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_score': score,
      'p_feedback': feedback,
    }),
  );

  @override
  Future<Submission> returnSubmission({
    required String submissionId,
    required String requestId,
    required int expectedVersion,
    required String feedback,
  }) async => _gradingResult(
    await _rpc('return_submission', {
      'p_submission_id': submissionId,
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_feedback': feedback,
    }),
  );

  Submission _gradingResult(Map<String, dynamic> json) => Submission(
    id: json['submission_id'] as String,
    assignmentId: '',
    studentId: '',
    studentName: null,
    answer: '',
    version: (json['version'] as num).toInt(),
    submittedAt: DateTime.fromMillisecondsSinceEpoch(0),
    upload: null,
    status: json['status'] == 'graded'
        ? SubmissionStatus.graded
        : SubmissionStatus.returned,
    score: (json['score'] as num?)?.toInt(),
    feedback: json['feedback'] as String?,
    gradedAt: DateTime.tryParse((json['graded_at'] as String?) ?? ''),
  );

  @override
  Future<List<GradeEvent>> listEvents(String submissionId) async {
    final rows = await _client
        .from('submission_events')
        .select('action, score, feedback, version_after, created_at')
        .eq('submission_id', submissionId)
        .order('version_after', ascending: true);
    return [for (final r in rows) ?GradeEvent.fromRow(r)];
  }

  Future<Map<String, dynamic>> _rpc(
    String fn,
    Map<String, dynamic> params,
  ) async {
    try {
      return Map<String, dynamic>.from(
        await _client.rpc(fn, params: params) as Map,
      );
    } on PostgrestException catch (e) {
      throw AppError.from(e);
    }
  }
}
