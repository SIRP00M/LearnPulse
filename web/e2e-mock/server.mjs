// Local mock of the Supabase endpoints the Web app calls (Auth + PostgREST), used ONLY for the localization acceptance run so that
// no remote fixture or remote write is needed. It serves fixed, language-neutral data and records every RPC call so tests can prove
// that switching the interface language never changes a request (windows, dates, versions, request ids).
// Usage: node e2e-mock/server.mjs  (default port 54399)
import { createServer } from 'node:http';

const PORT = Number(process.env.MOCK_PORT ?? 54399);
const calls = [];
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const jwt = (sub, email) => `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ sub, email, role: 'authenticated', exp: Math.floor(Date.now() / 1000) + 3600 })}.mocksignature`;

const USERS = {
  'teacher@mock.test': { id: '00000000-0000-4000-8000-0000000000a1', role: 'teacher', name: 'Somsri Teacher' },
  'student@mock.test': { id: '00000000-0000-4000-8000-0000000000b1', role: 'student', name: 'Nattapong Student' },
  'student2@mock.test': { id: '00000000-0000-4000-8000-0000000000b2', role: 'student', name: 'Aisyah Student' },
};
const PASSWORD = 'Mock-Pass1x';
const byToken = new Map();

const pad = (n) => String(n).padStart(2, '0');
const ymd = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const at = (days, h = 17, m = 0) => { const d = new Date(); d.setDate(d.getDate() + days); d.setHours(h, m, 0, 0); return d.toISOString(); };
const C1 = '11111111-1111-4111-8111-111111111111';
const A1 = '22222222-2222-4222-8222-222222222222';
const X1 = '33333333-3333-4333-8333-333333333333';
const S1 = '44444444-4444-4444-8444-444444444444';
const course = (teacherName) => ({ id: C1, owner_id: USERS['teacher@mock.test'].id, title: 'Algebra I', description: 'Functions and graphs', status: 'active', created_at: at(-30), owner: { full_name: teacherName } });
const today = () => ymd(new Date());

const progress = (who) => ({
  course: { id: C1, title: 'Algebra I', status: 'active' }, student: { id: USERS['student@mock.test'].id, full_name: who },
  enrollment: { status: 'active', joined_at: at(-20) },
  attendance: { sessions_total: 6, sessions_closed: 5, present: 4, late: 1, excused: 0, absent: 0, unmarked: 1, rate: 100, recent: [{ session_id: S1, title: 'Week 1', starts_at: at(-3), closed: true, status: 'present' }] },
  assignments: { published: 2, done: 1, awaiting_review: 0, graded: 1, needs_revision: 0, not_started: 1, overdue: 0, average_percent: 87.5, items_total: 2,
    items: [{ id: A1, title: 'Essay on Functions', due_at: at(1), max_score: 20, score: null, status: 'todo' }, { id: '55555555-5555-4555-8555-555555555555', title: 'Quiz 1', due_at: at(-5), max_score: 20, score: 17, status: 'graded' }] },
  activities: { activities: [{ activity_id: X1, title: 'Reading Journal', policy: 'teacher_verified', status: 'active', streak: { current: 3, best: 5, completed: 3, resolved: 3, window_days: 62, capped: false } }], pending_verification: 0 },
  generated_at: new Date().toISOString(),
});

const studentDashboard = () => ({
  courses_active: 1, published_assignments: 2, done: 1, awaiting_grade: 0, graded: 1, needs_revision: 0, not_started: 1, overdue: 0, average_percent: 87.5, attendance_rate: 92.3,
  upcoming_deadlines: [{ title: 'Essay on Functions', course_title: 'Algebra I', due_at: at(1), received: null, expected: null, status: 'todo' }],
  recent_graded: [{ title: 'Quiz 1', course_title: 'Algebra I', score: 17, max_score: 20, has_feedback: true }], recent_lessons: [],
  courses: [{ title: 'Algebra I', teacher_name: 'Somsri Teacher', status: 'active', assignments: 2, done: 1, progress_percent: 50, attendance_rate: 92.3 }],
});
const teacherDashboard = () => ({
  courses_active: 1, courses_archived: 0, active_students: 24, published_assignments: 2, expected_submissions: 48, received_submissions: 31, awaiting_grading: 5, graded: 20, returned: 2,
  open_attendance_sessions: 1, attendance_rate: 94.1,
  upcoming_deadlines: [{ title: 'Essay on Functions', course_title: 'Algebra I', due_at: at(1), received: 12, expected: 24, status: null }],
  recent_activity: [{ student_name: 'Nattapong Student', assignment_title: 'Quiz 1', course_title: 'Algebra I', status: 'submitted', at: at(0, 9) }],
  courses: [{ course_id: C1, title: 'Algebra I', status: 'active', students: 24, assignments: 2, awaiting_grading: 5, attendance_sessions: 6 }],
});
const taskItems = (view) => {
  const act = { kind: 'activity', id: X1, key2: today(), course_id: C1, course_title: 'Algebra I', title: 'Reading Journal', status: 'todo', task_at: null, due_at: null, occurrence_date: today(), policy: 'teacher_verified', version: 0, sort_at: at(0, 23, 59) };
  const asg = { kind: 'assignment', id: A1, key2: null, course_id: C1, course_title: 'Algebra I', title: 'Essay on Functions', status: 'todo', task_at: at(0, 18), due_at: at(0, 18), occurrence_date: null, policy: null, version: 1, sort_at: at(0, 18) };
  if (view === 'range') return [asg, act];
  if (view === 'upcoming') return [{ ...asg, task_at: at(2, 18), due_at: at(2, 18) }];
  if (view === 'overdue') return [{ ...asg, title: 'Late worksheet', status: 'overdue', id: '66666666-6666-4666-8666-666666666666', task_at: at(-2, 18), due_at: at(-2, 18) }];
  return [];
};
const calendar = () => ({
  items: [
    { kind: 'activity_day', id: X1, key2: today(), course_id: C1, course_title: 'Algebra I', title: 'Reading Journal', status: 'open', task_at: null, received: 20, expected: 24, pending: 2, occurrence_date: today() },
    { kind: 'assignment_due', id: A1, key2: null, course_id: C1, course_title: 'Algebra I', title: 'Essay on Functions', status: null, task_at: at(1, 18), received: 12, expected: 24, pending: null, occurrence_date: null },
    { kind: 'attendance_session', id: S1, key2: null, course_id: C1, course_title: 'Algebra I', title: 'Week 2 · Monday', status: 'scheduled', task_at: at(0, 9), received: null, expected: null, pending: null, occurrence_date: null },
  ],
  next_cursor: null, pending_verifications: 2, server_time: new Date().toISOString(),
});
const overview = () => ({ course_id: C1, activities: [{ id: X1, title: 'Reading Journal', description: '', policy: 'teacher_verified', status: 'active', version: 1, created_at: at(-10),
  schedule: { version_no: 1, weekdays: [1, 2, 3, 4, 5], effective_from: ymd(new Date(Date.now() - 10 * 864e5)), end_date: null, deadline_mode: 'day_end', deadline_time: null, timezone: 'Asia/Bangkok', created_at: at(-10) },
  today: { date: today(), scheduled: true, expected: 24, completed: 20, pending: 2 }, pending_total: 2 }] });
const attSummary = () => ({ sessions_total: 6, sessions_closed: 5, students: [{ student_id: USERS['student@mock.test'].id, full_name: 'Nattapong Student', present: 4, late: 1, excused: 0, absent: 0, rate: 100 }] });

const rpc = {
  get_student_dashboard: studentDashboard, get_teacher_dashboard: teacherDashboard,
  get_my_tasks: (b) => ({ view: b.p_view, items: taskItems(b.p_view), next_cursor: null, server_time: new Date().toISOString() }),
  get_teacher_calendar: calendar,
  get_pending_verifications: () => ({ items: [{ activity_id: X1, course_id: C1, course_title: 'Algebra I', activity_title: 'Reading Journal', student_id: USERS['student@mock.test'].id, full_name: 'Nattapong Student', occurrence_date: today(), submitted_at: at(0, 8), note: 'Chapter 3 notes', version: 1, due_at: at(0, 23, 59) }], next_cursor: null, total: 2 }),
  get_my_progress: () => progress('Nattapong Student'), get_student_progress: () => progress('Nattapong Student'),
  get_activity_overview: overview, get_attendance_summary: attSummary, get_course_join_code: () => 'ABC123',
  get_activity_streaks: () => ({ course_id: C1, student_id: null, activities: [{ activity_id: X1, title: 'Reading Journal', policy: 'teacher_verified', status: 'active', streak: { current: 3, best: 5, completed: 3, resolved: 3, window_days: 62, capped: false } }] }),
  get_my_activities: () => ({ items: [{ activity_id: X1, course_id: C1, course_title: 'Algebra I', title: 'Reading Journal', policy: 'teacher_verified', occurrence_date: today(), state: 'open', completion_status: null, version: 0, due_at: at(0, 23, 59), deadline_mode: 'day_end', timezone: 'Asia/Bangkok', note: null, reason: null }], next_cursor: null }),
  get_activity_register: () => ({ activity_id: X1, title: 'Reading Journal', policy: 'teacher_verified', week_start: today(), days: [{ date: today(), due_at: at(0, 23, 59), timezone: 'Asia/Bangkok', deadline_mode: 'day_end' }],
    students: [{ student_id: USERS['student@mock.test'].id, full_name: 'Nattapong Student', cells: [{ date: today(), state: 'pending', completion_status: 'pending', version: 1, note: 'Chapter 3 notes', reason: null }] }] }),
};

const tables = (path, user) => {
  if (path === 'profiles') return { role: user.role, full_name: user.name };
  if (path === 'courses') return [course('Somsri Teacher')];
  if (path === 'course_members') return [{ student_id: USERS['student@mock.test'].id, status: 'active', joined_at: at(-20), student: { full_name: 'Nattapong Student' } }];
  if (path === 'lessons') return [{ id: '77777777-7777-4777-8777-777777777777', course_id: C1, title: 'Functions and graphs', body: 'Plot y = 2x + 1.', status: 'published', version: 1 }];
  if (path === 'assignments') return [{ id: A1, course_id: C1, title: 'Essay on Functions', instructions: 'Write about functions.', max_score: 20, due_at: at(1), status: 'published', version: 1 }];
  if (path === 'attendance_sessions') return [{ id: S1, course_id: C1, title: 'Week 1', starts_at: at(-3), status: 'closed', version: 2 }];
  if (path === 'attendance_records') return [{ session_id: S1, student_id: USERS['student@mock.test'].id, status: 'present', note: null, version: 1 }];
  return [];
};

const cors = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', req.headers['access-control-request-headers'] ?? '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS,HEAD');
  res.setHeader('Access-Control-Expose-Headers', 'Content-Range, Content-Type');
  res.setHeader('Access-Control-Max-Age', '600');
};
const send = (res, status, body, extra = {}) => { res.writeHead(status, { 'Content-Type': 'application/json', ...extra }); res.end(body === undefined ? '' : JSON.stringify(body)); };
const readBody = (req) => new Promise((r) => { let d = ''; req.on('data', (c) => (d += c)); req.on('end', () => { try { r(d ? JSON.parse(d) : {}); } catch { r({}); } }); });
const userOf = (req) => byToken.get((req.headers.authorization ?? '').replace(/^Bearer /, ''));

createServer(async (req, res) => {
  cors(req, res);
  if (req.method === 'OPTIONS') { res.writeHead(204).end(); return; }
  const url = new URL(req.url, 'http://x');
  const p = url.pathname;
  if (p === '/__calls') { send(res, 200, calls.filter((c) => !url.searchParams.get('name') || c.name === url.searchParams.get('name'))); return; }
  if (p === '/__reset') { calls.length = 0; send(res, 200, { ok: true }); return; }
  if (p === '/auth/v1/settings') { send(res, 200, { disable_signup: false, mailer_autoconfirm: false, external: { email: true } }); return; }
  if (p === '/auth/v1/token') {
    const b = await readBody(req);
    if (url.searchParams.get('grant_type') === 'pkce' && b.auth_code === 'mock-recovery') {
      const email = 'student@mock.test';
      const u = USERS[email];
      const token = jwt(u.id, email);
      byToken.set(token, u);
      send(res, 200, { access_token: token, token_type: 'bearer', expires_in: 3600, refresh_token: 'mock-recovery-refresh',
        user: { id: u.id, aud: 'authenticated', role: 'authenticated', email, app_metadata: {}, user_metadata: { full_name: u.name }, created_at: at(-30) } });
      return;
    }
    const u = USERS[String(b.email ?? '').toLowerCase()];
    if (!u || b.password !== PASSWORD) { send(res, 400, { error: 'invalid_grant', error_code: 'invalid_credentials', code: 400, msg: 'Invalid login credentials' }); return; }
    const token = jwt(u.id, b.email);
    byToken.set(token, u);
    send(res, 200, { access_token: token, token_type: 'bearer', expires_in: 3600, expires_at: Math.floor(Date.now() / 1000) + 3600, refresh_token: 'mock-refresh-' + u.id,
      user: { id: u.id, aud: 'authenticated', role: 'authenticated', email: b.email, app_metadata: {}, user_metadata: { full_name: u.name }, created_at: at(-30) } });
    return;
  }
  if (p === '/auth/v1/logout') { send(res, 204); return; }
  if (p === '/auth/v1/user') { const u = userOf(req); if (!u) { send(res, 401, { code: 401, msg: 'invalid JWT' }); return; } send(res, 200, { id: u.id, email: 'x', user_metadata: { full_name: u.name } }); return; }
  const user = userOf(req);
  if (p.startsWith('/rest/v1/rpc/')) {
    const name = p.slice('/rest/v1/rpc/'.length);
    const body = req.method === 'POST' ? await readBody(req) : {};
    calls.push({ name, body, at: Date.now() });
    if (!user) { send(res, 401, { code: 'PT401', message: 'Not authenticated' }); return; }
    const h = rpc[name];
    if (!h) { send(res, 404, { code: 'PGRST202', message: 'no such function' }); return; }
    send(res, 200, h(body)); return;
  }
  if (p.startsWith('/rest/v1/')) {
    if (!user) { send(res, 200, []); return; }
    const t = p.slice('/rest/v1/'.length);
    const data = tables(t, user);
    if ((req.headers.accept ?? '').includes('vnd.pgrst.object+json')) { send(res, 200, Array.isArray(data) ? data[0] : data); return; }
    send(res, 200, Array.isArray(data) ? data : [data], { 'Content-Range': `0-${Math.max(0, (Array.isArray(data) ? data.length : 1) - 1)}/*` }); return;
  }
  send(res, 404, { message: 'not found' });
}).listen(PORT, '127.0.0.1', () => console.log(`mock supabase on http://127.0.0.1:${PORT}`));
