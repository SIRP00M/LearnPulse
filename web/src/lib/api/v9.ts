import { rpc } from '../rpc';
import {
  activityOverview, activityCreated, activityMutated, myActivities, register, completionResult, pendingQueue, streaks,
  progress, myTasks, teacherCalendar, type OccurrenceItem, type TaskItem, type CalendarItem, type PendingItem, type Policy,
} from '../schemas';

/** Reads every keyset page (bounded), never silently truncating: returns `capped` when the page budget is hit. */
export async function drain<T>(
  fetchPage: (cursor: unknown) => Promise<{ items: T[]; next_cursor?: unknown }>,
  maxPages = 25,
): Promise<{ items: T[]; capped: boolean }> {
  const items: T[] = [];
  let cursor: unknown = undefined;
  for (let i = 0; i < maxPages; i++) {
    const page = await fetchPage(cursor);
    items.push(...page.items);
    if (page.next_cursor == null) return { items, capped: false };
    cursor = page.next_cursor;
  }
  return { items, capped: true };
}

export interface ScheduleInput {
  weekdays: number[];
  deadlineMode: 'day_end' | 'time' | 'none';
  deadlineTime?: string | null;
  timezone: string;
  endDate?: string | null;
}

export const v9 = {
  // teacher
  createActivity: (a: ScheduleInput & { courseId: string; requestId: string; title: string; description: string; policy: Policy; startDate: string }) =>
    rpc('create_activity', {
      p_course_id: a.courseId, p_request_id: a.requestId, p_title: a.title, p_description: a.description, p_policy: a.policy,
      p_weekdays: a.weekdays, p_start_date: a.startDate, p_end_date: a.endDate ?? undefined, p_deadline_mode: a.deadlineMode,
      p_deadline_time: a.deadlineMode === 'time' ? a.deadlineTime : undefined, p_timezone: a.timezone,
    }, activityCreated),
  updateActivity: (a: { id: string; requestId: string; version: number; title: string; description: string }) =>
    rpc('update_activity', {
      p_activity_id: a.id, p_request_id: a.requestId, p_expected_version: a.version, p_title: a.title, p_description: a.description,
    }, activityMutated),
  addSchedule: (a: ScheduleInput & { id: string; requestId: string; version: number; effectiveFrom: string }) =>
    rpc('add_activity_schedule', {
      p_activity_id: a.id, p_request_id: a.requestId, p_expected_version: a.version, p_weekdays: a.weekdays,
      p_effective_from: a.effectiveFrom, p_end_date: a.endDate ?? undefined, p_deadline_mode: a.deadlineMode,
      p_deadline_time: a.deadlineMode === 'time' ? a.deadlineTime : undefined, p_timezone: a.timezone,
    }, activityMutated),
  setStatus: (a: { id: string; requestId: string; version: number; status: 'active' | 'inactive' | 'archived'; effectiveFrom?: string }) =>
    rpc('set_activity_status', {
      p_activity_id: a.id, p_request_id: a.requestId, p_expected_version: a.version, p_status: a.status, p_effective_from: a.effectiveFrom,
    }, activityMutated),
  mark: (a: { activityId: string; studentId: string; date: string; requestId: string; version: number; result: 'completed' | 'not_done'; note?: string }) =>
    rpc('mark_activity', {
      p_activity_id: a.activityId, p_student_id: a.studentId, p_occurrence_date: a.date, p_request_id: a.requestId,
      p_expected_version: a.version, p_result: a.result, p_note: a.note,
    }, completionResult),
  review: (a: { activityId: string; studentId: string; date: string; requestId: string; version: number; decision: 'approve' | 'reject'; reason?: string }) =>
    rpc('review_activity_completion', {
      p_activity_id: a.activityId, p_student_id: a.studentId, p_occurrence_date: a.date, p_request_id: a.requestId,
      p_expected_version: a.version, p_decision: a.decision, p_reason: a.reason,
    }, completionResult),
  overview: (courseId: string) => rpc('get_activity_overview', { p_course_id: courseId }, activityOverview),
  register: (activityId: string, weekStart: string) => rpc('get_activity_register', { p_activity_id: activityId, p_week_start: weekStart }, register),
  pending: (courseId?: string, cursor?: unknown) =>
    rpc('get_pending_verifications', { p_course_id: courseId, p_limit: 50, p_cursor: cursor }, pendingQueue),
  allPending: (courseId?: string): Promise<{ items: PendingItem[]; capped: boolean }> => drain((c) => v9.pending(courseId, c), 10),
  streaks: (courseId: string, studentId?: string) => rpc('get_activity_streaks', { p_course_id: courseId, p_student_id: studentId }, streaks),
  studentProgress: (courseId: string, studentId: string) => rpc('get_student_progress', { p_course_id: courseId, p_student_id: studentId }, progress),
  teacherCalendar: (from: Date, to: Date, fromDate: string, toDate: string, cursor?: unknown) =>
    rpc('get_teacher_calendar', {
      p_from: from.toISOString(), p_to: to.toISOString(), p_limit: 400, p_cursor: cursor, p_from_date: fromDate, p_to_date: toDate,
    }, teacherCalendar),
  calendarWindow: async (from: Date, to: Date, fromDate: string, toDate: string): Promise<{ items: CalendarItem[]; capped: boolean; pending: number }> => {
    let pending = 0;
    const r = await drain(async (c) => {
      const p = await v9.teacherCalendar(from, to, fromDate, toDate, c);
      pending = p.pending_verifications;
      return p;
    });
    return { ...r, pending };
  },

  // student
  complete: (a: { activityId: string; date: string; requestId: string; version?: number; note?: string }) =>
    rpc('complete_activity', {
      p_activity_id: a.activityId, p_occurrence_date: a.date, p_request_id: a.requestId, p_expected_version: a.version ?? 0, p_note: a.note,
    }, completionResult),
  retract: (a: { activityId: string; date: string; requestId: string; version: number }) =>
    rpc('retract_activity_completion', {
      p_activity_id: a.activityId, p_occurrence_date: a.date, p_request_id: a.requestId, p_expected_version: a.version,
    }, completionResult),
  myActivities: (from: string, to: string, courseId?: string, cursor?: unknown) =>
    rpc('get_my_activities', { p_from: from, p_to: to, p_course_id: courseId, p_limit: 400, p_cursor: cursor }, myActivities),
  myActivitiesWindow: (from: string, to: string, courseId?: string): Promise<{ items: OccurrenceItem[]; capped: boolean }> =>
    drain((c) => v9.myActivities(from, to, courseId, c)),
  myProgress: (courseId: string) => rpc('get_my_progress', { p_course_id: courseId }, progress),
  myTasksPage: (view: 'range' | 'upcoming' | 'overdue' | 'completed', cursor?: unknown, win?: { from: Date; to: Date; fromDate: string; toDate: string }) =>
    rpc('get_my_tasks', {
      p_view: view, p_from: win?.from.toISOString(), p_to: win?.to.toISOString(), p_from_date: win?.fromDate, p_to_date: win?.toDate,
      p_limit: 400, p_cursor: cursor,
    }, myTasks),
  myTasks: (view: 'range' | 'upcoming' | 'overdue' | 'completed', win?: { from: Date; to: Date; fromDate: string; toDate: string }): Promise<{ items: TaskItem[]; capped: boolean }> =>
    drain((c) => v9.myTasksPage(view, c, win)),
};
