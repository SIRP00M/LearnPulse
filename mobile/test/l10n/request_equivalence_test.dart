import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/formatting.dart';
import 'package:learn_pulse/core/locale_controller.dart';
import 'package:learn_pulse/features/activities/activity.dart';
import 'package:learn_pulse/features/activities/activity_repository.dart';
import 'package:learn_pulse/features/assignments/assignment_repository.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_repository.dart';
import 'package:learn_pulse/features/progress/progress_repository.dart';
import 'package:learn_pulse/features/tasks/task.dart';
import 'package:learn_pulse/features/tasks/task_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'real repository HTTP requests are identical in en, th and ms',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <Map<String, Object?>>[];
      final subscription = server.listen((request) async {
        requests.add({
          'path': request.uri.path,
          'method': request.method,
          'body': jsonDecode(await utf8.decoder.bind(request).join()),
        });
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'id': 'a1', 'items': [], 'version': 1}),
        );
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'public-test-key',
      );
      addTearDown(() async {
        await client.dispose();
        await subscription.cancel();
        await server.close(force: true);
      });
      final locale = LocaleController(InMemoryPreferenceStore());
      addTearDown(locale.dispose);
      final previous = AppFormat.current;
      addTearDown(() => AppFormat.current = previous);
      final from = DateTime(2026, 11, 16);
      final to = DateTime(2026, 11, 23);
      final cursor = {'task_at': '2026-11-17T10:00:00Z', 'id': 'a1'};
      List<Map<String, Object?>>? baseline;
      for (final language in AppLanguage.values) {
        await locale.setLanguage(language);
        AppFormat.current = AppFormat.forLocale(locale.locale!);
        requests.clear();
        final tasks = SupabaseTaskRepository(client);
        await tasks.myTasks(TaskView.range, from: from, to: to, cursor: cursor);
        await tasks.teacherCalendar(from, to, cursor: cursor);
        final activities = SupabaseActivityRepository(client);
        await activities.myActivities(from, to, courseId: 'c1');
        await activities.create(
          courseId: 'c1',
          requestId: 'request',
          title: 'User title',
          description: 'User text',
          policy: ActivityPolicy.values.last,
          weekdays: [1, 3],
          startDate: from,
          deadlineMode: 'time',
          deadlineTime: '18:00',
          timezone: 'Asia/Bangkok',
        );
        await activities.complete(
          activityId: 'a1',
          date: from,
          requestId: 'request',
          expectedVersion: 1,
          note: 'User note',
        );
        await SupabaseProgressRepository(client).mine('c1');
        await SupabaseProgressRepository(client).forStudent('c1', 's1');
        await SupabaseAttendanceRepository(client).mark(
          sessionId: 'session',
          studentId: 's1',
          requestId: 'request',
          expectedVersion: 1,
          status: AttendanceStatus.present,
          note: 'User note',
        );
        await SupabaseAssignmentRepository(
          client,
        ).publishAssignment('assignment', 1);
        expect(requests, hasLength(9));
        if (baseline == null) {
          baseline = List.of(requests);
        } else {
          expect(requests, baseline, reason: language.code);
        }
        final taskBody = requests.first['body'] as Map;
        expect(taskBody['p_from_date'], '2026-11-16');
        expect(taskBody['p_from'], from.toUtc().toIso8601String());
        expect((requests[3]['body'] as Map)['p_timezone'], 'Asia/Bangkok');
      }
    },
  );
}
