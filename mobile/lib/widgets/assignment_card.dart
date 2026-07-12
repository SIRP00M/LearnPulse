import 'package:flutter/material.dart';

import '../models/assignment.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final bool studentView;
  final String? courseName;
  final int? submittedCount;
  final int? totalStudents;
  final VoidCallback? onTap;

  const AssignmentCard({
    required this.assignment,
    this.studentView = false,
    this.courseName,
    this.submittedCount,
    this.totalStudents,
    this.onTap,
    super.key,
  });

  bool get _isDraft => assignment.publishedAt == null;

  bool get _isClosed {
    final dueAt = assignment.dueAt;

    if (dueAt == null) {
      return false;
    }

    return dueAt.isBefore(DateTime.now()) && !assignment.allowLate;
  }

  String get _statusText {
    if (_isDraft) {
      return 'Draft';
    }

    if (_isClosed) {
      return 'Closed';
    }

    return 'Active';
  }

  Color _statusColor(BuildContext context) {
    if (_isDraft) {
      return const Color(0xFFFF9F1C);
    }

    if (_isClosed) {
      return const Color(0xFF6B7280);
    }

    return Theme.of(context).colorScheme.primary;
  }

  String _formatDueDate(DateTime? dueAt) {
    if (dueAt == null) {
      return 'No deadline';
    }

    final local = dueAt.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String get _submissionText {
    if (studentView) {
      return assignment.dueAt == null
          ? 'No deadline'
          : 'Due ${_formatDueDate(assignment.dueAt)}';
    }

    if (submittedCount != null && totalStudents != null) {
      return '$submittedCount/$totalStudents submitted'
          ' • ${_formatDueDate(assignment.dueAt)}';
    }

    return _formatDueDate(assignment.dueAt);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.assignment_rounded, color: statusColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (courseName != null &&
                        courseName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        courseName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(_submissionText, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment.maxScore.toStringAsFixed(0)} points'
                      '${assignment.allowLate ? ' • Late allowed' : ''}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
