import 'l10n_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/core/academic.dart';
import 'package:learn_pulse/core/theme.dart';
import 'package:learn_pulse/features/assignments/student_assignment_pages.dart';
import 'package:learn_pulse/features/assignments/teacher_assignment_pages.dart';
import 'package:learn_pulse/features/attendance/attendance_pages.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/courses/course.dart';
import 'package:learn_pulse/features/courses/courses_page.dart';
import '../tool/studio_preview.dart' show createPreviewRoutes;
import 'fakes.dart';
import 'ui_test_helpers.dart';

void main() {
  for (final route in ['student', 'teacher']) {
    testWidgets('$route service tiles open real course-scoped workflows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final routes = await createPreviewRoutes(onDispose: addTearDown);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          theme: buildTheme(Brightness.light),
          home: Builder(builder: routes['/$route']!),
        ),
      );
      await tester.pumpAndSettle();
      final assignments = find.descendant(
        of: find.byType(AcademicServices),
        matching: find.text(route == 'teacher' ? 'Grading' : 'Assignments'),
      );
      await reveal(tester, assignments);
      await tester.tap(assignments);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<CourseArea>>(
              find.byType(DropdownButtonFormField<CourseArea>),
            )
            .initialValue,
        CourseArea.assignments,
      );
      await reveal(tester, find.text('Algebra'));
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
      expect(
        find.byType(
          route == 'teacher'
              ? TeacherAssignmentsSection
              : StudentAssignmentsSection,
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      // Changing the course service remains synchronized with the home shortcut.
      await reveal(tester, find.byType(DropdownButtonFormField<CourseArea>));
      await tester.tap(find.byType(DropdownButtonFormField<CourseArea>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attendance').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Algebra'));
      await tester.tap(find.text('Algebra'));
      await tester.pumpAndSettle();
      expect(
        find.byType(
          route == 'teacher'
              ? TeacherAttendanceSection
              : StudentAttendanceSection,
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      await reveal(tester, assignments);
      await tester.tap(assignments);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<CourseArea>>(
              find.byType(DropdownButtonFormField<CourseArea>),
            )
            .initialValue,
        CourseArea.assignments,
      );
      await tester.tap(find.byTooltip('Open profile'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-name')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'course status filters use actual course data and preserve empty-state recovery',
    (tester) async {
      final services = fakeServices(
        courses: FakeCourseRepository(
          courses: [
            fakeCourse(title: 'Current course'),
            fakeCourse(
              id: 'c2',
              title: 'Past course',
              status: CourseStatus.archived,
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: l10nDelegates,
          supportedLocales: l10nLocales,
          home: Scaffold(
            body: CoursesPage(
              profile: const Profile(role: AppRole.student, fullName: 'Sam'),
              services: services,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Active'));
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.text('Current course'), findsOneWidget);
      expect(find.text('Past course'), findsNothing);
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();
      expect(find.text('Current course'), findsNothing);
      expect(find.text('Past course'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'portal hero and status pairs retain readable contrast in both modes',
    () {
      for (final brightness in Brightness.values) {
        final s = buildTheme(brightness).colorScheme;
        for (final pair in [
          (s.secondary, s.onSecondary),
          (
            Color.alphaBlend(s.onSecondary.withValues(alpha: .12), s.secondary),
            s.onSecondary,
          ),
        ]) {
          final a = pair.$1.computeLuminance(), b = pair.$2.computeLuminance();
          expect(
            ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    },
  );
}
