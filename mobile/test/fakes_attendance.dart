import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/attendance/attendance.dart';
import 'package:learn_pulse/features/attendance/attendance_repository.dart';

/// In-memory attendance repository that mimics the server contract (versions, PT409, replay by request id).
class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({
    List<AttendanceSession>? sessions,
    List<({String id, String name})>? students,
  }) : sessions = sessions ?? [],
       students = students ?? [(id: 's1', name: 'Student One')];

  final List<AttendanceSession> sessions;
  final List<({String id, String name})> students;
  final records = <String, AttendanceRecord>{}; // key: session|student
  final events = <AttendanceEvent>[];
  final calls = <String>[];
  final seenRequests = <String, String>{}; // request id -> signature
  Object? error; // thrown once by the next mutating call
  Object? loadError;
  String?
  viewerId; // when set, mimics RLS for a student: only their own records
  int _n = 0;

  void _maybeThrow() {
    final e = error;
    if (e != null) {
      error = null;
      throw e;
    }
  }

  /// Scripted scan answer (null = a plain first check-in as present).
  ScanOutcome? scanOutcome;
  final scans = <String>[];

  @override
  Future<ScanOutcome> scan(String token) async {
    scans.add(token);
    _maybeThrow();
    return scanOutcome ??
        ScanOutcome(
          ok: true,
          action: 'in',
          status: AttendanceStatus.present,
          checkedInAt: DateTime.utc(2026, 11, 17, 2),
          title: 'Fake session',
        );
  }

  @override
  Future<List<AttendanceSession>> listSessions(String courseId) async {
    if (loadError != null) throw loadError!;
    return List.of(sessions);
  }

  @override
  Future<AttendanceSession?> getSession(String sessionId) async {
    for (final s in sessions) {
      if (s.id == sessionId) return s;
    }
    return null;
  }

  @override
  Future<List<AttendanceSession>> listSessionsBetween(
    String courseId,
    DateTime from,
    DateTime to,
  ) async {
    if (loadError != null) throw loadError!;
    return [
      for (final s in sessions)
        if (!s.startsAt.isBefore(from.toUtc()) &&
            s.startsAt.isBefore(to.toUtc()))
          s,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<List<AttendanceRecord>> listRecordsForSessions(
    List<String> sessionIds,
  ) async => [
    for (final r in records.values)
      if (sessionIds.contains(r.sessionId) &&
          (viewerId == null || r.studentId == viewerId))
        r,
  ];

  @override
  Future<List<AttendanceRecord>> listRecords(String sessionId) async => [
    for (final r in records.values)
      if (r.sessionId == sessionId) r,
  ];

  @override
  Future<List<AttendanceRecord>> listMyRecords(String courseId) async {
    if (loadError != null) throw loadError!;
    final titles = {for (final s in sessions) s.id: s};
    return [
      for (final r in records.values)
        if (titles[r.sessionId] != null && r.studentId == students.first.id)
          AttendanceRecord(
            sessionId: r.sessionId,
            studentId: r.studentId,
            status: r.status,
            note: r.note,
            version: r.version,
            sessionTitle: titles[r.sessionId]!.title,
            sessionStartsAt: titles[r.sessionId]!.startsAt,
            sessionClosed: titles[r.sessionId]!.closed,
          ),
    ];
  }

  @override
  Future<List<AttendanceEvent>> listEvents(String sessionId) async =>
      events.reversed.toList();

  @override
  Future<AttendanceSummary> summary(String courseId) async {
    if (loadError != null) throw loadError!;
    return AttendanceSummary(
      sessionsTotal: sessions.length,
      sessionsClosed: sessions.where((s) => s.closed).length,
      rows: [for (final st in students) _row(st.id, st.name)],
    );
  }

  AttendanceSummaryRow _row(String id, String name) {
    int count(AttendanceStatus s) =>
        records.values.where((r) => r.studentId == id && r.status == s).length;
    final p = count(AttendanceStatus.present);
    final l = count(AttendanceStatus.late);
    final a = count(AttendanceStatus.absent);
    final denom = p + l + a;
    return AttendanceSummaryRow(
      studentId: id,
      name: name,
      present: p,
      late: l,
      excused: count(AttendanceStatus.excused),
      absent: a,
      rate: denom == 0 ? null : 100.0 * (p + l) / denom,
    );
  }

  @override
  Future<void> createSession({
    required String courseId,
    required String requestId,
    required String title,
    required DateTime startsAt,
  }) async {
    calls.add('create:$title:$requestId');
    _maybeThrow();
    if (seenRequests.containsKey(requestId)) return; // replay
    seenRequests[requestId] = title;
    sessions.add(
      AttendanceSession(
        id: 'x${++_n}',
        courseId: courseId,
        title: title,
        startsAt: startsAt.toUtc(),
        closed: false,
        version: 1,
      ),
    );
  }

  @override
  Future<AttendanceRecord> mark({
    required String sessionId,
    required String studentId,
    required String requestId,
    required int expectedVersion,
    required AttendanceStatus status,
    required String note,
  }) async {
    calls.add('mark:$studentId:${status.wire}:v$expectedVersion:$requestId');
    _maybeThrow();
    final key = '$sessionId|$studentId';
    final existing = records[key];
    if (seenRequests.containsKey(requestId)) return existing!;
    if ((existing?.version ?? 0) != expectedVersion) {
      throw const AppError(AppErrorKind.conflict, 'changed');
    }
    seenRequests[requestId] = key;
    final rec = AttendanceRecord(
      sessionId: sessionId,
      studentId: studentId,
      status: status,
      note: note,
      version: expectedVersion + 1,
    );
    records[key] = rec;
    events.add(
      AttendanceEvent(
        action: existing == null ? 'marked' : 'corrected',
        studentId: studentId,
        oldStatus: existing?.status,
        newStatus: status,
        note: note,
        createdAt: DateTime.utc(2026, 11, 10, 8),
      ),
    );
    return rec;
  }

  @override
  Future<AttendanceSession> close({
    required String sessionId,
    required String requestId,
    required int expectedVersion,
  }) async {
    calls.add('close:$sessionId:$requestId');
    _maybeThrow();
    final i = sessions.indexWhere((s) => s.id == sessionId);
    final s = sessions[i];
    if (s.version != expectedVersion) {
      throw const AppError(AppErrorKind.conflict, 'changed');
    }
    for (final st in students) {
      records.putIfAbsent(
        '$sessionId|${st.id}',
        () => AttendanceRecord(
          sessionId: sessionId,
          studentId: st.id,
          status: AttendanceStatus.absent,
          note: 'Closed without a mark',
          version: 1,
        ),
      );
    }
    return sessions[i] = AttendanceSession(
      id: s.id,
      courseId: s.courseId,
      title: s.title,
      startsAt: s.startsAt,
      closed: true,
      version: s.version + 1,
    );
  }
}

AttendanceSession fakeSession({
  String id = 'a1',
  String title = 'Week 1',
  bool closed = false,
  int version = 1,
  DateTime? startsAt,
}) => AttendanceSession(
  id: id,
  courseId: 'c1',
  title: title,
  startsAt: startsAt ?? DateTime.utc(2026, 11, 10, 6, 30),
  closed: closed,
  version: version,
);
