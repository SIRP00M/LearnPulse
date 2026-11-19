-- V6 SQL-layer tests: attendance. Authorization, isolation, lifecycle, idempotency, versions, history,
-- summary. One transaction, rolled back.
\set ON_ERROR_STOP 1
\set QUIET 1
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"f0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"f0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"f0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"f0000000-0000-0000-0000-000000000012","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"f0000000-0000-0000-0000-000000000013","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'

begin;
insert into public.teacher_invitations (email) values ('t1@v6.test'), ('t2@v6.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  ('f0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 't1@v6.test', now(), '{"full_name":"T1"}'),
  ('f0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 't2@v6.test', now(), '{"full_name":"T2"}'),
  ('f0000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 's1@v6.test', now(), '{"full_name":"S1"}'),
  ('f0000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 's2@v6.test', now(), '{"full_name":"S2"}'),
  ('f0000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 's3@v6.test', now(), '{"full_name":"S3"}');

:as_t1
select (public.create_course('Math') ->> 'id') as c1 \gset
select public.get_course_join_code(:'c1') as code \gset
:as_s1
select (public.join_course_by_code(:'code') ->> 'joined') as j1 \gset
:as_s2
select (public.join_course_by_code(:'code') ->> 'joined') as j2 \gset
:as_t1
select (public.create_attendance_session(:'c1', 'a0000000-0000-0000-0000-000000000001', 'Week 1', now()) ->> 'id') as ses \gset
reset role;
select set_config('app.c1', :'c1', true), set_config('app.ses', :'ses', true) \gset

-- A. Isolation: other teacher, outsider, anon, direct writes.
:as_t2
do $$ begin
  if (select count(*) from public.attendance_sessions) <> 0 then raise exception 'FAIL other teacher sees session'; end if;
  begin perform public.create_attendance_session(current_setting('app.c1')::uuid, gen_random_uuid(), 'x', now()); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.mark_attendance(current_setting('app.ses')::uuid, 'f0000000-0000-0000-0000-000000000011', gen_random_uuid(), 0, 'present'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.close_attendance_session(current_setting('app.ses')::uuid, gen_random_uuid(), 1); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.get_attendance_summary(current_setting('app.c1')::uuid); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS A1: unrelated teacher gets PT404 on every operation and sees nothing';
end $$;
:as_s3
do $$ begin
  if (select count(*) from public.attendance_sessions) <> 0 or (select count(*) from public.attendance_records) <> 0 then
    raise exception 'FAIL outsider sees data'; end if;
  begin perform public.get_attendance_summary(current_setting('app.c1')::uuid); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS A2: outsider student sees nothing';
end $$;
:as_s1
do $$ begin
  begin perform public.mark_attendance(current_setting('app.ses')::uuid, 'f0000000-0000-0000-0000-000000000011', gen_random_uuid(), 0, 'present'); raise exception 'FAIL self-mark'; exception when sqlstate 'PT404' then null; end;
  begin perform public.create_attendance_session(current_setting('app.c1')::uuid, gen_random_uuid(), 'x', now()); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.close_attendance_session(current_setting('app.ses')::uuid, gen_random_uuid(), 1); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin insert into public.attendance_records (session_id, student_id, status) values (current_setting('app.ses')::uuid, 'f0000000-0000-0000-0000-000000000011', 'present'); raise exception 'FAIL direct insert'; exception when insufficient_privilege then null; end;
  begin update public.attendance_records set status = 'present'; raise exception 'FAIL direct update'; exception when insufficient_privilege then null; end;
  if (select count(*) from public.attendance_events) <> 0 then raise exception 'FAIL student reads history'; end if;
  if (select count(*) from public.attendance_sessions) <> 1 then raise exception 'FAIL member cannot see the session'; end if;
  raise notice 'PASS A3: students cannot mark, create, close or write directly or read history; member sees the session';
end $$;
:as_anon
do $$ begin
  begin perform count(*) from public.attendance_sessions; raise exception 'FAIL anon select'; exception when insufficient_privilege then null; end;
  begin perform public.get_attendance_summary(current_setting('app.c1')::uuid); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  raise notice 'PASS A4: anon has no access';
end $$;

-- B. Teacher marking: validation, versions, idempotency, history.
:as_t1
do $$ declare s uuid := current_setting('app.ses')::uuid; r jsonb; rid uuid := 'b0000000-0000-0000-0000-000000000001'; begin
  r := public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000011', rid, 0, 'present', 'on time');
  if (r ->> 'version')::int <> 1 or r ->> 'status' <> 'present' then raise exception 'FAIL mark %', r; end if;
  r := public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000011', rid, 0, 'present', 'on time');
  if (r ->> 'replayed')::boolean is not true or (r ->> 'version')::int <> 1 then raise exception 'FAIL replay %', r; end if;
  begin perform public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000011', rid, 0, 'absent', 'on time'); raise exception 'FAIL'; exception when sqlstate 'PT409' then null; end;
  begin perform public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000011', gen_random_uuid(), 0, 'late'); raise exception 'FAIL stale'; exception when sqlstate 'PT409' then null; end;
  begin perform public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000012', gen_random_uuid(), 5, 'late'); raise exception 'FAIL new record wrong version'; exception when sqlstate 'PT409' then null; end;
  begin perform public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000012', gen_random_uuid(), 0, null); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000012', gen_random_uuid(), 0, 'late', repeat('n', 501)); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000013', gen_random_uuid(), 0, 'present'); raise exception 'FAIL non-member'; exception when sqlstate 'PT404' then null; end;
  begin perform public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000001', gen_random_uuid(), 0, 'present'); raise exception 'FAIL teacher as student'; exception when sqlstate 'PT404' then null; end;
  begin perform public.mark_attendance(gen_random_uuid(), 'f0000000-0000-0000-0000-000000000011', gen_random_uuid(), 0, 'present'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  r := public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000011', gen_random_uuid(), 1, 'late', 'bus delay');
  if (r ->> 'version')::int <> 2 or r ->> 'status' <> 'late' then raise exception 'FAIL correction %', r; end if;
  r := public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000011', gen_random_uuid(), 2, 'late', 'bus delay');
  if (r ->> 'unchanged')::boolean is not true or (r ->> 'version')::int <> 2 then raise exception 'FAIL noop %', r; end if;
  if (select count(*) from public.attendance_events where student_id = 'f0000000-0000-0000-0000-000000000011') <> 2 then
    raise exception 'FAIL history count'; end if;
  if not exists (select 1 from public.attendance_events where action = 'corrected' and old_status = 'present' and new_status = 'late') then
    raise exception 'FAIL history missing old->new'; end if;
  raise notice 'PASS B1: marking, replay, same-id different content, stale versions, validation, membership, correction history';
end $$;

-- C. Student sees only their own record; summary is role-aware.
:as_s1
do $$ declare r jsonb; begin
  if (select count(*) from public.attendance_records) <> 1 then raise exception 'FAIL s1 records'; end if;
  if (select status from public.attendance_records) <> 'late' then raise exception 'FAIL s1 status'; end if;
  r := public.get_attendance_summary(current_setting('app.c1')::uuid);
  if jsonb_array_length(r -> 'students') <> 1 or (r -> 'students' -> 0 ->> 'late')::int <> 1 then raise exception 'FAIL s1 summary %', r; end if;
  raise notice 'PASS C1: student reads only own record and own summary row';
end $$;
:as_s2
do $$ begin
  if (select count(*) from public.attendance_records) <> 0 then raise exception 'FAIL s2 sees s1'; end if;
  raise notice 'PASS C2: another student sees no one else''s attendance';
end $$;
:as_t1
do $$ declare r jsonb; begin
  r := public.get_attendance_summary(current_setting('app.c1')::uuid);
  if jsonb_array_length(r -> 'students') <> 2 or (r ->> 'sessions_total')::int <> 1 or (r ->> 'sessions_closed')::int <> 0 then
    raise exception 'FAIL teacher summary %', r; end if;
  raise notice 'PASS C3: teacher summary lists all active students';
end $$;

-- D. Close: auto-absent for unmarked active members, idempotent, locks new records, corrections still allowed.
:as_t1
do $$ declare s uuid := current_setting('app.ses')::uuid; r jsonb; cid uuid := 'b0000000-0000-0000-0000-0000000000c1'; begin
  begin perform public.close_attendance_session(s, gen_random_uuid(), 99); raise exception 'FAIL'; exception when sqlstate 'PT409' then null; end;
  r := public.close_attendance_session(s, cid, 1);
  if r ->> 'status' <> 'closed' or (r ->> 'auto_absent')::int <> 1 or (r ->> 'version')::int <> 2 then raise exception 'FAIL close %', r; end if;
  r := public.close_attendance_session(s, cid, 1);
  if (r ->> 'replayed')::boolean is not true then raise exception 'FAIL close replay'; end if;
  begin perform public.close_attendance_session(s, gen_random_uuid(), 2); raise exception 'FAIL double close'; exception when sqlstate 'PT409' then null; end;
  if (select status from public.attendance_records where student_id = 'f0000000-0000-0000-0000-000000000012') <> 'absent' then
    raise exception 'FAIL s2 not auto-absent'; end if;
  r := public.mark_attendance(s, 'f0000000-0000-0000-0000-000000000012', gen_random_uuid(), 1, 'excused', 'doctor');
  if r ->> 'status' <> 'excused' or (r ->> 'version')::int <> 2 then raise exception 'FAIL post-close correction %', r; end if;
  if (select count(*) from public.attendance_events where session_id = s and action = 'closed') <> 1 then raise exception 'FAIL close event'; end if;
  raise notice 'PASS D1: close finalizes roster once, replay safe, corrections after close recorded';
end $$;

-- E. Late joiner and removed member after close.
:as_s3
select (public.join_course_by_code(:'code') ->> 'joined') as j3 \gset
:as_t1
do $$ begin
  begin perform public.mark_attendance(current_setting('app.ses')::uuid, 'f0000000-0000-0000-0000-000000000013', gen_random_uuid(), 0, 'present'); raise exception 'FAIL mark in closed'; exception when sqlstate 'PT409' then null; end;
  perform public.remove_course_member(current_setting('app.c1')::uuid, 'f0000000-0000-0000-0000-000000000011');
  begin perform public.mark_attendance(current_setting('app.ses')::uuid, 'f0000000-0000-0000-0000-000000000011', gen_random_uuid(), 2, 'present'); raise exception 'FAIL removed'; exception when sqlstate 'PT404' then null; end;
  if exists (select 1 from jsonb_array_elements(public.get_attendance_summary(current_setting('app.c1')::uuid) -> 'students') e
              where e ->> 'student_id' = 'f0000000-0000-0000-0000-000000000011') then raise exception 'FAIL removed in summary'; end if;
  raise notice 'PASS E1: closed session accepts no new record; removed member cannot be marked or summarized';
end $$;
:as_s1
do $$ begin
  if (select count(*) from public.attendance_records) <> 0 or (select count(*) from public.attendance_sessions) <> 0 then
    raise exception 'FAIL removed member still reads'; end if;
  begin perform public.get_attendance_summary(current_setting('app.c1')::uuid); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS E2: removed member loses attendance access';
end $$;

-- F. Archived course freezes writes; session rules.
:as_t1
do $$ declare c uuid := current_setting('app.c1')::uuid; r jsonb; begin
  begin perform public.create_attendance_session(c, gen_random_uuid(), '  ', now()); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.create_attendance_session(c, gen_random_uuid(), 'Far', now() + interval '2 years'); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.create_attendance_session(c, gen_random_uuid(), 'Far', null); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.create_attendance_session(c, 'a0000000-0000-0000-0000-000000000001', 'Other title', now()); raise exception 'FAIL id reuse'; exception when sqlstate 'PT409' then null; end;
  r := public.create_attendance_session(c, 'a0000000-0000-0000-0000-000000000001', 'Week 1', (select starts_at from public.attendance_sessions limit 1));
  if (r ->> 'replayed')::boolean is not true then raise exception 'FAIL create replay'; end if;
  perform public.update_course(c, null, null, 'archived');
  begin perform public.create_attendance_session(c, gen_random_uuid(), 'x', now()); raise exception 'FAIL archived create'; exception when sqlstate 'PT409' then null; end;
  begin perform public.mark_attendance(current_setting('app.ses')::uuid, 'f0000000-0000-0000-0000-000000000012', gen_random_uuid(), 2, 'present'); raise exception 'FAIL archived mark'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS F1: session validation, create replay, archived course is read-only';
end $$;

reset role;
select 'ALL PASS V6 SQL' as result;
rollback;
