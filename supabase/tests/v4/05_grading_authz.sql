-- V4 SQL-layer tests: grade / return / revision state machine, authorization, validation, idempotent
-- replay, optimistic versions, deadline rules, max-score lock, history. One transaction, rolled back.
\set ON_ERROR_STOP 1
\set QUIET 1
\set as_t1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000001","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_t2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000002","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s1 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000011","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s2 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000012","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_s3 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"sub":"d0000000-0000-0000-0000-000000000013","role":"authenticated"}'', true); end $$; set local role authenticated;'
\set as_anon 'reset role; do $$ begin perform set_config(''request.jwt.claims'', ''{"role":"anon"}'', true); end $$; set local role anon;'

begin;
insert into public.teacher_invitations (email) values ('t1@v4.test'), ('t2@v4.test');
insert into auth.users (id, aud, role, email, email_confirmed_at, raw_user_meta_data) values
  ('d0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 't1@v4.test', now(), '{"full_name":"T1"}'),
  ('d0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 't2@v4.test', now(), '{"full_name":"T2"}'),
  ('d0000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated', 's1@v4.test', now(), '{"full_name":"S1"}'),
  ('d0000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated', 's2@v4.test', now(), '{"full_name":"S2"}'),
  ('d0000000-0000-0000-0000-000000000013', 'authenticated', 'authenticated', 's3@v4.test', now(), '{"full_name":"S3"}');

-- A. Course, published assignment (max 50), two submissions at version 1.
:as_t1
select (public.create_course('Algebra') ->> 'id') as c1 \gset
select public.get_course_join_code(:'c1') as code \gset
select (public.create_assignment(:'c1', 'Essay', 'Write', 50, now() + interval '7 days') ->> 'id') as a1 \gset
select (public.publish_assignment(:'a1', 1) ->> 'version') as pv \gset
:as_s1
select (public.join_course_by_code(:'code') ->> 'joined') as j1 \gset
:as_s2
select (public.join_course_by_code(:'code') ->> 'joined') as j2 \gset
:as_s1
select (public.submit_assignment(:'a1', gen_random_uuid(), 'S1 answer') ->> 'submission_id') as sub1 \gset
:as_s2
select (public.submit_assignment(:'a1', gen_random_uuid(), 'S2 answer') ->> 'submission_id') as sub2 \gset
reset role;
select set_config('app.a1', :'a1', true), set_config('app.sub1', :'sub1', true), set_config('app.sub2', :'sub2', true),
       set_config('app.c1', :'c1', true) \gset

-- B. Authorization and direct-write denial.
:as_s1
do $$ declare s uuid := current_setting('app.sub1')::uuid; begin
  begin perform public.grade_submission(s, gen_random_uuid(), 1, 50, 'self'); raise exception 'FAIL student graded own work'; exception when sqlstate 'PT404' then null; end;
  begin perform public.return_submission(s, gen_random_uuid(), 1, 'self'); raise exception 'FAIL student returned own work'; exception when sqlstate 'PT404' then null; end;
  begin update public.submissions set score = 50, status = 'graded'; raise exception 'FAIL direct grade update'; exception when insufficient_privilege then null; end;
  begin insert into public.submission_events (submission_id, assignment_id, actor_id, action, version_after, request_id, response)
        values (s, current_setting('app.a1')::uuid, auth.uid(), 'graded', 9, gen_random_uuid(), '{}'); raise exception 'FAIL direct event insert';
  exception when insufficient_privilege then null; end;
  if (select count(*) from public.submission_events) <> 0 then raise exception 'FAIL student sees history'; end if;
  raise notice 'PASS B1: a student cannot grade/return their own work (PT404) or write grading data directly';
end $$;
:as_t2
do $$ declare s uuid := current_setting('app.sub1')::uuid; begin
  begin perform public.grade_submission(s, gen_random_uuid(), 1, 10, 'x'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  begin perform public.return_submission(s, gen_random_uuid(), 1, 'x'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  if (select count(*) from public.submissions) <> 0 or (select count(*) from public.submission_events) <> 0 then raise exception 'FAIL unrelated teacher sees data'; end if;
  raise notice 'PASS B2: an unrelated teacher gets PT404 and sees no submissions or history';
end $$;
:as_s3
do $$ begin
  begin perform public.grade_submission(current_setting('app.sub1')::uuid, gen_random_uuid(), 1, 10, 'x'); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS B3: an outsider student cannot grade (PT404)';
end $$;
:as_anon
do $$ begin
  begin perform public.grade_submission(gen_random_uuid(), gen_random_uuid(), 1, 1, ''); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform public.return_submission(gen_random_uuid(), gen_random_uuid(), 1, 'x'); raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  begin perform 1 from public.submission_events; raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  raise notice 'PASS B4: anon denied on grading RPCs and history';
end $$;

-- C. Grading: validation, versions, idempotent replay.
:as_t1
do $$ declare s uuid := current_setting('app.sub1')::uuid; begin
  begin perform public.grade_submission(s, gen_random_uuid(), 1, -1, ''); raise exception 'FAIL'; exception when sqlstate 'PT400' then null; end;
  begin perform public.grade_submission(s, gen_random_uuid(), 1, 51, ''); raise exception 'FAIL over max'; exception when sqlstate 'PT400' then null; end;
  begin perform public.grade_submission(s, gen_random_uuid(), 1, null, ''); raise exception 'FAIL null'; exception when sqlstate 'PT400' then null; end;
  begin perform public.grade_submission(s, gen_random_uuid(), 1, 10, repeat('x', 5001)); raise exception 'FAIL long feedback'; exception when sqlstate 'PT400' then null; end;
  begin perform public.grade_submission(s, null, 1, 10, ''); raise exception 'FAIL null request'; exception when sqlstate 'PT400' then null; end;
  begin perform public.grade_submission(s, gen_random_uuid(), 7, 10, ''); raise exception 'FAIL stale'; exception when sqlstate 'PT409' then null; end;
  begin perform public.grade_submission(gen_random_uuid(), gen_random_uuid(), 1, 10, ''); raise exception 'FAIL unknown'; exception when sqlstate 'PT404' then null; end;
  if (select count(*) from public.submission_events) <> 0 then raise exception 'FAIL rejected attempts left history'; end if;
  raise notice 'PASS C1: score 0..max, feedback <= 5000, request id and expected version enforced; rejected attempts leave no trace';
end $$;
select gen_random_uuid() as g1 \gset
select set_config('app.g1', :'g1', true) \gset
select (public.grade_submission(:'sub1', :'g1', 1, 40, '  Good work  ') ->> 'version') as gv \gset
select (public.grade_submission(:'sub1', :'g1', 1, 40, 'Good work') ->> 'replayed') as greplay \gset
select 1 / (:'gv' = '2' and :'greplay' = 'true')::int as grade_ok_and_replayed;
do $$ begin
  if (select version from public.submissions where id = current_setting('app.sub1')::uuid) <> 2
     or (select count(*) from public.submission_events) <> 1 then raise exception 'FAIL replay changed state'; end if;
  begin perform public.grade_submission(current_setting('app.sub1')::uuid, current_setting('app.g1')::uuid, 1, 41, 'Good work'); raise exception 'FAIL reused key';
  exception when sqlstate 'PT409' then null; end;
  begin perform public.grade_submission(current_setting('app.sub1')::uuid, gen_random_uuid(), 1, 45, ''); raise exception 'FAIL stale after grade';
  exception when sqlstate 'PT409' then null; end;
  begin perform public.grade_submission(current_setting('app.sub2')::uuid, current_setting('app.g1')::uuid, 1, 40, 'Good work'); raise exception 'FAIL key reused on another submission';
  exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS C2: grade bumps version once; replay (same key) is a no-op; reused key / stale version -> PT409';
end $$;

-- D. Student sees the result; graded work is locked.
:as_s1
do $$ declare r record; begin
  select status, score, feedback, version into r from public.submissions;
  if r.status <> 'graded' or r.score <> 40 or r.feedback <> 'Good work' or r.version <> 2 then raise exception 'FAIL student result %', r; end if;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'edit after grade', null, 2); raise exception 'FAIL edit graded';
  exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS D: student reads status/score/feedback; a graded submission is locked (PT409)';
end $$;
:as_s2
do $$ begin
  if (select count(*) from public.submissions) <> 1 or (select status from public.submissions) <> 'submitted'
     or (select score from public.submissions) is not null then raise exception 'FAIL other student sees another result'; end if;
  raise notice 'PASS D2: each student sees only their own submission and result';
end $$;

-- E. Regrade, then return.
:as_t1
select (public.grade_submission(:'sub1', gen_random_uuid(), 2, 45, 'Even better') ->> 'version') as rv \gset
select 1 / (:'rv' = '3')::int as regrade_bumps_version;
do $$ declare s uuid := current_setting('app.sub1')::uuid; begin
  begin perform public.return_submission(s, gen_random_uuid(), 3, '   '); raise exception 'FAIL empty feedback'; exception when sqlstate 'PT400' then null; end;
  begin perform public.return_submission(s, gen_random_uuid(), 2, 'old version'); raise exception 'FAIL stale'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS E1: regrade allowed; return needs feedback (PT400) and the current version (PT409)';
end $$;
select gen_random_uuid() as rq \gset
select set_config('app.rq', :'rq', true) \gset
select (public.return_submission(:'sub1', :'rq', 3, 'Please add working') ->> 'status') as rs \gset
select (public.return_submission(:'sub1', :'rq', 3, 'Please add working') ->> 'replayed') as rr \gset
select 1 / (:'rs' = 'returned' and :'rr' = 'true')::int as return_ok_and_replayed;
do $$ declare s uuid := current_setting('app.sub1')::uuid; r record; begin
  select status, score, feedback, version into r from public.submissions where id = s;
  if r.status <> 'returned' or r.score is not null or r.feedback <> 'Please add working' or r.version <> 4 then raise exception 'FAIL returned state %', r; end if;
  begin perform public.grade_submission(s, gen_random_uuid(), 4, 30, 'x'); raise exception 'FAIL grade returned'; exception when sqlstate 'PT409' then null; end;
  begin perform public.return_submission(s, gen_random_uuid(), 4, 'again'); raise exception 'FAIL double return'; exception when sqlstate 'PT409' then null; end;
  begin update public.submissions set status = 'graded' where id = s; raise exception 'FAIL'; exception when insufficient_privilege then null; end;
  raise notice 'PASS E2: return clears the score, keeps feedback, bumps the version; a returned row cannot be graded or returned again';
end $$;

-- F. Student revision (after the teacher returned it).
:as_s1
do $$ declare a uuid := current_setting('app.a1')::uuid; begin
  begin perform public.submit_assignment(a, gen_random_uuid(), 'stale revise', null, 3); raise exception 'FAIL stale revise'; exception when sqlstate 'PT409' then null; end;
  if (select status from public.submissions) <> 'returned' or (select feedback from public.submissions) <> 'Please add working' then
    raise exception 'FAIL student sees returned status and feedback'; end if;
  raise notice 'PASS F1: student sees "returned" with feedback; a stale revision is refused';
end $$;
select gen_random_uuid() as rv1 \gset
select (public.submit_assignment(:'a1', :'rv1', 'S1 revised answer', null, 4) ->> 'version') as v5 \gset
select (public.submit_assignment(:'a1', :'rv1', 'S1 revised answer', null, 4) ->> 'replayed') as v5r \gset
select 1 / (:'v5' = '5' and :'v5r' = 'true')::int as resubmission_bumps_version_and_replays;
do $$ declare r record; begin
  select status, score, feedback, graded_at, version, answer into r from public.submissions;
  if r.status <> 'submitted' or r.score is not null or r.feedback is not null or r.graded_at is not null or r.answer <> 'S1 revised answer' then
    raise exception 'FAIL resubmission must clear score and feedback: %', r; end if;
  raise notice 'PASS F2: resubmission -> submitted, score/feedback/graded_at cleared, new text';
end $$;
:as_t1
select (public.grade_submission(:'sub1', gen_random_uuid(), 5, 48, 'Great revision') ->> 'status') as g2 \gset
select 1 / (:'g2' = 'graded')::int as regrade_after_revision;
do $$ begin
  if (select count(*) from public.submission_events where submission_id = current_setting('app.sub1')::uuid) <> 4
     or (select string_agg(action || ':' || coalesce(score::text, '-'), ',' order by created_at, version_after)
           from public.submission_events where submission_id = current_setting('app.sub1')::uuid) <> 'graded:40,graded:45,returned:-,graded:48' then
    raise exception 'FAIL history: %', (select string_agg(action || ':' || coalesce(score::text, '-'), ',' order by version_after) from public.submission_events); end if;
  raise notice 'PASS F3: full grading history kept (graded 40, graded 45, returned, graded 48)';
end $$;

-- G. Deadline rules: returned work may be revised after the deadline, plain work may not.
select (public.return_submission(:'sub1', gen_random_uuid(), 6, 'One more pass') ->> 'version') as v7 \gset
select (public.update_assignment(:'a1', 2, p_due_at => now() - interval '1 hour') ->> 'version') as av \gset
:as_s1
do $$ begin
  perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'r.txt', 'text/plain', 3);
  raise notice 'PASS G1: a returned submission may still get an upload ticket after the deadline';
end $$;
select (public.submit_assignment(:'a1', gen_random_uuid(), 'S1 after deadline', null, 7) ->> 'version') as v8 \gset
select 1 / (:'v8' = '8')::int as returned_work_revised_after_deadline;
:as_s2
do $$ begin
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'late', null, 1); raise exception 'FAIL late plain'; exception when sqlstate 'PT409' then null; end;
  begin perform public.prepare_submission_upload(current_setting('app.a1')::uuid, 'l.txt', 'text/plain', 3); raise exception 'FAIL late ticket'; exception when sqlstate 'PT409' then null; end;
  raise notice 'PASS G2: an unreturned submission is still closed by the deadline';
end $$;

-- H. max_score lock.
:as_t1
do $$ begin
  begin perform public.update_assignment(current_setting('app.a1')::uuid, (select version from public.assignments), p_max_score => 60); raise exception 'FAIL';
  exception when sqlstate 'PT409' then null; end;
  perform public.update_assignment(current_setting('app.a1')::uuid, (select version from public.assignments), p_title => 'Essay v2', p_max_score => 50);
  raise notice 'PASS H: max_score cannot change once students have submitted; other edits still work';
end $$;

-- I. Removed student: loses access to the result, teacher can still grade the work.
:as_t1
select (public.remove_course_member(:'c1', 'd0000000-0000-0000-0000-000000000012') ->> 'status') as rm \gset
select (public.grade_submission(:'sub2', gen_random_uuid(), 1, 20, 'Graded after removal') ->> 'status') as g3 \gset
select 1 / (:'g3' = 'graded')::int as teacher_grades_removed_students_work;
:as_s2
do $$ begin
  if (select count(*) from public.submissions) <> 0 then raise exception 'FAIL removed student sees the result'; end if;
  begin perform public.submit_assignment(current_setting('app.a1')::uuid, gen_random_uuid(), 'x', null, 2); raise exception 'FAIL'; exception when sqlstate 'PT404' then null; end;
  raise notice 'PASS I: removed student sees no result and cannot submit; teacher authority over the work is kept';
end $$;

-- J. Integrity: the status/score constraint holds even for the owner role.
reset role;
do $$ begin
  begin update public.submissions set status = 'graded', score = null where id = current_setting('app.sub1')::uuid; raise exception 'FAIL constraint';
  exception when check_violation then null; end;
  begin update public.submissions set score = 5 where id = current_setting('app.sub1')::uuid and status <> 'graded'; exception when check_violation then null; end;
  raise notice 'PASS J: graded <=> score constraint enforced by the database';
end $$;
select 'V4 SQL authorization suite: ALL PASS' as result;
rollback;
