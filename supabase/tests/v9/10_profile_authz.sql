-- Profile sprint SQL tests: the display name is the only client-writable profile column, rows are own-only,
-- and profile visibility stays limited to own row + active teacher/student pairs. One transaction, rolled back.
\set ON_ERROR_STOP 1
\set QUIET 1
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000012","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000013","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'

begin;
insert into public.teacher_invitations (email) values ('t1@v9.test'), ('t2@v9.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  ('d0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 't1@v9.test', now(), '{"full_name":"T1"}'),
  ('d0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 't2@v9.test', now(), '{"full_name":"T2"}'),
  ('d0000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 's1@v9.test', now(), '{"full_name":"S1"}'),
  ('d0000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 's2@v9.test', now(), '{"full_name":"S2"}'),
  ('d0000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 's3@v9.test', now(), '{"full_name":"S3"}');

:as_t1
select (public.create_course('Algebra') ->> 'id') as c1 \gset
select public.get_course_join_code(:'c1') as code \gset
:as_s1
select (public.join_course_by_code(:'code') ->> 'joined') as j1 \gset
:as_s2
select (public.join_course_by_code(:'code') ->> 'joined') as j2 \gset
:as_t1
select (public.remove_course_member(:'c1', 'd0000000-0000-0000-0000-000000000012') ->> 'removed') as rm \gset

-- A. Own display name: updatable, length enforced by the table
:as_s1
do $$ declare n int; begin
  update public.profiles set full_name = 'Sam Renamed' where id = 'd0000000-0000-0000-0000-000000000011';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL A1 own update affected % rows', n; end if;
  raise notice 'PASS A1: a student can change their own display name';
  begin
    update public.profiles set full_name = repeat('x', 121) where id = 'd0000000-0000-0000-0000-000000000011';
    raise exception 'FAIL A2 121-character name accepted';
  exception when check_violation then raise notice 'PASS A2: name longer than 120 characters rejected'; end;
end $$;

-- B. Protected columns and other rows
:as_s1
do $$ declare n int; begin
  begin
    update public.profiles set role = 'teacher' where id = 'd0000000-0000-0000-0000-000000000011';
    raise exception 'FAIL B1 student changed own role';
  exception when insufficient_privilege then raise notice 'PASS B1: role is not writable by a student'; end;
  begin
    update public.profiles set created_at = now() where id = 'd0000000-0000-0000-0000-000000000011';
    raise exception 'FAIL B2 created_at writable';
  exception when insufficient_privilege then raise notice 'PASS B2: other profile columns are not writable'; end;
  update public.profiles set full_name = 'Hacked' where id = 'd0000000-0000-0000-0000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL B3 student renamed the teacher (% rows)', n; end if;
  raise notice 'PASS B3: a student cannot rename their teacher';
end $$;
:as_t1
do $$ declare n int; begin
  update public.profiles set full_name = 'Hacked' where id = 'd0000000-0000-0000-0000-000000000011';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL B4 teacher renamed an enrolled student (% rows)', n; end if;
  raise notice 'PASS B4: a teacher cannot edit a student profile';
  begin
    update public.profiles set role = 'student' where id = 'd0000000-0000-0000-0000-000000000001';
    raise exception 'FAIL B5 teacher changed own role';
  exception when insufficient_privilege then raise notice 'PASS B5: a teacher cannot change a role'; end;
  begin
    insert into public.profiles (id, role) values (gen_random_uuid(), 'teacher');
    raise exception 'FAIL B6 profile insert allowed';
  exception when insufficient_privilege then raise notice 'PASS B6: clients cannot insert profiles'; end;
  begin
    delete from public.profiles where id = 'd0000000-0000-0000-0000-000000000011';
    raise exception 'FAIL B7 profile delete allowed';
  exception when insufficient_privilege then raise notice 'PASS B7: clients cannot delete profiles'; end;
end $$;

-- C. Visibility: own + active teacher/student pairs only
:as_s1
do $$ declare names text; begin
  select string_agg(full_name, ',' order by full_name) into names from public.profiles;
  if names <> 'Sam Renamed,T1' then raise exception 'FAIL C1 student sees %', names; end if;
  raise notice 'PASS C1: a student sees only self and their course teacher (no classmates, no other teachers)';
end $$;
:as_s2
do $$ declare names text; begin
  select string_agg(full_name, ',' order by full_name) into names from public.profiles;
  if names <> 'S2' then raise exception 'FAIL C2 removed student sees %', names; end if;
  raise notice 'PASS C2: a removed student loses sight of the teacher profile';
end $$;
:as_s3
do $$ declare names text; begin
  select string_agg(full_name, ',' order by full_name) into names from public.profiles;
  if names <> 'S3' then raise exception 'FAIL C3 outsider sees %', names; end if;
  raise notice 'PASS C3: a student outside the course sees only self';
end $$;
:as_t1
do $$ declare names text; begin
  select string_agg(full_name, ',' order by full_name) into names from public.profiles;
  if names <> 'Sam Renamed,T1' then raise exception 'FAIL C4 teacher sees %', names; end if;
  raise notice 'PASS C4: a teacher sees self and active students only (not removed ones, not other teachers)';
end $$;
:as_t2
do $$ declare names text; begin
  select string_agg(full_name, ',' order by full_name) into names from public.profiles;
  if names <> 'T2' then raise exception 'FAIL C5 other teacher sees %', names; end if;
  raise notice 'PASS C5: another teacher sees only self';
end $$;
:as_anon
do $$ begin
  begin
    perform 1 from public.profiles;
    raise exception 'FAIL C6 anon can read profiles';
  exception when insufficient_privilege then raise notice 'PASS C6: anon cannot read profiles'; end;
end $$;

reset role;
select 'ALL PASS PROFILE SQL' as result;
rollback;
