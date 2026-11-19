import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_error.dart';
import 'dashboard.dart';

/// One read-only RPC per role; all aggregation happens on the server under the caller's identity.
abstract class DashboardRepository {
  Future<TeacherDashboard> teacher();
  Future<StudentDashboard> student();
}

class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseDashboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TeacherDashboard> teacher() async =>
      TeacherDashboard.fromJson(await _rpc('get_teacher_dashboard'));

  @override
  Future<StudentDashboard> student() async =>
      StudentDashboard.fromJson(await _rpc('get_student_dashboard'));

  Future<Map<String, dynamic>> _rpc(String fn) async {
    try {
      return Map<String, dynamic>.from(await _client.rpc(fn) as Map);
    } on PostgrestException catch (e) {
      throw AppError.from(e);
    }
  }
}
