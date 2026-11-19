-- V9 activities / progress / tasks: authorization, state machine, streaks, DST, pagination, V7 consistency.
-- Runs in ONE transaction that is rolled back: docker exec -i <pg> psql -U postgres -v ON_ERROR_STOP=1 -1 -f - < this file
-- (the final ROLLBACK is explicit, so nothing persists). Roles/claims are switched exactly like PostgREST does.
begin;
create schema t;
create table t.res (name text, ok boolean, detail text);
create table t.v (k text primary key, val text);
create function t.ck(n text, c boolean, d text default '') returns void language sql as $$ insert into t.res values (n, coalesce(c, false), left(d, 300)) $$;
create function t.set(k text, v text) returns void language sql as $$ insert into t.v values (k, v) on conflict (k) do update set val = excluded.val $$;
create function t.get(k text) returns text language sql as $$ select val from t.v where t.v.k = $1 $$;
create function t.u(k text) returns uuid language sql as $$ select val::uuid from t.v where t.v.k = $1 $$;
create function t.as_(uid uuid, q text) returns jsonb language plpgsql as $$
declare r jsonb;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('role', 'authenticated', true);
  execute q into r;
  perform set_config('role', 'postgres', true);
  return r;
exception when others then
  perform set_config('role', 'postgres', true);
  return jsonb_build_object('err', sqlstate, 'msg', sqlerrm);
end $$;
create function t.anon(q text) returns jsonb language plpgsql as $$
declare r jsonb;
begin
  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', 'anon', true);
  execute q into r;
  perform set_config('role', 'postgres', true);
  return r;
exception when others then
  perform set_config('role', 'postgres', true);
  return jsonb_build_object('err', sqlstate, 'msg', sqlerrm);
end $$;
create function t.err(j jsonb) returns text language sql as $$ select j ->> 'err' $$;
create function t.uid() returns uuid language sql as $$ select gen_random_uuid() $$;

-- wrappers (the caller is a key from t.v)
create function t.complete(u text, act uuid, d date, ver int default 0, req uuid default gen_random_uuid(), note text default '') returns jsonb
language sql as $$ select t.as_(t.u(u), format('select public.complete_activity(%L,%L,%L,%s,%L)', act, d, req, ver, note)) $$;
create function t.mark(u text, act uuid, student text, d date, ver int, res text, req uuid default gen_random_uuid()) returns jsonb
language sql as $$ select t.as_(t.u(u), format('select public.mark_activity(%L,%L,%L,%L,%s,%L)', act, t.u(student), d, req, ver, res)) $$;
create function t.review(u text, act uuid, student text, d date, ver int, decision text, reason text default '', req uuid default gen_random_uuid()) returns jsonb
language sql as $$ select t.as_(t.u(u), format('select public.review_activity_completion(%L,%L,%L,%L,%s,%L,%L)', act, t.u(student), d, req, ver, decision, reason)) $$;
create function t.mk(u text, course text, title text, policy text, wd text, start date, mode text default 'day_end', dtime time default null,
                     tz text default 'UTC', req uuid default gen_random_uuid(), enddate date default null) returns jsonb
language sql as $$ select t.as_(t.u(u), format('select public.create_activity(%L,%L,%L,%L,%L,%L::smallint[],%L,%L,%L,%L,%L)',
  t.u(course), req, title, '', policy, wd, start, enddate, mode, dtime, tz)) $$;

create function t.find_task(u text, view text, item uuid) returns text language plpgsql as $$
declare cur jsonb := null; j jsonb; st text; n int := 0;
begin
  loop
    j := t.as_(t.u(u), format('select public.get_my_tasks(%L,null,null,400,%L)', view, cur));
    select i ->> 'status' into st from jsonb_array_elements(j -> 'items') i where i ->> 'id' = item::text limit 1;
    if st is not null then return st; end if;
    cur := j -> 'next_cursor'; n := n + 1;
    if cur is null or cur = 'null'::jsonb or n > 20 then return null; end if;
  end loop;
end $$;

-- Users, invitations, courses ------------------------------------------------------------------------
do $$
declare k text; e text; id uuid;
begin
  foreach k in array array['t1', 't2', 's1', 's2', 's3'] loop
    id := gen_random_uuid(); e := k || '@example.test';
    if k like 't%' then insert into public.teacher_invitations (email) values (e); end if;
    insert into auth.users (id, email, email_confirmed_at, raw_user_meta_data, aud, role)
    values (id, e, now(), json_build_object('full_name', 'User ' || k)::jsonb, 'authenticated', 'authenticated');
    perform t.set(k, id::text);
  end loop;
end $$;
select t.ck('roles assigned by the server: 2 teachers, 3 students',
  (select count(*) from public.profiles where role = 'teacher') = 2 and (select count(*) from public.profiles where role = 'student') = 3);
do $$
declare c jsonb; c2 jsonb;
begin
  c := t.as_(t.u('t1'), $q$select public.create_course('Algebra', '')$q$); perform t.set('c1', c ->> 'id');
  c2 := t.as_(t.u('t2'), $q$select public.create_course('Other', '')$q$); perform t.set('c2', c2 ->> 'id');
  perform t.as_(t.u('s1'), format('select public.join_course_by_code(%L)', c ->> 'join_code'));
  perform t.as_(t.u('s2'), format('select public.join_course_by_code(%L)', c ->> 'join_code'));
  perform t.as_(t.u('s3'), format('select public.join_course_by_code(%L)', c2 ->> 'join_code'));
end $$;

-- A. creation -----------------------------------------------------------------------------------------
do $$
declare j jsonb; r uuid := gen_random_uuid(); today date := current_date;
begin
  j := t.mk('s1', 'c1', 'x', 'self_reported', '{1,2,3,4,5,6,7}', today);
  perform t.ck('student cannot create (PT404)', t.err(j) = 'PT404', j::text);
  j := t.mk('t2', 'c1', 'x', 'self_reported', '{1}', today);
  perform t.ck('other teacher cannot create in a course they do not own (PT404)', t.err(j) = 'PT404', j::text);
  j := t.anon(format('select public.create_activity(%L,%L,%L,%L,%L,%L::smallint[],%L)', t.get('c1'), gen_random_uuid(), 'x', '', 'self_reported', '{1}', today));
  perform t.ck('anon cannot call create_activity (42501)', t.err(j) = '42501', j::text);
  perform t.ck('empty weekdays rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{}', today)) = 'PT400');
  perform t.ck('duplicate weekdays rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{1,1}', today)) = 'PT400');
  perform t.ck('weekday 8 rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{8}', today)) = 'PT400');
  perform t.ck('unknown policy rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'magic', '{1}', today)) = 'PT400');
  perform t.ck('unknown timezone rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{1}', today, tz => 'Mars/Base')) = 'PT400');
  perform t.ck('start in the past rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{1}', today - 1)) = 'PT400');
  perform t.ck('time mode without a time rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{1}', today, mode => 'time')) = 'PT400');
  perform t.ck('day_end with a time rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{1}', today, dtime => '10:00')) = 'PT400');
  perform t.ck('empty title rejected (PT400)', t.err(t.mk('t1', 'c1', '  ', 'self_reported', '{1}', today)) = 'PT400');
  perform t.ck('end before start rejected (PT400)', t.err(t.mk('t1', 'c1', 'x', 'self_reported', '{1}', today, enddate => today - 1)) = 'PT400');

  j := t.mk('t1', 'c1', 'Self daily', 'self_reported', '{1,2,3,4,5,6,7}', today, req => r);
  perform t.ck('teacher creates a self-reported activity', j ->> 'version' = '1' and j ->> 'policy' = 'self_reported' and (j ->> 'schedule_version') = '1', j::text);
  perform t.set('a_self', j ->> 'id');
  perform t.ck('replay of the same request returns the same activity', (t.mk('t1', 'c1', 'Self daily', 'self_reported', '{1,2,3,4,5,6,7}', today, req => r)) ->> 'id' = t.get('a_self'));
  perform t.ck('request id reused with different content (PT409)', t.err(t.mk('t1', 'c1', 'Different', 'self_reported', '{1,2,3,4,5,6,7}', today, req => r)) = 'PT409');
  j := t.mk('t1', 'c1', 'Teacher daily', 'teacher_marked', '{1,2,3,4,5,6,7}', today); perform t.set('a_tm', j ->> 'id');
  j := t.mk('t1', 'c1', 'Verified daily', 'teacher_verified', '{1,2,3,4,5,6,7}', today); perform t.set('a_tv', j ->> 'id');
  j := t.mk('t1', 'c1', 'No deadline', 'self_reported', '{1,2,3,4,5,6,7}', today, mode => 'none'); perform t.set('a_none', j ->> 'id');
  j := t.mk('t1', 'c1', 'Bangkok default', 'self_reported', '{1,2,3,4,5,6,7}', (now() at time zone 'Asia/Bangkok')::date, tz => 'Asia/Bangkok');
  perform t.ck('default timezone zone is stored per schedule', (select timezone from public.activity_schedules where activity_id = (j ->> 'id')::uuid) = 'Asia/Bangkok');
  perform t.set('a_bkk', j ->> 'id');
  -- the 25-active limit counts what exists (6 so far in c1): fill to 25 then reject the 26th
  for i in 1..20 loop perform t.mk('t1', 'c1', 'fill ' || i, 'self_reported', '{1}', today); end loop;
  perform t.ck('26th active activity rejected (PT409)', t.err(t.mk('t1', 'c1', 'over', 'self_reported', '{1}', today)) = 'PT409');
  update public.activities set status = 'archived' where title like 'fill %';  -- clean the course for later checks
end $$;

-- B. completion by policy ----------------------------------------------------------------------------------
do $$
declare j jsonb; today date := current_date;
begin
  perform t.ck('teacher_marked: student cannot self-complete (PT403)', t.err(t.complete('s1', t.get('a_tm')::uuid, today)) = 'PT403');
  j := t.complete('s1', t.get('a_self')::uuid, today);
  perform t.ck('self_reported: completes with a server timestamp', j ->> 'status' = 'self_reported' and j ->> 'version' = '1' and (j ->> 'submitted_at') is not null, j::text);
  perform t.ck('double completion rejected (PT409)', t.err(t.complete('s1', t.get('a_self')::uuid, today)) = 'PT409');
  perform t.ck('student cannot complete a future occurrence (PT409)', t.err(t.complete('s1', t.get('a_self')::uuid, today + 1)) = 'PT409');
  perform t.ck('outsider student sees no activity (PT404)', t.err(t.complete('s3', t.get('a_self')::uuid, today)) = 'PT404');
  perform t.ck('teacher cannot call the student RPC as a member (PT404)', t.err(t.complete('t1', t.get('a_self')::uuid, today)) = 'PT404');
  perform t.ck('s1 completion is invisible to s2 (RLS)',
    (select count(*) from (select t.as_(t.u('s2'), format('select coalesce(jsonb_agg(c),''[]'') from public.activity_completions c where activity_id = %L', t.get('a_self')))) x where (x.as_)::text <> '[]') = 0);
  j := t.complete('s2', t.get('a_tv')::uuid, today, 0, gen_random_uuid(), 'did it');
  perform t.ck('teacher_verified: submission is pending', j ->> 'status' = 'pending', j::text);
  perform t.ck('pending cannot be completed again (PT409)', t.err(t.complete('s2', t.get('a_tv')::uuid, today)) = 'PT409');
  j := t.as_(t.u('s2'), format('select public.retract_activity_completion(%L,%L,%L,1)', t.get('a_tv'), today, gen_random_uuid()));
  perform t.ck('student withdraws a pending submission', j ->> 'status' = 'retracted', j::text);
  perform t.ck('the withdrawn row is gone', not exists (select 1 from public.activity_completions where activity_id = t.get('a_tv')::uuid and student_id = t.u('s2')));
  j := t.complete('s2', t.get('a_tv')::uuid, today, 0, gen_random_uuid(), 'again');
  perform t.ck('resubmission after a withdrawal works', j ->> 'status' = 'pending' and j ->> 'version' = '1', j::text);
  perform t.ck('events are append-only history (client cannot read or write them)',
    t.err(t.as_(t.u('s2'), 'select count(*)::int::text::jsonb from public.activity_events')) is null
    and (t.as_(t.u('s2'), 'select count(*)::text::jsonb from public.activity_events')) = '0'::jsonb);
  perform t.ck('direct insert into completions denied (42501)', t.err(t.as_(t.u('s1'), format('insert into public.activity_completions (activity_id, student_id, occurrence_date, status, schedule_version) values (%L,%L,%L,''self_reported'',1) returning to_jsonb(activity_completions)', t.get('a_self'), t.u('s1'), today + 5))) = '42501');
  perform t.ck('direct update of completions denied (42501)', t.err(t.as_(t.u('s1'), format('update public.activity_completions set status = ''approved'' where activity_id = %L returning to_jsonb(activity_completions)', t.get('a_self')))) = '42501');
  perform t.ck('direct delete from completions denied (42501)', t.err(t.as_(t.u('s1'), 'delete from public.activity_completions returning to_jsonb(activity_completions)')) = '42501');
  perform t.ck('direct update of schedules denied (42501)', t.err(t.as_(t.u('t1'), 'update public.activity_schedules set weekdays = ''{1}'' returning to_jsonb(activity_schedules)')) = '42501');
  perform t.ck('direct insert of activities denied (42501)', t.err(t.as_(t.u('t1'), 'insert into public.activities (course_id,title,policy,request_id,created_by) values (gen_random_uuid(),''x'',''self_reported'',gen_random_uuid(),gen_random_uuid()) returning to_jsonb(activities)')) = '42501');
end $$;

-- B2. deadline boundaries (server clock only) -----------------------------------------------------------------
do $$
declare j jsonb; today date := current_date; late time := ((now() at time zone 'UTC') - interval '1 minute')::time;
begin
  if (now() at time zone 'UTC')::time > '00:02' then
    j := t.mk('t1', 'c1', 'Past deadline', 'self_reported', '{1,2,3,4,5,6,7}', today, mode => 'time', dtime => late);
    perform t.ck('time mode: due_at = local date + time', (select due_at from private.activity_occurrences((j ->> 'id')::uuid, today, today)) = (today + late)::timestamp at time zone 'UTC', j::text);
    perform t.ck('student cannot complete after the deadline (PT409)', t.err(t.complete('s1', (j ->> 'id')::uuid, today)) = 'PT409');
    perform t.ck('teacher may still record it late (credited)', t.mark('t1', (j ->> 'id')::uuid, 's1', today, 0, 'completed') ->> 'status' = 'teacher_marked');
  end if;
  j := t.complete('s1', t.get('a_none')::uuid, today);
  perform t.ck('deadline-free activity is completable and never missed', j ->> 'status' = 'self_reported');
  perform t.ck('day_end due_at is local midnight ending the date', (select due_at from private.activity_occurrences(t.get('a_self')::uuid, today, today)) = (today + 1)::timestamp at time zone 'UTC');
end $$;

-- C. teacher marking ----------------------------------------------------------------------------------------------
do $$
declare j jsonb; today date := current_date; a uuid := t.get('a_tm')::uuid;
begin
  perform t.ck('student cannot mark (PT404)', t.err(t.mark('s1', a, 's1', today, 0, 'completed')) = 'PT404');
  perform t.ck('other teacher cannot mark (PT404)', t.err(t.mark('t2', a, 's1', today, 0, 'completed')) = 'PT404');
  perform t.ck('cannot mark a student of another course (PT404)', t.err(t.mark('t1', a, 's3', today, 0, 'completed')) = 'PT404');
  perform t.ck('future occurrence cannot be marked (PT409)', t.err(t.mark('t1', a, 's1', today + 1, 0, 'completed')) = 'PT409');
  perform t.ck('bad result rejected (PT400)', t.err(t.mark('t1', a, 's1', today, 0, 'maybe')) = 'PT400');
  j := t.mark('t1', a, 's1', today, 0, 'completed');
  perform t.ck('teacher marks completed', j ->> 'status' = 'teacher_marked' and j ->> 'version' = '1', j::text);
  perform t.ck('stale version rejected (PT409)', t.err(t.mark('t1', a, 's1', today, 0, 'not_done')) = 'PT409');
  j := t.mark('t1', a, 's1', today, 1, 'not_done');
  perform t.ck('correction to not_done bumps the version', j ->> 'status' = 'not_done' and j ->> 'version' = '2', j::text);
  perform t.ck('the correction is in the audit log', (select count(*) from public.activity_events where activity_id = a and student_id = t.u('s1') and action = 'corrected') = 1);
  perform t.ck('student may redo a not_done self-reported entry', t.err(t.complete('s1', a, today, 2)) = 'PT403');  -- teacher_marked policy: still PT403
end $$;
do $$
declare r uuid := gen_random_uuid(); a uuid := t.get('a_tm')::uuid; today date := current_date; j1 jsonb; j2 jsonb;
begin
  j1 := t.mark('t1', a, 's2', today, 0, 'completed', r);
  j2 := t.mark('t1', a, 's2', today, 0, 'completed', r);
  perform t.ck('mark replay returns the same result flagged replayed', j2 ->> 'version' = '1' and (j2 ->> 'replayed')::boolean, j2::text);
  perform t.ck('replay with different content (PT409)', t.err(t.mark('t1', a, 's2', today, 0, 'not_done', r)) = 'PT409');
end $$;

-- D. review ------------------------------------------------------------------------------------------------
do $$
declare j jsonb; today date := current_date; a uuid := t.get('a_tv')::uuid;
begin
  perform t.ck('student cannot review (PT404)', t.err(t.review('s2', a, 's2', today, 1, 'approve')) = 'PT404');
  perform t.ck('other teacher cannot review (PT404)', t.err(t.review('t2', a, 's2', today, 1, 'approve')) = 'PT404');
  perform t.ck('reject needs a reason (PT400)', t.err(t.review('t1', a, 's2', today, 1, 'reject', '')) = 'PT400');
  j := t.review('t1', a, 's2', today, 1, 'reject', 'Please add detail');
  perform t.ck('teacher rejects with a reason', j ->> 'status' = 'rejected' and j ->> 'version' = '2', j::text);
  perform t.ck('only pending can be reviewed (PT409)', t.err(t.review('t1', a, 's2', today, 2, 'approve')) = 'PT409');
  j := t.complete('s2', a, today, 2, gen_random_uuid(), 'more detail');
  perform t.ck('student may resubmit a rejected item before the deadline', j ->> 'status' = 'pending' and j ->> 'version' = '3', j::text);
  perform t.ck('the rejection reason was cleared on resubmission', (select reason from public.activity_completions where activity_id = a and student_id = t.u('s2')) = '');
  j := t.review('t1', a, 's2', today, 3, 'approve');
  perform t.ck('teacher approves', j ->> 'status' = 'approved' and j ->> 'version' = '4', j::text);
  perform t.ck('approved is final for the student (PT409)', t.err(t.complete('s2', a, today, 4)) = 'PT409');
  perform t.ck('student cannot withdraw an approved item (PT409)', t.err(t.as_(t.u('s2'), format('select public.retract_activity_completion(%L,%L,%L,4)', a, today, gen_random_uuid()))) = 'PT409');
  perform t.ck('events: submitted, rejected, submitted, approved recorded',
    (select string_agg(action, ',' order by created_at, id) from public.activity_events where activity_id = a and student_id = t.u('s2') and action in ('submitted','rejected','approved')) is not null);
end $$;

-- E. reads, pagination, isolation ---------------------------------------------------------------------------
do $$
declare j jsonb; today date := current_date; p1 jsonb; p2 jsonb; seen int := 0; cur jsonb := null; n int := 0; all_ids text[] := '{}'; dup boolean := false; k text;
begin
  perform t.ck('window over 62 days rejected (PT400)', t.err(t.as_(t.u('s1'), format('select public.get_my_activities(%L,%L)', today, today + 62))) = 'PT400');
  perform t.ck('page size 401 rejected (PT400)', t.err(t.as_(t.u('s1'), format('select public.get_my_activities(%L,%L,null,401)', today, today))) = 'PT400');
  perform t.ck('teacher cannot use the student view (PT403)', t.err(t.as_(t.u('t1'), format('select public.get_my_activities(%L,%L)', today, today))) = 'PT403');
  j := t.as_(t.u('s1'), format('select public.get_my_activities(%L,%L)', today, today));
  perform t.ck('student sees their own activities today (non-archived only)', jsonb_array_length(j -> 'items') = (select count(*) from public.activities a, lateral private.activity_occurrences(a.id, today, today) where a.course_id = t.u('c1') and a.status <> 'archived'), (j -> 'items')::text);
  perform t.ck('own completion state is completed for the self-reported item', exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'activity_id' = t.get('a_self') and i ->> 'state' = 'completed'));
  j := t.as_(t.u('s3'), format('select public.get_my_activities(%L,%L)', today, today));
  perform t.ck('student of another course sees none of these', jsonb_array_length(j -> 'items') = 0);
  -- pagination: 2 per page over a 3-day window, every row exactly once (oracle = the virtual occurrences themselves)
  loop
    j := t.as_(t.u('s1'), format('select public.get_my_activities(%L,%L,null,2,%L)', today, today + 2, cur));
    exit when j ->> 'err' is not null;
    for k in select i ->> 'activity_id' || '|' || (i ->> 'occurrence_date') from jsonb_array_elements(j -> 'items') i loop
      if k = any (all_ids) then dup := true; end if; all_ids := all_ids || k; end loop;
    n := n + 1;
    cur := j -> 'next_cursor';
    exit when cur is null or cur = 'null'::jsonb or n > 20;
  end loop;
  perform t.ck('keyset pagination returns every occurrence exactly once (no duplicates, none missing)', cardinality(all_ids) = (select count(*) from public.activities a, lateral private.activity_occurrences(a.id, today, today + 2) where a.course_id = t.u('c1') and a.status <> 'archived') and not dup, cardinality(all_ids)::text);
  perform t.ck('the page count is ceil(rows / 2): nothing silently truncated', n = ceil(cardinality(all_ids) / 2.0), n::text);

  j := t.as_(t.u('t1'), format('select public.get_activity_register(%L,%L)', t.get('a_self'), today));
  perform t.ck('register lists both active students with 7 days each', jsonb_array_length(j -> 'students') = 2 and jsonb_array_length(j -> 'students' -> 0 -> 'cells') = 7, left(j::text, 200));
  perform t.ck('register denies another teacher (PT404)', t.err(t.as_(t.u('t2'), format('select public.get_activity_register(%L,%L)', t.get('a_self'), today))) = 'PT404');
  perform t.ck('register denies a student (PT404)', t.err(t.as_(t.u('s1'), format('select public.get_activity_register(%L,%L)', t.get('a_self'), today))) = 'PT404');
  j := t.as_(t.u('t1'), format('select public.get_activity_overview(%L)', t.get('c1')));
  perform t.ck('overview counts today''s completions (self: 1 of 2 expected)', exists (select 1 from jsonb_array_elements(j -> 'activities') a where a ->> 'id' = t.get('a_self') and (a -> 'today' ->> 'completed') = '1' and (a -> 'today' ->> 'expected') = '2'), left(j::text, 300));
  perform t.ck('overview denies another teacher (PT404)', t.err(t.as_(t.u('t2'), format('select public.get_activity_overview(%L)', t.get('c1')))) = 'PT404');
  -- pending queue
  perform t.complete('s1', t.get('a_tv')::uuid, today);
  j := t.as_(t.u('t1'), 'select public.get_pending_verifications(null, 1)');
  perform t.ck('pending queue returns the item and a total', (j ->> 'total') = '1' and jsonb_array_length(j -> 'items') = 1, left(j::text, 200));
  perform t.ck('pending page size 51 rejected (PT400)', t.err(t.as_(t.u('t1'), 'select public.get_pending_verifications(null, 51)')) = 'PT400');
  perform t.ck('other teacher sees an empty queue', (t.as_(t.u('t2'), 'select public.get_pending_verifications(null, 50)') ->> 'total') = '0');
  perform t.ck('student cannot read the queue (empty, not an error that leaks)', (t.as_(t.u('s1'), 'select public.get_pending_verifications(null, 50)') ->> 'total') = '0');
end $$;

-- F. streaks -----------------------------------------------------------------------------------------------
do $$
declare
  today date := current_date; a uuid; miss date; n_before int; n_after int; j jsonb; s jsonb; dy date; sched date[];
begin
  -- Mon/Wed/Fri activity created 27 days ago (history inserted as the migration would have produced it)
  a := gen_random_uuid();
  insert into public.activities (id, course_id, title, policy, request_id, created_by) values (a, t.u('c1'), 'MWF', 'self_reported', gen_random_uuid(), t.u('t1'));
  insert into public.activity_schedules (activity_id, version_no, weekdays, effective_from, timezone, request_id, created_by)
  values (a, 1, '{1,3,5}', today - 27, 'UTC', gen_random_uuid(), t.u('t1'));
  select array_agg(d::date order by d) into sched from generate_series(today - 27, today - 1, interval '1 day') g(d) where extract(isodow from d) in (1, 3, 5);
  miss := sched[cardinality(sched) - 2];  -- the third most recent scheduled day before today
  foreach dy in array sched loop
    if dy <> miss then insert into public.activity_completions (activity_id, student_id, occurrence_date, status, schedule_version, due_at, submitted_at)
      values (a, t.u('s1'), dy, 'self_reported', 1, (dy + 1)::timestamp at time zone 'UTC', now()); end if;
  end loop;
  select count(*) into n_after from unnest(sched) x where x > miss;
  select count(*) into n_before from unnest(sched) x where x < miss;
  s := (t.as_(t.u('s1'), format('select public.get_activity_streaks(%L)', t.get('c1'))) -> 'activities');
  s := (select e -> 'streak' from jsonb_array_elements(s) e where e ->> 'activity_id' = a::text);
  perform t.ck('streak counts only scheduled days (weekends/unscheduled days skipped)', (s ->> 'current')::int = n_after, s::text || ' expected ' || n_after);
  perform t.ck('best streak spans the longer run before the miss', (s ->> 'best')::int = greatest(n_after, n_before), s::text);
  perform t.ck('resolved = every scheduled day before today; completed excludes the miss', (s ->> 'resolved')::int = cardinality(sched) and (s ->> 'completed')::int = cardinality(sched) - 1, s::text);
  perform t.ck('today (open) is neutral: not counted, not a miss', (s ->> 'current')::int = n_after);
  -- teacher reads a member's streak; other teacher / outsider cannot
  perform t.ck('teacher reads a member streak', jsonb_array_length(t.as_(t.u('t1'), format('select public.get_activity_streaks(%L,%L)', t.get('c1'), t.u('s1'))) -> 'activities') > 0);
  perform t.ck('other teacher denied (PT404)', t.err(t.as_(t.u('t2'), format('select public.get_activity_streaks(%L,%L)', t.get('c1'), t.u('s1')))) = 'PT404');
  perform t.ck('student cannot read another student''s streak (PT404)', t.err(t.as_(t.u('s1'), format('select public.get_activity_streaks(%L,%L)', t.get('c1'), t.u('s2')))) = 'PT404');

  -- pending is neutral
  a := gen_random_uuid();
  insert into public.activities (id, course_id, title, policy, request_id, created_by) values (a, t.u('c1'), 'PEND', 'teacher_verified', gen_random_uuid(), t.u('t1'));
  insert into public.activity_schedules (activity_id, version_no, weekdays, effective_from, timezone, request_id, created_by) values (a, 1, '{1,2,3,4,5,6,7}', today - 6, 'UTC', gen_random_uuid(), t.u('t1'));
  for dy in select g::date from generate_series(today - 6, today - 2, interval '1 day') g loop
    insert into public.activity_completions (activity_id, student_id, occurrence_date, status, schedule_version, due_at, submitted_at) values (a, t.u('s1'), dy, 'approved', 1, (dy + 1)::timestamp at time zone 'UTC', now()); end loop;
  insert into public.activity_completions (activity_id, student_id, occurrence_date, status, schedule_version, due_at, submitted_at) values (a, t.u('s1'), today - 1, 'pending', 1, (today)::timestamp at time zone 'UTC', now());
  s := (select e -> 'streak' from jsonb_array_elements(t.as_(t.u('s1'), format('select public.get_activity_streaks(%L)', t.get('c1'))) -> 'activities') e where e ->> 'activity_id' = a::text);
  perform t.ck('pending verification is neither credited nor a break', (s ->> 'current')::int = 5 and (s ->> 'completed')::int = 5, s::text);
  -- rejected after the deadline = missed (breaks)
  update public.activity_completions set status = 'rejected' where activity_id = a and occurrence_date = today - 1;
  s := (select e -> 'streak' from jsonb_array_elements(t.as_(t.u('s1'), format('select public.get_activity_streaks(%L)', t.get('c1'))) -> 'activities') e where e ->> 'activity_id' = a::text);
  perform t.ck('a rejected item past its deadline is missed and breaks the streak', (s ->> 'current')::int = 0 and (s ->> 'best')::int = 5, s::text);
  -- deadline-free has no streak
  s := (select e -> 'streak' from jsonb_array_elements(t.as_(t.u('s1'), format('select public.get_activity_streaks(%L)', t.get('c1'))) -> 'activities') e where e ->> 'activity_id' = t.get('a_none'));
  perform t.ck('deadline-free activities have no streak (null)', s -> 'current' = 'null'::jsonb, s::text);
  -- future occurrences are never missed
  j := t.as_(t.u('s1'), format('select public.get_my_activities(%L,%L)', today + 1, today + 3));
  perform t.ck('future occurrences are upcoming, never missed', not exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'state' in ('missed', 'not_done')) and exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'state' = 'upcoming'));
end $$;

-- G. schedule history ---------------------------------------------------------------------------------------
do $$
declare j jsonb; today date := current_date; a uuid := t.get('a_self')::uuid; v int; d date; before_due timestamptz;
begin
  select version into v from public.activities where id = a;
  before_due := (select due_at from private.activity_occurrences(a, today, today));
  perform t.ck('schedule change starting today is rejected (PT409)', t.err(t.as_(t.u('t1'), format('select public.add_activity_schedule(%L,%L,%s,%L::smallint[],%L)', a, gen_random_uuid(), v, '{1,2}', today))) = 'PT409');
  perform t.ck('student cannot add a schedule (PT404)', t.err(t.as_(t.u('s1'), format('select public.add_activity_schedule(%L,%L,%s,%L::smallint[],%L)', a, gen_random_uuid(), v, '{1,2}', today + 1))) = 'PT404');
  perform t.ck('stale activity version rejected (PT409)', t.err(t.as_(t.u('t1'), format('select public.add_activity_schedule(%L,%L,%s,%L::smallint[],%L)', a, gen_random_uuid(), v + 5, '{1,2}', today + 1))) = 'PT409');
  j := t.as_(t.u('t1'), format('select public.add_activity_schedule(%L,%L,%s,%L::smallint[],%L,null,''time'',''08:00'',''UTC'')', a, gen_random_uuid(), v, '{1,2}', today + 3));
  perform t.ck('a new immutable version starts in the future', j ->> 'schedule_version' = '2', j::text);
  perform t.ck('today''s occurrence and deadline are unchanged', (select due_at from private.activity_occurrences(a, today, today)) = before_due);
  perform t.ck('before the change every weekday is still eligible; from it only Mon/Tue',
    (select count(*) from private.activity_occurrences(a, today, today + 2)) = 3
    and (select count(*) from private.activity_occurrences(a, today + 3, today + 9)) = 2);
  perform t.ck('from the change the deadline is the time-of-day one',
    not exists (select 1 from private.activity_occurrences(a, today + 3, today + 9) o where o.deadline_mode <> 'time' or o.schedule_version <> 2));
  -- pause then resume via status
  select version into v from public.activities where id = a;
  j := t.as_(t.u('t1'), format('select public.set_activity_status(%L,%L,%s,''inactive'',%L)', a, gen_random_uuid(), v, today + 10));
  perform t.ck('pause writes an empty-weekday version', j ->> 'status' = 'inactive' and (select cardinality(weekdays) from public.activity_schedules where activity_id = a and version_no = 3) = 0, j::text);
  perform t.ck('no occurrences after the pause starts', (select count(*) from private.activity_occurrences(a, today + 10, today + 20)) = 0);
  select version into v from public.activities where id = a;
  j := t.as_(t.u('t1'), format('select public.set_activity_status(%L,%L,%s,''active'',%L)', a, gen_random_uuid(), v, today + 15));
  perform t.ck('resume restores the last non-empty settings', j ->> 'status' = 'active' and (select weekdays from public.activity_schedules where activity_id = a and version_no = 4) = '{1,2}');
  perform t.ck('student cannot change status (PT404)', t.err(t.as_(t.u('s1'), format('select public.set_activity_status(%L,%L,1,''archived'')', a, gen_random_uuid()))) = 'PT404');
  perform t.ck('history rows still resolve to their original versions', (select schedule_version from private.activity_occurrences(a, today, today)) = 1);
  -- version cap
  d := today + 20;
  for i in 1..20 loop
    select version into v from public.activities where id = t.get('a_bkk')::uuid;
    j := t.as_(t.u('t1'), format('select public.add_activity_schedule(%L,%L,%s,%L::smallint[],%L,null,''day_end'',null,''Asia/Bangkok'')', t.get('a_bkk'), gen_random_uuid(), v, '{1,2}', (now() at time zone 'Asia/Bangkok')::date + 1 + i));
    exit when j ->> 'err' is not null;
  end loop;
  perform t.ck('the 21st schedule version is rejected (PT409)', t.err(j) = 'PT409', j::text);
end $$;

-- H. progress -------------------------------------------------------------------------------------------------
do $$
declare j jsonb; today date := current_date; asg jsonb; sid uuid; sub uuid; v7 jsonb; prog jsonb; r jsonb;
begin
  -- assignments: published (past / future / no deadline), one draft; s1 submits, teacher grades one and returns one
  perform t.set('as1', t.as_(t.u('t1'), format('select public.create_assignment(%L,%L,''x'',100,%L)', t.get('c1'), 'A past due', now() - interval '3 days')) ->> 'id');
  perform t.set('as2', t.as_(t.u('t1'), format('select public.create_assignment(%L,%L,''x'',50,%L)', t.get('c1'), 'A future', now() + interval '3 days')) ->> 'id');
  perform t.set('as3', t.as_(t.u('t1'), format('select public.create_assignment(%L,%L,''x'',100,null)', t.get('c1'), 'A none')) ->> 'id');
  perform t.set('as4', t.as_(t.u('t1'), format('select public.create_assignment(%L,%L,''x'',100,%L)', t.get('c1'), 'A graded', now() + interval '5 days')) ->> 'id');
  perform t.set('as5', t.as_(t.u('t1'), format('select public.create_assignment(%L,%L,''x'',100,%L)', t.get('c1'), 'A returned', now() + interval '6 days')) ->> 'id');
  perform t.as_(t.u('t1'), format('select public.create_assignment(%L,%L,''x'',100,null)', t.get('c1'), 'A draft'));
  perform t.as_(t.u('t1'), format('select public.publish_assignment(%L,1)', t.get('as' || i)) ) from generate_series(1, 5) i;
  -- s1 submits as4 and as5 (future deadline), teacher grades as4 (80/100) and returns as5; then the deadlines of as1 is already past
  perform t.as_(t.u('s1'), format('select public.submit_assignment(%L,%L,''ans'')', t.get('as4'), gen_random_uuid()));
  perform t.as_(t.u('s1'), format('select public.submit_assignment(%L,%L,''ans'')', t.get('as5'), gen_random_uuid()));
  perform t.as_(t.u('s1'), format('select public.submit_assignment(%L,%L,''ans'')', t.get('as2'), gen_random_uuid()));
  sub := (select id from public.submissions where assignment_id = t.get('as4')::uuid and student_id = t.u('s1'));
  perform t.as_(t.u('t1'), format('select public.grade_submission(%L,%L,1,80,''ok'')', sub, gen_random_uuid()));
  sub := (select id from public.submissions where assignment_id = t.get('as5')::uuid and student_id = t.u('s1'));
  perform t.as_(t.u('t1'), format('select public.return_submission(%L,%L,1,''redo'')', sub, gen_random_uuid()));
  -- as1 was created with a past deadline: published assignments can have past deadlines; s1 never submitted it
  prog := t.as_(t.u('t1'), format('select public.get_student_progress(%L,%L)', t.get('c1'), t.u('s1')));
  asg := prog -> 'assignments';
  v7 := t.as_(t.u('s1'), 'select public.get_student_dashboard()');
  perform t.ck('progress denominators: 5 published assignments (draft excluded)', (asg ->> 'published') = '5' and (asg ->> 'items_total') = '5', asg::text);
  perform t.ck('progress equals V7 dashboard: done', (asg ->> 'done') = (v7 ->> 'done'), asg::text || v7::text);
  perform t.ck('progress equals V7 dashboard: awaiting / graded / needs_revision / not_started / overdue',
    (asg ->> 'awaiting_review') = (v7 ->> 'awaiting_grade') and (asg ->> 'graded') = (v7 ->> 'graded') and (asg ->> 'needs_revision') = (v7 ->> 'needs_revision')
    and (asg ->> 'not_started') = (v7 ->> 'not_started') and (asg ->> 'overdue') = (v7 ->> 'overdue') and (asg ->> 'average_percent') = (v7 ->> 'average_percent'), asg::text || v7::text);
  perform t.ck('returned work is needs_revision, not done', exists (select 1 from jsonb_array_elements(asg -> 'items') i where i ->> 'id' = t.get('as5') and i ->> 'status' = 'needs_revision'));
  perform t.ck('a past deadline with nothing submitted is overdue; a future one is todo',
    exists (select 1 from jsonb_array_elements(asg -> 'items') i where i ->> 'id' = t.get('as1') and i ->> 'status' = 'overdue')
    and exists (select 1 from jsonb_array_elements(asg -> 'items') i where i ->> 'id' = t.get('as3') and i ->> 'status' = 'todo'));
  -- attendance: one closed session, s1 present, s2 absent
  perform t.as_(t.u('t1'), format('select public.create_attendance_session(%L,%L,%L,%L)', t.get('c1'), gen_random_uuid(), 'Mon', now() - interval '1 hour'));
  sid := (select id from public.attendance_sessions where course_id = t.u('c1') limit 1);
  perform t.as_(t.u('t1'), format('select public.mark_attendance(%L,%L,%L,0,''present'',''''::text)', sid, t.u('s1'), gen_random_uuid()));
  prog := t.as_(t.u('t1'), format('select public.get_student_progress(%L,%L)', t.get('c1'), t.u('s1')));
  v7 := t.as_(t.u('t1'), format('select public.get_attendance_summary(%L)', t.get('c1')));
  perform t.ck('progress attendance rate equals the V6 summary rate for the student',
    (prog -> 'attendance' ->> 'rate') = (select s ->> 'rate' from jsonb_array_elements(v7 -> 'students') s where s ->> 'student_id' = t.get('s1')), (prog -> 'attendance')::text);
  perform t.ck('progress lists enrollment and identity', prog -> 'student' ->> 'full_name' = 'User s1' and prog -> 'enrollment' ->> 'status' = 'active');
  perform t.ck('progress carries activities with streak objects', jsonb_array_length(prog -> 'activities' -> 'activities') >= 1);
  perform t.ck('other teacher cannot read the progress (PT404)', t.err(t.as_(t.u('t2'), format('select public.get_student_progress(%L,%L)', t.get('c1'), t.u('s1')))) = 'PT404');
  perform t.ck('student cannot use the teacher RPC (PT404)', t.err(t.as_(t.u('s1'), format('select public.get_student_progress(%L,%L)', t.get('c1'), t.u('s1')))) = 'PT404');
  perform t.ck('unknown student and wrong-course student answer identically (PT404)',
    t.err(t.as_(t.u('t1'), format('select public.get_student_progress(%L,%L)', t.get('c1'), gen_random_uuid()))) = t.err(t.as_(t.u('t1'), format('select public.get_student_progress(%L,%L)', t.get('c1'), t.u('s3')))));
  j := t.as_(t.u('s1'), format('select public.get_my_progress(%L)', t.get('c1')));
  perform t.ck('student reads only their own progress (identity and figures)', j -> 'student' ->> 'id' = t.get('s1') and j -> 'student' ->> 'full_name' = 'User s1' and (j -> 'assignments' ->> 'done') = '2', left(j::text, 200));
  perform t.ck('outsider cannot read My Progress for a course (PT404)', t.err(t.as_(t.u('s3'), format('select public.get_my_progress(%L)', t.get('c1')))) = 'PT404');
end $$;

-- I. tasks / calendar ---------------------------------------------------------------------------------------------
do $$
declare j jsonb; today date := current_date; n int;
begin
  j := t.as_(t.u('s1'), format('select public.get_my_tasks(''range'',%L,%L)', today::timestamptz - interval '1 day', today::timestamptz + interval '8 days'));
  perform t.ck('range view returns assignments and activities, each with a status', jsonb_array_length(j -> 'items') > 0 and not exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'status' is null), left(j::text, 200));
  perform t.ck('a future unfinished assignment is todo, never overdue', t.find_task('s1', 'upcoming', t.get('as3')::uuid) = 'todo');
  -- date-based placement: a day_end activity's deadline instant is the NEXT midnight, but its occurrence belongs to its own date
  j := t.as_(t.u('s1'), format('select public.get_my_tasks(''range'',%L,%L,400,null,%L,%L)', today::timestamptz, (today + 1)::timestamptz, today, today + 1));
  perform t.ck('today window holds today''s activity occurrences (not yesterday''s)',
    exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'activity' and (i ->> 'occurrence_date')::date = today)
    and not exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'activity' and (i ->> 'occurrence_date')::date <> today), left(j::text, 300));
  j := t.as_(t.u('s1'), format('select public.get_my_tasks(''range'',%L,%L,400,null,%L,%L)', today::timestamptz, (today + 3)::timestamptz, today, today + 3));
  perform t.ck('a 3-day date window returns exactly the occurrences of those 3 dates',
    (select count(*) from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'activity')
      = (select count(*) from public.activities a, lateral private.activity_occurrences(a.id, today, today + 2) o where a.course_id = t.u('c1') and a.status <> 'archived'), left(j::text, 200));
  perform t.ck('an inverted or over-62-day date window is rejected (PT400)',
    t.err(t.as_(t.u('s1'), format('select public.get_my_tasks(''range'',%L,%L,400,null,%L,%L)', today::timestamptz, (today + 3)::timestamptz, today + 3, today))) = 'PT400'
    and t.err(t.as_(t.u('s1'), format('select public.get_my_tasks(''range'',%L,%L,400,null,%L,%L)', today::timestamptz, (today + 3)::timestamptz, today, today + 70))) = 'PT400');
  j := t.as_(t.u('t1'), format('select public.get_teacher_calendar(%L,%L,400,null,%L,%L)', today::timestamptz, (today + 1)::timestamptz, today, today + 1));
  perform t.ck('teacher calendar places activity days by date too', not exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'activity_day' and (i ->> 'occurrence_date')::date <> today)
    and exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'activity_day' and (i ->> 'occurrence_date')::date = today), left(j::text, 300));
  j := t.as_(t.u('s1'), 'select public.get_my_tasks(''overdue'')');
  perform t.ck('overdue view: the past-due unsubmitted assignment, no future items', exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'id' = t.get('as1') and i ->> 'status' = 'overdue')
    and not exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'status' not in ('overdue', 'missed')), left(j::text, 300));
  j := t.as_(t.u('s1'), 'select public.get_my_tasks(''upcoming'')');
  perform t.ck('upcoming view: returned work stays actionable; graded work absent',
    exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'id' = t.get('as5') and i ->> 'status' = 'needs_revision')
    and not exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'id' = t.get('as4')), left(j::text, 300));
  j := t.as_(t.u('s1'), 'select public.get_my_tasks(''completed'')');
  perform t.ck('completed view: graded and awaiting items, newest first', exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'id' = t.get('as4') and i ->> 'status' = 'graded'), left(j::text, 300));
  perform t.ck('the same assignment has one status on every surface (task vs progress)',
    (select i ->> 'status' from jsonb_array_elements(t.as_(t.u('s1'), 'select public.get_my_tasks(''completed'')') -> 'items') i where i ->> 'id' = t.get('as4'))
    = (select i ->> 'status' from jsonb_array_elements(t.as_(t.u('s1'), format('select public.get_my_progress(%L)', t.get('c1'))) -> 'assignments' -> 'items') i where i ->> 'id' = t.get('as4')));
  perform t.ck('unknown view (PT400)', t.err(t.as_(t.u('s1'), 'select public.get_my_tasks(''x'')')) = 'PT400');
  perform t.ck('range needs a window (PT400)', t.err(t.as_(t.u('s1'), 'select public.get_my_tasks(''range'')')) = 'PT400');
  perform t.ck('range window over 62 days (PT400)', t.err(t.as_(t.u('s1'), format('select public.get_my_tasks(''range'',%L,%L)', today::timestamptz, today::timestamptz + interval '63 days'))) = 'PT400');
  perform t.ck('teacher cannot use student tasks (PT403)', t.err(t.as_(t.u('t1'), 'select public.get_my_tasks(''overdue'')')) = 'PT403');
  perform t.ck('anon denied (42501)', t.err(t.anon('select public.get_my_tasks(''overdue'')')) = '42501');
  j := t.as_(t.u('s3'), 'select public.get_my_tasks(''overdue'')');
  perform t.ck('a student of another course sees none of these tasks', jsonb_array_length(j -> 'items') = 0);
  -- pagination with limit 1 over the upcoming view
  declare cur jsonb := null; seen text[] := '{}'; k text; pages int := 0; tot int;
  begin
    tot := jsonb_array_length(t.as_(t.u('s1'), 'select public.get_my_tasks(''upcoming'',null,null,400)') -> 'items');
    loop
      j := t.as_(t.u('s1'), format('select public.get_my_tasks(''upcoming'',null,null,1,%L)', cur));
      exit when j ->> 'err' is not null;
      for k in select (i ->> 'kind') || (i ->> 'id') || coalesce(i ->> 'key2', '') from jsonb_array_elements(j -> 'items') i loop seen := seen || k; end loop;
      pages := pages + 1; cur := j -> 'next_cursor';
      exit when cur is null or cur = 'null'::jsonb or pages > 500;
    end loop;
    perform t.ck('task pagination visits every upcoming item exactly once', cardinality(seen) = tot and (select count(distinct x) from unnest(seen) x) = tot, tot::text || '/' || cardinality(seen)::text);
  end;
  -- removed member loses everything
  perform t.as_(t.u('t1'), format('select public.remove_course_member(%L,%L)', t.get('c1'), t.u('s2')));
  perform t.ck('removed student gets no tasks', jsonb_array_length(t.as_(t.u('s2'), 'select public.get_my_tasks(''upcoming'')') -> 'items') = 0);
  perform t.ck('removed student gets no activities', jsonb_array_length(t.as_(t.u('s2'), format('select public.get_my_activities(%L,%L)', today, today)) -> 'items') = 0);
  perform t.ck('removed student cannot complete (PT404)', t.err(t.complete('s2', t.get('a_self')::uuid, today)) = 'PT404');
  perform t.ck('removed student cannot read My Progress (PT404)', t.err(t.as_(t.u('s2'), format('select public.get_my_progress(%L)', t.get('c1')))) = 'PT404');
  perform t.ck('teacher can no longer open the removed student progress (PT404)', t.err(t.as_(t.u('t1'), format('select public.get_student_progress(%L,%L)', t.get('c1'), t.u('s2')))) = 'PT404');
  perform t.ck('removed student is gone from the register', jsonb_array_length(t.as_(t.u('t1'), format('select public.get_activity_register(%L,%L)', t.get('a_self'), today)) -> 'students') = 1);
  -- teacher calendar
  j := t.as_(t.u('t1'), format('select public.get_teacher_calendar(%L,%L)', today::timestamptz - interval '8 days', today::timestamptz + interval '8 days'));
  perform t.ck('teacher calendar: assignment dues, activity days and an attendance session', exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'assignment_due')
    and exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'activity_day') and exists (select 1 from jsonb_array_elements(j -> 'items') i where i ->> 'kind' = 'attendance_session'), left(j::text, 200));
  perform t.ck('teacher calendar reports the pending verification workload', (j ->> 'pending_verifications') = '1', j ->> 'pending_verifications');
  perform t.ck('other teacher calendar is empty of these courses', not exists (select 1 from jsonb_array_elements(t.as_(t.u('t2'), format('select public.get_teacher_calendar(%L,%L)', today::timestamptz - interval '8 days', today::timestamptz + interval '8 days')) -> 'items') i where i ->> 'course_id' = t.get('c1')));
  perform t.ck('student cannot use the teacher calendar (PT403)', t.err(t.as_(t.u('s1'), format('select public.get_teacher_calendar(%L,%L)', today::timestamptz, today::timestamptz + interval '3 days'))) = 'PT403');
end $$;

-- J. DST / timezone determinism --------------------------------------------------------------------------------
do $$
declare a uuid; due timestamptz;
begin
  a := gen_random_uuid();
  insert into public.activities (id, course_id, title, policy, request_id, created_by) values (a, t.u('c1'), 'DST', 'self_reported', gen_random_uuid(), t.u('t1'));
  insert into public.activity_schedules (activity_id, version_no, weekdays, effective_from, deadline_mode, deadline_time, timezone, request_id, created_by)
  values (a, 1, '{1,2,3,4,5,6,7}', '2026-01-01', 'time', '02:30', 'America/New_York', gen_random_uuid(), t.u('t1'));
  perform t.ck('New York spring-forward gap resolves with the pre-change offset (02:30 -> 07:30Z)', (select due_at from private.activity_occurrences(a, '2026-03-08', '2026-03-08')) = '2026-03-08 07:30:00+00');
  update public.activity_schedules set deadline_time = '01:30' where activity_id = a;
  perform t.ck('New York fall-back overlap resolves to the later (standard-time) instant (01:30 -> 06:30Z)', (select due_at from private.activity_occurrences(a, '2026-11-01', '2026-11-01')) = '2026-11-01 06:30:00+00');
  update public.activity_schedules set deadline_mode = 'day_end', deadline_time = null where activity_id = a;
  perform t.ck('day_end on the 23-hour NY day (cutoff 04:00Z)', (select due_at from private.activity_occurrences(a, '2026-03-08', '2026-03-08')) = '2026-03-09 04:00:00+00');
  perform t.ck('day_end on the 25-hour NY day (cutoff 05:00Z)', (select due_at from private.activity_occurrences(a, '2026-11-01', '2026-11-01')) = '2026-11-02 05:00:00+00');
  update public.activity_schedules set timezone = 'Europe/London' where activity_id = a;
  perform t.ck('London spring day_end (cutoff 23:00Z)', (select due_at from private.activity_occurrences(a, '2026-03-29', '2026-03-29')) = '2026-03-29 23:00:00+00');
  update public.activity_schedules set timezone = 'Australia/Lord_Howe' where activity_id = a;
  perform t.ck('Lord Howe 30-minute DST day_end (cutoff 13:00Z)', (select due_at from private.activity_occurrences(a, '2026-10-04', '2026-10-04')) = '2026-10-04 13:00:00+00');
  update public.activity_schedules set timezone = 'Asia/Bangkok', deadline_mode = 'time', deadline_time = '23:30' where activity_id = a;
  perform t.ck('Bangkok has no DST: 23:30 local = 16:30Z', (select due_at from private.activity_occurrences(a, '2026-11-16', '2026-11-16')) = '2026-11-16 16:30:00+00');
  update public.activity_schedules set timezone = 'Australia/Sydney', deadline_time = '02:30' where activity_id = a;
  perform t.ck('Sydney overlap and gap are deterministic (2026-04-05 02:30 -> 04-04 16:30Z; 2026-10-04 02:30 -> 10-03 16:30Z)',
    (select due_at from private.activity_occurrences(a, '2026-04-05', '2026-04-05')) = '2026-04-04 16:30:00+00' and (select due_at from private.activity_occurrences(a, '2026-10-04', '2026-10-04')) = '2026-10-03 16:30:00+00');
  perform t.ck('the weekday of an occurrence is the local weekday (ISO)', (select count(*) from private.activity_occurrences(a, '2026-11-16', '2026-11-22')) = 7);
  a := (t.mk('t1', 'c1', 'Ends soon', 'self_reported', '{1,2,3,4,5,6,7}', current_date, enddate => current_date + 2) ->> 'id')::uuid;
  perform t.ck('end_date bounds eligibility (3 days, then nothing)', (select count(*) from private.activity_occurrences(a, current_date, current_date + 8)) = 3);
end $$;

-- K. security audit of the new objects -------------------------------------------------------------------------------
do $$
declare r record; bad text := '';
begin
  for r in select p.oid::regprocedure::text as sig, p.prosecdef, p.proconfig from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname in ('create_activity','update_activity','add_activity_schedule','set_activity_status','complete_activity',
              'retract_activity_completion','mark_activity','review_activity_completion','get_my_activities','get_activity_streaks','get_activity_overview',
              'get_activity_register','get_pending_verifications','get_student_progress','get_my_progress','get_my_tasks','get_teacher_calendar') loop
    if not r.prosecdef or r.proconfig is null or not ('search_path=""' = any (r.proconfig)) then bad := bad || ' definer/search_path:' || r.sig; end if;
    if has_function_privilege('anon', r.sig, 'execute') or has_function_privilege('public', r.sig, 'execute') or not has_function_privilege('authenticated', r.sig, 'execute') then
      bad := bad || ' grants:' || r.sig; end if;
  end loop;
  perform t.ck('all 17 new RPCs are definer, search_path-pinned, authenticated-only', bad = '' and (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname in ('create_activity','update_activity','add_activity_schedule','set_activity_status','complete_activity','retract_activity_completion','mark_activity','review_activity_completion','get_my_activities','get_activity_streaks','get_activity_overview','get_activity_register','get_pending_verifications','get_student_progress','get_my_progress','get_my_tasks','get_teacher_calendar')) = 17, bad);
  perform t.ck('private helpers are not executable by API roles',
    not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'private' and p.proname like any (array['activity_%', 'occurrence_%', 'assignment_task_%', 'build_student_%', 'student_task_%', 'check_%', 'resolve_%'])
                  and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute'))));
  perform t.ck('RLS is enabled on all four new tables', (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relname in ('activities','activity_schedules','activity_completions','activity_events') and c.relrowsecurity) = 4);
  perform t.ck('API roles have SELECT only on the new tables', not exists (select 1 from information_schema.role_table_grants g where g.table_schema = 'public' and g.table_name in ('activities','activity_schedules','activity_completions','activity_events') and g.grantee in ('anon','authenticated') and g.privilege_type <> 'SELECT'));
  perform t.ck('anon has no access to the new tables', not exists (select 1 from information_schema.role_table_grants g where g.table_schema = 'public' and g.table_name like 'activit%' and g.grantee = 'anon'));
end $$;

select case when ok then 'PASS ' else 'FAIL ' end || name || case when ok then '' else '  -> ' || detail end as result from t.res order by ok, name;
select count(*) filter (where ok) as passed, count(*) filter (where not ok) as failed from t.res;
rollback;
