-- V3 SQL-layer tests: assignment visibility, teacher RPCs, upload tickets, idempotent / versioned
-- submissions, removed-member denial, Storage object helpers. One transaction, rolled back.
-- Real object bytes and HTTP-level Storage behaviour are covered by http_submissions.py.
\set ON_ERROR_STOP 1
\set QUIET 1
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000012","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"c0000000-0000-0000-0000-000000000013","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'

begin;
insert into public.teacher_invitations (email) values ('t1@v3.test'), ('t2@v3.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  ('c0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 't1@v3.test', now(), '{"full_name":"T1"}'),
  ('c0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 't2@v3.test', now(), '{"full_name":"T2"}'),
  ('c0000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 's1@v3.test', now(), '{"full_name":"S1"}'),
  ('c0000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 's2@v3.test', now(), '{"full_name":"S2"}'),
  ('c0000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 's3@v3.test', now(), '{"full_name":"S3"}');

-- Course with S1 and S2 enrolled; S3 is an outsider.
:as_t1
select (public.create_course('Algebra') ->> 'id') as c1 \gset
select public.get_course_join_code(:'c1') as code \gset
:as_s1
select (public.join_course_by_code(:'code') ->> 'joined') as j1 \gset
:as_s2
select (public.join_course_by_code(:'code') ->> 'joined') as j2 \gset
reset role;
select set_config('app.c1', :'c1', true) \gset

-- A. Teacher: drafts are invisible to students; validation; versions; publish.
:as_t1
select (public.create_assignment(:'c1', '  Essay ', 'Write 500 words', 50, now() + interval '7 days') ->> 'id') as a1 \gset
select (public.create_assignment(:'c1', 'Draft only') ->> 'id') as a2 \gset
reset role;
select set_config('app.a1', :'a1', true), set_config('app.a2', :'a2', true) \gset
:as_t1
do $$ begin
  begin perform public.create_assignment(current_setting('app.c1')::uuid, '   '); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.create_assignment(current_setting('app.c1')::uuid, 'x', '', 0); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.create_assignment(current_setting('app.c1')::uuid, 'x', '', 1001); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.create_assignment(gen_random_uuid(), 'x'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  if (select count(*) from public.assignments) <> 2 or (select title from public.assignments where id = current_setting('app.a1')::uuid) <> 'Essay' then
    raise exception 'FAIL teacher sees both drafts, title trimmed'; end if;
  begin update public.assignments set title = 'x'; raise exception 'FAIL direct update'; exception when insufficient_privilege then null; end;
  begin insert into public.assignments (course_id, title) values (current_setting('app.c1')::uuid, 'x'); raise exception 'FAIL direct insert'; exception when insufficient_privilege then null; end;
  raise notice 'PASS A1: teacher create/validate; direct writes denied';
end $$;
:as_s1
do $$ begin
  if (select count(*) from public.assignments) <> 0 then raise exception 'FAIL student sees a draft'; end if;
  begin perform public.create_assignment(current_setting('app.c1')::uuid, 'x'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'a.txt', 'text/plain', 5); raise exception 'FAIL draft upload'; exception when sqlstate 'PT404' then null; end;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'hi'); raise exception 'FAIL draft submit'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS A2: drafts invisible; student cannot create, upload to or submit a draft (PT404)';
end $$;
:as_t2
do $$ begin
  begin perform public.update_assignment(current_setting('app.a1')::uuid, 1, 'hacked'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.publish_assignment(current_setting('app.a1')::uuid, 1); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  if (select count(*) from public.assignments) <> 0 then raise exception 'FAIL other teacher sees assignments'; end if;
  raise notice 'PASS A3: another teacher: PT404 on update/publish, sees nothing';
end $$;
:as_t1
do $$ declare r jsonb; begin
  begin perform public.update_assignment(current_setting('app.a1')::uuid, 99, 'x'); raise exception 'FAIL stale'; exception when sqlstate 'PT409' then null; end;
  r := public.update_assignment(current_setting('app.a1')::uuid, 1, p_instructions => 'Write 600 words');
  if (r ->> 'version')::int <> 2 then raise exception 'FAIL version bump'; end if;
  begin perform public.publish_assignment(current_setting('app.a1')::uuid, 1); raise exception 'FAIL stale publish'; exception when sqlstate 'PT409' then null; end;
  r := public.publish_assignment(current_setting('app.a1')::uuid, 2);
  if r ->> 'status' <> 'published' or (r ->> 'version')::int <> 3 then raise exception 'FAIL publish'; end if;
  begin perform public.publish_assignment(current_setting('app.a1')::uuid, 3); raise exception 'FAIL republish'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS A4: optimistic versions (PT409 stale), publish once';
end $$;
:as_s1
do $$ begin
  if (select count(*) from public.assignments) <> 1 or (select count(*) from public.assignments where id = current_setting('app.a2')::uuid) <> 0 then
    raise exception 'FAIL student sees exactly the published assignment'; end if;
  raise notice 'PASS A5: enrolled student sees the published assignment only';
end $$;
:as_s3
do $$ begin
  if (select count(*) from public.assignments) <> 0 then raise exception 'FAIL outsider sees assignment'; end if;
  begin perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'a.txt', 'text/plain', 5); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'hi'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS A6: outsider student: nothing visible, PT404 on upload and submit';
end $$;

-- B. Upload tickets: strict validation.
:as_s1
do $$ declare a uuid := current_setting('app.a1')::uuid; begin
  begin perform public.prepare_submission_upload(a, 'virus.exe', 'application/octet-stream', 5); raise exception 'FAIL exe'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_submission_upload(a, 'x.pdf', 'text/plain', 5); raise exception 'FAIL mime mismatch'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_submission_upload(a, 'x.pdf', 'application/pdf', 0); raise exception 'FAIL zero'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_submission_upload(a, 'x.pdf', 'application/pdf', 10485761); raise exception 'FAIL too big'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_submission_upload(a, '../x.pdf', 'application/pdf', 5); raise exception 'FAIL traversal'; exception when sqlstate 'PT400' then null; end;
  begin perform public.prepare_submission_upload(a, 'noext', 'text/plain', 5); raise exception 'FAIL no ext'; exception when sqlstate 'PT400' then null; end;
  raise notice 'PASS B1: extension, MIME-match, size and path-traversal validation (PT400)';
end $$;
select (t.r ->> 'upload_id') as u1, (t.r ->> 'path') as p1 from (select public.prepare_submission_upload(:'a1', 'My Essay (final).TXT', 'text/plain', 11) as r) t \gset
reset role;
select set_config('app.u1', :'u1', true), set_config('app.p1', :'p1', true) \gset
do $$ begin
  if (select storage_path from public.submission_uploads where id = current_setting('app.u1')::uuid) !~ '^[0-9a-f-]{36}/c0000000-0000-0000-0000-000000000011/[0-9a-f-]{36}/My_Essay__final_.TXT$' then
    raise exception 'FAIL storage path shape: %', (select storage_path from public.submission_uploads where id = current_setting('app.u1')::uuid); end if;
  raise notice 'PASS B2: ticket path = assignment/student/upload/sanitized-name';
end $$;

-- C. Storage object helpers: only the ticket owner may upload; owner teacher and the student may read.
:as_s1
select private.can_upload_object(:'p1') as s1_can_upload \gset
:as_s2
select private.can_upload_object(:'p1') as s2_can_upload, private.can_read_object(:'p1') as s2_can_read \gset
:as_t1
select private.can_read_object(:'p1') as t1_can_read, private.can_upload_object(:'p1') as t1_can_upload \gset
:as_t2
select private.can_read_object(:'p1') as t2_can_read \gset
:as_s1
select private.can_read_object(:'p1') as s1_can_read, private.can_upload_object('x/y/z/none.txt') as unknown_path \gset
select 1 / (:'s1_can_upload'::boolean and not :'s2_can_upload'::boolean and not :'s2_can_read'::boolean
            and :'t1_can_read'::boolean and not :'t1_can_upload'::boolean and not :'t2_can_read'::boolean
            and :'s1_can_read'::boolean and not :'unknown_path'::boolean)::int as storage_helper_matrix;

-- D. Submissions: idempotent replay, versions, attachments (object rows stand in for uploaded bytes here).
select gen_random_uuid() as r1 \gset
select set_config('app.r1', :'r1', true) \gset
:as_s1
select (public.submit_assignment(:'a1', :'r1', 'My first answer') ->> 'version') as v1 \gset
select (public.submit_assignment(:'a1', :'r1', 'My first answer') ->> 'replayed') as replay \gset
select 1 / (:'v1' = '1' and :'replay' = 'true')::int as replay_returns_same_response;
do $$ begin
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, current_setting('app.r1')::uuid, 'DIFFERENT');
        raise exception 'FAIL reused key'; exception when sqlstate 'PT409' then null; end;
  if (select count(*) from public.submissions) <> 1 then raise exception 'FAIL replay created a second row'; end if;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'x'); raise exception 'FAIL missing expected version';
        exception when sqlstate 'PT409' then null; end;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), '   ', null, 1); raise exception 'FAIL empty';
        exception when sqlstate 'PT400' then null; end;
  raise notice 'PASS D1: replay returns the stored response; reused key with new content PT409; stale/missing version PT409; empty PT400';
end $$;
-- attachment with no object / wrong object / right object
do $$ begin
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'v2', current_setting('app.u1')::uuid, 1);
        raise exception 'FAIL attach without object'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS D2: attaching a file that was never uploaded -> PT409';
end $$;
reset role;
insert into storage.objects (bucket_id, name, owner, metadata)
  values ('submission-files', :'p1', 'c0000000-0000-0000-0000-000000000011', '{"size": 999, "mimetype": "text/plain"}');
:as_s1
do $$ begin
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'v2', current_setting('app.u1')::uuid, 1);
        raise exception 'FAIL size mismatch'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS D3: stored object size differing from the declared size -> PT409';
end $$;
reset role;
update storage.objects set metadata = '{"size": 11, "mimetype": "text/plain"}' where name = :'p1';
:as_s1
select (public.submit_assignment(:'a1', gen_random_uuid(), 'Second answer', :'u1', 1) ->> 'version') as v2 \gset
select 1 / (:'v2' = '2')::int as attach_and_version_bump;
do $$ begin
  if (select status from public.submission_uploads where id = current_setting('app.u1')::uuid) <> 'attached'
     or (select upload_id from public.submissions) <> current_setting('app.u1')::uuid then raise exception 'FAIL attachment link'; end if;
  if private.can_upload_object(current_setting('app.p1')) then raise exception 'FAIL attached upload still writable'; end if;
  raise notice 'PASS D4: verified object attaches; submission version 2; ticket no longer accepts uploads';
end $$;
select (public.submit_assignment(:'a1', gen_random_uuid(), 'Third answer (keeps file)', null, 2) ->> 'upload_id') as keep \gset
select (public.submit_assignment(:'a1', gen_random_uuid(), 'Fourth answer (drops file)', null, 3, true) ->> 'upload_id') is null as dropped \gset
select 1 / (:'keep' = :'u1' and :'dropped'::boolean)::int as attachment_kept_then_cleared;

-- E. Visibility between students and teachers.
:as_s2
do $$ begin
  if (select count(*) from public.submissions) <> 0 or (select count(*) from public.submission_uploads) <> 0 then
    raise exception 'FAIL other student sees submission'; end if;
  raise notice 'PASS E1: another student sees no submissions or uploads';
end $$;
:as_t1
do $$ begin
  if (select count(*) from public.submissions) <> 1 or (select count(*) from public.submission_uploads) <> 1 then
    raise exception 'FAIL teacher sees the submission and its upload'; end if;
  begin update public.submissions set answer = 'x'; raise exception 'FAIL teacher edits submission'; exception when insufficient_privilege then null; end;
  raise notice 'PASS E2: owner teacher reads submission and upload metadata; cannot write directly';
end $$;
:as_t2
do $$ begin
  if (select count(*) from public.submissions) <> 0 then raise exception 'FAIL other teacher sees submissions'; end if;
  raise notice 'PASS E3: other teacher sees no submissions';
end $$;

-- F. Deadline: closed for uploads and submits; a committed request still replays.
:as_t1
do $$ declare r jsonb; begin
  r := public.update_assignment(current_setting('app.a1')::uuid, 3, p_due_at => now() - interval '1 minute');
  raise notice 'deadline set in the past, version %', r ->> 'version';
end $$;
:as_s1
do $$ declare v int; begin
  select version into v from public.submissions;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'late', null, v); raise exception 'FAIL late submit'; exception when sqlstate 'PT409' then null; end;
  begin perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'late.txt', 'text/plain', 4); raise exception 'FAIL late upload'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS F1: after the deadline submit and upload are refused (PT409)';
end $$;
select 1 / ((public.submit_assignment(:'a1', :'r1', 'My first answer') ->> 'replayed') = 'true')::int as committed_request_replays_after_deadline;

-- G. Removed member: no visibility, no submit, no upload, no object access, no replay.
:as_t1
select (public.update_assignment(:'a1', 4, p_clear_due => true) ->> 'version') as v_reopen \gset
select (public.remove_course_member(:'c1', 'c0000000-0000-0000-0000-000000000011') ->> 'status') as removed \gset
:as_s1
do $$ begin
  if (select count(*) from public.assignments) <> 0 or (select count(*) from public.submissions) <> 0
     or (select count(*) from public.submission_uploads) <> 0 then raise exception 'FAIL removed member keeps visibility'; end if;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'x', null, 4); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'x.txt', 'text/plain', 1); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  if private.can_read_object(current_setting('app.p1')) then raise exception 'FAIL removed member can read the object'; end if;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, current_setting('app.r1')::uuid, 'My first answer');
        raise exception 'FAIL replay for removed member'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS G: removed member loses assignment/submission/file access and cannot submit, upload or replay';
end $$;
:as_t1
do $$ begin
  if not private.can_read_object(current_setting('app.p1')) then raise exception 'FAIL teacher still reads removed student''s file'; end if;
  raise notice 'PASS G2: owner teacher keeps access to the submitted file after removal';
end $$;

-- H. Expired pending uploads, throttle, role rules, anon.
reset role;
:as_s2
do $$ declare t jsonb; begin
  t := public.prepare_submission_upload(current_setting('app.a1')::uuid, 'ok.txt', 'text/plain', 3);
  for i in 1..9 loop perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'ok' || i || '.txt', 'text/plain', 3); end loop;
  begin perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'ok11.txt', 'text/plain', 3); raise exception 'FAIL throttle'; exception when sqlstate 'PT429' then null; end;
  raise notice 'PASS H1: 10 pending uploads per hour, the 11th is PT429';
end $$;
:as_t1
do $$ begin
  begin perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'x.txt', 'text/plain', 1); raise exception 'FAIL'; exception when sqlstate 'PT403' then null; end;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'x'); raise exception 'FAIL'; exception when sqlstate 'PT403' then null; end;
  raise notice 'PASS H2: teachers cannot upload or submit (PT403)';
end $$;
:as_anon
do $$ begin
  begin perform 1 from public.assignments; raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform public.submit_assignment(gen_random_uuid(), gen_random_uuid(), 'x'); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform public.create_assignment(gen_random_uuid(), 'x'); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform private.can_read_object('x'); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  raise notice 'PASS H3: anon denied on tables, RPCs and storage helpers';
end $$;
reset role;
select id as old_up from public.submission_uploads where student_id = 'c0000000-0000-0000-0000-000000000012' order by created_at limit 1 \gset
update public.submission_uploads set created_at = now() - interval '25 hours' where id = :'old_up';
select count(*) as stale_listed from private.stale_pending_uploads(interval '24 hours') \gset
select 1 / (:'stale_listed'::int = 1)::int as expired_pending_upload_listed_for_cleanup;
select set_config('app.old_up', :'old_up', true) \gset
:as_s2
do $$ begin
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'late attach', current_setting('app.old_up')::uuid);
        raise exception 'FAIL expired upload attached'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS H4: an expired pending upload cannot be attached (PT409) and is listed for cleanup';
end $$;
reset role;
select 'V3 SQL authorization suite: ALL PASS' as result;
rollback;
