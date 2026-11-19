import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../assignments/assignment.dart' show PickedFile;
import 'lesson.dart';

/// Lesson access: RLS-scoped reads and the V5 RPCs only. Files go to the private `course-files` bucket
/// through a server-issued ticket path; the client never writes tables.
abstract class LessonRepository {
  Future<List<Lesson>> listLessons(String courseId);
  Future<List<LessonResource>> listResources(String courseId);
  Future<void> createLesson(String courseId, String title, String body);
  Future<void> updateLesson(
    String lessonId,
    int expectedVersion, {
    String? title,
    String? body,
  });
  Future<void> setPublished(String lessonId, int expectedVersion, bool publish);
  Future<void> deleteLesson(String lessonId, int expectedVersion);

  Future<ResourceTicket> prepareResource(String lessonId, PickedFile file);
  Future<void> uploadBytes(ResourceTicket ticket, PickedFile file);
  Future<void> finalizeResource(String resourceId, String title);
  Future<void> deleteResource(String resourceId);
  Future<String> signedUrl(String path);
}

class SupabaseLessonRepository implements LessonRepository {
  SupabaseLessonRepository(this._client);

  final SupabaseClient _client;
  static const _bucket = 'course-files';

  @override
  Future<List<Lesson>> listLessons(String courseId) async {
    final rows = await _client
        .from('lessons')
        .select('id, course_id, title, body, status, version')
        .eq('course_id', courseId)
        .order('position', ascending: true)
        .order('created_at', ascending: true);
    return [for (final r in rows) ?Lesson.fromRow(r)];
  }

  @override
  Future<List<LessonResource>> listResources(String courseId) async {
    final rows = await _client
        .from('lesson_resources')
        .select(
          'id, lesson_id, title, file_name, size_bytes, storage_path, status',
        )
        .eq('course_id', courseId)
        .order('created_at', ascending: true);
    return [for (final r in rows) ?LessonResource.fromRow(r)];
  }

  @override
  Future<void> createLesson(String courseId, String title, String body) async {
    await _rpc('create_lesson', {
      'p_course_id': courseId,
      'p_title': title,
      'p_body': body,
    });
  }

  @override
  Future<void> updateLesson(
    String lessonId,
    int expectedVersion, {
    String? title,
    String? body,
  }) async {
    await _rpc('update_lesson', {
      'p_lesson_id': lessonId,
      'p_expected_version': expectedVersion,
      'p_title': ?title,
      'p_body': ?body,
    });
  }

  @override
  Future<void> setPublished(
    String lessonId,
    int expectedVersion,
    bool publish,
  ) async {
    await _rpc('set_lesson_status', {
      'p_lesson_id': lessonId,
      'p_expected_version': expectedVersion,
      'p_status': publish ? 'published' : 'draft',
    });
  }

  @override
  Future<void> deleteLesson(String lessonId, int expectedVersion) async {
    await _rpc('delete_lesson', {
      'p_lesson_id': lessonId,
      'p_expected_version': expectedVersion,
    });
  }

  @override
  Future<ResourceTicket> prepareResource(
    String lessonId,
    PickedFile file,
  ) async {
    final json = await _rpc('prepare_resource_upload', {
      'p_lesson_id': lessonId,
      'p_file_name': file.name,
      'p_mime_type': file.mimeType,
      'p_size_bytes': file.size,
    });
    return ResourceTicket(
      resourceId: json['resource_id'] as String,
      path: json['path'] as String,
    );
  }

  @override
  Future<void> uploadBytes(ResourceTicket ticket, PickedFile file) async {
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            ticket.path,
            Uint8List.fromList(file.bytes),
            fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
          );
    } on StorageException catch (e) {
      // A retry after a lost response finds the object already stored (409): finalize_resource
      // verifies size and type, so this is safe to treat as done.
      if (e.statusCode == '409' || e.message.contains('already exists')) return;
      throw AppError.from(e);
    }
  }

  @override
  Future<void> finalizeResource(String resourceId, String title) async {
    await _rpc('finalize_resource', {
      'p_resource_id': resourceId,
      'p_title': title,
    });
  }

  @override
  Future<void> deleteResource(String resourceId) async {
    await _rpc('delete_resource', {'p_resource_id': resourceId});
  }

  @override
  Future<String> signedUrl(String path) async {
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, 120);
    } on StorageException {
      throw const AppError(
        AppErrorKind.forbidden,
        'You do not have access to this file.',
        AppErrorCode.fileNoAccess,
      );
    }
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
