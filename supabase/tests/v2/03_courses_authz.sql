-- V2 SQL-layer tests: join-code secrecy, update_course, remove_course_member, roster visibility.
-- One transaction, rolled back. HTTP-level proof is in http_courses.py.
\set ON_ERROR_STOP 1
\set QUIET 1
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"b0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"b0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"b0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"b0000000-0000-0000-0000-000000000012","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'

begin;
insert into public.teacher_invitations (email) values ('t1@v2.test'), ('t2@v2.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  ('b0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 't1@v2.test', now(), '{"full_name":"Teacher One"}'),
  ('b0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 't2@v2.test', now(), '{"full_name":"Teacher Two"}'),
  ('b0000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 's1@v2.test', now(), '{"full_name":"Student One"}'),
  ('b0000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 's2@v2.test', now(), '{"full_name":"Student Two"}');

-- A. Teacher creates courses; the code is obtainable only through the owner-only RPC.
:as_t1
select (public.create_course('Algebra', 'Intro') ->> 'id') as c1 \gset
select (public.create_course('Physics') ->> 'id') as c2 \gset
select public.get_course_join_code(:'c1') as code1 \gset
reset role;
select set_config('app.c1', :'c1', true), set_config('app.c2', :'c2', true) \gset
:as_t1
do $$ begin
  begin perform join_code from public.courses; raise exception 'FAIL teacher read join_code column';
  exception when insufficient_privilege then null; end;
  begin perform * from public.courses; raise exception 'FAIL select * must be denied';
  exception when insufficient_privilege then null; end;
  if (select count(*) from public.courses) <> 2 then raise exception 'FAIL teacher sees own 2 courses'; end if;
  raise notice 'PASS A: join_code column unreadable even by the owner; two courses listed';
end $$;

-- B/D. Student joins; cannot read the code and cannot manage anything.
:as_s1
select (public.join_course_by_code(:'code1') ->> 'joined') as j1 \gset
do $$ begin
  begin perform public.get_course_join_code(current_setting('app.c1')::uuid); raise exception 'FAIL student read code';
  exception when sqlstate 'PT404' then null; end;
  begin perform public.update_course(current_setting('app.c1')::uuid, 'hacked'); raise exception 'FAIL student update';
  exception when sqlstate 'PT404' then null; end;
  begin perform public.remove_course_member(current_setting('app.c1')::uuid, auth.uid()); raise exception 'FAIL student remove';
  exception when sqlstate 'PT404' then null; end;
  begin update public.courses set title = 'x'; raise exception 'FAIL direct update';
  exception when insufficient_privilege then null; end;
  if (select count(*) from public.courses) <> 1 then raise exception 'FAIL member sees only the joined course'; end if;
  raise notice 'PASS B/D: student cannot read the code or manage courses (PT404, no direct writes)';
end $$;

-- C. Another teacher: no visibility, no management, uniform PT404.
:as_t2
do $$ begin
  begin perform public.update_course(current_setting('app.c1')::uuid, 'hacked'); raise exception 'FAIL';
  exception when sqlstate 'PT404' then null; end;
  begin perform public.get_course_join_code(current_setting('app.c1')::uuid); raise exception 'FAIL';
  exception when sqlstate 'PT404' then null; end;
  begin perform public.remove_course_member(current_setting('app.c1')::uuid, 'b0000000-0000-0000-0000-000000000011'); raise exception 'FAIL';
  exception when sqlstate 'PT404' then null; end;
  begin perform public.update_course(gen_random_uuid(), 'x'); raise exception 'FAIL';
  exception when sqlstate 'PT404' then null; end;
  if (select count(*) from public.courses) <> 0 or (select count(*) from public.course_members) <> 0
     or (select count(*) from public.profiles) <> 1 then raise exception 'FAIL other teacher sees data'; end if;
  raise notice 'PASS C: other teacher gets PT404 everywhere and sees nothing (unknown id indistinguishable)';
end $$;

-- E. Owner edits and archives.
:as_t1
do $$ declare r jsonb; begin
  r := public.update_course(current_setting('app.c1')::uuid, '  Algebra II ', 'New description');
  if r ->> 'title' <> 'Algebra II' or r ->> 'description' <> 'New description' then raise exception 'FAIL edit'; end if;
  begin perform public.update_course(current_setting('app.c1')::uuid, '   '); raise exception 'FAIL blank';
  exception when sqlstate 'PT400' then null; end;
  begin perform public.update_course(current_setting('app.c1')::uuid, repeat('x', 121)); raise exception 'FAIL long';
  exception when sqlstate 'PT400' then null; end;
  r := public.update_course(current_setting('app.c1')::uuid, p_status => 'archived');
  if r ->> 'status' <> 'archived' or r ->> 'title' <> 'Algebra II' then raise exception 'FAIL archive keeps other fields'; end if;
  raise notice 'PASS E: edit trims/validates (PT400), archive only changes status';
end $$;
:as_s2
select (public.join_course_by_code(:'code1') ->> 'reason') as arch \gset
select 1 / (:'arch' = 'invalid_code')::int as archived_course_not_joinable;
:as_t1
select (public.update_course(:'c1', p_status => 'active') ->> 'status') as reopened \gset
select 1 / (:'reopened' = 'active')::int as reopened_ok;
:as_s2
select (public.join_course_by_code(:'code1') ->> 'joined') as j2 \gset
select 1 / (:'j2' = 'true')::int as second_student_joins_after_reopen;

-- F. Roster: owner sees active members with names; removal revokes access and blocks self-rejoin.
:as_t1
do $$ begin
  if (select count(*) from public.course_members where course_id = current_setting('app.c1')::uuid and status = 'active') <> 2
     or (select count(*) from public.profiles) <> 3 then raise exception 'FAIL roster shows 2 active students + self'; end if;
  perform public.remove_course_member(current_setting('app.c1')::uuid, 'b0000000-0000-0000-0000-000000000011');
  begin perform public.remove_course_member(current_setting('app.c1')::uuid, 'b0000000-0000-0000-0000-000000000011'); raise exception 'FAIL';
  exception when sqlstate 'PT404' then null; end;
  if (select count(*) from public.course_members where status = 'removed') <> 1
     or (select count(*) from public.profiles) <> 2 then raise exception 'FAIL removed member stays in roster history but loses profile visibility'; end if;
  raise notice 'PASS F1: roster lists members with names; removal is idempotent-safe (PT404 on repeat)';
end $$;
:as_s1
do $$ begin
  if (select count(*) from public.courses) <> 0 or (select count(*) from public.profiles) <> 1 then
    raise exception 'FAIL removed student retains access'; end if;
  raise notice 'PASS F2: removed student loses course and teacher-profile visibility';
end $$;
select (public.join_course_by_code(:'code1') ->> 'reason') as rej \gset
select 1 / (:'rej' = 'removed')::int as removed_student_cannot_rejoin;

-- G. anon: nothing.
:as_anon
do $$ begin
  begin perform public.get_course_join_code(gen_random_uuid()); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform public.update_course(gen_random_uuid(), 'x'); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform public.remove_course_member(gen_random_uuid(), gen_random_uuid()); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  raise notice 'PASS G: anon cannot call any V2 RPC';
end $$;

reset role;
select 'V2 SQL authorization suite: ALL PASS' as result;
rollback;
