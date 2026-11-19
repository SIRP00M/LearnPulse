import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import '../activities/activity.dart';
import 'task.dart';

/// Derived task and calendar reads (V9). Windows are at most 62 days, pages at most 400 rows; the cursor continues a page.
abstract class TaskRepository {
  Future<ServerPage<TaskItem>> myTasks(
    TaskView view, {
    DateTime? from,
    DateTime? to,
    int limit,
    Map<String, dynamic>? cursor,
  });

  Future<CalendarPage> teacherCalendar(
    DateTime from,
    DateTime to, {
    int limit,
    Map<String, dynamic>? cursor,
  });
}

class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> _rpc(String fn, Map<String, dynamic> p) async {
    try {
      return Map<String, dynamic>.from(await _client.rpc(fn, params: p) as Map);
    } on PostgrestException catch (e) {
      throw AppError.from(e);
    }
  }

  Map<String, dynamic>? _cursor(Object? v) =>
      v == null ? null : Map<String, dynamic>.from(v as Map);

  @override
  Future<ServerPage<TaskItem>> myTasks(
    TaskView view, {
    DateTime? from,
    DateTime? to,
    int limit = 100,
    Map<String, dynamic>? cursor,
  }) async {
    final j = await _rpc('get_my_tasks', {
      'p_view': view.name,
      'p_from': from?.toUtc().toIso8601String(),
      'p_to': to?.toUtc().toIso8601String(),
      'p_limit': limit,
      'p_cursor': cursor,
      // Activity occurrences are calendar dates: the viewer's local window, sent as dates.
      'p_from_date': from == null ? null : wireDate(from),
      'p_to_date': to == null ? null : wireDate(to),
    });
    return ServerPage([
      for (final r in (j['items'] as List? ?? const []))
        TaskItem.fromJson(Map<String, dynamic>.from(r as Map)),
    ], _cursor(j['next_cursor']));
  }

  @override
  Future<CalendarPage> teacherCalendar(
    DateTime from,
    DateTime to, {
    int limit = 100,
    Map<String, dynamic>? cursor,
  }) async {
    final j = await _rpc('get_teacher_calendar', {
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
      'p_limit': limit,
      'p_cursor': cursor,
      'p_from_date': wireDate(from),
      'p_to_date': wireDate(to),
    });
    return CalendarPage(
      [
        for (final r in (j['items'] as List? ?? const []))
          CalendarItem.fromJson(Map<String, dynamic>.from(r as Map)),
      ],
      _cursor(j['next_cursor']),
      ((j['pending_verifications'] as num?) ?? 0).toInt(),
    );
  }
}
