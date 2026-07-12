class Course {
  final String id;
  final String teacherId;
  final String title;
  final String courseCode;
  final String description;
  final String overview;
  final String? coverUrl;
  final String status;
  final String teacherName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Course({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.courseCode,
    required this.description,
    required this.overview,
    required this.coverUrl,
    required this.status,
    required this.teacherName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    final teacher = _readRelatedProfile(
      map['teacher'] ?? map['profiles'],
    );

    return Course(
      id: _readString(map['id']),
      teacherId: _readString(map['teacher_id']),
      title: _readString(
        map['title'],
        fallback: 'Untitled course',
      ),
      courseCode: _readString(map['course_code']),
      description: _readString(map['description']),
      overview: _readString(map['overview']),
      coverUrl: _readNullableString(map['cover_url']),
      status: _readString(
        map['status'],
        fallback: 'draft',
      ),
      teacherName: _readString(
        teacher?['full_name'],
      ),
      createdAt: _readDateTime(map['created_at']),
      updatedAt: _readDateTime(map['updated_at']),
    );
  }

  Course copyWith({
    String? id,
    String? teacherId,
    String? title,
    String? courseCode,
    String? description,
    String? overview,
    String? coverUrl,
    bool clearCoverUrl = false,
    String? status,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      courseCode: courseCode ?? this.courseCode,
      description: description ?? this.description,
      overview: overview ?? this.overview,
      coverUrl: clearCoverUrl ? null : coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Map<String, dynamic>? _readRelatedProfile(
    dynamic rawValue,
  ) {
    if (rawValue is Map) {
      return Map<String, dynamic>.from(rawValue);
    }

    // เผื่อ Supabase คืน relation เป็น List
    if (rawValue is List && rawValue.isNotEmpty) {
      final first = rawValue.first;

      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static DateTime? _readDateTime(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}