import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_pulse/app_services.dart';
import 'package:learn_pulse/core/paged_controller.dart';
import 'package:learn_pulse/core/app_error.dart';
import 'package:learn_pulse/features/activities/activity.dart';
import 'package:learn_pulse/features/activities/activity_controllers.dart';
import 'package:learn_pulse/features/assignments/assignment.dart';
import 'package:learn_pulse/features/dashboard/dashboard_controller.dart';
import 'package:learn_pulse/features/dashboard/summary_bus.dart';
import 'package:learn_pulse/features/tasks/task.dart';
import 'package:learn_pulse/features/tasks/tasks_controller.dart';

import 'fakes.dart';

// Fixed "server clock": Wednesday 16 Jan 2030, 10:00.
final _now = DateTime(2030, 1, 16, 10);
DateTime _clock() => _now;
final _today = DateTime(2030, 1, 16);

class _World {
  _World() {
    activities = FakeActivityRepository(now: _clock);
    assignments = FakeAssignmentRepository(
      assignments: [
        fakeAssignment(
          id: 'a-late',
          title: 'Past due',
          dueAt: DateTime(2030, 1, 10),
        ),
        fakeAssignment(
          id: 'a-soon',
          title: 'Soon',
          dueAt: DateTime(2030, 1, 18, 12),
        ),
        fakeAssignment(id: 'a-open', title: 'Open', dueAt: null),
      ],
    );
    attendance = FakeAttendanceRepository(sessions: [fakeSession()]);
    services = fakeServices(
      assignments: assignments,
      attendance: attendance,
      activities: activities,
      summaries: bus,
    );
    self = _add('Reading', ActivityPolicy.selfReported);
    verified = _add('Journal', ActivityPolicy.teacherVerified);
    marked = _add('Lab prep', ActivityPolicy.teacherMarked);
  }

  late final FakeActivityRepository activities;
  late final FakeAssignmentRepository assignments;
  late final FakeAttendanceRepository attendance;
  late final AppServices services;
  final bus = SummaryBus();
  late final FakeActivity self, verified, marked;

  FakeActivity _add(String title, ActivityPolicy p) {
    final a = FakeActivity(
      id: 'act-${title.toLowerCase().replaceAll(' ', '-')}',
      courseId: 'c1',
      title: title,
      policy: p,
      schedules: [
        FakeSchedule(
          effectiveFrom: DateTime(2030, 1, 1),
          weekdays: const [1, 2, 3, 4, 5, 6, 7],
        ),
      ],
    );
    activities.activities.add(a);
    return a;
  }

  ActivityActions actions() => ActivityActions(activities, summaries: bus);

  Future<ActivityOccurrence> today(FakeActivity a) async {
    final page = await activities.myActivities(_today, _today, courseId: 'c1');
    return page.items.firstWhere((o) => o.activityId == a.id);
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

class _Numbers extends PagedController<int> {
  _Numbers() : super(topic: SummaryTopic.tasks);
  final count = 7;
  final size = 3;
  int fetches = 0;
  Completer<void>? gate;

  @override
  Future<ServerPage<int>> fetch(Map<String, dynamic>? cursor) async {
    fetches++;
    final start = cursor == null ? 0 : cursor['n'] as int;
    final snapshot = [
      for (var i = start; i < count && i < start + size; i++) i,
    ];
    await gate?.future;
    return ServerPage(
      snapshot,
      start + size < count ? {'n': start + size} : null,
    );
  }
}

void main() {
  group('policies and mutations', () {
    test(
      'self-reported: the student completes; the topics are invalidated after the server confirms',
      () async {
        final w = _World();
        final topics = <Set<SummaryTopic>>[];
        w.bus.addListener(() => topics.add(w.bus.lastTopics));
        final actions = w.actions();
        expect(await actions.complete(await w.today(w.self)), isTrue);
        expect((await w.today(w.self)).state, OccurrenceState.completed);
        expect(topics.single, {
          SummaryTopic.activities,
          SummaryTopic.progress,
          SummaryTopic.tasks,
        });
      },
    );

    test(
      'teacher-marked: a student cannot complete it (403) and nothing is invalidated',
      () async {
        final w = _World();
        final actions = w.actions();
        expect(await actions.complete(await w.today(w.marked)), isFalse);
        expect(actions.error?.kind, AppErrorKind.forbidden);
        expect(w.bus.revision, 0);
      },
    );

    test(
      'teacher-verified: submit -> pending -> reject with reason -> resubmit -> approve',
      () async {
        final w = _World();
        final actions = w.actions();
        expect(
          await actions.complete(await w.today(w.verified), note: 'did it'),
          isTrue,
        );
        var o = await w.today(w.verified);
        expect(o.state, OccurrenceState.pending);
        var q = await w.activities.pending();
        expect(q.total, 1);
        // Rejection needs a reason (server rule) and leaves the item resubmittable before the deadline.
        expect(
          await actions.review(q.items.single, approve: false, reason: ''),
          isFalse,
        );
        expect(actions.error?.kind, AppErrorKind.validation);
        expect(
          await actions.review(
            q.items.single,
            approve: false,
            reason: 'Add detail',
          ),
          isTrue,
        );
        o = await w.today(w.verified);
        expect(o.state, OccurrenceState.rejected);
        expect(o.reason, 'Add detail');
        expect(o.canComplete, isTrue);
        expect(await actions.complete(o, note: 'more detail'), isTrue);
        q = await w.activities.pending();
        expect(await actions.review(q.items.single, approve: true), isTrue);
        expect((await w.today(w.verified)).state, OccurrenceState.completed);
        expect((await w.activities.pending()).total, 0);
      },
    );

    test(
      'a failed mutation keeps its idempotency key for the retry and then forgets it',
      () async {
        final w = _World();
        final actions = w.actions();
        final o = await w.today(w.self);
        w.activities.error = const AppError(AppErrorKind.network, 'lost');
        expect(await actions.complete(o), isFalse);
        expect(w.bus.revision, 0);
        expect(await actions.complete(o), isTrue); // same content, same key
        final ids = w.activities.calls
            .where((c) => c.startsWith('complete'))
            .map((c) => c.split(':').last)
            .toList();
        expect(ids.length, 2);
        expect(
          ids.first,
          ids.last,
        ); // the lost-response retry replays the same request id
        expect(w.bus.revision, 1);
      },
    );

    test(
      'the deadline is judged on the server clock: a time-mode occurrence after its time cannot be completed',
      () async {
        final w = _World();
        w.activities.activities.add(
          FakeActivity(
            id: 'act-timed',
            courseId: 'c1',
            title: 'Timed',
            policy: ActivityPolicy.selfReported,
            schedules: [
              FakeSchedule(
                effectiveFrom: DateTime(2030, 1, 1),
                weekdays: const [1, 2, 3, 4, 5, 6, 7],
                mode: 'time',
                time: '09:00',
              ),
            ],
          ),
        );
        final o = (await w.activities.myActivities(
          _today,
          _today,
        )).items.firstWhere((x) => x.activityId == 'act-timed');
        expect(o.state, OccurrenceState.missed);
        final actions = w.actions();
        expect(await actions.complete(o), isFalse);
        expect(actions.error?.kind, AppErrorKind.conflict);
      },
    );

    test(
      'schedule changes are versions: past eligibility and deadlines do not move',
      () async {
        final w = _World();
        final overview = await w.activities.overview('c1');
        final a = overview.firstWhere((x) => x.id == w.self.id);
        final before = w.activities
            .occurrences(w.self, DateTime(2030, 1, 10), DateTime(2030, 1, 16))
            .length;
        final actions = w.actions();
        expect(
          await actions.addSchedule(
            a,
            weekdays: const [1],
            effectiveFrom: _today,
            deadlineMode: 'day_end',
            timezone: 'Asia/Bangkok',
          ),
          isFalse,
        ); // starts today: rejected
        expect(
          await actions.addSchedule(
            a,
            weekdays: const [1],
            effectiveFrom: DateTime(2030, 1, 21),
            deadlineMode: 'day_end',
            timezone: 'Asia/Bangkok',
          ),
          isTrue,
        );
        expect(
          w.activities
              .occurrences(w.self, DateTime(2030, 1, 10), DateTime(2030, 1, 16))
              .length,
          before,
        );
        expect(
          w.activities
              .occurrences(w.self, DateTime(2030, 1, 21), DateTime(2030, 1, 27))
              .length,
          1,
        ); // Mondays only from the change
      },
    );
  });

  group('streaks (server rule mirrored by the fake)', () {
    test(
      'unscheduled days do not break it, a miss does, pending is neutral, today is open',
      () async {
        final w = _World();
        final a = FakeActivity(
          id: 'act-mwf',
          courseId: 'c1',
          title: 'MWF',
          policy: ActivityPolicy.selfReported,
          schedules: [
            FakeSchedule(
              effectiveFrom: DateTime(2030, 1, 1),
              weekdays: const [1, 3, 5],
            ),
          ],
        );
        w.activities.activities.add(a);
        // 2030-01-14 Mon, 01-11 Fri, 01-09 Wed, 01-07 Mon are the scheduled days before today (Wed 01-16 is scheduled, open).
        for (final d in [
          DateTime(2030, 1, 14),
          DateTime(2030, 1, 11),
          DateTime(2030, 1, 7),
        ]) {
          w.activities.completions['act-mwf|s1|${wireDate(d)}'] =
              FakeCompletion('self_reported');
        }
        // Wed 01-09 is missed (no row): the streak is the two completed days after it.
        var s = w.activities.streakOf(a, 's1');
        expect(s.current, 2);
        expect(s.best, 2);
        expect(s.resolved, 6); // Jan 14, 11, 9, 7, 4, 2 (today is still open)
        expect(s.completed, 3);
        // Completing today (open) extends the current streak; weekends in between never mattered.
        w.activities.completions['act-mwf|s1|2030-01-16'] = FakeCompletion(
          'self_reported',
        );
        s = w.activities.streakOf(a, 's1');
        expect(s.current, 3);
        // A pending item is neither credited nor a break.
        w.activities.completions['act-mwf|s1|2030-01-16'] = FakeCompletion(
          'pending',
        );
        s = w.activities.streakOf(a, 's1');
        expect(s.current, 2);
      },
    );

    test('a deadline-free activity has no streak', () async {
      final w = _World();
      w.activities.activities.add(
        FakeActivity(
          id: 'act-none',
          courseId: 'c1',
          title: 'Free',
          policy: ActivityPolicy.selfReported,
          schedules: [
            FakeSchedule(
              effectiveFrom: DateTime(2030, 1, 1),
              weekdays: const [1, 2, 3, 4, 5, 6, 7],
              mode: 'none',
            ),
          ],
        ),
      );
      final s = (await w.activities.streaks(
        'c1',
      )).firstWhere((x) => x.activityId == 'act-none').streak;
      expect(s.current, isNull);
    });
  });

  group('PagedController', () {
    test(
      'loadMore follows the cursor; every row exactly once, nothing truncated',
      () async {
        final c = _Numbers();
        addTearDown(c.dispose);
        await c.load();
        expect(c.items, [0, 1, 2]);
        expect(c.next, isNotNull);
        await c.loadAll();
        expect(c.items, [0, 1, 2, 3, 4, 5, 6]);
        expect(c.next, isNull);
      },
    );

    test(
      'a failed refresh keeps the rows; the next activation retries once',
      () async {
        final w = _World();
        final c = StudentActivitiesController(
          w.activities,
          from: _today,
          to: _today,
          courseId: 'c1',
          bus: w.bus,
        )..active = true;
        addTearDown(c.dispose);
        await c.load();
        final rows = c.items.length;
        w.activities.error = const AppError(
          AppErrorKind.network,
          'No connection.',
        );
        c.deactivate();
        w.bus.invalidate({SummaryTopic.activities});
        await _settle();
        expect(c.stale, isTrue);
        w.activities.error = const AppError(
          AppErrorKind.network,
          'No connection.',
        );
        c.activate();
        await _settle();
        expect(c.items.length, rows); // kept
        expect(c.error, isNotNull);
        expect(c.stale, isTrue); // still stale: retried on the next activation
        c.activate();
        await _settle();
        expect(c.error, isNull);
        expect(c.stale, isFalse);
      },
    );

    test(
      'a topic the controller does not follow is ignored (no request)',
      () async {
        final w = _World();
        final c = StudentActivitiesController(
          w.activities,
          from: _today,
          to: _today,
          courseId: 'c1',
          bus: w.bus,
        );
        addTearDown(c.dispose);
        await c.load();
        final calls = w.activities.calls.length;
        w.bus.invalidate({SummaryTopic.dashboard});
        await _settle();
        expect(w.activities.calls.length, calls);
        w.bus.invalidate({SummaryTopic.activities});
        await _settle();
        expect(w.activities.calls.length, calls + 1);
      },
    );

    test('reset discards the response of the previous view', () async {
      final w = _World();
      final c = StudentActivitiesController(
        w.activities,
        from: DateTime(2030, 1, 14),
        to: DateTime(2030, 1, 14),
        courseId: 'c1',
        bus: w.bus,
      );
      addTearDown(c.dispose);
      final first = c.load();
      c.setWindow(DateTime(2030, 1, 15), DateTime(2030, 1, 15));
      await first;
      await _settle();
      expect(c.items.every((o) => o.date == DateTime(2030, 1, 15)), isTrue);
    });
  });

  group('register', () {
    test(
      'marking updates the cell from the server; week changes drop the previous week',
      () async {
        final w = _World();
        final r = ActivityRegisterController(
          w.activities,
          w.marked.id,
          weekStart: DateTime(2030, 1, 14),
          bus: w.bus,
        );
        addTearDown(r.dispose);
        await r.load();
        expect(r.data!.students.length, 2);
        expect(
          r.data!.students.first.cells.every(
            (c) => c.state != OccurrenceState.completed,
          ),
          isTrue,
        );
        final actions = w.actions();
        expect(
          await actions.mark(
            w.marked.id,
            's1',
            DateTime(2030, 1, 15),
            0,
            completed: true,
          ),
          isTrue,
        );
        await _settle();
        final cell = r.data!.students
            .firstWhere((s) => s.studentId == 's1')
            .cells
            .firstWhere((c) => c.date == DateTime(2030, 1, 15));
        expect(cell.state, OccurrenceState.completed);
        expect(cell.version, 1);
        // Future days cannot be marked (server rule).
        expect(
          await actions.mark(
            w.marked.id,
            's1',
            DateTime(2030, 1, 17),
            0,
            completed: true,
          ),
          isFalse,
        );
        r.shiftWeeks(1);
        await _settle();
        expect(r.weekStart, DateTime(2030, 1, 21));
        expect(
          r.data!.days.every((d) => !d.isBefore(DateTime(2030, 1, 21))),
          isTrue,
        );
      },
    );
  });

  group('tasks and progress share one status vocabulary', () {
    test(
      'assignments and activities get one status each across Tasks and Progress',
      () async {
        final w = _World();
        w.assignments.mine['a-soon'] = fakeSubmission(
          assignmentId: 'a-soon',
          status: SubmissionStatus.returned,
        );
        final tasks = TasksController(
          w.services.tasks,
          mode: TaskMode.overdue,
          focus: _today,
          bus: w.bus,
        );
        addTearDown(tasks.dispose);
        await tasks.load();
        final overdue = {for (final t in tasks.items) t.id: t.status};
        expect(overdue['a-late'], 'overdue');
        final prog = await w.services.progress.mine('c1');
        final byId = {for (final e in prog.assignments.items) e.id: e.status};
        expect(
          byId['a-late'],
          overdue['a-late'],
        ); // same status on both surfaces
        expect(byId['a-soon'], 'needs_revision'); // returned work is not "done"
        expect(prog.assignments.done, 0);
        expect(prog.assignments.overdue, 1);
        expect(prog.assignments.notStarted, 2);
      },
    );

    test(
      'completing an activity updates Tasks and the streak without a manual refresh',
      () async {
        final w = _World();
        final tasks = TasksController(
          w.services.tasks,
          mode: TaskMode.today,
          focus: _today,
          bus: w.bus,
        );
        addTearDown(tasks.dispose);
        await tasks.load();
        TaskItem find() => tasks.items.firstWhere(
          (t) => t.kind == TaskKind.activity && t.id == w.self.id,
        );
        expect(find().status, 'todo');
        final streaks = DashboardController(
          () => w.activities.streaks('c1'),
          bus: w.bus,
          topic: SummaryTopic.activities,
        );
        addTearDown(streaks.dispose);
        await streaks.load();
        expect(
          streaks.data!
              .firstWhere((s) => s.activityId == w.self.id)
              .streak
              .current,
          0,
        );
        expect(await w.actions().complete(await w.today(w.self)), isTrue);
        await _settle();
        expect(find().status, 'done');
        expect(
          streaks.data!
              .firstWhere((s) => s.activityId == w.self.id)
              .streak
              .current,
          1,
        );
      },
    );

    test(
      'submitting an assignment (default topics) refreshes Tasks and Progress',
      () async {
        final w = _World();
        final tasks = TasksController(
          w.services.tasks,
          mode: TaskMode.upcoming,
          focus: _today,
          bus: w.bus,
        );
        final progress = DashboardController(
          () => w.services.progress.mine('c1'),
          bus: w.bus,
          topic: SummaryTopic.progress,
        );
        addTearDown(tasks.dispose);
        addTearDown(progress.dispose);
        await tasks.load();
        await progress.load();
        expect(progress.data!.assignments.done, 0);
        w.assignments.mine['a-soon'] = fakeSubmission(
          assignmentId: 'a-soon',
          status: SubmissionStatus.submitted,
        );
        w.bus
            .invalidate(); // what SubmissionController does after the server confirms
        await _settle();
        expect(progress.data!.assignments.done, 1);
        expect(progress.data!.assignments.awaitingReview, 1);
        expect(
          tasks.items.any((t) => t.id == 'a-soon' && t.status == 'todo'),
          isFalse,
        );
      },
    );

    test(
      'the paged task list never truncates silently: pages join into the whole',
      () async {
        final w = _World();
        for (var i = 0; i < 30; i++) {
          w.assignments.assignments.add(
            fakeAssignment(
              id: 'x$i',
              title: 'W$i',
              dueAt: DateTime(2030, 1, 20 + (i % 3)),
            ),
          );
        }
        final c = TasksController(
          w.services.tasks,
          mode: TaskMode.upcoming,
          focus: _today,
          bus: w.bus,
        );
        addTearDown(c.dispose);
        await c.load();
        await c.loadAll();
        final all = (await w.services.tasks.myTasks(
          TaskView.upcoming,
          limit: 400,
        )).items.length;
        expect(c.items.length, all);
        expect({for (final t in c.items) t.key}.length, all);
      },
    );

    test(
      'a stale response requested before a mutation is not applied to Tasks',
      () async {
        final w = _World();
        final c = TasksController(
          w.services.tasks,
          mode: TaskMode.today,
          focus: _today,
          bus: w.bus,
        );
        addTearDown(c.dispose);
        await c.load();
        expect(
          c.items.where(
            (t) => t.kind == TaskKind.activity && t.status == 'done',
          ),
          isEmpty,
        );
        final reload = c.load(
          showSpinner: false,
        ); // in flight when the mutation lands
        await w.actions().complete(await w.today(w.self));
        await reload;
        await _settle();
        expect(
          c.items.any((t) => t.id == w.self.id && t.status == 'done'),
          isTrue,
        );
      },
    );
  });

  group('teacher calendar', () {
    test(
      'lists assignment due dates and the pending verification workload',
      () async {
        final w = _World();
        await w.actions().complete(await w.today(w.verified));
        final c = TeacherCalendarController(
          w.services.tasks,
          mode: TaskMode.week,
          focus: DateTime(2030, 1, 18),
          bus: w.bus,
        );
        addTearDown(c.dispose);
        await c.load();
        expect(
          c.items.any((i) => i.kind == 'assignment_due' && i.id == 'a-soon'),
          isTrue,
        );
        expect(c.pendingVerifications, 1);
        // Approving removes it from the workload by itself (topic tasks).
        final p = (await w.activities.pending()).items.single;
        await w.actions().review(p, approve: true);
        await _settle();
        expect(c.pendingVerifications, 0);
      },
    );
  });

  group('time windows follow the device calendar', () {
    test(
      'week starts on Monday, month covers the whole month, today is one day',
      () {
        final focus = DateTime(2030, 1, 16);
        expect(rangeFor(TaskMode.week, focus), (
          DateTime(2030, 1, 14),
          DateTime(2030, 1, 21),
        ));
        expect(rangeFor(TaskMode.month, focus), (
          DateTime(2030, 1),
          DateTime(2030, 2),
        ));
        expect(rangeFor(TaskMode.today, focus), (
          DateTime(2030, 1, 16),
          DateTime(2030, 1, 17),
        ));
      },
    );
  });
}
