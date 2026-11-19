-- V7 SQL-layer tests: dashboards. Authorization, aggregate accuracy against a seeded fixture, zero-data,
-- archived course and removed-member exclusion. One transaction, rolled back.
-- Fixture (course C1, active): s1 s2 s3 active, s4 removed after acting. Assignments: A1 (max 50, due +2d),
-- A2 (max 100, due moved into the past after submissions), A3 draft.
--   A1: s1 submitted, s2 graded 30/50, s4 submitted (then removed)   A2: s1 graded 80/100
--   Attendance (one closed session): s1 present, s2 late, s3 absent, s4 absent (then removed)
-- Expected teacher: expected=6 received=3 outstanding=3 awaiting=1 graded=2 rate=66.7 (4 records would give 50.0)
\set ON_ERROR_STOP 1
\set QUIET 1
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000003","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000012","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000013","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s4 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000014","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s5 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000015","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'

begin;
insert into public.teacher_invitations (email) values ('t1@v7.test'), ('t2@v7.test'), ('t3@v7.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  ('c0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 't1@v7.test', now(), '{"full_name":"T1"}'),
  ('c0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 't2@v7.test', now(), '{"full_name":"T2"}'),
  ('c0000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 't3@v7.test', now(), '{"full_name":"T3"}'),
  ('c0000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 's1@v7.test', now(), '{"full_name":"S1"}'),
  ('c0000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 's2@v7.test', now(), '{"full_name":"S2"}'),
  ('c0000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 's3@v7.test', now(), '{"full_name":"S3"}'),
  ('c0000000-0000-0000-0000-000000000014', 'authenticated', 'authenticated', 's4@v7.test', now(), '{"full_name":"S4"}'),
  ('c0000000-0000-0000-0000-000000000015', 'authenticated', 'authenticated', 's5@v7.test', now(), '{"full_name":"S5"}');

:as_t1
select (public.create_course('Algebra') ->> 'id') as c1 \gset
select public.get_course_join_code(:'c1') as code \gset
select (public.create_assignment(:'c1', 'Essay', 'x', 50, now() + interval '2 days') ->> 'id') as a1 \gset
select (public.create_assignment(:'c1', 'Quiz', 'x', 100, now() + interval '1 day') ->> 'id') as a2 \gset
select (public.create_assignment(:'c1', 'Draft work', 'x', 100, now() + interval '3 days') ->> 'id') as a3 \gset
select (public.publish_assignment(:'a1', 1) ->> 'version') as p1 \gset
select (public.publish_assignment(:'a2', 1) ->> 'version') as p2 \gset
select (public.create_course('Old course') ->> 'id') as c2 \gset
select public.get_course_join_code(:'c2') as code2 \gset
select (public.create_assignment(:'c2', 'Old task', 'x', 100, now() + interval '5 days') ->> 'id') as a4 \gset
select (public.publish_assignment(:'a4', 1) ->> 'version') as p4 \gset
:as_s1
select (public.join_course_by_code(:'code') ->> 'joined') as j1 \gset
select (public.join_course_by_code(:'code2') ->> 'joined') as j1b \gset
:as_s2
select (public.join_course_by_code(:'code') ->> 'joined') as j2 \gset
:as_s3
select (public.join_course_by_code(:'code') ->> 'joined') as j3 \gset
:as_s4
select (public.join_course_by_code(:'code') ->> 'joined') as j4 \gset
:as_s1
select (public.submit_assignment(:'a1', gen_random_uuid(), 'a') ->> 'submission_id') as s1a1 \gset
select (public.submit_assignment(:'a2', gen_random_uuid(), 'a') ->> 'submission_id') as s1a2 \gset
:as_s2
select (public.submit_assignment(:'a1', gen_random_uuid(), 'a') ->> 'submission_id') as s2a1 \gset
:as_s4
select (public.submit_assignment(:'a1', gen_random_uuid(), 'a') ->> 'submission_id') as s4a1 \gset
:as_t1
select (public.grade_submission(:'s2a1', gen_random_uuid(), 1, 30, 'ok') ->> 'version') as g1 \gset
select (public.grade_submission(:'s1a2', gen_random_uuid(), 1, 80, '') ->> 'version') as g2 \gset
select (public.create_attendance_session(:'c1', gen_random_uuid(), 'Week 1', now()) ->> 'id') as ses \gset
select (public.mark_attendance(:'ses', 'c0000000-0000-0000-0000-000000000011', gen_random_uuid(), 0, 'present') ->> 'version') as m1 \gset
select (public.mark_attendance(:'ses', 'c0000000-0000-0000-0000-000000000012', gen_random_uuid(), 0, 'late') ->> 'version') as m2 \gset
select (public.mark_attendance(:'ses', 'c0000000-0000-0000-0000-000000000014', gen_random_uuid(), 0, 'absent') ->> 'version') as m4 \gset
select (public.close_attendance_session(:'ses', gen_random_uuid(), 1) ->> 'auto_absent') as auto \gset
select (public.remove_course_member(:'c1', 'c0000000-0000-0000-0000-000000000014') ->> 'removed') as rm \gset
-- the deadline of the quiz moves into the past after submissions exist
select (public.update_assignment(:'a2', 2, null, null, null, now() - interval '1 day') ->> 'version') as u2 \gset
select (public.update_course(:'c2', null, null, 'archived') ->> 'status') as arch \gset
reset role;
select set_config('app.c1', :'c1', true) \gset

-- A. Authorization
:as_s1
do $$ begin
  begin perform public.get_teacher_dashboard(); raise exception 'FAIL student reads teacher dashboard'; exception when sqlstate 'PT403' then null; end;
  raise notice 'PASS A1: student cannot call the teacher dashboard (PT403)';
end $$;
:as_t1
do $$ begin
  begin perform public.get_student_dashboard(); raise exception 'FAIL teacher reads student dashboard'; exception when sqlstate 'PT403' then null; end;
  raise notice 'PASS A2: teacher cannot call the student dashboard (PT403)';
end $$;
:as_anon
do $$ begin
  begin perform public.get_teacher_dashboard(); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform public.get_student_dashboard(); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  raise notice 'PASS A3: anon has no access';
end $$;

-- B. Teacher aggregates
:as_t1
do $$ declare d jsonb := public.get_teacher_dashboard(); begin
  if (d ->> 'courses_active')::int <> 1 or (d ->> 'courses_archived')::int <> 1 then raise exception 'FAIL courses %', d; end if;
  if (d ->> 'active_students')::int <> 3 then raise exception 'FAIL active_students (removed + archived-only students must not count) %', d; end if;
  if (d ->> 'published_assignments')::int <> 2 then raise exception 'FAIL published (draft/archived excluded) %', d; end if;
  if (d ->> 'expected_submissions')::int <> 6 or (d ->> 'received_submissions')::int <> 3 then raise exception 'FAIL expected/received %', d; end if;
  if (d ->> 'awaiting_grading')::int <> 1 or (d ->> 'graded')::int <> 2 or (d ->> 'returned')::int <> 0 then raise exception 'FAIL grading counts %', d; end if;
  if (d ->> 'attendance_rate')::numeric <> 66.7 then raise exception 'FAIL attendance rate (removed member excluded) %', d; end if;
  if (d ->> 'open_attendance_sessions')::int <> 0 then raise exception 'FAIL open sessions %', d; end if;
  raise notice 'PASS B1: teacher counts, removed member and archived course excluded, attendance rate 66.7';
end $$;
:as_t1
do $$ declare d jsonb := public.get_teacher_dashboard(); dl jsonb; begin
  if jsonb_array_length(d -> 'upcoming_deadlines') <> 1 then raise exception 'FAIL deadlines (past quiz and archived task excluded) %', d -> 'upcoming_deadlines'; end if;
  dl := d -> 'upcoming_deadlines' -> 0;
  if dl ->> 'title' <> 'Essay' or (dl ->> 'received')::int <> 2 or (dl ->> 'expected')::int <> 3 then raise exception 'FAIL deadline row %', dl; end if;
  if jsonb_array_length(d -> 'recent_activity') <> 3 then raise exception 'FAIL recent activity (removed excluded) %', d -> 'recent_activity'; end if;
  if jsonb_array_length(d -> 'courses') <> 2 then raise exception 'FAIL course rows'; end if;
  if (select (e ->> 'awaiting_grading')::int from jsonb_array_elements(d -> 'courses') e where e ->> 'title' = 'Algebra') <> 1 then raise exception 'FAIL per-course awaiting'; end if;
  raise notice 'PASS B2: upcoming deadline row (2 of 3 received), bounded recent activity, per-course rows';
end $$;

-- C. Student aggregates
:as_s1
do $$ declare d jsonb := public.get_student_dashboard(); c jsonb; begin
  if (d ->> 'published_assignments')::int <> 2 or (d ->> 'done')::int <> 2 or (d ->> 'awaiting_grade')::int <> 1 or (d ->> 'graded')::int <> 1
     or (d ->> 'not_started')::int <> 0 or (d ->> 'overdue')::int <> 0 then raise exception 'FAIL s1 counts %', d; end if;
  if (d ->> 'average_percent')::numeric <> 80.0 or (d ->> 'attendance_rate')::numeric <> 100.0 then raise exception 'FAIL s1 avg/attendance %', d; end if;
  if jsonb_array_length(d -> 'recent_graded') <> 1 or (d -> 'recent_graded' -> 0 ->> 'score')::int <> 80 then raise exception 'FAIL recent graded'; end if;
  select e into c from jsonb_array_elements(d -> 'courses') e where e ->> 'title' = 'Algebra';
  if (c ->> 'progress_percent')::numeric <> 100.0 or (c ->> 'attendance_rate')::numeric <> 100.0 then raise exception 'FAIL s1 course row %', c; end if;
  select e into c from jsonb_array_elements(d -> 'courses') e where e ->> 'title' = 'Old course';
  if c ->> 'status' <> 'archived' or (c ->> 'assignments')::int <> 0 or c -> 'progress_percent' <> 'null'::jsonb then raise exception 'FAIL archived row %', c; end if;
  raise notice 'PASS C1: s1 counts, avg 80.0, attendance 100, archived course listed but excluded from work figures';
end $$;
:as_s2
do $$ declare d jsonb := public.get_student_dashboard(); begin
  if (d ->> 'done')::int <> 1 or (d ->> 'graded')::int <> 1 or (d ->> 'not_started')::int <> 1 or (d ->> 'overdue')::int <> 1 then raise exception 'FAIL s2 %', d; end if;
  if (d ->> 'average_percent')::numeric <> 60.0 or (d ->> 'attendance_rate')::numeric <> 100.0 then raise exception 'FAIL s2 avg/attendance (late counts as attended) %', d; end if;
  if (d -> 'courses' -> 0 ->> 'progress_percent')::numeric <> 50.0 then raise exception 'FAIL s2 progress %', d; end if;
  raise notice 'PASS C2: s2 partial data: done 1 of 2, overdue 1, average 60.0';
end $$;
:as_s3
do $$ declare d jsonb := public.get_student_dashboard(); begin
  if (d ->> 'done')::int <> 0 or (d ->> 'not_started')::int <> 2 or (d ->> 'overdue')::int <> 1 then raise exception 'FAIL s3 %', d; end if;
  if d -> 'average_percent' <> 'null'::jsonb or (d ->> 'attendance_rate')::numeric <> 0.0 then raise exception 'FAIL s3 avg/attendance %', d; end if;
  if jsonb_array_length(d -> 'upcoming_deadlines') <> 1 or d -> 'upcoming_deadlines' -> 0 ->> 'title' <> 'Essay' then raise exception 'FAIL s3 deadlines %', d -> 'upcoming_deadlines'; end if;
  raise notice 'PASS C3: s3 nothing done, one overdue, past quiz not an upcoming deadline, attendance 0.0';
end $$;
:as_s4
do $$ declare d jsonb := public.get_student_dashboard(); begin
  if (d ->> 'courses_active')::int <> 0 or (d ->> 'published_assignments')::int <> 0 or jsonb_array_length(d -> 'courses') <> 0 then raise exception 'FAIL removed member still sees data %', d; end if;
  raise notice 'PASS C4: removed member sees an empty dashboard';
end $$;

-- D. Zero data and isolation
:as_s5
do $$ declare d jsonb := public.get_student_dashboard(); begin
  if (d ->> 'courses_active')::int <> 0 or d -> 'attendance_rate' <> 'null'::jsonb or d -> 'average_percent' <> 'null'::jsonb
     or jsonb_array_length(d -> 'upcoming_deadlines') <> 0 or jsonb_array_length(d -> 'recent_lessons') <> 0 then raise exception 'FAIL zero student %', d; end if;
  raise notice 'PASS D1: a student with no courses gets zeros, nulls and empty lists';
end $$;
:as_t3
do $$ declare d jsonb := public.get_teacher_dashboard(); begin
  if (d ->> 'courses_active')::int <> 0 or (d ->> 'expected_submissions')::int <> 0 or d -> 'attendance_rate' <> 'null'::jsonb
     or jsonb_array_length(d -> 'courses') <> 0 or jsonb_array_length(d -> 'recent_activity') <> 0 then raise exception 'FAIL zero teacher %', d; end if;
  raise notice 'PASS D2: a teacher with no courses gets zeros and empty lists';
end $$;
:as_t2
do $$ declare c uuid; d jsonb; begin
  c := (public.create_course('Other teacher course') ->> 'id')::uuid;
  d := public.get_teacher_dashboard();
  if (d ->> 'courses_active')::int <> 1 or (d ->> 'active_students')::int <> 0 or (d ->> 'received_submissions')::int <> 0
     or jsonb_array_length(d -> 'recent_activity') <> 0 or d -> 'attendance_rate' <> 'null'::jsonb then raise exception 'FAIL teacher isolation %', d; end if;
  raise notice 'PASS D3: another teacher sees none of this teacher''s students, submissions or attendance';
end $$;

reset role;
select 'ALL PASS V7 SQL' as result;
rollback;
