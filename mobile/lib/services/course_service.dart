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

/// ข้อมูล Course พร้อมรายชื่อนักเรียนภายใน Course นั้น
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

/// ข้อมูลนักเรียนแบบย่อสำหรับแสดงในหน้า Teacher Students
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

  CourseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  User get _currentUser {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must sign in before accessing courses.',
      );
    }

    return user;
  }

  /// รายวิชาที่ Teacher คนปัจจุบันเป็นเจ้าของ
  Future<List<TeacherCourseSummary>> fetchTeacherCourses() async {
    final user = _currentUser;

    final response = await _client
        .from('courses')
        .select(
          '''
          *,
          profiles!courses_teacher_id_fkey(full_name),
          course_members(count)
          ''',
        )
        .eq('teacher_id', user.id)
        .order('created_at', ascending: false);

    final rows = response as List<dynamic>;

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

  /// รายวิชาที่ Student คนปัจจุบันเข้าร่วม
  Future<List<Course>> fetchStudentCourses() async {
    final user = _currentUser;

    final response = await _client
        .from('course_members')
        .select(
          '''
          course:courses(
            *,
            profiles!courses_teacher_id_fkey(full_name)
          )
          ''',
        )
        .eq('student_id', user.id)
        .order('joined_at', ascending: false);

    final rows = response as List<dynamic>;
    final courses = <Course>[];

    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(
        rawRow as Map,
      );

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

  /// รายชื่อ Course ของ Teacher พร้อมนักเรียนในแต่ละ Course
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
        .order('title', ascending: true);

    final rows = response as List<dynamic>;
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

          final rawStudent = member['student'];

          Map<String, dynamic>? studentProfile;

          if (rawStudent is Map) {
            studentProfile = Map<String, dynamic>.from(
              rawStudent,
            );
          }

          final studentId = (
            studentProfile?['id'] ??
            member['student_id'] ??
            ''
          ).toString();

          if (studentId.isEmpty) {
            continue;
          }

          final fullName =
              studentProfile?['full_name']
                      ?.toString()
                      .trim() ??
                  '';

          final joinedAtText =
              member['joined_at']?.toString().trim() ?? '';

          students.add(
            CourseStudentSummary(
              studentId: studentId,
              fullName: fullName.isEmpty
                  ? 'Unknown student'
                  : fullName,
              joinedAt: DateTime.tryParse(joinedAtText),
            ),
          );
        }
      }

      students.sort(
        (first, second) {
          return first.fullName
              .toLowerCase()
              .compareTo(
                second.fullName.toLowerCase(),
              );
        },
      );

      courses.add(
        TeacherCourseStudents(
          courseId: row['id']?.toString() ?? '',
          courseTitle:
              row['title']?.toString().trim().isNotEmpty ==
                      true
                  ? row['title'].toString().trim()
                  : 'Untitled course',
          courseCode:
              row['course_code']?.toString() ?? '',
          students: students,
        ),
      );
    }

    return courses;
  }

  /// Teacher สร้างรายวิชา
  ///
  /// ไม่ส่ง course_code ไปยัง Supabase
  /// เพราะ PostgreSQL จะสร้างรหัสให้อัตโนมัติจาก DEFAULT
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

          // ไม่ส่ง course_code
          // Backend จะสร้างรหัสให้อัตโนมัติ
        })
        .select(
          '''
          *,
          profiles!courses_teacher_id_fkey(full_name)
          ''',
        )
        .single();

    return Course.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  /// Student เข้าร่วมรายวิชาด้วยรหัส Course
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

    return int.tryParse(
          count?.toString() ?? '',
        ) ??
        0;
  }
}