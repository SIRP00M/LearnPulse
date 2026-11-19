import 'package:learn_pulse/features/dashboard/dashboard.dart';
import 'package:learn_pulse/features/dashboard/dashboard_repository.dart';

TeacherDashboard fakeTeacherDashboard({
  int active = 1,
  int archived = 0,
  int students = 3,
  int awaiting = 1,
}) => TeacherDashboard.fromJson({
  'courses_active': active,
  'courses_archived': archived,
  'active_students': students,
  'published_assignments': 2,
  'expected_submissions': 6,
  'received_submissions': 3,
  'awaiting_grading': 1,
  'graded': 2,
  'returned': 0,
  'open_attendance_sessions': 1,
  'attendance_rate': 66.7,
  'upcoming_deadlines': [
    {
      'title': 'Essay',
      'course_title': 'Algebra',
      'due_at': '2026-11-13T06:00:00+00:00',
      'received': 2,
      'expected': 3,
    },
  ],
  'recent_activity': [
    {
      'student_name': 'Sam',
      'assignment_title': 'Essay',
      'course_title': 'Algebra',
      'status': 'submitted',
      'at': '2026-11-10T06:00:00+00:00',
    },
  ],
  'courses': [
    {
      'course_id': 'c1',
      'title': 'Algebra',
      'status': 'active',
      'students': students,
      'assignments': 2,
      'awaiting_grading': awaiting,
      'attendance_sessions': 1,
    },
  ],
});

StudentDashboard fakeStudentDashboard({bool empty = false}) =>
    StudentDashboard.fromJson(
      empty
          ? {'courses': []}
          : {
              'courses_active': 1,
              'published_assignments': 2,
              'done': 1,
              'awaiting_grade': 1,
              'graded': 0,
              'needs_revision': 0,
              'not_started': 1,
              'overdue': 1,
              'average_percent': null,
              'attendance_rate': 100.0,
              'upcoming_deadlines': [
                {
                  'title': 'Essay',
                  'course_title': 'Algebra',
                  'due_at': '2026-11-13T06:00:00+00:00',
                  'status': 'returned',
                },
              ],
              'recent_graded': [
                {
                  'title': 'Quiz',
                  'course_title': 'Algebra',
                  'score': 80,
                  'max_score': 100,
                  'has_feedback': true,
                },
              ],
              'recent_lessons': [],
              'courses': [
                {
                  'title': 'Algebra',
                  'status': 'active',
                  'teacher_name': 'Ms T',
                  'assignments': 2,
                  'done': 1,
                  'progress_percent': 50.0,
                  'attendance_rate': 100.0,
                },
              ],
            },
    );

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({
    TeacherDashboard? teacher,
    StudentDashboard? student,
  }) : teacherData = teacher ?? fakeTeacherDashboard(),
       studentData = student ?? fakeStudentDashboard();

  TeacherDashboard teacherData;
  StudentDashboard studentData;
  Object? error; // thrown by the next call
  int calls = 0;

  void _maybeThrow() {
    calls++;
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
  }

  @override
  Future<TeacherDashboard> teacher() async {
    _maybeThrow();
    return teacherData;
  }

  @override
  Future<StudentDashboard> student() async {
    _maybeThrow();
    return studentData;
  }
}
