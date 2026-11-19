enum CourseStatus { active, archived }

CourseStatus? _status(Object? v) => switch (v) {
  'active' => CourseStatus.active,
  'archived' => CourseStatus.archived,
  _ => null,
};

/// A course as the server shows it to the signed-in user (never carries the join code).
class Course {
  const Course({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.status,
    required this.teacherName,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final CourseStatus status;
  final String teacherName;
  final DateTime createdAt;

  bool get archived => status == CourseStatus.archived;

  static Course? fromRow(Map<String, dynamic> row) {
    final status = _status(row['status']);
    final id = row['id'];
    final title = row['title'];
    if (status == null || id is! String || title is! String) return null;
    final owner = row['owner'];
    return Course(
      id: id,
      ownerId: (row['owner_id'] as String?) ?? '',
      title: title,
      description: (row['description'] as String?) ?? '',
      status: status,
      teacherName: owner is Map ? ((owner['full_name'] as String?) ?? '') : '',
      createdAt:
          DateTime.tryParse((row['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class NewCourse {
  const NewCourse({
    required this.id,
    required this.title,
    required this.joinCode,
  });
  final String id;
  final String title;
  final String joinCode;
}

enum JoinOutcome { joined, invalidCode, removed }

class JoinResult {
  const JoinResult(this.outcome, {this.title});
  final JoinOutcome outcome;
  final String? title;

  static JoinResult fromJson(Map<String, dynamic> json) {
    if (json['joined'] == true) {
      return JoinResult(JoinOutcome.joined, title: json['title'] as String?);
    }
    return JoinResult(
      json['reason'] == 'removed'
          ? JoinOutcome.removed
          : JoinOutcome.invalidCode,
    );
  }
}

/// One roster row. [name] is null when the server hides the profile (removed students).
class RosterEntry {
  const RosterEntry({
    required this.studentId,
    required this.name,
    required this.active,
    required this.joinedAt,
  });

  final String studentId;
  final String? name;
  final bool active;
  final DateTime joinedAt;

  static RosterEntry? fromRow(Map<String, dynamic> row) {
    final id = row['student_id'];
    if (id is! String) return null;
    final student = row['student'];
    return RosterEntry(
      studentId: id,
      name: student is Map ? student['full_name'] as String? : null,
      active: row['status'] == 'active',
      joinedAt:
          DateTime.tryParse((row['joined_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
