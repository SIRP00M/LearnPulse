-- V5 SQL-layer tests: lessons and resources. Authorization, draft/publish visibility, removed-member loss,
-- validation, optimistic versions, resource tickets, Storage policy helpers. One transaction, rolled back.
\set ON_ERROR_STOP 1
\set QUIET 1
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"e0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"e0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"e0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"e0000000-0000-0000-0000-000000000013","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'

begin;
insert into public.teacher_invitations (email) values ('t1@v5.test'), ('t2@v5.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  ('e0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 't1@v5.test', now(), '{"full_name":"T1"}'),
  ('e0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 't2@v5.test', now(), '{"full_name":"T2"}'),
  ('e0000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 's1@v5.test', now(), '{"full_name":"S1"}'),
  ('e0000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 's3@v5.test', now(), '{"full_name":"S3"}');

:as_t1
select (public.create_course('Physics') ->> 'id') as c1 \gset
select public.get_course_join_code(:'c1') as code \gset
select (public.create_lesson(:'c1', 'Motion', 'Newton') ->> 'id') as l1 \gset
:as_s1
select (public.join_course_by_code(:'code') ->> 'joined') as j1 \gset
reset role;
select set_config('app.c1', :'c1', true), set_config('app.l1', :'l1', true) \gset

-- A. Draft is invisible to students and outsiders; owner sees it.
:as_s1
do $$ begin
  if (select count(*) from public.lessons) <> 0 then raise exception 'FAIL student sees draft'; end if;
  begin perform public.create_lesson(current_setting('app.c1')::uuid, 'x'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.set_lesson_status(current_setting('app.l1')::uuid, 1, 'published'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin insert into public.lessons (course_id, title) values (current_setting('app.c1')::uuid, 'direct'); raise exception 'FAIL direct insert'; exception when insufficient_privilege then null; end;
  raise notice 'PASS A1: drafts hidden from students; students cannot write lessons (PT404 / no privilege)';
end $$;
:as_t2
do $$ begin
  if (select count(*) from public.lessons) <> 0 then raise exception 'FAIL other teacher sees lesson'; end if;
  begin perform public.update_lesson(current_setting('app.l1')::uuid, 1, 'hijack'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.delete_lesson(current_setting('app.l1')::uuid, 1); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.prepare_resource_upload(current_setting('app.l1')::uuid, 'a.pdf', 'application/pdf', 10); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS A2: another teacher gets PT404 everywhere';
end $$;
:as_anon
do $$ begin
  begin perform count(*) from public.lessons; raise exception 'FAIL anon select'; exception when insufficient_privilege then null; end;
  begin perform public.create_lesson(current_setting('app.c1')::uuid, 'x'); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  raise notice 'PASS A3: anon has no access';
end $$;

-- B. Versions, validation, publish.
:as_t1
do $$ declare l uuid := current_setting('app.l1')::uuid; r jsonb; begin
  begin perform public.update_lesson(l, 99, 'x'); raise exception 'FAIL'; exception when sqlstate 'PT409' then null; end;
  begin perform public.update_lesson(l, 1, '   '); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.update_lesson(l, 1, null, repeat('a', 20001)); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  r := public.update_lesson(l, 1, 'Motion 2'); if (r ->> 'version')::int <> 2 then raise exception 'FAIL version'; end if;
  r := public.set_lesson_status(l, 2, 'published'); if r ->> 'status' <> 'published' then raise exception 'FAIL publish'; end if;
  begin perform public.set_lesson_status(l, 3, 'published'); raise exception 'FAIL'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS B1: optimistic versions, validation, publish';
end $$;
:as_s1
do $$ begin
  if (select count(*) from public.lessons) <> 1 then raise exception 'FAIL member cannot see published lesson'; end if;
  raise notice 'PASS B2: active member sees the published lesson';
end $$;
:as_s3
do $$ begin
  if (select count(*) from public.lessons) <> 0 then raise exception 'FAIL non-member sees lesson'; end if;
  raise notice 'PASS B3: non-member sees nothing';
end $$;

-- C. Resource tickets: type / size / name validation, then Storage helper checks.
:as_t1
do $$ declare l uuid := current_setting('app.l1')::uuid; r jsonb; begin
  begin perform public.prepare_resource_upload(l, 'a.exe', 'application/octet-stream', 10); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_resource_upload(l, 'a.pdf', 'image/png', 10); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_resource_upload(l, 'a.pdf', 'application/pdf', 10485761); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_resource_upload(l, '../a.pdf', 'application/pdf', 10); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  r := public.prepare_resource_upload(l, 'notes.pdf', 'application/pdf', 100);
  perform set_config('app.res', r ->> 'resource_id', true); perform set_config('app.path', r ->> 'path', true);
  if r ->> 'path' not like current_setting('app.c1') || '/' || l::text || '/%/notes.pdf' then raise exception 'FAIL path shape %', r ->> 'path'; end if;
  begin perform public.finalize_resource((r ->> 'resource_id')::uuid); raise exception 'FAIL finalize without bytes'; exception when sqlstate 'PT409' then null; end;
  if not private.can_upload_resource_object(current_setting('app.path')) then raise exception 'FAIL owner cannot upload'; end if;
  if not private.can_read_resource_object(current_setting('app.path')) then raise exception 'FAIL owner cannot read'; end if;
  if private.can_upload_resource_object(current_setting('app.path') || 'x') then raise exception 'FAIL other path'; end if;
  raise notice 'PASS C1: ticket validation, finalize-without-upload denied, owner-only pending upload';
end $$;
:as_s1
do $$ begin
  if private.can_upload_resource_object(current_setting('app.path')) then raise exception 'FAIL student upload'; end if;
  if private.can_read_resource_object(current_setting('app.path')) then raise exception 'FAIL student reads pending'; end if;
  if (select count(*) from public.lesson_resources) <> 0 then raise exception 'FAIL student sees pending resource'; end if;
  raise notice 'PASS C2: pending upload is not writable or readable by students';
end $$;

-- D. Simulated stored object, finalize (idempotent), student read, unpublish and removal revoke access.
reset role;
insert into storage.objects (bucket_id, name, owner_id, metadata)
values ('course-files', current_setting('app.path'), 'e0000000-0000-0000-0000-000000000001',
        '{"size":100,"mimetype":"application/pdf"}');
:as_t1
do $$ declare r jsonb; begin
  r := public.finalize_resource(current_setting('app.res')::uuid, 'Notes');
  if r ->> 'status' <> 'attached' or r ->> 'title' <> 'Notes' then raise exception 'FAIL finalize %', r; end if;
  r := public.finalize_resource(current_setting('app.res')::uuid, 'Other');
  if (r ->> 'replayed')::boolean is not true or r ->> 'title' <> 'Notes' then raise exception 'FAIL replay %', r; end if;
  if private.can_upload_resource_object(current_setting('app.path')) then raise exception 'FAIL upload after attach'; end if;
  raise notice 'PASS D1: finalize verifies bytes, replay is idempotent, no re-upload after attach';
end $$;
:as_s1
do $$ begin
  if (select count(*) from public.lesson_resources) <> 1 or not private.can_read_resource_object(current_setting('app.path')) then
    raise exception 'FAIL member cannot read attached resource'; end if;
  raise notice 'PASS D2: member reads attached resource of a published lesson';
end $$;
:as_t1
select public.set_lesson_status(:'l1', 3, 'draft') as _ \gset
:as_s1
do $$ begin
  if (select count(*) from public.lesson_resources) <> 0 or private.can_read_resource_object(current_setting('app.path')) then
    raise exception 'FAIL unpublished lesson still readable'; end if;
  raise notice 'PASS D3: unpublish revokes lesson and file access';
end $$;
:as_t1
select public.set_lesson_status(:'l1', 4, 'published') as _ \gset
select public.remove_course_member(:'c1', 'e0000000-0000-0000-0000-000000000011') as _ \gset
:as_s1
do $$ begin
  if (select count(*) from public.lessons) <> 0 or (select count(*) from public.lesson_resources) <> 0
     or private.can_read_resource_object(current_setting('app.path')) then raise exception 'FAIL removed member keeps access'; end if;
  raise notice 'PASS D4: removed member loses lessons and files at once';
end $$;

-- E. Deleting a resource and a lesson.
:as_t1
do $$ begin
  perform public.delete_resource(current_setting('app.res')::uuid);
  if private.can_read_resource_object(current_setting('app.path')) then raise exception 'FAIL read after delete'; end if;
  begin perform public.delete_resource(current_setting('app.res')::uuid); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.delete_lesson(current_setting('app.l1')::uuid, 1); raise exception 'FAIL'; exception when sqlstate 'PT409' then null; end;
  perform public.delete_lesson(current_setting('app.l1')::uuid, 5);
  if (select count(*) from public.lessons) <> 0 then raise exception 'FAIL lesson not deleted'; end if;
  raise notice 'PASS E1: delete resource / lesson; stale version rejected';
end $$;
reset role;
select 'ALL PASS V5 SQL' as result;
rollback;
