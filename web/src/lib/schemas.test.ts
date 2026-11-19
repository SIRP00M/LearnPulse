import { describe, expect, it } from 'vitest';
import {
  activityOverview, completionResult, courseRow, myTasks, progress, register, rosterRow, studentDashboard, submissionRow, teacherCalendar, occState,
} from './schemas';

const uuid = '11111111-1111-4111-8111-111111111111';

describe('runtime contracts', () => {
  it('accepts the documented shapes and strips unknown keys', () => {
    const c = courseRow.parse({ id: uuid, owner_id: uuid, title: 'A', description: null, status: 'active', created_at: '2026-11-16T00:00:00Z', owner: { full_name: 'T' }, extra: 1 });
    expect(c).not.toHaveProperty('extra');
    expect(rosterRow.parse({ student_id: uuid, status: 'removed', joined_at: 'x', student: null }).status).toBe('removed');
  });

  it('rejects a response with a missing required field or an unknown enum (contract error, not invented data)', () => {
    expect(courseRow.safeParse({ id: uuid, title: 'A' }).success).toBe(false);
    expect(submissionRow.safeParse({ id: uuid, assignment_id: uuid, student_id: uuid, version: 1, submitted_at: 'x', status: 'weird' }).success).toBe(false);
    expect(occState.safeParse('done').success).toBe(false); // the server vocabulary is the only vocabulary
    expect(studentDashboard.safeParse({ courses_active: 'many' }).success).toBe(false);
  });

  it('retract answers without a version (found against the real backend)', () => {
    expect(completionResult.safeParse({ activity_id: uuid, occurrence_date: '2026-11-16', status: 'retracted' }).success).toBe(true);
  });

  it('activity overview, register, tasks, calendar and progress parse their documented shapes', () => {
    expect(activityOverview.safeParse({ course_id: uuid, activities: [{
      id: uuid, title: 'J', description: '', policy: 'teacher_verified', status: 'active', version: 1, created_at: 'x',
      schedule: { version_no: 1, weekdays: [1, 2], effective_from: '2026-11-16', end_date: null, deadline_mode: 'day_end', deadline_time: null, timezone: 'UTC' },
      today: { date: '2026-11-16', scheduled: true, expected: 2, completed: 0, pending: 1 }, pending_total: 1 }] }).success).toBe(true);
    expect(register.safeParse({ activity_id: uuid, title: 'J', policy: 'teacher_marked', week_start: '2026-11-16', days: [{ date: '2026-11-16', due_at: null }],
      students: [{ student_id: uuid, full_name: 'S', cells: [{ date: '2026-11-16', state: 'open', completion_status: null, version: 0, note: null, reason: null }] }] }).success).toBe(true);
    expect(myTasks.safeParse({ view: 'range', items: [{ kind: 'activity', id: uuid, key2: '2026-11-16', course_id: uuid, title: 'J', status: 'todo' }], next_cursor: null }).success).toBe(true);
    expect(teacherCalendar.safeParse({ items: [], next_cursor: null, pending_verifications: 0 }).success).toBe(true);
    const p = progress.safeParse({ course: { id: uuid, title: 'A' }, student: { id: uuid }, enrollment: { status: 'active' },
      attendance: { sessions_total: 0, sessions_closed: 0, present: 0, late: 0, excused: 0, absent: 0, unmarked: 0, rate: null },
      assignments: { published: 0, done: 0, awaiting_review: 0, graded: 0, needs_revision: 0, not_started: 0, overdue: 0, average_percent: null, items_total: 0 },
      activities: { pending_verification: 0 } });
    expect(p.success).toBe(true);
    if (p.success) expect(p.data.attendance.rate).toBeNull(); // null stays null: no client-invented percentage
  });
});
