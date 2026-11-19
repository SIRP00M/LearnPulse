-- V7 dashboards: two read-only, role-checked aggregate RPCs. No new tables, no client table access.
-- Every number is computed from persisted rows; nothing is cached or invented.
-- Definitions (also shown in the UI):
--   * Only ACTIVE course members count (removed students vanish from every figure); archived courses are
--     excluded from work/attendance figures and counted separately.
--   * expected submissions = published assignments of active courses x active members of that course.
--   * outstanding = expected - received; awaiting grading = submissions in status 'submitted'.
--   * student "done" = a submission in status submitted or graded (a returned one is NOT done: it needs revision);
--     progress % = done / published assignments of the course (null when the course has none).
--   * attendance rate = (present + late) / (present + late + absent); excused and unmarked are excluded.
--   * upcoming deadline = published assignment in an active course with due_at >= now(), soonest first, max 5.
--   * lesson completion is NOT tracked (no such interaction exists); lessons appear only as "recently published".
-- Bounded output: 5 deadlines, 10 recent items, one row per course.

create index submissions_student_idx on public.submissions (student_id);

create function public.get_teacher_dashboard() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_out jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'teacher') then
    raise exception 'Only teachers have this dashboard' using errcode = 'PT403'; end if;

  with mine as (
    select c.id, c.title, c.status from public.courses c where c.owner_id = v_uid),
  roster as (
    select m.course_id, m.student_id from public.course_members m
      join mine on mine.id = m.course_id where m.status = 'active'),
  pub as (
    select a.id, a.course_id, a.title, a.due_at from public.assignments a
      join mine on mine.id = a.course_id where a.status = 'published' and mine.status = 'active'),
  subs as (
    select s.id, s.assignment_id, s.student_id, s.status, s.submitted_at, pub.course_id, pub.title as a_title
      from public.submissions s join pub on pub.id = s.assignment_id
      join roster r on r.course_id = pub.course_id and r.student_id = s.student_id),
  att as (
    select s.course_id, r.status from public.attendance_records r
      join public.attendance_sessions s on s.id = r.session_id
      join mine on mine.id = s.course_id and mine.status = 'active'
      join roster ro on ro.course_id = s.course_id and ro.student_id = r.student_id)
  select jsonb_build_object(
    'courses_active', (select count(*) from mine where status = 'active'),
    'courses_archived', (select count(*) from mine where status = 'archived'),
    'active_students', (select count(distinct r.student_id) from roster r join mine on mine.id = r.course_id and mine.status = 'active'),
    'published_assignments', (select count(*) from pub),
    'expected_submissions', (select count(*) from pub join roster r on r.course_id = pub.course_id),
    'received_submissions', (select count(*) from subs),
    'awaiting_grading', (select count(*) from subs where status = 'submitted'),
    'graded', (select count(*) from subs where status = 'graded'),
    'returned', (select count(*) from subs where status = 'returned'),
    'open_attendance_sessions', (select count(*) from public.attendance_sessions s
                                  join mine on mine.id = s.course_id and mine.status = 'active' where s.status = 'open'),
    'attendance_rate', (select case when count(*) filter (where status in ('present', 'late', 'absent')) = 0 then null
                               else round(100.0 * count(*) filter (where status in ('present', 'late'))
                                          / count(*) filter (where status in ('present', 'late', 'absent')), 1) end from att),
    'upcoming_deadlines', coalesce((
      select jsonb_agg(d order by d.due_at) from (
        select pub.id as assignment_id, pub.course_id, mine.title as course_title, pub.title, pub.due_at,
               (select count(*) from subs where subs.assignment_id = pub.id) as received,
               (select count(*) from roster r where r.course_id = pub.course_id) as expected
          from pub join mine on mine.id = pub.course_id
         where pub.due_at is not null and pub.due_at >= now() order by pub.due_at limit 5) d), '[]'::jsonb),
    'recent_activity', coalesce((
      select jsonb_agg(x order by x.at desc) from (
        select subs.id as submission_id, subs.course_id, mine.title as course_title, subs.a_title as assignment_title,
               p.full_name as student_name, subs.status, subs.submitted_at as at
          from subs join mine on mine.id = subs.course_id join public.profiles p on p.id = subs.student_id
         order by subs.submitted_at desc limit 10) x), '[]'::jsonb),
    'courses', coalesce((
      select jsonb_agg(c order by c.title) from (
        select mine.id as course_id, mine.title, mine.status,
               (select count(*) from roster r where r.course_id = mine.id) as students,
               (select count(*) from pub where pub.course_id = mine.id) as assignments,
               (select count(*) from subs where subs.course_id = mine.id and subs.status = 'submitted') as awaiting_grading,
               (select count(*) from public.attendance_sessions s where s.course_id = mine.id) as attendance_sessions
          from mine) c), '[]'::jsonb)
  ) into v_out;
  return v_out;
end $$;

create function public.get_student_dashboard() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_out jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'student') then
    raise exception 'Only students have this dashboard' using errcode = 'PT403'; end if;

  with mine as (
    select c.id, c.title, c.status, p.full_name as teacher_name
      from public.course_members m join public.courses c on c.id = m.course_id
      join public.profiles p on p.id = c.owner_id
     where m.student_id = v_uid and m.status = 'active'),
  pub as (
    select a.id, a.course_id, a.title, a.due_at, a.max_score from public.assignments a
      join mine on mine.id = a.course_id where a.status = 'published' and mine.status = 'active'),
  work as (
    select pub.*, s.status as sub_status, s.score, s.graded_at, (s.feedback is not null and s.feedback <> '') as has_feedback
      from pub left join public.submissions s on s.assignment_id = pub.id and s.student_id = v_uid),
  att as (
    select s.course_id, r.status from public.attendance_records r
      join public.attendance_sessions s on s.id = r.session_id
      join mine on mine.id = s.course_id and mine.status = 'active'
     where r.student_id = v_uid)
  select jsonb_build_object(
    'courses_active', (select count(*) from mine where status = 'active'),
    'published_assignments', (select count(*) from work),
    'done', (select count(*) from work where sub_status in ('submitted', 'graded')),
    'awaiting_grade', (select count(*) from work where sub_status = 'submitted'),
    'graded', (select count(*) from work where sub_status = 'graded'),
    'needs_revision', (select count(*) from work where sub_status = 'returned'),
    'not_started', (select count(*) from work where sub_status is null),
    'overdue', (select count(*) from work where due_at < now() and (sub_status is null)),
    'average_percent', (select round(avg(100.0 * score / max_score), 1) from work where sub_status = 'graded'),
    'attendance_rate', (select case when count(*) filter (where status in ('present', 'late', 'absent')) = 0 then null
                               else round(100.0 * count(*) filter (where status in ('present', 'late'))
                                          / count(*) filter (where status in ('present', 'late', 'absent')), 1) end from att),
    'upcoming_deadlines', coalesce((
      select jsonb_agg(d order by d.due_at) from (
        select w.id as assignment_id, w.course_id, mine.title as course_title, w.title, w.due_at, w.sub_status as status
          from work w join mine on mine.id = w.course_id
         where w.due_at is not null and w.due_at >= now() and (w.sub_status is null or w.sub_status = 'returned')
         order by w.due_at limit 5) d), '[]'::jsonb),
    'recent_graded', coalesce((
      select jsonb_agg(g order by g.graded_at desc) from (
        select w.id as assignment_id, mine.title as course_title, w.title, w.score, w.max_score, w.graded_at, w.has_feedback
          from work w join mine on mine.id = w.course_id where w.sub_status = 'graded' and w.graded_at is not null
         order by w.graded_at desc limit 5) g), '[]'::jsonb),
    'recent_lessons', coalesce((
      select jsonb_agg(l order by l.published_at desc) from (
        select ls.id as lesson_id, mine.title as course_title, ls.title, ls.published_at
          from public.lessons ls join mine on mine.id = ls.course_id and mine.status = 'active'
         where ls.status = 'published' order by ls.published_at desc limit 5) l), '[]'::jsonb),
    'courses', coalesce((
      select jsonb_agg(c order by c.title) from (
        select mine.id as course_id, mine.title, mine.status, mine.teacher_name,
               (select count(*) from work w where w.course_id = mine.id) as assignments,
               (select count(*) from work w where w.course_id = mine.id and w.sub_status in ('submitted', 'graded')) as done,
               case when (select count(*) from work w where w.course_id = mine.id) = 0 then null
                    else round(100.0 * (select count(*) from work w where w.course_id = mine.id and w.sub_status in ('submitted', 'graded'))
                               / (select count(*) from work w where w.course_id = mine.id), 1) end as progress_percent,
               (select case when count(*) filter (where a.status in ('present', 'late', 'absent')) = 0 then null
                       else round(100.0 * count(*) filter (where a.status in ('present', 'late'))
                                  / count(*) filter (where a.status in ('present', 'late', 'absent')), 1) end
                  from att a where a.course_id = mine.id) as attendance_rate
          from mine) c), '[]'::jsonb)
  ) into v_out;
  return v_out;
end $$;

do $$
declare
  f text;
begin
  foreach f in array array['public.get_teacher_dashboard()', 'public.get_student_dashboard()'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
