-- V9 query-volume benchmark (rolled back). 1 teacher, 40 students, 25 activities x 30 past days (~80% complete), 30 assignments with
-- submissions, 40 attendance sessions with records. Timings are wall-clock per RPC call as the student/teacher would run it.
begin;
create schema b;
create function b.as_(uid uuid, q text) returns jsonb language plpgsql as $$
declare r jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('role', 'authenticated', true);
  execute q into r; perform set_config('role', 'postgres', true); return r;
exception when others then perform set_config('role', 'postgres', true); return jsonb_build_object('err', sqlstate, 'msg', sqlerrm);
end $$;
create table b.v (k text primary key, val text);
do $$
declare tid uuid := gen_random_uuid(); cid uuid; sid uuid; aid uuid; i int; j int; stu uuid[] := '{}'; t0 timestamptz; r jsonb; ses uuid; asg uuid;
begin
  insert into public.teacher_invitations (email) values ('bt@example.test');
  insert into auth.users (id, email, email_confirmed_at, raw_user_meta_data, aud, role) values (tid, 'bt@example.test', now(), '{"full_name":"T"}', 'authenticated', 'authenticated');
  cid := (b.as_(tid, $q$select public.create_course('Bench','')$q$) ->> 'id')::uuid;
  for i in 1..40 loop
    sid := gen_random_uuid(); stu := stu || sid;
    insert into auth.users (id, email, email_confirmed_at, raw_user_meta_data, aud, role) values (sid, 'bs' || i || '@example.test', now(), json_build_object('full_name', 'Student ' || i)::jsonb, 'authenticated', 'authenticated');
    insert into public.course_members (course_id, student_id) values (cid, sid);
  end loop;
  for i in 1..25 loop
    aid := gen_random_uuid();
    insert into public.activities (id, course_id, title, policy, request_id, created_by) values (aid, cid, 'Activity ' || i, (array['teacher_marked','self_reported','teacher_verified'])[1 + i % 3], gen_random_uuid(), tid);
    insert into public.activity_schedules (activity_id, version_no, weekdays, effective_from, timezone, request_id, created_by) values (aid, 1, '{1,2,3,4,5,6,7}', current_date - 30, 'UTC', gen_random_uuid(), tid);
    insert into public.activity_completions (activity_id, student_id, occurrence_date, status, schedule_version, due_at, submitted_at)
      select aid, s, d::date, 'self_reported', 1, (d::date + 1)::timestamp at time zone 'UTC', now()
        from unnest(stu) s, generate_series(current_date - 30, current_date - 1, interval '1 day') d where random() < 0.8;
  end loop;
  insert into public.activity_completions (activity_id, student_id, occurrence_date, status, schedule_version, due_at, submitted_at)
    select (select id from public.activities where course_id = cid limit 1), s, current_date, 'pending', 1, (current_date + 1)::timestamp at time zone 'UTC', now() from unnest(stu) s;
  for i in 1..30 loop
    asg := gen_random_uuid();
    insert into public.assignments (id, course_id, title, max_score, due_at, status, published_at) values (asg, cid, 'Assignment ' || i, 100, now() + (i - 15) * interval '2 days', 'published', now());
    insert into public.submissions (assignment_id, student_id, answer) select asg, s, 'x' from unnest(stu) s where random() < .7;
  end loop;
  update public.submissions set status = 'graded', score = 70, graded_at = now() where random() < .5;
  for i in 1..40 loop
    ses := gen_random_uuid();
    insert into public.attendance_sessions (id, course_id, title, starts_at, request_id, created_by) values (ses, cid, 'S' || i, now() - i * interval '1 day', gen_random_uuid(), tid);
    insert into public.attendance_records (session_id, student_id, status) select ses, s, 'present' from unnest(stu) s;
  end loop;
  insert into b.v values ('t', tid::text), ('s', stu[1]::text), ('c', cid::text), ('a', (select id::text from public.activities where course_id = cid limit 1));
  analyze;
end $$;
create function b.time_it(label text, u text, q text) returns void language plpgsql as $$
declare t0 timestamptz := clock_timestamp(); r jsonb; ms numeric;
begin
  r := b.as_((select val from b.v where k = u)::uuid, q);
  ms := round(extract(epoch from clock_timestamp() - t0) * 1000, 1);
  raise notice '% ms  %  (%)', lpad(ms::text, 8), rpad(label, 52), coalesce(r ->> 'err', 'ok ' || length(r::text) || ' bytes');
end $$;
select b.time_it('student  get_my_progress (1 course, 30 assignments, 25 activities)', 's', format('select public.get_my_progress(%L)', (select val from b.v where k = 'c')));
select b.time_it('teacher  get_student_progress (open one student)', 't', format('select public.get_student_progress(%L,%L)', (select val from b.v where k = 'c'), (select val from b.v where k = 's')));
select b.time_it('student  get_my_tasks range 31 days (limit 400)', 's', format('select public.get_my_tasks(''range'',%L,%L,400)', now() - interval '15 days', now() + interval '16 days'));
select b.time_it('student  get_my_tasks upcoming (first page 100)', 's', 'select public.get_my_tasks(''upcoming'')');
select b.time_it('student  get_my_tasks overdue (first page 100)', 's', 'select public.get_my_tasks(''overdue'')');
select b.time_it('student  get_my_tasks completed (first page 100)', 's', 'select public.get_my_tasks(''completed'')');
select b.time_it('student  get_my_activities 62-day window (limit 400)', 's', format('select public.get_my_activities(%L,%L,null,400)', current_date - 61, current_date));
select b.time_it('student  get_activity_streaks (25 activities)', 's', format('select public.get_activity_streaks(%L)', (select val from b.v where k = 'c')));
select b.time_it('teacher  get_activity_overview (25 activities)', 't', format('select public.get_activity_overview(%L)', (select val from b.v where k = 'c')));
select b.time_it('teacher  get_activity_register (1 activity x 40 students x 7 d)', 't', format('select public.get_activity_register(%L,%L)', (select val from b.v where k = 'a'), current_date - 6));
select b.time_it('teacher  get_pending_verifications (page 50 of 40)', 't', 'select public.get_pending_verifications(null, 50)');
select b.time_it('teacher  get_teacher_calendar 62-day window (limit 400)', 't', format('select public.get_teacher_calendar(%L,%L,400)', now() - interval '31 days', now() + interval '31 days'));
select b.time_it('V7 baseline: student get_student_dashboard', 's', 'select public.get_student_dashboard()');
select b.time_it('V7 baseline: teacher get_teacher_dashboard', 't', 'select public.get_teacher_dashboard()');
select 'rows: completions=' || (select count(*) from public.activity_completions) || ' submissions=' || (select count(*) from public.submissions) || ' records=' || (select count(*) from public.attendance_records) as volume;
rollback;
