import 'dart:async';

import 'package:learn_pulse/app_services.dart';
import 'package:learn_pulse/features/demo/demo_repository.dart';
import 'package:learn_pulse/core/locale_controller.dart';
import 'package:learn_pulse/features/dashboard/summary_bus.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/assignments/assignment_repository.dart';
import 'package:learn_pulse/features/auth/auth_repository.dart';
import 'package:learn_pulse/features/auth/profile.dart';
import 'package:learn_pulse/features/courses/course.dart';
import 'package:learn_pulse/features/profile/avatar_repository.dart';
import 'package:learn_pulse/features/staff/staff_repository.dart';
import 'package:learn_pulse/features/courses/course_repository.dart';
import 'fakes_activity.dart';
import 'fakes_attendance.dart';
import 'fakes_dashboard.dart';
import 'fakes_lessons.dart';

export 'fakes_activity.dart';
export 'fakes_attendance.dart';
export 'fakes_dashboard.dart';
export 'fakes_lessons.dart';

/// Scriptable in-memory repository; records calls so tests can assert on them.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.hasSession = false, this.profile});

  @override
  bool hasSession;
  Profile? profile;
  Object? signInError;
  Object? signUpError;
  Object? resendError;
  final List<Object> profileFailures = [];
  bool signUpNeedsConfirmation = true;
  Completer<void>? signInGate;

  final _changes = StreamController<AuthChange>.broadcast();
  final calls = <String>[];

  @override
  Stream<AuthChange> get changes => _changes.stream;

  void emit(AuthChange c) => _changes.add(c);

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    calls.add('signUp:$email:$fullName');
    if (signUpError != null) throw signUpError!;
    return SignUpOutcome(needsConfirmation: signUpNeedsConfirmation);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    await signInGate?.future;
    if (signInError != null) throw signInError!;
    hasSession = true;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    hasSession = false;
    _changes.add(AuthChange.signedOut);
  }

  @override
  Future<void> resendConfirmation(String email) async {
    calls.add('resend:$email');
    if (resendError != null) throw resendError!;
  }

  @override
  Future<void> requestPasswordReset(String email) async =>
      calls.add('reset:$email');

  @override
  Future<void> updatePassword(String newPassword) async =>
      calls.add('updatePassword');

  @override
  String? email = 'fake@example.test';
  Object? updateNameError;

  @override
  Future<void> updateDisplayName(String name) async {
    calls.add('updateName:$name');
    if (updateNameError != null) throw updateNameError!;
  }

  @override
  Future<Profile> loadProfile() async {
    calls.add('loadProfile');
    if (profileFailures.isNotEmpty) throw profileFailures.removeAt(0);
    return profile!;
  }
}

/// In-memory course backend for controller and widget tests.
class FakeCourseRepository implements CourseRepository {
  FakeCourseRepository({List<Course>? courses, List<RosterEntry>? roster})
    : courses = courses ?? [],
      rosterEntries = roster ?? [];

  List<Course> courses;
  List<RosterEntry> rosterEntries;
  final List<Object> listFailures = [];
  Object? createError;
  Object? joinError;
  Object? codeError;
  Object? updateError;
  JoinResult joinResult = const JoinResult(
    JoinOutcome.joined,
    title: 'Algebra',
  );
  String code = 'ABCD2345';
  Completer<void>? gate;
  final calls = <String>[];

  @override
  Future<List<Course>> listCourses() async {
    calls.add('list');
    if (listFailures.isNotEmpty) throw listFailures.removeAt(0);
    return List.of(courses);
  }

  @override
  Future<NewCourse> createCourse({
    required String title,
    String description = '',
  }) async {
    calls.add('create:$title');
    await gate?.future;
    if (createError != null) throw createError!;
    courses = [
      fakeCourse(id: 'c-new', title: title, description: description),
      ...courses,
    ];
    return NewCourse(id: 'c-new', title: title, joinCode: 'NEWCODE2');
  }

  @override
  Future<JoinResult> joinByCode(String code) async {
    calls.add('join:$code');
    await gate?.future;
    if (joinError != null) throw joinError!;
    if (joinResult.outcome == JoinOutcome.joined) {
      courses = [
        fakeCourse(id: 'c-joined', title: joinResult.title ?? 'Course'),
        ...courses,
      ];
    }
    return joinResult;
  }

  @override
  Future<String> joinCode(String courseId) async {
    calls.add('code:$courseId');
    if (codeError != null) throw codeError!;
    return code;
  }

  @override
  Future<void> updateCourse(
    String courseId, {
    String? title,
    String? description,
    CourseStatus? status,
  }) async {
    calls.add('update:$courseId:${title ?? ''}:${status?.name ?? ''}');
    if (updateError != null) throw updateError!;
    courses = [
      for (final c in courses)
        if (c.id == courseId)
          fakeCourse(
            id: c.id,
            title: title ?? c.title,
            description: description ?? c.description,
            status: status ?? c.status,
          )
        else
          c,
    ];
  }

  @override
  Future<List<RosterEntry>> roster(String courseId) async {
    calls.add('roster:$courseId');
    return List.of(rosterEntries);
  }

  @override
  Future<void> removeMember(String courseId, String studentId) async {
    calls.add('remove:$studentId');
    rosterEntries = [
      for (final r in rosterEntries)
        if (r.studentId == studentId)
          RosterEntry(
            studentId: r.studentId,
            name: null,
            active: false,
            joinedAt: r.joinedAt,
          )
        else
          r,
    ];
  }
}

Course fakeCourse({
  String id = 'c1',
  String title = 'Algebra',
  String description = '',
  CourseStatus status = CourseStatus.active,
  String teacher = 'Tia',
}) => Course(
  id: id,
  ownerId: 'owner',
  title: title,
  description: description,
  status: status,
  teacherName: teacher,
  createdAt: DateTime(2030, 1, 1),
);

RosterEntry fakeMember(String id, String name, {bool active = true}) =>
    RosterEntry(
      studentId: id,
      name: name,
      active: active,
      joinedAt: DateTime(2030, 1, 2),
    );

/// In-memory assignment/submission backend for controller and widget tests.
class FakeAssignmentRepository implements AssignmentRepository {
  FakeAssignmentRepository({
    List<Assignment>? assignments,
    Map<String, Submission>? mine,
    List<Submission>? teacherView,
  }) : assignments = assignments ?? [],
       mine = mine ?? {},
       teacherView = teacherView ?? [];

  List<Assignment> assignments;
  Map<String, Submission> mine;
  List<Submission> teacherView;
  final List<Object> submitFailures = [];
  final List<Object> uploadFailures = [];
  final List<Object> listFailures = [];
  Object? prepareError;
  Object? urlError;
  Completer<void>? gate;
  final calls = <String>[];
  final submitRequestIds = <String>[];
  final uploadedPaths = <String>[];
  int prepareCount = 0;

  @override
  Future<List<Assignment>> listAssignments(String courseId) async {
    calls.add('listAssignments');
    if (listFailures.isNotEmpty) throw listFailures.removeAt(0);
    return List.of(assignments);
  }

  @override
  Future<void> createAssignment({
    required String courseId,
    required String title,
    required String instructions,
    required int maxScore,
    DateTime? dueAt,
  }) async {
    calls.add('create:$title:$maxScore');
    assignments = [
      ...assignments,
      fakeAssignment(
        id: 'a-new',
        title: title,
        instructions: instructions,
        maxScore: maxScore,
        dueAt: dueAt,
        published: false,
      ),
    ];
  }

  @override
  Future<void> updateAssignment(
    String assignmentId,
    int expectedVersion, {
    String? title,
    String? instructions,
    int? maxScore,
    DateTime? dueAt,
    bool clearDue = false,
  }) async {
    calls.add('update:$assignmentId:v$expectedVersion');
    assignments = [
      for (final a in assignments)
        if (a.id == assignmentId)
          fakeAssignment(
            id: a.id,
            title: title ?? a.title,
            instructions: instructions ?? a.instructions,
            maxScore: maxScore ?? a.maxScore,
            dueAt: clearDue ? null : (dueAt ?? a.dueAt),
            published: a.published,
            version: a.version + 1,
          )
        else
          a,
    ];
  }

  @override
  Future<void> publishAssignment(
    String assignmentId,
    int expectedVersion,
  ) async {
    calls.add('publish:$assignmentId:v$expectedVersion');
    assignments = [
      for (final a in assignments)
        if (a.id == assignmentId)
          fakeAssignment(
            id: a.id,
            title: a.title,
            instructions: a.instructions,
            maxScore: a.maxScore,
            dueAt: a.dueAt,
            published: true,
            version: a.version + 1,
          )
        else
          a,
    ];
  }

  @override
  Future<List<Submission>> listMySubmissions() async {
    calls.add('listMine');
    return mine.values.toList();
  }

  @override
  Future<List<Submission>> listSubmissions(String assignmentId) async {
    calls.add('listSubmissions');
    return List.of(teacherView);
  }

  @override
  Future<UploadTicket> prepareUpload(
    String assignmentId,
    PickedFile file,
  ) async {
    calls.add('prepare:${file.name}');
    if (prepareError != null) throw prepareError!;
    prepareCount++;
    return UploadTicket(
      uploadId: 'up-$prepareCount',
      path: '$assignmentId/me/up-$prepareCount/${file.name}',
    );
  }

  @override
  Future<void> uploadBytes(UploadTicket ticket, PickedFile file) async {
    calls.add('upload:${ticket.uploadId}');
    if (uploadFailures.isNotEmpty) throw uploadFailures.removeAt(0);
    uploadedPaths.add(ticket.path);
  }

  @override
  Future<Submission> submit({
    required String assignmentId,
    required String requestId,
    required String answer,
    String? uploadId,
    int? expectedVersion,
    bool clearAttachment = false,
  }) async {
    calls.add('submit:${expectedVersion ?? '-'}:${uploadId ?? '-'}');
    submitRequestIds.add(requestId);
    await gate?.future;
    if (submitFailures.isNotEmpty) throw submitFailures.removeAt(0);
    final previous = mine[assignmentId];
    final upload = uploadId != null
        ? UploadInfo(
            id: uploadId,
            fileName: 'file.txt',
            mimeType: 'text/plain',
            sizeBytes: 3,
            path: 'p/$uploadId',
          )
        : (clearAttachment ? null : previous?.upload);
    final saved = Submission(
      id: 's1',
      assignmentId: assignmentId,
      studentId: 'me',
      studentName: 'Me',
      answer: answer,
      version: (expectedVersion ?? 0) + 1,
      submittedAt: DateTime(2030, 1, 1, 12),
      upload: upload,
    );
    mine = {...mine, assignmentId: saved};
    return saved;
  }

  final List<Object> gradeFailures = [];
  final gradeRequestIds = <String>[];
  List<GradeEvent> events = [];

  Submission _withStatus(
    Submission s,
    SubmissionStatus st, {
    int? score,
    String? feedback,
  }) => Submission(
    id: s.id,
    assignmentId: s.assignmentId,
    studentId: s.studentId,
    studentName: s.studentName,
    answer: s.answer,
    version: s.version + 1,
    submittedAt: s.submittedAt,
    upload: s.upload,
    status: st,
    score: score,
    feedback: feedback,
    gradedAt: DateTime(2030, 1, 3),
  );

  @override
  Future<Submission> gradeSubmission({
    required String submissionId,
    required String requestId,
    required int expectedVersion,
    required int score,
    String feedback = '',
  }) async {
    calls.add('grade:$submissionId:v$expectedVersion:$score');
    gradeRequestIds.add(requestId);
    await gate?.future;
    if (gradeFailures.isNotEmpty) throw gradeFailures.removeAt(0);
    final cur = teacherView.firstWhere((s) => s.id == submissionId);
    final next = _withStatus(
      cur,
      SubmissionStatus.graded,
      score: score,
      feedback: feedback.isEmpty ? null : feedback,
    );
    teacherView = [
      for (final s in teacherView) s.id == submissionId ? next : s,
    ];
    events = [
      ...events,
      GradeEvent(
        action: 'graded',
        score: score,
        feedback: feedback,
        versionAfter: next.version,
        createdAt: DateTime(2030, 1, 3),
      ),
    ];
    return next;
  }

  @override
  Future<Submission> returnSubmission({
    required String submissionId,
    required String requestId,
    required int expectedVersion,
    required String feedback,
  }) async {
    calls.add('return:$submissionId:v$expectedVersion');
    gradeRequestIds.add(requestId);
    await gate?.future;
    if (gradeFailures.isNotEmpty) throw gradeFailures.removeAt(0);
    final cur = teacherView.firstWhere((s) => s.id == submissionId);
    final next = _withStatus(
      cur,
      SubmissionStatus.returned,
      feedback: feedback,
    );
    teacherView = [
      for (final s in teacherView) s.id == submissionId ? next : s,
    ];
    events = [
      ...events,
      GradeEvent(
        action: 'returned',
        score: null,
        feedback: feedback,
        versionAfter: next.version,
        createdAt: DateTime(2030, 1, 3),
      ),
    ];
    return next;
  }

  @override
  Future<List<GradeEvent>> listEvents(String submissionId) async {
    calls.add('events');
    return List.of(events);
  }

  @override
  Future<String> signedUrl(String path) async {
    calls.add('sign:$path');
    if (urlError != null) throw urlError!;
    return 'https://example.test/signed/$path';
  }
}

class FakeFilePicker implements FilePickerService {
  PickedFile? next;
  Object? error;
  int calls = 0;

  @override
  Future<PickedFile?> pick() async {
    calls++;
    if (error != null) throw error!;
    return next;
  }
}

Assignment fakeAssignment({
  String id = 'a1',
  String title = 'Essay',
  String instructions = 'Write about it',
  int maxScore = 100,
  DateTime? dueAt,
  bool published = true,
  int version = 1,
}) => Assignment(
  id: id,
  courseId: 'c1',
  title: title,
  instructions: instructions,
  maxScore: maxScore,
  dueAt: dueAt,
  status: published ? AssignmentStatus.published : AssignmentStatus.draft,
  version: version,
);

Submission fakeSubmission({
  String assignmentId = 'a1',
  String answer = 'saved',
  int version = 1,
  UploadInfo? upload,
  String name = 'Sam',
  SubmissionStatus status = SubmissionStatus.submitted,
  int? score,
  String? feedback,
}) => Submission(
  id: 's-$assignmentId',
  assignmentId: assignmentId,
  studentId: 'sid',
  studentName: name,
  answer: answer,
  version: version,
  submittedAt: DateTime(2030, 1, 1, 9),
  upload: upload,
  status: status,
  score: score,
  feedback: feedback,
  gradedAt: status == SubmissionStatus.submitted ? null : DateTime(2030, 1, 2),
);

PickedFile fakeFile({String name = 'notes.txt', int size = 3}) => PickedFile(
  name: name,
  mimeType: mimeForFileName(name) ?? 'text/plain',
  bytes: List.filled(size, 65),
);

AppServices fakeServices({
  FakeCourseRepository? courses,
  FakeAssignmentRepository? assignments,
  FakeFilePicker? picker,
  FakeLessonRepository? lessons,
  FakeAttendanceRepository? attendance,
  FakeDashboardRepository? dashboard,
  FakeActivityRepository? activities,
  FakeProgressRepository? progress,
  FakeTaskRepository? tasks,
  AvatarRepository? avatars,
  StaffRepository? staff,
  DemoRepository? demo,
  SummaryBus? summaries,
  LocaleController? locale,
}) {
  final a = assignments ?? FakeAssignmentRepository();
  final att = attendance ?? FakeAttendanceRepository();
  final act = activities ?? FakeActivityRepository();
  return AppServices(
    courses: courses ?? FakeCourseRepository(),
    assignments: a,
    lessons: lessons ?? FakeLessonRepository(),
    attendance: att,
    dashboard: dashboard ?? FakeDashboardRepository(),
    activities: act,
    progress:
        progress ??
        FakeProgressRepository(
          assignments: a,
          attendance: att,
          activities: act,
        ),
    tasks: tasks ?? FakeTaskRepository(assignments: a, activities: act),
    filePicker: picker ?? FakeFilePicker(),
    avatars: avatars,
    staff: staff,
    demo: demo,
    summaries: summaries,
    locale: locale,
  );
}
