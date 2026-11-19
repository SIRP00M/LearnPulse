import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'activity.dart';

/// Activity access: V9 RPCs only (the tables are read-only for the client and every rule lives on the server).
abstract class ActivityRepository {
  // Teacher
  Future<List<Activity>> overview(String courseId);
  Future<String> create({
    required String courseId,
    required String requestId,
    required String title,
    required String description,
    required ActivityPolicy policy,
    required List<int> weekdays,
    required DateTime startDate,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  });
  Future<void> update({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required String title,
    required String description,
  });
  Future<void> addSchedule({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required List<int> weekdays,
    required DateTime effectiveFrom,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  });
  Future<void> setStatus({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required String status,
    DateTime? effectiveFrom,
  });
  Future<ActivityRegister> register(String activityId, DateTime weekStart);
  Future<void> mark({
    required String activityId,
    required String studentId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    required bool completed,
    String note,
  });
  Future<void> review({
    required String activityId,
    required String studentId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    required bool approve,
    String reason,
  });
  Future<ServerPage<PendingVerification>> pending({
    String? courseId,
    int limit,
    Map<String, dynamic>? cursor,
  });

  // Student (and teacher reading a member)
  Future<ServerPage<ActivityOccurrence>> myActivities(
    DateTime from,
    DateTime to, {
    String? courseId,
    int limit,
    Map<String, dynamic>? cursor,
  });
  Future<void> complete({
    required String activityId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    String note,
  });
  Future<void> retract({
    required String activityId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
  });
  Future<List<ActivityStreak>> streaks(String courseId, {String? studentId});
}

class SupabaseActivityRepository implements ActivityRepository {
  SupabaseActivityRepository(this._client);

  final SupabaseClient _client;

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

  List<Map<String, dynamic>> _rows(Object? v) => [
    for (final r in (v as List? ?? const []))
      Map<String, dynamic>.from(r as Map),
  ];

  @override
  Future<List<Activity>> overview(String courseId) async {
    final j = await _rpc('get_activity_overview', {'p_course_id': courseId});
    return [for (final r in _rows(j['activities'])) Activity.fromJson(r)];
  }

  @override
  Future<String> create({
    required String courseId,
    required String requestId,
    required String title,
    required String description,
    required ActivityPolicy policy,
    required List<int> weekdays,
    required DateTime startDate,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  }) async {
    final j = await _rpc('create_activity', {
      'p_course_id': courseId,
      'p_request_id': requestId,
      'p_title': title,
      'p_description': description,
      'p_policy': policy.wire,
      'p_weekdays': weekdays,
      'p_start_date': wireDate(startDate),
      'p_end_date': endDate == null ? null : wireDate(endDate),
      'p_deadline_mode': deadlineMode,
      'p_deadline_time': deadlineTime,
      'p_timezone': timezone,
    });
    return j['id'] as String;
  }

  @override
  Future<void> update({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required String title,
    required String description,
  }) async {
    await _rpc('update_activity', {
      'p_activity_id': activityId,
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_title': title,
      'p_description': description,
    });
  }

  @override
  Future<void> addSchedule({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required List<int> weekdays,
    required DateTime effectiveFrom,
    DateTime? endDate,
    required String deadlineMode,
    String? deadlineTime,
    required String timezone,
  }) async {
    await _rpc('add_activity_schedule', {
      'p_activity_id': activityId,
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_weekdays': weekdays,
      'p_effective_from': wireDate(effectiveFrom),
      'p_end_date': endDate == null ? null : wireDate(endDate),
      'p_deadline_mode': deadlineMode,
      'p_deadline_time': deadlineTime,
      'p_timezone': timezone,
    });
  }

  @override
  Future<void> setStatus({
    required String activityId,
    required String requestId,
    required int expectedVersion,
    required String status,
    DateTime? effectiveFrom,
  }) async {
    await _rpc('set_activity_status', {
      'p_activity_id': activityId,
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_status': status,
      'p_effective_from': effectiveFrom == null
          ? null
          : wireDate(effectiveFrom),
    });
  }

  @override
  Future<ActivityRegister> register(
    String activityId,
    DateTime weekStart,
  ) async => ActivityRegister.fromJson(
    await _rpc('get_activity_register', {
      'p_activity_id': activityId,
      'p_week_start': wireDate(weekStart),
    }),
  );

  @override
  Future<void> mark({
    required String activityId,
    required String studentId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    required bool completed,
    String note = '',
  }) async {
    await _rpc('mark_activity', {
      'p_activity_id': activityId,
      'p_student_id': studentId,
      'p_occurrence_date': wireDate(date),
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_result': completed ? 'completed' : 'not_done',
      'p_note': note,
    });
  }

  @override
  Future<void> review({
    required String activityId,
    required String studentId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    required bool approve,
    String reason = '',
  }) async {
    await _rpc('review_activity_completion', {
      'p_activity_id': activityId,
      'p_student_id': studentId,
      'p_occurrence_date': wireDate(date),
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_decision': approve ? 'approve' : 'reject',
      'p_reason': reason,
    });
  }

  @override
  Future<ServerPage<PendingVerification>> pending({
    String? courseId,
    int limit = 50,
    Map<String, dynamic>? cursor,
  }) async {
    final j = await _rpc('get_pending_verifications', {
      'p_course_id': courseId,
      'p_limit': limit,
      'p_cursor': cursor,
    });
    return ServerPage(
      [for (final r in _rows(j['items'])) PendingVerification.fromJson(r)],
      j['next_cursor'] == null
          ? null
          : Map<String, dynamic>.from(j['next_cursor'] as Map),
      total: (j['total'] as num?)?.toInt(),
    );
  }

  @override
  Future<ServerPage<ActivityOccurrence>> myActivities(
    DateTime from,
    DateTime to, {
    String? courseId,
    int limit = 200,
    Map<String, dynamic>? cursor,
  }) async {
    final j = await _rpc('get_my_activities', {
      'p_from': wireDate(from),
      'p_to': wireDate(to),
      'p_course_id': courseId,
      'p_limit': limit,
      'p_cursor': cursor,
    });
    return ServerPage(
      [for (final r in _rows(j['items'])) ActivityOccurrence.fromJson(r)],
      j['next_cursor'] == null
          ? null
          : Map<String, dynamic>.from(j['next_cursor'] as Map),
    );
  }

  @override
  Future<void> complete({
    required String activityId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
    String note = '',
  }) async {
    await _rpc('complete_activity', {
      'p_activity_id': activityId,
      'p_occurrence_date': wireDate(date),
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
      'p_note': note,
    });
  }

  @override
  Future<void> retract({
    required String activityId,
    required DateTime date,
    required String requestId,
    required int expectedVersion,
  }) async {
    await _rpc('retract_activity_completion', {
      'p_activity_id': activityId,
      'p_occurrence_date': wireDate(date),
      'p_request_id': requestId,
      'p_expected_version': expectedVersion,
    });
  }

  @override
  Future<List<ActivityStreak>> streaks(
    String courseId, {
    String? studentId,
  }) async {
    final j = await _rpc('get_activity_streaks', {
      'p_course_id': courseId,
      'p_student_id': studentId,
    });
    return [for (final r in _rows(j['activities'])) ActivityStreak.fromJson(r)];
  }
}
