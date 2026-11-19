-- V14 Staff (teacher) attendance — a domain separate from student attendance (additive). See docs/ATTENDANCE_OPTION_E_ARCHITECTURE.md §4.
--   Staff = existing `teacher` accounts; app_role is unchanged. Nobody is a manager by default: supervision is an explicit row in
--   staff_supervision that only an administrator (service role / migration) can create. There is NO client write path to any table.
--   All punches use the SERVER clock. Missing check-out and absence are DERIVED at read time (nothing is fabricated or auto-closed).
-- Errors: PT400 invalid input, PT401, PT403 (wrong role / self-decision), PT404 (not found OR not authorised: no existence leak),
-- PT409 state conflict, PT429 limit.

create table public.staff_supervision (
  supervisor_id uuid not null references public.profiles (id) on delete cascade,
  staff_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (supervisor_id, staff_id),
  check (supervisor_id <> staff_id)
);

create table public.staff_schedules (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles (id) on delete cascade,
  label text not null default '' check (char_length(label) <= 60),
  weekdays smallint[] not null check (cardinality(weekdays) between 1 and 7 and weekdays <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]),
  start_time time not null,
  end_time time not null,
  timezone text not null default 'Asia/Bangkok',
  late_grace_minutes integer not null default 10 check (late_grace_minutes between 0 and 120),
  effective_from date not null default current_date,
  effective_to date,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  check (end_time > start_time),
  check (effective_to is null or effective_to >= effective_from)
);
create index staff_schedules_staff_idx on public.staff_schedules (staff_id);

create table public.staff_attendance (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles (id) on delete cascade,
  work_date date not null,
  schedule_id uuid references public.staff_schedules (id) on delete set null,
  clock_in_at timestamptz not null,
  clock_out_at timestamptz,
  late_minutes integer not null default 0 check (late_minutes >= 0),
  source text not null default 'self' check (source in ('self', 'correction')),
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (clock_out_at is null or clock_out_at >= clock_in_at)
);
create unique index staff_attendance_period_uq
  on public.staff_attendance (staff_id, work_date, coalesce(schedule_id, '00000000-0000-0000-0000-000000000000'::uuid));
create index staff_attendance_staff_date_idx on public.staff_attendance (staff_id, work_date desc);

create table public.staff_requests (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('leave', 'correction')),
  date_from date not null,
  date_to date not null,
  proposed_clock_in timestamptz,
  proposed_clock_out timestamptz,
  reason text not null check (char_length(btrim(reason)) between 3 and 500),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  decision_note text not null default '' check (char_length(decision_note) <= 500),
  request_id uuid not null unique,
  created_at timestamptz not null default now(),
  check (date_to >= date_from),
  check (kind <> 'correction' or (date_from = date_to and (proposed_clock_in is not null or proposed_clock_out is not null))),
  check (kind <> 'leave' or (proposed_clock_in is null and proposed_clock_out is null))
);
create index staff_requests_staff_idx on public.staff_requests (staff_id, status);

create table public.staff_attendance_events (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid not null references public.profiles (id) on delete cascade,
  actor_id uuid not null references public.profiles (id) on delete cascade,
  action text not null check (action in ('clock_in', 'clock_out', 'leave_requested', 'correction_requested', 'approved', 'rejected', 'cancelled', 'schedule_saved', 'schedule_ended')),
  details jsonb not null default '{}',
  request_id uuid unique,
  created_at timestamptz not null default now()
);
create index staff_attendance_events_staff_idx on public.staff_attendance_events (staff_id, created_at desc);

-- Authorization helpers (private schema: usable by RLS, not reachable through the API) -------------
create function private.supervises(p_staff_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.staff_supervision
                  where supervisor_id = (select auth.uid()) and staff_id = p_staff_id and supervisor_id <> staff_id)
$$;
revoke all on function private.supervises(uuid) from public, anon, authenticated, service_role;
grant execute on function private.supervises(uuid) to authenticated;

alter table public.staff_supervision enable row level security;
alter table public.staff_schedules enable row level security;
alter table public.staff_attendance enable row level security;
alter table public.staff_requests enable row level security;
alter table public.staff_attendance_events enable row level security;

create policy staff_supervision_select on public.staff_supervision for select to authenticated
  using (supervisor_id = (select auth.uid()) or staff_id = (select auth.uid()));
create policy staff_schedules_select on public.staff_schedules for select to authenticated
  using (staff_id = (select auth.uid()) or private.supervises(staff_id));
create policy staff_attendance_select on public.staff_attendance for select to authenticated
  using (staff_id = (select auth.uid()) or private.supervises(staff_id));
create policy staff_requests_select on public.staff_requests for select to authenticated
  using (staff_id = (select auth.uid()) or private.supervises(staff_id));
create policy staff_attendance_events_select on public.staff_attendance_events for select to authenticated
  using (staff_id = (select auth.uid()) or private.supervises(staff_id));
grant select on public.staff_supervision, public.staff_schedules, public.staff_attendance, public.staff_requests,
  public.staff_attendance_events to authenticated;

-- Derived report for ONE staff member (internal; callers authorise first) --------------------------
create function private.staff_report(p_staff uuid, p_from date, p_to date) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_rows jsonb;
  v_totals jsonb;
begin
  with days as (select d::date as day from generate_series(p_from, p_to, interval '1 day') d),
  expected as (
    select dy.day, sc.id as schedule_id, sc.start_time, sc.end_time, sc.timezone, sc.late_grace_minutes
      from days dy join public.staff_schedules sc
        on sc.staff_id = p_staff and extract(isodow from dy.day)::smallint = any (sc.weekdays)
       and dy.day between sc.effective_from and coalesce(sc.effective_to, 'infinity'::date)),
  punches as (select * from public.staff_attendance where staff_id = p_staff and work_date between p_from and p_to),
  leave_days as (
    select distinct g::date as day from public.staff_requests r, generate_series(r.date_from, r.date_to, interval '1 day') g
     where r.staff_id = p_staff and r.kind = 'leave' and r.status = 'approved'),
  joined as (
    select coalesce(e.day, p.work_date) as day, coalesce(e.schedule_id, p.schedule_id) as schedule_id,
           e.start_time, e.end_time, e.timezone, p.id as punch_id, p.clock_in_at, p.clock_out_at, p.late_minutes, p.source
      from expected e full join punches p on p.work_date = e.day and p.schedule_id is not distinct from e.schedule_id),
  rowsx as (
    select j.*, (select true from leave_days l where l.day = j.day) as on_leave,
           case when j.end_time is null then null
                else ((j.day + j.end_time) at time zone j.timezone) end as period_end
      from joined j)
  select coalesce(jsonb_agg(jsonb_build_object(
           'day', day, 'schedule_id', schedule_id, 'start_time', start_time, 'end_time', end_time,
           'clock_in_at', clock_in_at, 'clock_out_at', clock_out_at, 'late_minutes', late_minutes, 'source', source,
           'state', case
             when punch_id is not null and clock_out_at is null
               then case when (period_end is not null and period_end < now()) or (period_end is null and day < (now() at time zone 'Asia/Bangkok')::date)
                         then 'missing_checkout' else 'in_progress' end
             when punch_id is not null and schedule_id is null then 'unscheduled'
             when punch_id is not null and late_minutes > 0 then 'late'
             when punch_id is not null then 'on_time'
             when on_leave then 'leave'
             when period_end < now() then 'absent'
             else 'upcoming' end) order by day, start_time nulls last, clock_in_at), '[]'::jsonb)
    into v_rows from rowsx;
  select jsonb_build_object(
    'on_time', count(*) filter (where r ->> 'state' = 'on_time'),
    'late', count(*) filter (where r ->> 'state' = 'late'),
    'missing_checkout', count(*) filter (where r ->> 'state' = 'missing_checkout'),
    'absent', count(*) filter (where r ->> 'state' = 'absent'),
    'leave', count(*) filter (where r ->> 'state' = 'leave'),
    'unscheduled', count(*) filter (where r ->> 'state' = 'unscheduled'),
    'late_minutes', coalesce(sum((r ->> 'late_minutes')::int) filter (where r ->> 'state' in ('late')), 0),
    'worked_minutes', coalesce(sum(floor(extract(epoch from ((r ->> 'clock_out_at')::timestamptz - (r ->> 'clock_in_at')::timestamptz)) / 60)::int)
                               filter (where r ->> 'clock_out_at' is not null), 0))
    into v_totals from jsonb_array_elements(v_rows) r;
  return jsonb_build_object('staff_id', p_staff, 'from', p_from, 'to', p_to, 'rows', v_rows, 'totals', v_totals);
end $$;
revoke all on function private.staff_report(uuid, date, date) from public, anon, authenticated, service_role;

-- RPCs ---------------------------------------------------------------------------------------------
create function public.get_my_staff_context() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'teacher') then
    return jsonb_build_object('is_staff', false, 'is_supervisor', false); end if;
  return jsonb_build_object(
    'is_staff', true,
    'is_supervisor', exists (select 1 from public.staff_supervision where supervisor_id = v_uid),
    'server_now', now(),
    'supervisors', (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.full_name)), '[]') from public.staff_supervision s join public.profiles p on p.id = s.supervisor_id where s.staff_id = v_uid),
    'supervisees', (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.full_name) order by p.full_name), '[]') from public.staff_supervision s join public.profiles p on p.id = s.staff_id where s.supervisor_id = v_uid),
    'schedules', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'label', label, 'weekdays', weekdays, 'start_time', start_time, 'end_time', end_time,
                    'timezone', timezone, 'late_grace_minutes', late_grace_minutes, 'effective_from', effective_from, 'effective_to', effective_to) order by start_time), '[]')
                    from public.staff_schedules where staff_id = v_uid and (effective_to is null or effective_to >= current_date)),
    'open_punch', (select to_jsonb(a) from (select id, work_date, clock_in_at, late_minutes, schedule_id from public.staff_attendance
                    where staff_id = v_uid and clock_out_at is null order by clock_in_at desc limit 1) a));
end $$;

create function public.staff_clock_in(p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
  v_sch public.staff_schedules;
  v_ev public.staff_attendance_events;
  v_row public.staff_attendance;
  v_local timestamp;
  v_start timestamp;
  v_late integer := 0;
  v_date date;
  v_resp jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'teacher') then
    raise exception 'Only staff can clock in' using errcode = 'PT403'; end if;
  select * into v_ev from public.staff_attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.action <> 'clock_in' then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.details || jsonb_build_object('replayed', true);
  end if;
  perform 1 from public.profiles where id = v_uid for update;  -- serialises this person's punches
  if exists (select 1 from public.staff_attendance where staff_id = v_uid and clock_out_at is null and clock_in_at > v_now - interval '20 hours') then
    raise exception 'You are already clocked in; clock out first' using errcode = 'PT409'; end if;

  select sc.* into v_sch
    from public.staff_schedules sc
    cross join lateral (select (v_now at time zone sc.timezone) as l) x
   where sc.staff_id = v_uid and extract(isodow from x.l)::smallint = any (sc.weekdays)
     and x.l::date between sc.effective_from and coalesce(sc.effective_to, 'infinity'::date)
     and x.l between (x.l::date + sc.start_time) - interval '60 minutes' and (x.l::date + sc.end_time)
   order by sc.start_time limit 1;
  if found then
    v_local := v_now at time zone v_sch.timezone;
    v_date := v_local::date;
    v_start := v_date + v_sch.start_time;
    if v_local > v_start + make_interval(mins => v_sch.late_grace_minutes) then
      v_late := floor(extract(epoch from (v_local - v_start)) / 60)::int; end if;
  else
    v_date := (v_now at time zone 'Asia/Bangkok')::date;
  end if;
  begin
    insert into public.staff_attendance (staff_id, work_date, schedule_id, clock_in_at, late_minutes)
    values (v_uid, v_date, v_sch.id, v_now, v_late) returning * into v_row;
  exception when unique_violation then
    raise exception 'You already have a record for this working period' using errcode = 'PT409';
  end;
  v_resp := jsonb_build_object('id', v_row.id, 'work_date', v_row.work_date, 'clock_in_at', v_row.clock_in_at, 'late_minutes', v_row.late_minutes,
                               'schedule_id', v_row.schedule_id, 'scheduled', v_sch.id is not null, 'state', case when v_late > 0 then 'late' else 'on_time' end);
  insert into public.staff_attendance_events (staff_id, actor_id, action, details, request_id) values (v_uid, v_uid, 'clock_in', v_resp, p_request_id);
  return v_resp;
end $$;

create function public.staff_clock_out(p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
  v_ev public.staff_attendance_events;
  v_row public.staff_attendance;
  v_resp jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'teacher') then
    raise exception 'Only staff can clock out' using errcode = 'PT403'; end if;
  select * into v_ev from public.staff_attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.action <> 'clock_out' then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.details || jsonb_build_object('replayed', true);
  end if;
  perform 1 from public.profiles where id = v_uid for update;
  select * into v_row from public.staff_attendance where staff_id = v_uid and clock_out_at is null order by clock_in_at desc limit 1 for update;
  if not found then raise exception 'You are not clocked in' using errcode = 'PT409'; end if;
  update public.staff_attendance set clock_out_at = v_now, version = version + 1, updated_at = now() where id = v_row.id returning * into v_row;
  v_resp := jsonb_build_object('id', v_row.id, 'work_date', v_row.work_date, 'clock_in_at', v_row.clock_in_at, 'clock_out_at', v_row.clock_out_at,
                               'worked_minutes', floor(extract(epoch from (v_row.clock_out_at - v_row.clock_in_at)) / 60)::int);
  insert into public.staff_attendance_events (staff_id, actor_id, action, details, request_id) values (v_uid, v_uid, 'clock_out', v_resp, p_request_id);
  return v_resp;
end $$;

create function public.get_staff_attendance(p_from date, p_to date, p_staff_id uuid default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_target uuid;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  v_target := coalesce(p_staff_id, v_uid);
  if p_from is null or p_to is null or p_to < p_from or p_to - p_from > 92 then
    raise exception 'Choose a range of at most 93 days' using errcode = 'PT400'; end if;
  if v_target <> v_uid and not exists (select 1 from public.staff_supervision where supervisor_id = v_uid and staff_id = v_target) then
    raise exception 'Staff member not found' using errcode = 'PT404'; end if;
  if not exists (select 1 from public.profiles where id = v_target and role = 'teacher') then
    raise exception 'Staff member not found' using errcode = 'PT404'; end if;
  return private.staff_report(v_target, p_from, p_to)
         || jsonb_build_object('name', (select full_name from public.profiles where id = v_target), 'server_now', now());
end $$;

create function public.get_staff_team_summary(p_from date, p_to date) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_from is null or p_to is null or p_to < p_from or p_to - p_from > 92 then
    raise exception 'Choose a range of at most 93 days' using errcode = 'PT400'; end if;
  return jsonb_build_object('from', p_from, 'to', p_to, 'staff', (
    select coalesce(jsonb_agg(jsonb_build_object('staff_id', s.staff_id, 'name', p.full_name,
             'totals', private.staff_report(s.staff_id, p_from, p_to) -> 'totals') order by p.full_name), '[]')
      from public.staff_supervision s join public.profiles p on p.id = s.staff_id where s.supervisor_id = v_uid));
end $$;

create function public.submit_staff_request(
  p_request_id uuid, p_kind text, p_from date, p_to date, p_reason text, p_clock_in timestamptz default null, p_clock_out timestamptz default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_ev public.staff_attendance_events;
  v_r public.staff_requests;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_resp jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'teacher') then
    raise exception 'Only staff can submit requests' using errcode = 'PT403'; end if;
  select * into v_ev from public.staff_attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.action not in ('leave_requested', 'correction_requested') then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.details || jsonb_build_object('replayed', true);
  end if;
  if p_kind is null or p_kind not in ('leave', 'correction') then raise exception 'Kind must be leave or correction' using errcode = 'PT400'; end if;
  if char_length(v_reason) not between 3 and 500 then raise exception 'Give a reason of 3 to 500 characters' using errcode = 'PT400'; end if;
  if p_from is null or p_to is null or p_to < p_from or p_from < current_date - 366 or p_to > current_date + 366 then
    raise exception 'Choose valid dates within a year of today' using errcode = 'PT400'; end if;
  if (select count(*) from public.staff_requests where staff_id = v_uid and status = 'pending') >= 20 then
    raise exception 'You have too many pending requests' using errcode = 'PT429'; end if;
  if p_kind = 'leave' then
    if p_to - p_from > 30 then raise exception 'Leave is limited to 31 days per request' using errcode = 'PT400'; end if;
    if p_clock_in is not null or p_clock_out is not null then raise exception 'Leave has no clock times' using errcode = 'PT400'; end if;
  else
    if p_from <> p_to or p_to > current_date then raise exception 'A correction is for one past day' using errcode = 'PT400'; end if;
    if p_clock_in is null and p_clock_out is null then raise exception 'Give the correct clock-in or clock-out time' using errcode = 'PT400'; end if;
    if p_clock_in is not null and p_clock_out is not null and p_clock_out < p_clock_in then
      raise exception 'Clock-out must be after clock-in' using errcode = 'PT400'; end if;
  end if;
  insert into public.staff_requests (staff_id, kind, date_from, date_to, proposed_clock_in, proposed_clock_out, reason, request_id)
  values (v_uid, p_kind, p_from, p_to, p_clock_in, p_clock_out, v_reason, p_request_id) returning * into v_r;
  v_resp := jsonb_build_object('id', v_r.id, 'kind', v_r.kind, 'status', v_r.status, 'date_from', v_r.date_from, 'date_to', v_r.date_to);
  insert into public.staff_attendance_events (staff_id, actor_id, action, details, request_id)
  values (v_uid, v_uid, case p_kind when 'leave' then 'leave_requested' else 'correction_requested' end, v_resp, p_request_id);
  return v_resp;
end $$;

create function public.cancel_staff_request(p_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_r public.staff_requests;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select * into v_r from public.staff_requests where id = p_id and staff_id = v_uid for update;
  if not found then raise exception 'Request not found' using errcode = 'PT404'; end if;
  if v_r.status <> 'pending' then raise exception 'Only a pending request can be cancelled' using errcode = 'PT409'; end if;
  update public.staff_requests set status = 'cancelled' where id = p_id;
  insert into public.staff_attendance_events (staff_id, actor_id, action, details) values (v_uid, v_uid, 'cancelled', jsonb_build_object('request', p_id));
  return jsonb_build_object('id', p_id, 'status', 'cancelled');
end $$;

create function public.list_staff_requests(p_scope text default 'mine', p_status text default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_scope not in ('mine', 'decide') then raise exception 'Scope must be mine or decide' using errcode = 'PT400'; end if;
  if p_status is not null and p_status not in ('pending', 'approved', 'rejected', 'cancelled') then raise exception 'Unknown status' using errcode = 'PT400'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', r.id, 'staff_id', r.staff_id, 'staff_name', p.full_name, 'kind', r.kind,
            'date_from', r.date_from, 'date_to', r.date_to, 'proposed_clock_in', r.proposed_clock_in, 'proposed_clock_out', r.proposed_clock_out,
            'reason', r.reason, 'status', r.status, 'decided_at', r.decided_at, 'decision_note', r.decision_note, 'created_at', r.created_at)
            order by r.created_at desc), '[]')
    from (select * from public.staff_requests q
           where (p_status is null or q.status = p_status)
             and ((p_scope = 'mine' and q.staff_id = v_uid)
               or (p_scope = 'decide' and q.staff_id <> v_uid and exists (select 1 from public.staff_supervision s where s.supervisor_id = v_uid and s.staff_id = q.staff_id)))
           order by q.created_at desc limit 100) r
    join public.profiles p on p.id = r.staff_id);
end $$;

create function public.decide_staff_request(p_id uuid, p_request_id uuid, p_decision text, p_note text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_ev public.staff_attendance_events;
  v_r public.staff_requests;
  v_note text := btrim(coalesce(p_note, ''));
  v_punch public.staff_attendance;
  v_sch public.staff_schedules;
  v_new_in timestamptz;
  v_late integer := 0;
  v_resp jsonb;
  v_before jsonb := '{}';
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  if p_decision is null or p_decision not in ('approve', 'reject') then raise exception 'Decision must be approve or reject' using errcode = 'PT400'; end if;
  if char_length(v_note) > 500 then raise exception 'Note is too long' using errcode = 'PT400'; end if;
  select * into v_ev from public.staff_attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.action not in ('approved', 'rejected') then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.details || jsonb_build_object('replayed', true);
  end if;
  select * into v_r from public.staff_requests where id = p_id for update;
  if not found then raise exception 'Request not found' using errcode = 'PT404'; end if;
  if v_r.staff_id = v_uid then raise exception 'You cannot decide your own request' using errcode = 'PT403'; end if;
  if not exists (select 1 from public.staff_supervision where supervisor_id = v_uid and staff_id = v_r.staff_id) then
    raise exception 'Request not found' using errcode = 'PT404'; end if;
  if v_r.status <> 'pending' then raise exception 'This request was already decided' using errcode = 'PT409'; end if;

  if p_decision = 'approve' and v_r.kind = 'correction' then
    select * into v_punch from public.staff_attendance where staff_id = v_r.staff_id and work_date = v_r.date_from order by clock_in_at limit 1 for update;
    if found then
      v_before := jsonb_build_object('clock_in_at', v_punch.clock_in_at, 'clock_out_at', v_punch.clock_out_at, 'late_minutes', v_punch.late_minutes);
      v_new_in := coalesce(v_r.proposed_clock_in, v_punch.clock_in_at);
      if coalesce(v_r.proposed_clock_out, v_punch.clock_out_at) is not null and coalesce(v_r.proposed_clock_out, v_punch.clock_out_at) < v_new_in then
        raise exception 'The corrected times are inconsistent' using errcode = 'PT409'; end if;
      if v_punch.schedule_id is not null and v_r.proposed_clock_in is not null then
        select * into v_sch from public.staff_schedules where id = v_punch.schedule_id;
        if found and (v_new_in at time zone v_sch.timezone) > (v_punch.work_date + v_sch.start_time) + make_interval(mins => v_sch.late_grace_minutes) then
          v_late := floor(extract(epoch from ((v_new_in at time zone v_sch.timezone) - (v_punch.work_date + v_sch.start_time))) / 60)::int; end if;
      elsif v_r.proposed_clock_in is null then
        v_late := v_punch.late_minutes;
      end if;
      update public.staff_attendance set clock_in_at = v_new_in, clock_out_at = coalesce(v_r.proposed_clock_out, clock_out_at),
             late_minutes = v_late, source = 'correction', version = version + 1, updated_at = now() where id = v_punch.id;
    else
      if v_r.proposed_clock_in is null then raise exception 'No punch exists that day; the request needs a clock-in time' using errcode = 'PT409'; end if;
      select sc.* into v_sch from public.staff_schedules sc
       where sc.staff_id = v_r.staff_id and extract(isodow from v_r.date_from)::smallint = any (sc.weekdays)
         and v_r.date_from between sc.effective_from and coalesce(sc.effective_to, 'infinity'::date) order by sc.start_time limit 1;
      if found and (v_r.proposed_clock_in at time zone v_sch.timezone) > (v_r.date_from + v_sch.start_time) + make_interval(mins => v_sch.late_grace_minutes) then
        v_late := floor(extract(epoch from ((v_r.proposed_clock_in at time zone v_sch.timezone) - (v_r.date_from + v_sch.start_time))) / 60)::int; end if;
      insert into public.staff_attendance (staff_id, work_date, schedule_id, clock_in_at, clock_out_at, late_minutes, source)
      values (v_r.staff_id, v_r.date_from, v_sch.id, v_r.proposed_clock_in, v_r.proposed_clock_out, v_late, 'correction');
    end if;
  end if;

  update public.staff_requests
     set status = case p_decision when 'approve' then 'approved' else 'rejected' end, decided_by = v_uid, decided_at = now(), decision_note = v_note
   where id = p_id;
  v_resp := jsonb_build_object('id', p_id, 'status', case p_decision when 'approve' then 'approved' else 'rejected' end, 'kind', v_r.kind,
                               'staff_id', v_r.staff_id, 'decided_by', v_uid, 'note', v_note, 'before', v_before);
  insert into public.staff_attendance_events (staff_id, actor_id, action, details, request_id)
  values (v_r.staff_id, v_uid, case p_decision when 'approve' then 'approved' else 'rejected' end, v_resp, p_request_id);
  return v_resp;
end $$;

create function public.save_staff_schedule(
  p_staff_id uuid, p_request_id uuid, p_label text, p_weekdays smallint[], p_start time, p_end time, p_timezone text,
  p_grace integer, p_effective_from date, p_effective_to date default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_ev public.staff_attendance_events;
  v_s public.staff_schedules;
  v_resp jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  if p_staff_id = v_uid or not exists (select 1 from public.staff_supervision where supervisor_id = v_uid and staff_id = p_staff_id) then
    raise exception 'Staff member not found' using errcode = 'PT404'; end if;
  select * into v_ev from public.staff_attendance_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.action <> 'schedule_saved' then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.details || jsonb_build_object('replayed', true);
  end if;
  if p_timezone is null or not exists (select 1 from pg_timezone_names where name = p_timezone) then raise exception 'Unknown time zone' using errcode = 'PT400'; end if;
  if p_weekdays is null or cardinality(p_weekdays) not between 1 and 7 or not (p_weekdays <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[])
     or p_start is null or p_end is null or p_end <= p_start or p_grace is null or p_grace not between 0 and 120
     or p_effective_from is null or (p_effective_to is not null and p_effective_to < p_effective_from) then
    raise exception 'The schedule is invalid' using errcode = 'PT400'; end if;
  if (select count(*) from public.staff_schedules where staff_id = p_staff_id and (effective_to is null or effective_to >= current_date)) >= 10 then
    raise exception 'Too many active schedules' using errcode = 'PT429'; end if;
  insert into public.staff_schedules (staff_id, label, weekdays, start_time, end_time, timezone, late_grace_minutes, effective_from, effective_to, created_by)
  values (p_staff_id, left(btrim(coalesce(p_label, '')), 60), p_weekdays, p_start, p_end, p_timezone, p_grace, p_effective_from, p_effective_to, v_uid) returning * into v_s;
  v_resp := jsonb_build_object('id', v_s.id, 'staff_id', p_staff_id);
  insert into public.staff_attendance_events (staff_id, actor_id, action, details, request_id) values (p_staff_id, v_uid, 'schedule_saved', v_resp, p_request_id);
  return v_resp;
end $$;

create function public.end_staff_schedule(p_schedule_id uuid, p_effective_to date) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_s public.staff_schedules;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select sc.* into v_s from public.staff_schedules sc where sc.id = p_schedule_id for update;
  if not found or v_s.staff_id = v_uid or not exists (select 1 from public.staff_supervision where supervisor_id = v_uid and staff_id = v_s.staff_id) then
    raise exception 'Schedule not found' using errcode = 'PT404'; end if;
  if p_effective_to is null or p_effective_to < v_s.effective_from then raise exception 'The end date is invalid' using errcode = 'PT400'; end if;
  update public.staff_schedules set effective_to = p_effective_to where id = p_schedule_id;
  insert into public.staff_attendance_events (staff_id, actor_id, action, details) values (v_s.staff_id, v_uid, 'schedule_ended', jsonb_build_object('schedule', p_schedule_id, 'to', p_effective_to));
  return jsonb_build_object('id', p_schedule_id, 'effective_to', p_effective_to);
end $$;

do $$
declare f text;
begin
  foreach f in array array[
    'public.get_my_staff_context()', 'public.staff_clock_in(uuid)', 'public.staff_clock_out(uuid)',
    'public.get_staff_attendance(date, date, uuid)', 'public.get_staff_team_summary(date, date)',
    'public.submit_staff_request(uuid, text, date, date, text, timestamptz, timestamptz)', 'public.cancel_staff_request(uuid)',
    'public.list_staff_requests(text, text)', 'public.decide_staff_request(uuid, uuid, text, text)',
    'public.save_staff_schedule(uuid, uuid, text, smallint[], time, time, text, integer, date, date)', 'public.end_staff_schedule(uuid, date)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
