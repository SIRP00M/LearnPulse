import { z } from 'zod';
import { supabase } from '../supabase';
import { config } from '../../config';
import { rpc, read } from '../rpc';
import { AppError, toAppError } from '../errors';
import {
  courses as coursesSchema, newCourse, joinResult, rosterRow, lessonRow, resourceRow, resourceTicket, assignmentRow,
  submissionRow, submissionEvent, uploadTicket, submitResult, gradeResult, idResult, sessionRow, recordRow, attEvent,
  attendanceSummary, markResult, closeResult, teacherDashboard, studentDashboard, profileSchema,
  type AttendanceStatus, type Profile,
} from '../schemas';

/** Allowed upload types, mirroring the server's allow-list (the server remains the authority). */
export const ALLOWED_UPLOADS: Record<string, string> = {
  pdf: 'application/pdf',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  zip: 'application/zip',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  webp: 'image/webp',
  txt: 'text/plain',
};
export const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
export function mimeForFileName(name: string): string | null {
  const dot = name.lastIndexOf('.');
  if (dot < 0) return null;
  return ALLOWED_UPLOADS[name.slice(dot + 1).toLowerCase()] ?? null;
}
/** Returns a translation KEY (errors:…) or null. */
export function checkUpload(file: File): string | null {
  if (!mimeForFileName(file.name)) return 'errors:fileTypeUpload';
  if (file.size === 0) return 'errors:fileEmpty';
  if (file.size > MAX_UPLOAD_BYTES) return 'errors:fileTooLarge';
  return null;
}

async function upload(bucket: string, path: string, file: File) {
  const mime = mimeForFileName(file.name);
  if (!mime) throw new AppError('validation', 'That file type is not allowed.', undefined, 'errors:fileType');
  const { error } = await supabase.storage.from(bucket).upload(path, file, { contentType: mime, upsert: false });
  // A retry after a lost response finds the object already stored (409); the server re-verifies size/type on save.
  if (error && !(String((error as { statusCode?: string }).statusCode) === '409' || /already exists/i.test(error.message))) {
    throw toAppError(error);
  }
}
async function signed(bucket: string, path: string, seconds: number): Promise<string> {
  const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, seconds);
  if (error || !data?.signedUrl) throw new AppError('forbidden', 'You do not have access to this file.', undefined, 'errors:fileNoAccess');
  return data.signedUrl;
}

const SUB_SELECT =
  'id, assignment_id, student_id, answer, version, submitted_at, status, score, feedback, graded_at, ' +
  'upload:submission_uploads!submissions_upload_id_fkey(id, file_name, mime_type, size_bytes, storage_path), ' +
  'student:profiles!submissions_student_id_fkey(full_name)';

/** Public Auth settings (no secrets): lets the UI respect server configuration instead of guessing. */
export async function authSettings(): Promise<{ signupDisabled: boolean | null }> {
  try {
    const r = await fetch(`${config.supabaseUrl}/auth/v1/settings`, { headers: { apikey: config.publishableKey } });
    if (!r.ok) return { signupDisabled: null };
    const j = (await r.json()) as { disable_signup?: boolean };
    return { signupDisabled: typeof j.disable_signup === 'boolean' ? j.disable_signup : null };
  } catch {
    return { signupDisabled: null }; // unknown: show the form; the server still enforces its own rule
  }
}

const SESSION_COLS = 'id, course_id, title, starts_at, status, version, requires_checkout, late_after_minutes, checkin_opens_minutes, checkin_window_minutes';
const RECORD_COLS = 'session_id, student_id, status, note, version, checked_in_at, checked_out_at, source';

export const api = {
  // ── profile ───────────────────────────────────────────────
  async loadProfile(userId: string): Promise<Profile> {
    const row = await read(supabase.from('profiles').select('role, full_name, avatar_path').eq('id', userId).maybeSingle(), profileSchema.nullable());
    if (!row) throw new AppError('unknown', 'Your account is not ready yet. Please try again in a moment.', undefined, 'errors:profileNotReady');
    return { role: row.role, fullName: row.full_name ?? '', avatarPath: row.avatar_path ?? null };
  },
  async updateName(userId: string, name: string) {
    const rows = await read(supabase.from('profiles').update({ full_name: name }).eq('id', userId).select('id'), z.array(z.object({ id: z.string() })));
    if (rows.length === 0) throw new AppError('unknown', 'Your name could not be saved.', undefined, 'errors:nameNotSaved');
  },

  // ── courses ───────────────────────────────────────────────
  listCourses: () =>
    read(
      supabase.from('courses')
        .select('id, owner_id, title, description, status, created_at, owner:profiles!courses_owner_id_fkey(full_name)')
        .order('created_at', { ascending: false }),
      coursesSchema,
    ),
  createCourse: (title: string, description: string) => rpc('create_course', { p_title: title, p_description: description }, newCourse),
  joinByCode: (code: string) => rpc('join_course_by_code', { p_code: code }, joinResult),
  async joinCode(courseId: string): Promise<string> {
    return rpc('get_course_join_code', { p_course_id: courseId }, z.string());
  },
  updateCourse: (courseId: string, patch: { title?: string; description?: string; status?: 'active' | 'archived' }) =>
    rpc('update_course', { p_course_id: courseId, p_title: patch.title, p_description: patch.description, p_status: patch.status }, idResult),
  roster: (courseId: string) =>
    read(
      supabase.from('course_members')
        .select('student_id, status, joined_at, student:profiles!course_members_student_id_fkey(full_name)')
        .eq('course_id', courseId).order('joined_at', { ascending: true }),
      z.array(rosterRow),
    ),
  removeMember: (courseId: string, studentId: string) =>
    rpc('remove_course_member', { p_course_id: courseId, p_student_id: studentId }, idResult),

  // ── lessons ───────────────────────────────────────────────
  listLessons: (courseId: string) =>
    read(
      supabase.from('lessons').select('id, course_id, title, body, status, version').eq('course_id', courseId)
        .order('position', { ascending: true }).order('created_at', { ascending: true }),
      z.array(lessonRow),
    ),
  listResources: (courseId: string) =>
    read(
      supabase.from('lesson_resources').select('id, lesson_id, title, file_name, size_bytes, storage_path, status')
        .eq('course_id', courseId).order('created_at', { ascending: true }),
      z.array(resourceRow),
    ),
  createLesson: (courseId: string, title: string, body: string) =>
    rpc('create_lesson', { p_course_id: courseId, p_title: title, p_body: body }, idResult),
  updateLesson: (id: string, version: number, patch: { title?: string; body?: string }) =>
    rpc('update_lesson', { p_lesson_id: id, p_expected_version: version, p_title: patch.title, p_body: patch.body }, idResult),
  setLessonStatus: (id: string, version: number, publish: boolean) =>
    rpc('set_lesson_status', { p_lesson_id: id, p_expected_version: version, p_status: publish ? 'published' : 'draft' }, idResult),
  deleteLesson: (id: string, version: number) => rpc('delete_lesson', { p_lesson_id: id, p_expected_version: version }, idResult),
  async addResource(lessonId: string, file: File, title: string) {
    const bad = checkUpload(file);
    if (bad) throw new AppError('validation', bad, undefined, bad);
    const t = await rpc('prepare_resource_upload', {
      p_lesson_id: lessonId, p_file_name: file.name, p_mime_type: mimeForFileName(file.name), p_size_bytes: file.size,
    }, resourceTicket);
    await upload('course-files', t.path, file);
    await rpc('finalize_resource', { p_resource_id: t.resource_id, p_title: title }, idResult);
  },
  deleteResource: (id: string) => rpc('delete_resource', { p_resource_id: id }, idResult),
  resourceUrl: (path: string) => signed('course-files', path, 120),

  // ── assignments & submissions ─────────────────────────────
  listAssignments: (courseId: string) =>
    read(
      supabase.from('assignments').select('id, course_id, title, instructions, max_score, due_at, status, version')
        .eq('course_id', courseId).order('created_at', { ascending: true }),
      z.array(assignmentRow),
    ),
  createAssignment: (a: { courseId: string; title: string; instructions: string; maxScore: number; dueAt: string | null }) =>
    rpc('create_assignment', {
      p_course_id: a.courseId, p_title: a.title, p_instructions: a.instructions, p_max_score: a.maxScore, p_due_at: a.dueAt ?? undefined,
    }, idResult),
  updateAssignment: (id: string, version: number, p: { title?: string; instructions?: string; maxScore?: number; dueAt?: string | null }) =>
    rpc('update_assignment', {
      p_assignment_id: id, p_expected_version: version, p_title: p.title, p_instructions: p.instructions, p_max_score: p.maxScore,
      p_due_at: p.dueAt ?? undefined, p_clear_due: p.dueAt === null,
    }, idResult),
  publishAssignment: (id: string, version: number) => rpc('publish_assignment', { p_assignment_id: id, p_expected_version: version }, idResult),
  mySubmissions: () => read(supabase.from('submissions').select(SUB_SELECT), z.array(submissionRow)),
  listSubmissions: (assignmentId: string) =>
    read(supabase.from('submissions').select(SUB_SELECT).eq('assignment_id', assignmentId).order('submitted_at', { ascending: false }), z.array(submissionRow)),
  submissionEvents: (submissionId: string) =>
    read(
      supabase.from('submission_events').select('action, score, feedback, version_after, created_at')
        .eq('submission_id', submissionId).order('version_after', { ascending: true }),
      z.array(submissionEvent),
    ),
  /** Upload (when a file is given) then submit. `requestId` is kept by the caller across retries. */
  async submit(a: { assignmentId: string; requestId: string; answer: string; file?: File | null; expectedVersion?: number; clearAttachment?: boolean }) {
    let uploadId: string | undefined;
    if (a.file) {
      const bad = checkUpload(a.file);
      if (bad) throw new AppError('validation', bad, undefined, bad);
      const t = await rpc('prepare_submission_upload', {
        p_assignment_id: a.assignmentId, p_file_name: a.file.name, p_mime_type: mimeForFileName(a.file.name), p_size_bytes: a.file.size,
      }, uploadTicket);
      await upload('submission-files', t.path, a.file);
      uploadId = t.upload_id;
    }
    return rpc('submit_assignment', {
      p_assignment_id: a.assignmentId, p_request_id: a.requestId, p_answer: a.answer, p_upload_id: uploadId,
      p_expected_version: a.expectedVersion, p_clear_attachment: a.clearAttachment ?? false,
    }, submitResult);
  },
  submissionUrl: (path: string) => signed('submission-files', path, 600),
  grade: (a: { submissionId: string; requestId: string; version: number; score: number; feedback: string }) =>
    rpc('grade_submission', {
      p_submission_id: a.submissionId, p_request_id: a.requestId, p_expected_version: a.version, p_score: a.score, p_feedback: a.feedback,
    }, gradeResult),
  returnForRevision: (a: { submissionId: string; requestId: string; version: number; feedback: string }) =>
    rpc('return_submission', {
      p_submission_id: a.submissionId, p_request_id: a.requestId, p_expected_version: a.version, p_feedback: a.feedback,
    }, gradeResult),

  // ── attendance ────────────────────────────────────────────
  listSessions: (courseId: string) =>
    read(
      supabase.from('attendance_sessions').select(SESSION_COLS).eq('course_id', courseId)
        .order('starts_at', { ascending: false }).limit(300),
      z.array(sessionRow),
    ),
  getSession: (id: string) =>
    read(supabase.from('attendance_sessions').select(SESSION_COLS).eq('id', id).maybeSingle(), sessionRow.nullable()),
  async listRecordsFor(sessionIds: string[]) {
    if (sessionIds.length === 0) return [];
    const page = 1000;
    const all: z.infer<typeof recordRow>[] = [];
    for (let from = 0; from < 10 * page; from += page) {
      const rows = await read(
        supabase.from('attendance_records').select(RECORD_COLS).in('session_id', sessionIds)
          .order('session_id').order('student_id').range(from, from + page - 1),
        z.array(recordRow),
      );
      all.push(...rows);
      if (rows.length < page) break;
    }
    return all;
  },
  myRecords: (courseId: string) =>
    read(
      supabase.from('attendance_records')
        .select(RECORD_COLS + ', attendance_sessions!inner(title, starts_at, status, course_id)')
        .eq('attendance_sessions.course_id', courseId),
      z.array(recordRow),
    ),
  sessionEvents: (sessionId: string) =>
    read(
      supabase.from('attendance_events').select('action, student_id, old_status, new_status, note, created_at')
        .eq('session_id', sessionId).order('created_at', { ascending: false }).limit(200),
      z.array(attEvent),
    ),
  attendanceSummary: (courseId: string) => rpc('get_attendance_summary', { p_course_id: courseId }, attendanceSummary),
  createSession: (courseId: string, requestId: string, title: string, startsAtIso: string) =>
    rpc('create_attendance_session', { p_course_id: courseId, p_request_id: requestId, p_title: title, p_starts_at: startsAtIso }, idResult),
  markAttendance: (a: { sessionId: string; studentId: string; requestId: string; version: number; status: AttendanceStatus; note: string }) =>
    rpc('mark_attendance', {
      p_session_id: a.sessionId, p_student_id: a.studentId, p_request_id: a.requestId, p_expected_version: a.version,
      p_status: a.status, p_note: a.note,
    }, markResult),
  closeSession: (sessionId: string, requestId: string, version: number) =>
    rpc('close_attendance_session', { p_session_id: sessionId, p_request_id: requestId, p_expected_version: version }, closeResult),

  // ── dashboards ────────────────────────────────────────────
  teacherDashboard: () => rpc('get_teacher_dashboard', undefined, teacherDashboard),
  studentDashboard: () => rpc('get_student_dashboard', undefined, studentDashboard),
};
