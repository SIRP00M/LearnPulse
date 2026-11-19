import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../l10n/app_localizations.dart';

import '../../core/app_error.dart';
import '../../core/academic.dart';
import '../../core/theme.dart';
import '../../core/states.dart';
import '../../core/ui.dart';
import 'course.dart';

/// Full-page loading-failed state (framed, with the right recovery action for the failure).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry});

  final AppError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      ErrorPanel(error: error, onRetry: onRetry);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    this.action,
  });

  final IconData icon;
  final String title;
  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) => EmptyPanel(
    icon: icon,
    title: title,
    message: hint,
    action: action,
    full: true,
  );
}

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.teacherView,
    required this.onTap,
  });

  final Course course;
  final bool teacherView;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subtitle = teacherView
        ? l.courseTapToManage
        : (course.teacherName.isEmpty
              ? l.roleTeacher
              : l.courseTeacherName(course.teacherName));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 1,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Same course, same pastel on every device.
                    AcademicIcon(
                      Icons.menu_book_outlined,
                      category: course.title.codeUnits.fold<int>(
                        0,
                        (a, c) => a + c,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        teacherView
                            ? l.courseTeachingCourse
                            : l.courseEnrolledCourse,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    if (course.archived)
                      StatusPill(
                        l.commonArchived,
                        icon: Icons.archive_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: Space.md),
                ScaleCap(
                  max: 2,
                  child: Text(course.title, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  course.description.isEmpty
                      ? (teacherView
                            ? l.courseTeachingWorkspace
                            : l.courseLearningWorkspace)
                      : course.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    Icon(
                      teacherView ? Icons.edit_outlined : Icons.person_outline,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(subtitle, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: Text(teacherView ? l.courseManage : l.courseOpen),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Locale-aware (uses the app's current language); the instant itself is unchanged.
/// Pass [f] (from `AppFormat.of(context)`) so the widget repaints on a language change.
String formatDate(DateTime d, {AppFormat? f}) =>
    (f ?? AppFormat.current).date(d.toLocal());

String formatDateTime(DateTime d, {AppFormat? f}) =>
    (f ?? AppFormat.current).dateTime(d.toLocal());
