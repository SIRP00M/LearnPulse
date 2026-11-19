-- V6 teacher-controlled attendance.
-- Model: a session (open -> closed) per class meeting; one record per (session, student) with a status of
-- present / absent / late / excused. Students only read their own records; every write is an RPC.
-- Lifecycle: open --mark--> records appear; close finalizes the roster: every ACTIVE member with no record gets
-- 'absent' (event note "Closed without a mark"). After close, existing records can still be corrected
-- (history keeps every change); students who joined after close have no record and cannot be marked.
-- Concurrency: record `version` (0 = no record yet) + PT409; every RPC takes a client request id for lost-response
-- replay. All timestamps are timestamptz (UTC on the wire); the client renders device-local time.
-- Summary rate = (present + late) / (present + late + absent); excused and unmarked are excluded.

create type public.attendance_status as enum ('present', 'absent', 'late', 'excused');
create type public.attendance_session_status as enum ('open', 'closed');

create table public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  starts_at timestamptz not null,
  status public.attendance_session_status not null default 'open',
  closed_at timestamptz,
  version integer not null default 1,
  request_id uuid not null unique,
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  check ((status = 'closed') = (closed_at is not null))
);
create index attendance_sessions_course_idx on public.attendance_sessions (course_id, starts_at desc);

create table public.attendance_records (
  session_id uuid not null references public.attendance_sessions (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  status public.attendance_status not null,
  note text not null default '' check (char_length(note) <= 500),
  version integer not null default 1,
  marked_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now(),
  primary key (session_id, student_id)
);
create index attendance_records_student_idx on public.attendance_records (student_id);

-- Append-only history; clients have no write privilege on it.
create table public.attendance_events (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.attendance_sessions (id) on delete cascade,
  student_id uuid references public.profiles (id) on delete cascade,
  actor_id uuid not null references public.profiles (id) on delete cascade,
  action text not null check (action in ('marked', 'corrected', 'closed')),
  old_status public.attendance_status,
  new_status public.attendance_status,
  note text not null default '',
  version_after integer not null,
  request_id uuid not null unique,
  response jsonb not null,
  created_at timestamptz not null default now()
);
create index attendance_events_session_idx on public.attendance_events (session_id, created_at);

-- Authorization helpers (private schema: usable by RLS, not reachable through the API) -------------
create function private.is_attendance_owner(p_session_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.attendance_sessions s join public.courses c on c.id = s.course_id
                  where s.id = p_session_id and c.owner_id = (select auth.uid()))
$$;

create function private.is_attendance_member(p_session_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.attendance_sessions s
                   join public.course_members m on m.course_id = s.course_id
                  where s.id = p_session_id and m.student_id = (select auth.uid()) and m.status = 'active')
$$;

do $$
declare
  f text;
begin
  foreach f in array array['private.is_attendance_owner(uuid)', 'private.is_attendance_member(uuid)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

alter table public.attendance_sessions enable row level security;
alter table public.attendance_records enable row level security;
alter table public.attendance_events enable row level security;

create policy attendance_sessions_select on public.attendance_sessions for select to authenticated
  using (private.is_attendance_owner(id) or private.is_attendance_member(id));
create policy attendance_records_select on public.attendance_records for select to authenticated
  using (private.is_attendance_owner(session_id)
         or (student_id = (select auth.uid()) and private.is_attendance_member(session_id)));
create policy attendance_events_select on public.attendance_events for select to authenticated
  using (private.is_attendance_owner(session_id));

grant select on public.attendance_sessions, public.attendance_records, public.attendance_events to authenticated;

-- RPCs ---------------------------------------------------------------------------------------
create function public.create_attendance_session(
  p_course_id uuid, p_request_id uuid, p_title text, p_starts_at timestamptz
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_title text := btrim(coalesce(p_title, ''));
  v_course public.courses;
  v_s public.attendance_sessions;
  v_rows integer;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  select * into v_course from public.courses where id = p_course_id and owner_id = v_uid;
  if not found then raise exception 'Course not found' using errcode = 'PT404'; end if;

  select * into v_s from public.attendance_sessions where request_id = p_request_id;
  if found then
    if v_s.created_by <> v_uid or v_s.course_id <> p_course_id or v_s.title <> v_title
       or v_s.starts_at is distinct from p_starts_at then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return jsonb_build_object('id', v_s.id, 'version', v_s.version, 'status', v_s.status,
                              'starts_at', v_s.starts_at, 'replayed', true);
  end if;

  if v_course.status <> 'active' then raise exception 'Course is archived' using errcode = 'PT409'; end if;
  if char_length(v_title) not between 1 and 120 then
    raise exception 'Title must be 1-120 characters' using errcode = 'PT400'; end if;
  if p_starts_at is null or p_starts_at < now() - interval '1 year' or p_starts_at > now() + interval '1 year' then
    raise exception 'Start time must be within a year of today' using errcode = 'PT400'; end if;
  if (select count(*) from public.attendance_sessions where course_id = p_course_id) >= 300 then
    raise exception 'This course reached the 300 session limit' using errcode = 'PT409'; end if;

  insert into public.attendance_sessions (course_id, title, starts_at, request_id, created_by)
  values (p_course_id, v_title, p_starts_at, p_request_id, v_uid)
  on conflict (request_id) do nothing returning * into v_s;
  get diagnostics v_rows = row_count;
  if v_rows = 0 then  -- a concurrent retry with the same id won the insert
    select * into v_s from public.attendance_sessions where request_id = p_request_id;
    if v_s.created_by <> v_uid or v_s.course_id <> p_course_id or v_s.title <> v_title
       or v_s.starts_at is distinct from p_starts_at then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return jsonb_build_object('id', v_s.id, 'version', v_s.version, 'status', v_s.status,
                              'starts_at', v_s.starts_at, 'replayed', true);
  end if;
  return jsonb_build_object('id', v_s.id, 'version', v_s.version, 'status', v_s.status, 'starts_at', v_s.starts_at);
end $$;

create function public.mark_attendance(
  p_session_id uuid, p_student_id uuid, p_request_id uuid, p_expected_version integer,
  p_status public.attendance_status, p_note text default ''
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_s public.attendance_sessions;
  v_course_status public.course_status;
  v_ev public.attendance_events;
  v_rec public.attendance_records;
  v_note text := btrim(coalesce(p_note, ''));
  v_exists boolean;
  v_old public.attendance_status;
  v_response jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  -- Locking the session row serializes marks and close for this session.
  select s.* into v_s
    from public.attendance_sessions s join public.courses c on c.id = s.course_id
   where s.id = p_session_id and c.owner_id = v_uid for update of s;
  if not found then raise exception 'Session not found' using errcode = 'PT404'; end if;
  select status into v_course_status from public.courses where id = v_s.course_id;

  select * into v_ev from public.attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.session_id <> p_session_id or v_ev.student_id is distinct from p_student_id
       or v_ev.action not in ('marked', 'corrected') or v_ev.new_status is distinct from p_status
       or v_ev.note <> v_note then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.response || jsonb_build_object('replayed', true);
  end if;

  if p_status is null then raise exception 'Status required' using errcode = 'PT400'; end if;
  if char_length(v_note) > 500 then raise exception 'Note is too long (500 characters maximum)' using errcode = 'PT400'; end if;
  if v_course_status <> 'active' then raise exception 'Course is archived' using errcode = 'PT409'; end if;
  if not exists (select 1 from public.course_members
                  where course_id = v_s.course_id and student_id = p_student_id and status = 'active') then
    raise exception 'Student is not an active member of this course' using errcode = 'PT404'; end if;

  select * into v_rec from public.attendance_records where session_id = p_session_id and student_id = p_student_id for update;
  v_exists := found;
  if v_exists then
    if v_rec.version is distinct from p_expected_version then
      raise exception 'This record changed; reload and try again' using errcode = 'PT409'; end if;
    if v_rec.status = p_status and v_rec.note = v_note then  -- nothing to correct
      return jsonb_build_object('session_id', p_session_id, 'student_id', p_student_id, 'status', v_rec.status,
                                'note', v_rec.note, 'version', v_rec.version, 'unchanged', true);
    end if;
    v_old := v_rec.status;
    update public.attendance_records
       set status = p_status, note = v_note, version = version + 1, marked_by = v_uid, updated_at = now()
     where session_id = p_session_id and student_id = p_student_id returning * into v_rec;
  else
    if coalesce(p_expected_version, 0) <> 0 then
      raise exception 'This record changed; reload and try again' using errcode = 'PT409'; end if;
    if v_s.status = 'closed' then
      raise exception 'This session is closed' using errcode = 'PT409'; end if;
    insert into public.attendance_records (session_id, student_id, status, note, marked_by)
    values (p_session_id, p_student_id, p_status, v_note, v_uid) returning * into v_rec;
  end if;

  v_response := jsonb_build_object('session_id', p_session_id, 'student_id', p_student_id, 'status', v_rec.status,
                                   'note', v_rec.note, 'version', v_rec.version, 'updated_at', v_rec.updated_at);
  insert into public.attendance_events (session_id, student_id, actor_id, action, old_status, new_status, note,
                                        version_after, request_id, response)
  values (p_session_id, p_student_id, v_uid, case when v_exists then 'corrected' else 'marked' end,
          v_old,
          p_status, v_note, v_rec.version, p_request_id, v_response);
  return v_response;
end $$;

create function public.close_attendance_session(
  p_session_id uuid, p_request_id uuid, p_expected_version integer
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_s public.attendance_sessions;
  v_course_status public.course_status;
  v_ev public.attendance_events;
  v_auto integer;
  v_response jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  select s.* into v_s
    from public.attendance_sessions s join public.courses c on c.id = s.course_id
   where s.id = p_session_id and c.owner_id = v_uid for update of s;
  if not found then raise exception 'Session not found' using errcode = 'PT404'; end if;
  select status into v_course_status from public.courses where id = v_s.course_id;

  select * into v_ev from public.attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.session_id <> p_session_id or v_ev.action <> 'closed' then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.response || jsonb_build_object('replayed', true);
  end if;

  if v_s.version is distinct from p_expected_version then
    raise exception 'The session changed; reload and try again' using errcode = 'PT409'; end if;
  if v_s.status = 'closed' then raise exception 'This session is already closed' using errcode = 'PT409'; end if;
  if v_course_status <> 'active' then raise exception 'Course is archived' using errcode = 'PT409'; end if;

  with ins as (
    insert into public.attendance_records (session_id, student_id, status, note, marked_by)
    select p_session_id, m.student_id, 'absent', 'Closed without a mark', v_uid
      from public.course_members m
     where m.course_id = v_s.course_id and m.status = 'active'
       and not exists (select 1 from public.attendance_records r
                        where r.session_id = p_session_id and r.student_id = m.student_id)
    returning student_id),
  ev as (
    insert into public.attendance_events (session_id, student_id, actor_id, action, new_status, note,
                                          version_after, request_id, response)
    select p_session_id, student_id, v_uid, 'marked', 'absent', 'Closed without a mark', 1, gen_random_uuid(),
           jsonb_build_object('auto', true)
      from ins returning 1)
  select count(*) into v_auto from ev;

  update public.attendance_sessions set status = 'closed', closed_at = now(), version = version + 1
   where id = p_session_id returning * into v_s;
  v_response := jsonb_build_object('session_id', v_s.id, 'version', v_s.version, 'status', v_s.status,
                                   'closed_at', v_s.closed_at, 'auto_absent', v_auto);
  insert into public.attendance_events (session_id, actor_id, action, version_after, request_id, response)
  values (v_s.id, v_uid, 'closed', v_s.version, p_request_id, v_response);
  return v_response;
end $$;

-- Role-aware summary: the course owner gets every active student, an active member gets only themself.
create function public.get_attendance_summary(p_course_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_owner boolean;
  v_sessions integer;
  v_closed integer;
  v_students jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  v_owner := exists (select 1 from public.courses where id = p_course_id and owner_id = v_uid);
  if not v_owner and not exists (select 1 from public.course_members
                                  where course_id = p_course_id and student_id = v_uid and status = 'active') then
    raise exception 'Course not found' using errcode = 'PT404'; end if;

  select count(*), count(*) filter (where status = 'closed') into v_sessions, v_closed
    from public.attendance_sessions where course_id = p_course_id;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb order by t.full_name, t.student_id), '[]'::jsonb) into v_students
    from (
      select m.student_id, p.full_name,
             count(*) filter (where r.status = 'present') as present,
             count(*) filter (where r.status = 'absent') as absent,
             count(*) filter (where r.status = 'late') as late,
             count(*) filter (where r.status = 'excused') as excused,
             case when count(*) filter (where r.status in ('present', 'late', 'absent')) = 0 then null
                  else round(100.0 * count(*) filter (where r.status in ('present', 'late'))
                             / count(*) filter (where r.status in ('present', 'late', 'absent')), 1) end as rate
        from public.course_members m
        join public.profiles p on p.id = m.student_id
        left join public.attendance_records r on r.student_id = m.student_id
             and r.session_id in (select id from public.attendance_sessions where course_id = p_course_id)
       where m.course_id = p_course_id and m.status = 'active' and (v_owner or m.student_id = v_uid)
       group by m.student_id, p.full_name) t;

  return jsonb_build_object('course_id', p_course_id, 'sessions_total', v_sessions, 'sessions_closed', v_closed,
                            'students', v_students);
end $$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.create_attendance_session(uuid, uuid, text, timestamptz)',
    'public.mark_attendance(uuid, uuid, uuid, integer, public.attendance_status, text)',
    'public.close_attendance_session(uuid, uuid, integer)',
    'public.get_attendance_summary(uuid)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
