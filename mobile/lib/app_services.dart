import 'package:flutter/foundation.dart';

import 'core/locale_controller.dart';
import 'features/activities/activity_repository.dart';
import 'features/assignments/assignment_repository.dart';
import 'features/attendance/attendance_repository.dart';
import 'features/courses/course_repository.dart';
import 'features/dashboard/dashboard_repository.dart';
import 'features/demo/demo_repository.dart';
import 'features/dashboard/summary_bus.dart';
import 'features/lessons/lesson_repository.dart';
import 'features/profile/avatar_repository.dart';
import 'features/staff/staff_repository.dart';
import 'features/progress/progress_repository.dart';
import 'features/tasks/task_repository.dart';

/// Everything the UI talks to the backend through; tests pass fakes.
@immutable
class AppServices {
  AppServices({
    required this.courses,
    required this.assignments,
    required this.lessons,
    required this.attendance,
    required this.dashboard,
    required this.activities,
    required this.progress,
    required this.tasks,
    required this.filePicker,
    AvatarRepository? avatars,
    StaffRepository? staff,
    DemoRepository? demo,
    PreferenceStore? prefs,
    SummaryBus? summaries,
    LocaleController? locale,
  }) : avatars = avatars ?? const NoAvatarRepository(),
       staff = staff ?? const NoStaffRepository(),
       demo = demo ?? const NoDemoRepository(),
       prefs = prefs ?? InMemoryPreferenceStore(),
       summaries = summaries ?? SummaryBus(),
       locale = locale ?? LocaleController(InMemoryPreferenceStore());

  final CourseRepository courses;
  final AssignmentRepository assignments;
  final LessonRepository lessons;
  final AttendanceRepository attendance;
  final DashboardRepository dashboard;
  final ActivityRepository activities;
  final ProgressRepository progress;
  final TaskRepository tasks;
  final FilePickerService filePicker;

  /// Profile photos; initials-only where not wired (tests, previews).
  final AvatarRepository avatars;

  /// Teacher/staff attendance (clock in/out, requests, approvals); nobody is staff where not wired.
  final StaffRepository staff;

  /// Live Demo (student join and presenter console); not wired in tests that do not need it.
  final DemoRepository demo;

  /// Device-level preferences (the demo claim nonce lives here, never credentials).
  final PreferenceStore prefs;

  /// Mutating controllers call [SummaryBus.invalidate] after a confirmed success.
  final SummaryBus summaries;

  /// Device language preference (shared_preferences in the app, in-memory in tests).
  final LocaleController locale;
}
