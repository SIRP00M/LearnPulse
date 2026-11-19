-- V13 Student QR attendance (additive). See docs/ATTENDANCE_OPTION_E_ARCHITECTURE.md (option C).
--   * per-session rules (check-out required?, late threshold, check-in window) with defaults that keep every old session unchanged
--   * check-in / check-out timestamps on attendance_records (NULL for all historical rows; nothing is back-filled)
--   * rotating opaque QR credentials stored only as SHA-256 hashes; validated by one SECURITY DEFINER RPC using the SERVER clock
-- Errors: PT400 invalid input, PT401 not authenticated, PT403 wrong role, PT404 not found/not yours, PT409 state conflict,
-- PT429 throttled. scan_attendance reports business outcomes as {ok:false, reason} so the attempt log is not rolled back.

alter table public.attendance_sessions
  add column requires_checkout boolean not null default false,
  add column late_after_minutes integer not null default 10 check (late_after_minutes between 0 and 240),
  add column checkin_opens_minutes integer not null default 15 check (checkin_opens_minutes between 0 and 240),
  add column checkin_window_minutes integer check (checkin_window_minutes is null or checkin_window_minutes between 1 and 720);

alter table public.attendance_records
  add column checked_in_at timestamptz,
  add column checked_out_at timestamptz,
  add column source text not null default 'manual' check (source in ('manual', 'qr')),
  add constraint attendance_records_times_ordered check (checked_out_at is null or checked_in_at is null or checked_out_at >= checked_in_at);

do $$
declare v_name text;
begin
  select conname into v_name from pg_constraint
   where conrelid = 'public.attendance_events'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%marked%';
  execute format('alter table public.attendance_events drop constraint %I', v_name);
  alter table public.attendance_events add constraint attendance_events_action_check
    check (action in ('marked', 'corrected', 'closed', 'checkin', 'checkout', 'rules'));
end $$;

create table public.attendance_qr_tokens (
  token_hash bytea primary key,
  session_id uuid not null references public.attendance_sessions (id) on delete cascade,
  action text not null check (action in ('in', 'out')),
  issued_by uuid not null references public.profiles (id) on delete cascade,
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null
);
create index attendance_qr_tokens_session_idx on public.attendance_qr_tokens (session_id, expires_at);

create table public.attendance_scan_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  attempted_at timestamptz not null default now()
);
create index attendance_scan_attempts_user_idx on public.attendance_scan_attempts (user_id, attempted_at desc);

alter table public.attendance_qr_tokens enable row level security;
alter table public.attendance_scan_attempts enable row level security;
-- No policies and no grants: only the SECURITY DEFINER functions below can touch these two tables.

create function public.set_attendance_rules(
  p_session_id uuid, p_request_id uuid, p_expected_version integer,
  p_requires_checkout boolean, p_late_after_minutes integer, p_checkin_opens_minutes integer, p_checkin_window_minutes integer
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_s public.attendance_sessions;
  v_ev public.attendance_events;
  v_response jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  select s.* into v_s from public.attendance_sessions s join public.courses c on c.id = s.course_id
   where s.id = p_session_id and c.owner_id = v_uid for update of s;
  if not found then raise exception 'Session not found' using errcode = 'PT404'; end if;
  select * into v_ev from public.attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.session_id <> p_session_id or v_ev.action <> 'rules' then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.response || jsonb_build_object('replayed', true);
  end if;
  if v_s.version is distinct from p_expected_version then
    raise exception 'The session changed; reload and try again' using errcode = 'PT409'; end if;
  if v_s.status <> 'open' then raise exception 'This session is closed' using errcode = 'PT409'; end if;
  if p_requires_checkout is null or p_late_after_minutes is null or p_checkin_opens_minutes is null
     or p_late_after_minutes not between 0 and 240 or p_checkin_opens_minutes not between 0 and 240
     or (p_checkin_window_minutes is not null and p_checkin_window_minutes not between 1 and 720) then
    raise exception 'Attendance rules are out of range' using errcode = 'PT400'; end if;
  update public.attendance_sessions
     set requires_checkout = p_requires_checkout, late_after_minutes = p_late_after_minutes,
         checkin_opens_minutes = p_checkin_opens_minutes, checkin_window_minutes = p_checkin_window_minutes, version = version + 1
   where id = p_session_id returning * into v_s;
  v_response := jsonb_build_object('session_id', v_s.id, 'version', v_s.version, 'requires_checkout', v_s.requires_checkout,
    'late_after_minutes', v_s.late_after_minutes, 'checkin_opens_minutes', v_s.checkin_opens_minutes,
    'checkin_window_minutes', v_s.checkin_window_minutes);
  insert into public.attendance_events (session_id, actor_id, action, version_after, request_id, response)
  values (v_s.id, v_uid, 'rules', v_s.version, p_request_id, v_response);
  return v_response;
end $$;

-- A teacher's classroom display asks for a fresh credential every 30 s; each is valid 45 s on the server clock.
create function public.issue_attendance_qr(p_session_id uuid, p_action text default 'in') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_s public.attendance_sessions;
  v_course_status public.course_status;
  v_token text;
  v_exp timestamptz;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_action is null or p_action not in ('in', 'out') then raise exception 'Action must be in or out' using errcode = 'PT400'; end if;
  select s.* into v_s from public.attendance_sessions s join public.courses c on c.id = s.course_id
   where s.id = p_session_id and c.owner_id = v_uid;
  if not found then raise exception 'Session not found' using errcode = 'PT404'; end if;
  select status into v_course_status from public.courses where id = v_s.course_id;
  if v_s.status <> 'open' or v_course_status <> 'active' then raise exception 'This session is closed' using errcode = 'PT409'; end if;
  if p_action = 'out' and not v_s.requires_checkout then raise exception 'This class does not use check-out' using errcode = 'PT409'; end if;
  delete from public.attendance_qr_tokens where session_id = p_session_id and expires_at < now() - interval '5 minutes';
  if (select count(*) from public.attendance_qr_tokens where session_id = p_session_id and expires_at > now()) >= 20 then
    raise exception 'Too many active codes; wait a moment' using errcode = 'PT429'; end if;
  v_token := 'LP1.' || encode(extensions.gen_random_bytes(16), 'hex');
  v_exp := now() + interval '45 seconds';
  insert into public.attendance_qr_tokens (token_hash, session_id, action, issued_by, expires_at)
  values (extensions.digest(v_token, 'sha256'), p_session_id, p_action, v_uid, v_exp);
  return jsonb_build_object('token', v_token, 'action', p_action, 'expires_at', v_exp, 'refresh_seconds', 30);
end $$;

create function public.scan_attendance(p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
  v_t public.attendance_qr_tokens;
  v_s public.attendance_sessions;
  v_course_status public.course_status;
  v_rec public.attendance_records;
  v_status public.attendance_status;
  v_fail text;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'student') then
    raise exception 'Only students can scan attendance codes' using errcode = 'PT403'; end if;
  if (select count(*) from public.attendance_scan_attempts where user_id = v_uid and attempted_at > now() - interval '5 minutes') >= 30 then
    raise exception 'Too many scans; try again in a few minutes' using errcode = 'PT429'; end if;
  insert into public.attendance_scan_attempts (user_id) values (v_uid);  -- persisted: failures below return, never raise

  if p_token is null or p_token !~ '^LP1\.[0-9a-f]{32}$' then return jsonb_build_object('ok', false, 'reason', 'invalid'); end if;
  select * into v_t from public.attendance_qr_tokens where token_hash = extensions.digest(p_token, 'sha256');
  if not found then return jsonb_build_object('ok', false, 'reason', 'invalid'); end if;
  if v_t.expires_at <= v_now then return jsonb_build_object('ok', false, 'reason', 'expired'); end if;
  select * into v_s from public.attendance_sessions where id = v_t.session_id;
  select status into v_course_status from public.courses where id = v_s.course_id;
  if v_s.status <> 'open' or v_course_status <> 'active' then return jsonb_build_object('ok', false, 'reason', 'closed'); end if;
  if not exists (select 1 from public.course_members where course_id = v_s.course_id and student_id = v_uid and status = 'active') then
    return jsonb_build_object('ok', false, 'reason', 'not_member'); end if;

  if v_t.action = 'in' then
    if v_now < v_s.starts_at - make_interval(mins => v_s.checkin_opens_minutes) then
      return jsonb_build_object('ok', false, 'reason', 'too_early', 'opens_at', v_s.starts_at - make_interval(mins => v_s.checkin_opens_minutes)); end if;
    if v_s.checkin_window_minutes is not null and v_now > v_s.starts_at + make_interval(mins => v_s.checkin_window_minutes) then
      return jsonb_build_object('ok', false, 'reason', 'too_late'); end if;
    v_status := case when v_now > v_s.starts_at + make_interval(mins => v_s.late_after_minutes) then 'late' else 'present' end;
    insert into public.attendance_records (session_id, student_id, status, marked_by, checked_in_at, source)
    values (v_s.id, v_uid, v_status, v_uid, v_now, 'qr')
    on conflict (session_id, student_id) do nothing returning * into v_rec;
    if found then
      insert into public.attendance_events (session_id, student_id, actor_id, action, new_status, version_after, request_id, response)
      values (v_s.id, v_uid, v_uid, 'checkin', v_status, v_rec.version, gen_random_uuid(),
              jsonb_build_object('status', v_status, 'checked_in_at', v_now));
      return jsonb_build_object('ok', true, 'action', 'in', 'already', false, 'status', v_rec.status, 'checked_in_at', v_rec.checked_in_at,
                                'session_id', v_s.id, 'title', v_s.title, 'requires_checkout', v_s.requires_checkout);
    end if;
    select * into v_rec from public.attendance_records where session_id = v_s.id and student_id = v_uid;
    return jsonb_build_object('ok', true, 'action', 'in', 'already', true, 'status', v_rec.status, 'checked_in_at', v_rec.checked_in_at,
                              'session_id', v_s.id, 'title', v_s.title, 'requires_checkout', v_s.requires_checkout);
  end if;

  -- check-out: only after a valid present/late record; never changes the status or the version
  select * into v_rec from public.attendance_records where session_id = v_s.id and student_id = v_uid for update;
  if not found or v_rec.status not in ('present', 'late') then return jsonb_build_object('ok', false, 'reason', 'no_checkin'); end if;
  if v_rec.checked_out_at is not null then
    return jsonb_build_object('ok', true, 'action', 'out', 'already', true, 'status', v_rec.status, 'checked_in_at', v_rec.checked_in_at,
                              'checked_out_at', v_rec.checked_out_at, 'session_id', v_s.id, 'title', v_s.title);
  end if;
  update public.attendance_records set checked_out_at = v_now where session_id = v_s.id and student_id = v_uid returning * into v_rec;
  insert into public.attendance_events (session_id, student_id, actor_id, action, new_status, version_after, request_id, response)
  values (v_s.id, v_uid, v_uid, 'checkout', v_rec.status, v_rec.version, gen_random_uuid(), jsonb_build_object('checked_out_at', v_now));
  return jsonb_build_object('ok', true, 'action', 'out', 'already', false, 'status', v_rec.status, 'checked_in_at', v_rec.checked_in_at,
                            'checked_out_at', v_rec.checked_out_at, 'session_id', v_s.id, 'title', v_s.title);
end $$;

do $$
declare f text;
begin
  foreach f in array array['public.set_attendance_rules(uuid, uuid, integer, boolean, integer, integer, integer)',
                           'public.issue_attendance_qr(uuid, text)', 'public.scan_attendance(text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
