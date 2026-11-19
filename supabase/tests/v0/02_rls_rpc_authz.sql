-- V0 authorization tests at the SQL layer (RLS, grants, RPC rules, role assignment).
-- Everything runs in one transaction that is rolled back. Not a substitute for http_authz.py.
\set ON_ERROR_STOP 1
\set QUIET 1
\set T1 'a0000000-0000-0000-0000-000000000001'
\set T2 'a0000000-0000-0000-0000-000000000002'
\set S1 'a0000000-0000-0000-0000-000000000011'
\set S2 'a0000000-0000-0000-0000-000000000012'
\set U1 'a0000000-0000-0000-0000-000000000021'
\set L1 'a0000000-0000-0000-0000-000000000022'
\set E1 'a0000000-0000-0000-0000-000000000023'

\set as_pg 'reset role;'
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"a0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"a0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"a0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"a0000000-0000-0000-0000-000000000012","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'
\set as_s3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"a0000000-0000-0000-0000-000000000013","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_service 'reset role; set local role service_role;'

begin;

-- Fixtures (as postgres). Invitations for T1, T2, L1; E1's invitation is expired; U1 is not invited.
insert into public.teacher_invitations (email) values ('t1@example.test'), ('t2@example.test'), ('l1@example.test');
insert into public.teacher_invitations (email, expires_at) values ('e1@example.test', now() - interval '1 day');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  (:'T1', 'authenticated', 'authenticated', 't1@example.test', now(), '{"full_name":"Teacher One"}'),
  (:'T2', 'authenticated', 'authenticated', 'T2@Example.test ', now(), '{"full_name":"Teacher Two"}'),
  (:'S1', 'authenticated', 'authenticated', 's1@example.test', now(), '{"full_name":"Student One","role":"teacher"}'),
  (:'S2', 'authenticated', 'authenticated', 's2@example.test', now(), '{"full_name":"Student Two"}'),
  (:'U1', 'authenticated', 'authenticated', 'u1@example.test', now(), '{"role":"teacher","full_name":"Fake Teacher"}'),
  (:'L1', 'authenticated', 'authenticated', 'l1@example.test', null, '{}'),
  (:'E1', 'authenticated', 'authenticated', 'e1@example.test', now(), '{}'),
  ('a0000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 's3@example.test', now(), '{}');

do $$ begin
  if (select role from public.profiles where id = 'a0000000-0000-0000-0000-000000000001') <> 'teacher'
     or (select role from public.profiles where id = 'a0000000-0000-0000-0000-000000000002') <> 'teacher' then
    raise exception 'FAIL invited confirmed emails (incl. case/space-normalised) must become teachers'; end if;
  if (select role from public.profiles where id = 'a0000000-0000-0000-0000-000000000011') <> 'student'
     or (select role from public.profiles where id = 'a0000000-0000-0000-0000-000000000021') <> 'student' then
    raise exception 'FAIL signup metadata role=teacher must be ignored'; end if;
  if (select role from public.profiles where id = 'a0000000-0000-0000-0000-000000000023') <> 'student' then
    raise exception 'FAIL expired invitation must not grant teacher'; end if;
  if (select role from public.profiles where id = 'a0000000-0000-0000-0000-000000000022') <> 'student' then
    raise exception 'FAIL unconfirmed invited email must not be teacher yet'; end if;
  raise notice 'PASS role assignment: invited+confirmed => teacher; metadata/expired/unconfirmed => student';
end $$;
update auth.users set email_confirmed_at = now() where id = :'L1';
do $$ begin
  if (select role from public.profiles where id = 'a0000000-0000-0000-0000-000000000022') <> 'teacher'
     or exists (select 1 from public.teacher_invitations where email = 'l1@example.test' and consumed_at is null) then
    raise exception 'FAIL confirming an invited email must promote exactly once'; end if;
  raise notice 'PASS late email confirmation promotes invited teacher and consumes invitation';
end $$;
-- Role is re-evaluated only on confirmation: a second confirmation cannot re-promote or demote.
update auth.users set email_confirmed_at = now() where id = :'S1';

-- Role-integrity triggers (as postgres)
do $$ begin
  begin insert into public.courses (owner_id, title, join_code) values ('a0000000-0000-0000-0000-000000000011', 'x', 'ABCDEFGH');
        raise exception 'FAIL student owned a course';
  exception when sqlstate 'PT403' then null; end;
  raise notice 'PASS trigger: only teachers can own courses';
end $$;

-- T1 / S1 / anon: RPC rules and visibility
:as_t1
select (public.create_course('Algebra', 'Intro') is not null) and (public.create_course('Physics') is not null) as created \gset
select id as c1_id_real, public.get_course_join_code(id) as c1_code from public.courses where title = 'Algebra' \gset
do $$ begin
  if (select count(*) from public.courses) <> 2 then raise exception 'FAIL teacher sees own 2 courses'; end if;
  begin perform public.create_course('   '); raise exception 'FAIL blank title accepted';
  exception when sqlstate 'PT400' then null; end;
  begin insert into public.courses (owner_id, title, join_code) values (auth.uid(), 'direct', 'ABCDEFGH');
        raise exception 'FAIL direct course insert allowed';
  exception when insufficient_privilege then null; end;
  begin update public.profiles set role = 'student' where id = auth.uid(); raise exception 'FAIL role update allowed';
  exception when insufficient_privilege then null; end;
  begin perform 1 from public.teacher_invitations; raise exception 'FAIL invitations readable by client';
  exception when insufficient_privilege then null; end;
  begin perform public.generate_join_code(); raise exception 'FAIL internal function callable';
  exception when insufficient_privilege then null; end;
  begin perform public.sync_profile_from_auth(); raise exception 'FAIL trigger function callable';
  exception when insufficient_privilege then null; end;
  raise notice 'PASS teacher: create_course ok; blank title PT400; direct writes, role update, invitations, internal functions denied';
end $$;

:as_s1
do $$ begin
  begin perform public.create_course('Nope'); raise exception 'FAIL student created course';
  exception when sqlstate 'PT403' then null; end;
  if (select count(*) from public.courses) <> 0 then raise exception 'FAIL non-member sees courses'; end if;
  raise notice 'PASS student: create_course PT403; non-member sees nothing';
end $$;
select (public.join_course_by_code(lower(:'c1_code'))) ->> 'joined' as j1 \gset
select (public.join_course_by_code(:'c1_code')) ->> 'joined' as j1b \gset
do $$ begin
  if (select count(*) from public.course_members) <> 1 then raise exception 'FAIL join not idempotent'; end if;
  if (select count(*) from public.courses) <> 1 or (select title from public.courses) <> 'Algebra' then
    raise exception 'FAIL member must see only the joined course'; end if;
  if (select count(*) from public.profiles) <> 2 then raise exception 'FAIL student sees self + course teacher only'; end if;
  begin insert into public.course_members (course_id, student_id) values (gen_random_uuid(), auth.uid());
        raise exception 'FAIL direct membership insert allowed';
  exception when insufficient_privilege then null; end;
  begin update public.courses set title = 'hacked'; raise exception 'FAIL student updated course';
  exception when insufficient_privilege then null; end;
  begin delete from public.profiles where id = auth.uid(); raise exception 'FAIL profile delete allowed';
  exception when insufficient_privilege then null; end;
  update public.profiles set full_name = 'Renamed' where id = auth.uid();
  if (select full_name from public.profiles where id = auth.uid()) <> 'Renamed' then raise exception 'FAIL own name update'; end if;
  update public.profiles set full_name = 'pwned' where id <> auth.uid();
  raise notice 'PASS student: idempotent join, scoped visibility, direct writes denied, own name editable';
end $$;
do $$ begin
  if (select full_name from public.profiles where id = 'a0000000-0000-0000-0000-000000000001') = 'pwned' then
    raise exception 'FAIL cross-user profile update'; end if;
  raise notice 'PASS cross-user profile update affected nothing';
end $$;

-- S2: outsider, invalid code, throttling
:as_s2
select (public.join_course_by_code('ZZZZZZZZ')) ->> 'reason' as bad_reason \gset
do $$ begin
  if (select count(*) from public.courses) <> 0 or (select count(*) from public.course_members) <> 0
     or (select count(*) from public.profiles) <> 1 then raise exception 'FAIL outsider sees course data'; end if;
  if private.is_course_owner(gen_random_uuid()) or private.is_course_member(gen_random_uuid()) then
    raise exception 'FAIL helper true for unknown course'; end if;
  raise notice 'PASS outsider student isolated (courses 0, members 0, profiles self only)';
end $$;
do $$ declare i int; begin
  for i in 1..9 loop perform public.join_course_by_code('YYYYYYY' || i); end loop;
  begin perform public.join_course_by_code('XXXXXXXX'); raise exception 'FAIL join throttle not enforced';
  exception when sqlstate 'PT429' then null; end;
  raise notice 'PASS join-code throttle: PT429 after 10 attempts in 10 min';
end $$;

-- T2: another teacher cannot see or touch T1's data
:as_t2
do $$ begin
  if (select count(*) from public.courses) <> 0 or (select count(*) from public.course_members) <> 0
     or (select count(*) from public.profiles) <> 1 then raise exception 'FAIL teacher T2 sees T1 data'; end if;
  begin update public.courses set title = 'x'; raise exception 'FAIL teacher update allowed';
  exception when insufficient_privilege then null; end;
  raise notice 'PASS cross-teacher isolation (courses 0, members 0, profiles self only)';
end $$;

-- T1 sees own roster; removed members lose access; archived/removed cannot rejoin
:as_t1
do $$ begin
  if (select count(*) from public.course_members) <> 1 or (select count(*) from public.profiles) <> 2 then
    raise exception 'FAIL teacher roster visibility'; end if;
  raise notice 'PASS teacher sees own roster and member profiles only';
end $$;
reset role;
update public.course_members set status = 'removed', removed_at = now() where student_id = :'S1';
:as_s1
do $$ begin
  if (select count(*) from public.courses) <> 0 or (select count(*) from public.profiles) <> 1 then
    raise exception 'FAIL removed member retains access'; end if;
end $$;
select (public.join_course_by_code(:'c1_code')) ->> 'reason' as removed_reason \gset
-- psql variables do not interpolate inside $$ bodies; division by zero = FAIL (removed student rejoined)
select 1 / (:'removed_reason' = 'removed')::int as removed_member_cannot_rejoin;
reset role;
update public.courses set status = 'archived' where id = :'c1_id_real';
:as_s3
select (public.join_course_by_code(:'c1_code')) ->> 'reason' as arch_reason \gset
select 1 / (:'arch_reason' = 'invalid_code')::int as archived_course_not_joinable;

-- anon: no table, function or schema access at all
:as_anon
do $$ begin
  begin perform 1 from public.courses; raise exception 'FAIL anon read courses';
  exception when insufficient_privilege then null; end;
  begin perform public.create_course('x'); raise exception 'FAIL anon called create_course';
  exception when insufficient_privilege then null; end;
  begin perform public.join_course_by_code('AAAAAAAA'); raise exception 'FAIL anon called join';
  exception when insufficient_privilege then null; end;
  begin perform private.is_course_owner(gen_random_uuid()); raise exception 'FAIL anon called helper';
  exception when insufficient_privilege then null; end;
  raise notice 'PASS anon denied on tables and functions';
end $$;

-- service_role: invitations only; no application data
:as_service
do $$ begin
  insert into public.teacher_invitations (email) values ('svc@example.test');
  begin perform 1 from public.courses; raise exception 'FAIL service_role read courses';
  exception when insufficient_privilege then null; end;
  begin perform 1 from public.profiles; raise exception 'FAIL service_role read profiles';
  exception when insufficient_privilege then null; end;
  raise notice 'PASS service_role limited to teacher_invitations';
end $$;

reset role;
do $$ begin
  begin insert into public.course_members (course_id, student_id)
        select id, 'a0000000-0000-0000-0000-000000000002' from public.courses limit 1;
        raise exception 'FAIL teacher enrolled as member';
  exception when sqlstate 'PT403' then null; end;
  raise notice 'PASS trigger: only students can be members';
end $$;
select 'V0 SQL authorization suite: ALL PASS' as result;
rollback;
