import 'package:flutter/material.dart';

import '../models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final bool teacherView;
  final int? studentCount;
  final double? progress;

  const CourseCard({
    required this.course,
    this.onTap,
    this.teacherView = true,
    this.studentCount,
    this.progress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressValue = progress?.clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CourseThumbnail(course: course),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (course.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (progressValue != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                minHeight: 7,
                                backgroundColor: colorScheme.primaryContainer,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(progressValue * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      _StatusChip(status: course.status),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (teacherView) {
      final countText = studentCount == null
          ? 'Students not loaded'
          : '$studentCount students';

      return '${course.courseCode} • $countText';
    }

    final teacherName = course.teacherName.trim().isEmpty
        ? 'Unknown teacher'
        : course.teacherName;

    return '${course.courseCode} • $teacherName';
  }
}

class _CourseThumbnail extends StatelessWidget {
  final Course course;

  const _CourseThumbnail({required this.course});

  @override
  Widget build(BuildContext context) {
    if (course.coverUrl != null && course.coverUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          course.coverUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _placeholder(context);
          },
        ),
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(_getCourseIcon(course.title), color: colorScheme.primary),
    );
  }

  IconData _getCourseIcon(String title) {
    final normalized = title.toLowerCase();

    if (normalized.contains('computer') ||
        normalized.contains('program') ||
        normalized.contains('flutter') ||
        normalized.contains('mobile')) {
      return Icons.memory_rounded;
    }

    if (normalized.contains('language') ||
        normalized.contains('japanese') ||
        normalized.contains('english')) {
      return Icons.translate_rounded;
    }

    if (normalized.contains('ai') ||
        normalized.contains('artificial') ||
        normalized.contains('machine learning')) {
      return Icons.smart_toy_rounded;
    }

    if (normalized.contains('math')) {
      return Icons.calculate_rounded;
    }

    return Icons.menu_book_rounded;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isPublished = status == 'published';
    final isArchived = status == 'archived';

    final label = switch (status) {
      'published' => 'Published',
      'archived' => 'Archived',
      _ => 'Draft',
    };

    final backgroundColor = isPublished
        ? colorScheme.primaryContainer
        : isArchived
        ? colorScheme.surfaceContainerHighest
        : colorScheme.secondaryContainer;

    final foregroundColor = isPublished
        ? colorScheme.onPrimaryContainer
        : isArchived
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSecondaryContainer;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
