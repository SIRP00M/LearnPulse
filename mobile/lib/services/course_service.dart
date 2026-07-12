import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course.dart';

class TeacherCourseSummary {
  final Course course;
  final int studentCount;

  const TeacherCourseSummary({
    required this.course,
    required this.studentCount,
  });
}

class TeacherCourseStudents {
  final String courseId;
  final String courseTitle;
  final String courseCode;
  final List<CourseStudentSummary> students;

  const TeacherCourseStudents({
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.students,
  });
}

class CourseStudentSummary {
  final String studentId;
  final String fullName;
  final DateTime? joinedAt;

  const CourseStudentSummary({
    required this.studentId,
    required this.fullName,
    required this.joinedAt,
  });
}

class CourseService {
  final SupabaseClient _client;

  CourseService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  User get _currentUser {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must sign in before accessing courses.',
      );
    }

    return user;
  }

  /// Course ทั้งหมดที่อาจารย์คนปัจจุบันเป็นเจ้าของ
  Future<List<TeacherCourseSummary>> fetchTeacherCourses() async {
    final user = _currentUser;

    final response = await _client
        .from('courses')
        .select(
          '''
          *,
          teacher:profiles!courses_teacher_id_fkey(
            id,
            full_name
          ),
          course_members(count)
          ''',
        )
        .eq('teacher_id', user.id)
        .order(
          'created_at',
          ascending: false,
        );

    final rows = List<dynamic>.from(response);

    return rows.map((rawRow) {
      final row = Map<String, dynamic>.from(
        rawRow as Map,
      );

      return TeacherCourseSummary(
        course: Course.fromMap(row),
        studentCount: _readStudentCount(
          row['course_members'],
        ),
      );
    }).toList();
  }

  /// Course ทั้งหมดที่นักเรียนคนปัจจุบันเข้าร่วม
  Future<List<Course>> fetchStudentCourses() async {
    final user = _currentUser;

    final response = await _client
        .from('course_members')
        .select(
          '''
          joined_at,
          course:courses(
            *,
            teacher:profiles!courses_teacher_id_fkey(
              id,
              full_name
            )
          )
          ''',
        )
        .eq('student_id', user.id)
        .order(
          'joined_at',
          ascending: false,
        );

    final rows = List<dynamic>.from(response);
    final courses = <Course>[];

    for (final rawRow in rows) {
      if (rawRow is! Map) {
        continue;
      }

      final row = Map<String, dynamic>.from(rawRow);
      final rawCourse = row['course'];

      if (rawCourse is Map) {
        courses.add(
          Course.fromMap(
            Map<String, dynamic>.from(rawCourse),
          ),
        );
      }
    }

    return courses;
  }

  /// อาจารย์สร้าง Course
  ///
  /// ไม่ส่ง course_code เพราะ PostgreSQL
  /// เป็นผู้สร้างรหัสห้องให้อัตโนมัติ
  Future<Course> createCourse({
    required String title,
    String description = '',
  }) async {
    final user = _currentUser;

    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'Course title cannot be empty.',
      );
    }

    final response = await _client
        .from('courses')
        .insert({
          'teacher_id': user.id,
          'title': normalizedTitle,
          'description': normalizedDescription,
          'overview': '',
          'status': 'draft',
        })
        .select(
          '''
          *,
          teacher:profiles!courses_teacher_id_fkey(
            id,
            full_name
          )
          ''',
        )
        .single();

    return Course.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// นักเรียนเข้าร่วม Course ด้วยรหัสห้อง
  Future<void> joinCourseByCode(String courseCode) async {
    final normalizedCode = courseCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw ArgumentError(
        'Course code cannot be empty.',
      );
    }

    await _client.rpc(
      'join_course_by_code',
      params: {
        'p_course_code': normalizedCode,
      },
    );
  }

  /// รายชื่อนักเรียน แยกตามแต่ละ Course ของอาจารย์
  Future<List<TeacherCourseStudents>>
      fetchTeacherCourseStudents() async {
    final user = _currentUser;

    final response = await _client
        .from('courses')
        .select(
          '''
          id,
          title,
          course_code,
          course_members(
            student_id,
            joined_at,
            student:profiles!course_members_student_id_fkey(
              id,
              full_name
            )
          )
          ''',
        )
        .eq('teacher_id', user.id)
        .order(
          'title',
          ascending: true,
        );

    final rows = List<dynamic>.from(response);
    final courses = <TeacherCourseStudents>[];

    for (final rawRow in rows) {
      if (rawRow is! Map) {
        continue;
      }

      final row = Map<String, dynamic>.from(rawRow);
      final students = <CourseStudentSummary>[];
      final rawMembers = row['course_members'];

      if (rawMembers is List) {
        for (final rawMember in rawMembers) {
          if (rawMember is! Map) {
            continue;
          }

          final member = Map<String, dynamic>.from(
            rawMember,
          );

          final studentProfile = _readRelatedMap(
            member['student'],
          );

          final studentId = _readString(
            studentProfile?['id'] ??
                member['student_id'],
          );

          if (studentId.isEmpty) {
            continue;
          }

          final fullName = _readString(
            studentProfile?['full_name'],
            fallback: 'Unknown student',
          );

          students.add(
            CourseStudentSummary(
              studentId: studentId,
              fullName: fullName,
              joinedAt: _readDateTime(
                member['joined_at'],
              ),
            ),
          );
        }
      }

      students.sort((first, second) {
        return first.fullName.toLowerCase().compareTo(
              second.fullName.toLowerCase(),
            );
      });

      courses.add(
        TeacherCourseStudents(
          courseId: _readString(row['id']),
          courseTitle: _readString(
            row['title'],
            fallback: 'Untitled course',
          ),
          courseCode: _readString(
            row['course_code'],
          ),
          students: students,
        ),
      );
    }

    return courses;
  }

  int _readStudentCount(dynamic rawMembers) {
    if (rawMembers is! List || rawMembers.isEmpty) {
      return 0;
    }

    final firstItem = rawMembers.first;

    if (firstItem is! Map) {
      return 0;
    }

    final count = firstItem['count'];

    if (count is int) {
      return count;
    }

    if (count is num) {
      return count.toInt();
    }

    return int.tryParse(
          count?.toString() ?? '',
        ) ??
        0;
  }

  Map<String, dynamic>? _readRelatedMap(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;

      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  DateTime? _readDateTime(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}