import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/academic.dart';
import '../../core/adaptive.dart';
import '../activities/student_activity_pages.dart';
import '../assignments/student_assignment_pages.dart';
import '../attendance/attendance_pages.dart';
import '../lessons/lessons_pages.dart';
import 'course.dart';

/// Course view for an enrolled student: details plus the published assignments.
class StudentCoursePage extends StatelessWidget {
  const StudentCoursePage({
    super.key,
    required this.course,
    required this.services,
  });

  final Course course;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: StudioPage(
        maxWidth: StudioLayout.maxWorkspace,
        children: [
          AcademicPageHeader(
            eyebrow: l.courseLearningEyebrow,
            icon: Icons.menu_book_outlined,
            title: course.title,
            description: course.description.isEmpty ? null : course.description,
            meta: [
              MetadataRow(
                Icons.person_outline,
                course.teacherName.isEmpty
                    ? l.roleTeacher
                    : l.courseTeacherName(course.teacherName),
              ),
              if (course.archived)
                MetadataRow(Icons.archive_outlined, l.courseArchivedNote),
            ],
          ),
          const SizedBox(height: Space.md),
          StudioColumns(
            primary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudentActivitiesSection(
                  courseId: course.id,
                  courseTitle: course.title,
                  services: services,
                ),
                const SizedBox(height: Space.lg),
                StudentLessonsSection(
                  courseId: course.id,
                  services: services,
                  courseTitle: course.title,
                ),
                const SizedBox(height: Space.lg),
                StudentAssignmentsSection(
                  courseId: course.id,
                  services: services,
                ),
              ],
            ),
            secondary: StudentAttendanceSection(
              courseId: course.id,
              services: services,
            ),
          ),
        ],
      ),
    );
  }
}
