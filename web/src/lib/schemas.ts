import { z } from 'zod';

// Zod 4 would try `new Function` to JIT its parsers; the CSP forbids eval, so use the interpreted parsers.
z.config({ jitless: true });

/**
 * Runtime contracts for every server response the Web app consumes (docs/WEB_CONTRACTS_V0_V7.md and
 * docs/WEB_HANDOFF.md). Unknown extra keys are stripped; required keys that go missing fail loudly as a
 * `contract` error instead of rendering invented values.
 */
const id = z.string().min(1);
const ts = z.string();
const num = z.number();
const nnum = z.number().nullish();
const str = z.string();
const nstr = z.string().nullish();

export const roleSchema = z.enum(['student', 'teacher']);
export type Role = z.infer<typeof roleSchema>;
export const profileSchema = z.object({ role: roleSchema, full_name: z.string().nullish(), avatar_path: z.string().nullish() });
export type Profile = { role: Role; fullName: string; avatarPath: string | null };

// ── Courses (V2) ───────────────────────────────────────────────
export const courseStatus = z.enum(['active', 'archived']);
export const courseRow = z.object({
  id, owner_id: id, title: str, description: nstr, status: courseStatus, created_at: ts,
  owner: z.object({ full_name: nstr }).nullish(),
});
export type Course = z.infer<typeof courseRow>;
export const courses = z.array(courseRow);
export const newCourse = z.object({ id, title: str, join_code: str });
export const joinResult = z.object({ joined: z.boolean().optional(), title: nstr, reason: nstr });
export const rosterRow = z.object({
  student_id: id, status: z.enum(['active', 'removed']), joined_at: ts, student: z.object({ full_name: nstr }).nullish(),
});
export type RosterEntry = z.infer<typeof rosterRow>;

// ── Lessons (V5) ───────────────────────────────────────────────
export const lessonRow = z.object({
  id, course_id: id, title: str, body: nstr, status: z.enum(['draft', 'published']), version: num,
});
export type Lesson = z.infer<typeof lessonRow>;
export const resourceRow = z.object({
  id, lesson_id: id, title: nstr, file_name: str, size_bytes: nnum, storage_path: str, status: nstr,
});
export type Resource = z.infer<typeof resourceRow>;
export const resourceTicket = z.object({ resource_id: id, bucket: nstr, path: str });

// ── Assignments (V3/V4) ────────────────────────────────────────
export const assignmentRow = z.object({
  id, course_id: id, title: str, instructions: nstr, max_score: num, due_at: nstr,
  status: z.enum(['draft', 'published']), version: num,
});
export type Assignment = z.infer<typeof assignmentRow>;
export const submissionStatus = z.enum(['submitted', 'graded', 'returned']);
export const uploadRow = z.object({
  id, file_name: str, mime_type: nstr, size_bytes: nnum, storage_path: str,
}).nullish();
export const submissionRow = z.object({
  id, assignment_id: id, student_id: id, answer: nstr, version: num, submitted_at: ts, status: submissionStatus,
  score: nnum, feedback: nstr, graded_at: nstr, upload: uploadRow, student: z.object({ full_name: nstr }).nullish(),
});
export type Submission = z.infer<typeof submissionRow>;
export const submissionEvent = z.object({
  action: str, score: nnum, feedback: nstr, version_after: num, created_at: ts,
});
export type SubmissionEvent = z.infer<typeof submissionEvent>;
export const uploadTicket = z.object({ upload_id: id, path: str });
export const submitResult = z.object({
  submission_id: id, version: num, submitted_at: ts, answer: nstr, replayed: z.boolean().optional(),
});
export const gradeResult = z.object({
  submission_id: id, version: num, status: submissionStatus, score: nnum, feedback: nstr, graded_at: nstr,
});
export const idResult = z.object({ id: id.optional(), version: nnum }).loose();

// ── Attendance (V6) ────────────────────────────────────────────
export const attendanceStatus = z.enum(['present', 'late', 'excused', 'absent']);
export type AttendanceStatus = z.infer<typeof attendanceStatus>;
export const sessionRow = z.object({
  id, course_id: id, title: str, starts_at: ts, status: z.enum(['open', 'closed']), version: num,
  requires_checkout: z.boolean().default(false), late_after_minutes: num.default(10), checkin_opens_minutes: num.default(15), checkin_window_minutes: nnum,
});
export type AttSession = z.infer<typeof sessionRow>;
export const recordRow = z.object({
  session_id: id, student_id: id, status: attendanceStatus, note: nstr, version: num,
  checked_in_at: nstr, checked_out_at: nstr, source: nstr,
  attendance_sessions: z.object({ title: nstr, starts_at: nstr, status: nstr, course_id: nstr }).nullish(),
});
export type AttRecord = z.infer<typeof recordRow>;
export const attEvent = z.object({
  action: str, student_id: nstr, old_status: nstr, new_status: nstr, note: nstr, created_at: ts,
});
export const attendanceSummary = z.object({
  sessions_total: num, sessions_closed: num,
  students: z.array(z.object({
    student_id: id, full_name: nstr, present: num, late: num, excused: num, absent: num, rate: nnum,
  })),
});
export type AttSummary = z.infer<typeof attendanceSummary>;
export const markResult = z.object({ status: attendanceStatus, note: nstr, version: num });
export const closeResult = z.object({ status: nstr, version: num });

// ── Dashboards (V7) ────────────────────────────────────────────
const deadline = z.object({
  title: nstr, course_title: nstr, due_at: nstr, received: nnum, expected: nnum, status: nstr,
});
export type Deadline = z.infer<typeof deadline>;
export const teacherDashboard = z.object({
  courses_active: num, courses_archived: num, active_students: num, published_assignments: num,
  expected_submissions: num, received_submissions: num, awaiting_grading: num, graded: num, returned: num,
  open_attendance_sessions: num, attendance_rate: nnum,
  upcoming_deadlines: z.array(deadline).default([]),
  recent_activity: z.array(z.object({
    student_name: nstr, assignment_title: nstr, course_title: nstr, status: nstr, at: nstr,
  })).default([]),
  courses: z.array(z.object({
    course_id: id, title: str, status: nstr, students: num, assignments: num, awaiting_grading: num, attendance_sessions: num,
  })).default([]),
});
export type TeacherDashboard = z.infer<typeof teacherDashboard>;
export const studentDashboard = z.object({
  courses_active: num, published_assignments: num, done: num, awaiting_grade: num, graded: num,
  needs_revision: num, not_started: num, overdue: num, average_percent: nnum, attendance_rate: nnum,
  upcoming_deadlines: z.array(deadline).default([]),
  recent_graded: z.array(z.object({
    title: nstr, course_title: nstr, score: nnum, max_score: nnum, has_feedback: z.boolean().nullish(),
  })).default([]),
  recent_lessons: z.array(z.object({ title: nstr, course_title: nstr, published_at: nstr })).default([]),
  courses: z.array(z.object({
    title: str, teacher_name: nstr, status: nstr, assignments: num, done: num, progress_percent: nnum, attendance_rate: nnum,
  })).default([]),
});
export type StudentDashboard = z.infer<typeof studentDashboard>;

// ── Activities (V9) ────────────────────────────────────────────
export const policy = z.enum(['teacher_marked', 'self_reported', 'teacher_verified']);
export type Policy = z.infer<typeof policy>;
export const deadlineMode = z.enum(['day_end', 'time', 'none']);
export const occState = z.enum(['upcoming', 'open', 'pending', 'completed', 'rejected', 'not_done', 'missed']);
export type OccState = z.infer<typeof occState>;
export const completionStatus = z.enum(['teacher_marked', 'self_reported', 'pending', 'approved', 'rejected', 'not_done']);
export const activityStatus = z.enum(['active', 'inactive', 'archived']);
export const streak = z.object({
  current: nnum, best: nnum, completed: nnum, resolved: nnum, window_days: nnum, capped: z.boolean().nullish(),
}).nullish();
export type Streak = z.infer<typeof streak>;
export const scheduleRow = z.object({
  version_no: num, weekdays: z.array(num), effective_from: str, end_date: nstr, deadline_mode: deadlineMode,
  deadline_time: nstr, timezone: str, created_at: nstr,
}).nullish();
export const activityOverview = z.object({
  course_id: id,
  activities: z.array(z.object({
    id, title: str, description: nstr, policy, status: activityStatus, version: num, created_at: nstr,
    schedule: scheduleRow,
    today: z.object({ date: str, scheduled: z.boolean(), expected: num, completed: num, pending: num }),
    pending_total: num,
  })),
});
export type ActivityOverview = z.infer<typeof activityOverview>;
export type OverviewActivity = ActivityOverview['activities'][number];
export const activityCreated = z.object({ id, version: num, status: nstr, policy: nstr, schedule_version: nnum });
export const activityMutated = z.object({ id: id.optional(), version: num, status: nstr, schedule_version: nnum });
export const occurrenceItem = z.object({
  activity_id: id, course_id: id, course_title: nstr, title: str, policy, occurrence_date: str, state: occState,
  completion_status: completionStatus.nullish(), version: num, due_at: nstr, deadline_mode: deadlineMode,
  timezone: nstr, note: nstr, reason: nstr,
});
export type OccurrenceItem = z.infer<typeof occurrenceItem>;
export const myActivities = z.object({ items: z.array(occurrenceItem), next_cursor: z.unknown().nullish() });
export const register = z.object({
  activity_id: id, title: str, policy, week_start: str,
  days: z.array(z.object({ date: str, due_at: nstr, timezone: nstr, deadline_mode: nstr })),
  students: z.array(z.object({
    student_id: id, full_name: nstr,
    cells: z.array(z.object({
      date: str, state: occState, completion_status: completionStatus.nullish(), version: num, note: nstr, reason: nstr,
    })),
  })),
});
export type Register = z.infer<typeof register>;
export const completionResult = z.object({
  activity_id: id.optional(), occurrence_date: nstr, student_id: nstr, status: nstr, version: nnum, submitted_at: nstr, // retract answers without a version
  replayed: z.boolean().optional(),
});
export const pendingQueue = z.object({
  items: z.array(z.object({
    activity_id: id, course_id: id, course_title: nstr, activity_title: str, student_id: id, full_name: nstr,
    occurrence_date: str, submitted_at: nstr, note: nstr, version: num, due_at: nstr,
  })),
  next_cursor: z.unknown().nullish(), total: num,
});
export type PendingItem = z.infer<typeof pendingQueue>['items'][number];
export const streaks = z.object({
  course_id: id, student_id: nstr,
  activities: z.array(z.object({ activity_id: id, title: str, policy, status: nstr, streak })),
});

// ── Progress (V9) ──────────────────────────────────────────────
export const progress = z.object({
  course: z.object({ id, title: str, status: nstr }),
  student: z.object({ id, full_name: nstr }),
  enrollment: z.object({ status: nstr, joined_at: nstr }),
  attendance: z.object({
    sessions_total: num, sessions_closed: num, present: num, late: num, excused: num, absent: num, unmarked: num, rate: nnum,
    recent: z.array(z.object({ session_id: id, title: str, starts_at: ts, closed: z.boolean(), status: nstr })).default([]),
  }),
  assignments: z.object({
    published: num, done: num, awaiting_review: num, graded: num, needs_revision: num, not_started: num, overdue: num,
    average_percent: nnum, items_total: num,
    items: z.array(z.object({ id, title: str, due_at: nstr, max_score: nnum, score: nnum, status: nstr })).default([]),
  }),
  activities: z.object({
    activities: z.array(z.object({ activity_id: id, title: str, policy, status: nstr, streak })).default([]),
    pending_verification: num,
  }),
  generated_at: nstr,
});
export type Progress = z.infer<typeof progress>;

// ── Tasks & Calendar (V9) ──────────────────────────────────────
export const taskKind = z.enum(['assignment', 'activity', 'attendance_session']);
export const taskItem = z.object({
  kind: taskKind, id, key2: nstr, course_id: id, course_title: nstr, title: str, status: str, task_at: nstr,
  due_at: nstr, occurrence_date: nstr, policy: nstr, version: nnum, sort_at: nstr,
});
export type TaskItem = z.infer<typeof taskItem>;
export const myTasks = z.object({ view: str, items: z.array(taskItem), next_cursor: z.unknown().nullish(), server_time: nstr });
export const calendarItem = z.object({
  kind: z.enum(['assignment_due', 'activity_day', 'attendance_session']), id, key2: nstr, course_id: id, course_title: nstr,
  title: str, status: nstr, task_at: nstr, received: nnum, expected: nnum, pending: nnum, occurrence_date: nstr,
});
export type CalendarItem = z.infer<typeof calendarItem>;
export const teacherCalendar = z.object({
  items: z.array(calendarItem), next_cursor: z.unknown().nullish(), pending_verifications: num, server_time: nstr,
});

// ── QR attendance (V13) ─────────────────────────────────────────
export const qrIssue = z.object({ token: str, action: z.enum(['in', 'out']), expires_at: ts, refresh_seconds: num });
/** `ok:false` carries a business reason (never raised), so the server can persist the attempt. */
export const scanResult = z.object({
  ok: z.boolean(), reason: nstr, action: nstr, already: z.boolean().nullish(), status: nstr, checked_in_at: nstr, checked_out_at: nstr,
  session_id: nstr, title: nstr, requires_checkout: z.boolean().nullish(), opens_at: nstr,
});
export type ScanResult = z.infer<typeof scanResult>;
export const rulesResult = z.object({ session_id: id, version: num });

// ── Staff attendance (V14) ──────────────────────────────────────
export const staffState = z.enum(['on_time', 'late', 'missing_checkout', 'in_progress', 'absent', 'leave', 'unscheduled', 'upcoming']);
export type StaffState = z.infer<typeof staffState>;
const person = z.object({ id, name: nstr });
export const staffContext = z.object({
  is_staff: z.boolean(), is_supervisor: z.boolean(), server_now: nstr,
  supervisors: z.array(person).default([]), supervisees: z.array(person).default([]),
  schedules: z.array(z.object({
    id, label: nstr, weekdays: z.array(num), start_time: str, end_time: str, timezone: str, late_grace_minutes: num, effective_from: str, effective_to: nstr,
  })).default([]),
  open_punch: z.object({ id, work_date: str, clock_in_at: ts, late_minutes: num, schedule_id: nstr }).nullish(),
});
export type StaffContext = z.infer<typeof staffContext>;
const staffTotals = z.object({
  on_time: num, late: num, missing_checkout: num, absent: num, leave: num, unscheduled: num, late_minutes: num, worked_minutes: num,
});
export type StaffTotals = z.infer<typeof staffTotals>;
export const staffRow = z.object({
  day: str, schedule_id: nstr, start_time: nstr, end_time: nstr, clock_in_at: nstr, clock_out_at: nstr, late_minutes: nnum, source: nstr, state: staffState,
});
export type StaffRow = z.infer<typeof staffRow>;
export const staffReport = z.object({ staff_id: id, name: nstr, rows: z.array(staffRow), totals: staffTotals, server_now: nstr });
export type StaffReport = z.infer<typeof staffReport>;
export const teamSummary = z.object({ staff: z.array(z.object({ staff_id: id, name: nstr, totals: staffTotals })) });
export const punchResult = z.object({ id, work_date: str, clock_in_at: nstr, clock_out_at: nstr, late_minutes: nnum, scheduled: z.boolean().nullish(), state: nstr, worked_minutes: nnum });
export const staffRequest = z.object({
  id, staff_id: id, staff_name: nstr, kind: z.enum(['leave', 'correction']), date_from: str, date_to: str, proposed_clock_in: nstr, proposed_clock_out: nstr,
  reason: str, status: z.enum(['pending', 'approved', 'rejected', 'cancelled']), decided_at: nstr, decision_note: nstr, created_at: ts,
});
export type StaffRequest = z.infer<typeof staffRequest>;
