-- V7 performance smoke: 1 teacher, 5 courses x 60 students x 10 published assignments, ~2400 submissions,
-- 20 attendance sessions per course with full records. Both dashboards must answer in well under a second.
-- Data is inserted directly as postgres (bypassing RPCs) inside a transaction that is rolled back.
\set ON_ERROR_STOP 1
\set QUIET 1
begin;
insert into public.teacher_invitations (email) values ('perf-t@v7.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data)
select ('d0000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid, 'authenticated', 'authenticated',
       'perf' || n || '@v7.test', now(), '{"full_name":"Perf"}'
  from generate_series(1, 60) n;
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data)
values ('d1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'perf-t@v7.test', now(), '{"full_name":"PerfT"}');

insert into public.courses (id, owner_id, title, join_code)
select gen_random_uuid(), 'd1000000-0000-0000-0000-000000000001', 'Course ' || n, public.generate_join_code() from generate_series(1, 5) n;
insert into public.course_members (course_id, student_id)
select c.id, p.id from public.courses c cross join public.profiles p where p.role = 'student' and p.id::text like 'd0000000-%';
insert into public.assignments (course_id, title, max_score, due_at, status, published_at)
select c.id, 'A' || n, 100, now() + (n || ' days')::interval, 'published', now()
  from public.courses c cross join generate_series(1, 10) n;
insert into public.submissions (assignment_id, student_id, status, score, graded_at)
select a.id, m.student_id, st.s::public.submission_status, case when st.s = 'graded' then 70 end,
       case when st.s = 'graded' then now() end
  from public.assignments a join public.course_members m on m.course_id = a.course_id
  cross join lateral (select case when random() < 0.5 then 'graded' else 'submitted' end as s) st
 where random() < 0.8;
insert into public.attendance_sessions (course_id, title, starts_at, request_id, created_by, status, closed_at)
select c.id, 'S' || n, now() - (n || ' days')::interval, gen_random_uuid(), 'd1000000-0000-0000-0000-000000000001', 'closed', now()
  from public.courses c cross join generate_series(1, 20) n;
insert into public.attendance_records (session_id, student_id, status)
select s.id, m.student_id, (array['present', 'late', 'absent', 'excused'])[1 + floor(random() * 4)::int]::public.attendance_status
  from public.attendance_sessions s join public.course_members m on m.course_id = s.course_id;
analyze;

do $$
declare t0 timestamptz; ms numeric; d jsonb; n_sub bigint; n_rec bigint;
begin
  select count(*) into n_sub from public.submissions;
  select count(*) into n_rec from public.attendance_records;
  perform set_config('request.jwt.claims', '{"sub":"d1000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
  set local role authenticated;
  t0 := clock_timestamp();
  d := public.get_teacher_dashboard();
  ms := extract(milliseconds from clock_timestamp() - t0);
  reset role;
  raise notice 'teacher dashboard: % ms over % submissions / % attendance records (students %)', round(ms), n_sub, n_rec, d ->> 'active_students';
  if ms > 1000 then raise exception 'FAIL teacher dashboard too slow: % ms', ms; end if;
  if (d ->> 'active_students')::int <> 60 or jsonb_array_length(d -> 'courses') <> 5
     or jsonb_array_length(d -> 'recent_activity') > 10 or jsonb_array_length(d -> 'upcoming_deadlines') > 5 then
    raise exception 'FAIL teacher dashboard shape or bounds %', d; end if;

  perform set_config('request.jwt.claims', '{"sub":"d0000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
  set local role authenticated;
  t0 := clock_timestamp();
  d := public.get_student_dashboard();
  ms := extract(milliseconds from clock_timestamp() - t0);
  reset role;
  raise notice 'student dashboard: % ms (5 courses, 50 assignments)', round(ms);
  if ms > 1000 then raise exception 'FAIL student dashboard too slow: % ms', ms; end if;
  if (d ->> 'published_assignments')::int <> 50 or jsonb_array_length(d -> 'courses') <> 5 then raise exception 'FAIL student shape %', d; end if;
  raise notice 'PASS V7 performance smoke (both under 1000 ms, output bounded)';
end $$;
rollback;
