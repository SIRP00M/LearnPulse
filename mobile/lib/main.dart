import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/formatting.dart';
import 'core/locale_controller.dart';
import 'core/app_config.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'app_services.dart';
import 'features/demo/demo_repository.dart';
import 'features/profile/avatar_repository.dart';
import 'features/staff/staff_repository.dart';
import 'features/activities/activity_repository.dart';
import 'features/assignments/assignment_repository.dart';
import 'features/attendance/attendance_repository.dart';
import 'features/courses/course_repository.dart';
import 'features/dashboard/dashboard_repository.dart';
import 'features/lessons/lesson_repository.dart';
import 'features/progress/progress_repository.dart';
import 'features/tasks/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFormatting();
  final localeController = LocaleController();
  await localeController.load();
  final config = AppConfig.fromEnvironment();
  final problem = config.validate();
  if (problem != null) {
    runApp(ConfigErrorApp(problem: problem, locale: localeController));
    return;
  }
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  final controller = AuthController(
    SupabaseAuthRepository(Supabase.instance.client),
  );
  runApp(
    LearnPulseApp(
      controller: controller,
      services: AppServices(
        courses: SupabaseCourseRepository(Supabase.instance.client),
        assignments: SupabaseAssignmentRepository(Supabase.instance.client),
        lessons: SupabaseLessonRepository(Supabase.instance.client),
        attendance: SupabaseAttendanceRepository(Supabase.instance.client),
        dashboard: SupabaseDashboardRepository(Supabase.instance.client),
        activities: SupabaseActivityRepository(Supabase.instance.client),
        progress: SupabaseProgressRepository(Supabase.instance.client),
        tasks: SupabaseTaskRepository(Supabase.instance.client),
        filePicker: SystemFilePicker(),
        avatars: SupabaseAvatarRepository(Supabase.instance.client),
        staff: SupabaseStaffRepository(Supabase.instance.client),
        demo: SupabaseDemoRepository(Supabase.instance.client),
        prefs: SharedPreferenceStore(),
        locale: localeController,
      ),
    ),
  );
  await controller.start();
}
