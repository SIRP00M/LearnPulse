import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment.dart';
import '../models/course_file.dart';
import '../models/course_post.dart';
import '../models/lesson.dart';

class StudentCourseService {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<CoursePost>> getPosts(String courseId) async {
    final data = await _supabase
        .from('course_posts')
        .select()
        .eq('course_id', courseId)
        .not('published_at', 'is', null)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => CoursePost.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Lesson>> getLessons(String courseId) async {
    final data = await _supabase
        .from('lessons')
        .select()
        .eq('course_id', courseId)
        .not('published_at', 'is', null)
        .order('position');

    return (data as List<dynamic>)
        .map((item) => Lesson.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    final data = await _supabase
        .from('assignments')
        .select()
        .eq('course_id', courseId)
        .not('published_at', 'is', null)
        .order('due_at');

    return (data as List<dynamic>)
        .map((item) => Assignment.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CourseFile>> getFiles(String courseId) async {
    final data = await _supabase
        .from('course_files')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((item) => CourseFile.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> createFileDownloadUrl(String storagePath) async {
    return _supabase.storage
        .from('course-files')
        .createSignedUrl(storagePath, 60 * 10);
  }
}
