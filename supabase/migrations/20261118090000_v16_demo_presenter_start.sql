-- V16 Unified Demo Experience: presenter can START the prepared event from the app (Web and Flutter), no terminal needed.
-- Additive: new demo_start_session; replaces demo_my_sessions / demo_session_overview / demo_set_joins / demo_end_session (same signatures, same grants).
--   * Start is presenter-only, idempotent (a repeat never moves the clocks), refuses unless every seat is verified AVAILABLE and a Workshop exists.
--   * Resume can never extend the original absolute join deadline.
--   * Presenter actions lock the session row, so concurrent Start/Pause/End calls serialise.

create or replace function public.demo_my_sessions() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', d.id, 'label', d.label, 'status', d.status, 'workshop_course_id', d.workshop_course_id,
            'joins_close_at', d.joins_close_at, 'expires_at', d.expires_at, 'capacity', d.capacity, 'seats', d.seats) order by d.created_at desc), '[]')
            from public.demo_sessions d where d.presenter_id = v_uid and d.status in ('provisioning', 'open', 'paused', 'closed', 'expired')
             and exists (select 1 from public.profiles p where p.id = v_uid and p.role = 'teacher'));
end $$;

create or replace function public.demo_session_overview(p_session uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions;
begin
  d := private.demo_presenter_session(p_session);
  update public.demo_seats set state = 'disabled', disabled_reason = 'orphaned' where session_id = d.id and state = 'claimed' and reserve_expires_at < now();
  return jsonb_build_object('id', d.id, 'label', d.label, 'status', d.status, 'capacity', d.capacity, 'seats', d.seats, 'workshop_course_id', d.workshop_course_id,
    'workshop_title', (select c.title from public.courses c where c.id = d.workshop_course_id),
    'joins_close_at', d.joins_close_at, 'expires_at', d.expires_at, 'server_now', now(),
    'join_window_seconds', extract(epoch from d.joins_close_at - d.joins_open_at)::int,
    'lifetime_seconds', extract(epoch from d.expires_at - d.created_at)::int,
    'counts', (select coalesce(jsonb_object_agg(state, c), '{}') from (select state, count(*) c from public.demo_seats where session_id = d.id group by state) x),
    'recent', (select jsonb_build_object('claims', coalesce(sum(claims), 0), 'refused', coalesce(sum(refused), 0)) from public.demo_claim_stats where session_id = d.id and minute > now() - interval '10 minutes'),
    'seats_list', (select coalesce(jsonb_agg(jsonb_build_object('seat_no', seat_no, 'state', state, 'name', display_name, 'reserve', is_reserve) order by seat_no), '[]') from public.demo_seats where session_id = d.id));
end $$;

create function public.demo_start_session(p_session uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions; n integer; v_ready integer;
begin
  d := private.demo_presenter_session(p_session);
  perform 1 from public.demo_sessions where id = d.id for update;
  select * into d from public.demo_sessions where id = d.id;
  if d.status <> 'provisioning' then   -- idempotent: a repeat or retry returns the CURRENT clocks and changes nothing
    return jsonb_build_object('status', d.status, 'already', true, 'joins_close_at', d.joins_close_at, 'expires_at', d.expires_at);
  end if;
  if d.workshop_course_id is null then raise exception 'The Workshop is not ready' using errcode = 'PT409'; end if;
  select count(*) filter (where state = 'provisioning'), count(*) filter (where state = 'available') into n, v_ready from public.demo_seats where session_id = d.id;
  if n > 0 or v_ready < d.capacity then raise exception 'Seats are not ready' using errcode = 'PT409'; end if;
  perform private.demo_open_session(d.id);
  insert into public.demo_events (session_id, actor_id, action, details) values (d.id, (select auth.uid()), 'started', '{}');
  select * into d from public.demo_sessions where id = d.id;
  return jsonb_build_object('status', d.status, 'already', false, 'joins_close_at', d.joins_close_at, 'expires_at', d.expires_at);
end $$;
revoke all on function public.demo_start_session(uuid) from public, anon, authenticated, service_role;
grant execute on function public.demo_start_session(uuid) to authenticated;

create or replace function public.demo_set_joins(p_session uuid, p_mode text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions;
begin
  d := private.demo_presenter_session(p_session);
  if p_mode not in ('open', 'paused', 'closed') then raise exception 'Mode must be open, paused or closed' using errcode = 'PT400'; end if;
  perform 1 from public.demo_sessions where id = d.id for update;
  select * into d from public.demo_sessions where id = d.id;
  if d.status = p_mode then return jsonb_build_object('status', d.status, 'already', true); end if;
  if d.status in ('expired', 'deleted', 'provisioning') then raise exception 'This session cannot change joins' using errcode = 'PT409'; end if;
  if p_mode = 'open' and d.status = 'closed' then raise exception 'Closed joins cannot be reopened' using errcode = 'PT409'; end if;
  if p_mode = 'open' and (now() >= d.joins_close_at or now() >= d.expires_at) then raise exception 'The joining window has ended' using errcode = 'PT409'; end if;
  update public.demo_sessions set status = p_mode where id = d.id;
  insert into public.demo_events (session_id, actor_id, action, details) values (d.id, (select auth.uid()), 'joins_' || p_mode, '{}');
  return jsonb_build_object('status', p_mode, 'already', false);
end $$;

create or replace function public.demo_end_session(p_session uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions; n integer;
begin
  d := private.demo_presenter_session(p_session);
  perform 1 from public.demo_sessions where id = d.id for update;
  select * into d from public.demo_sessions where id = d.id;
  if d.status in ('expired', 'deleted') then return jsonb_build_object('status', d.status, 'already', true); end if;
  update public.demo_sessions set status = 'expired', ended_at = now() where id = d.id;
  update public.demo_seats set state = 'expired' where session_id = d.id and state in ('available', 'claimed', 'active');
  get diagnostics n = row_count;
  delete from public.demo_join_tokens where session_id = d.id;
  if d.workshop_course_id is not null then update public.courses set status = 'archived' where id = d.workshop_course_id; end if;
  insert into public.demo_events (session_id, actor_id, action, details) values (d.id, (select auth.uid()), 'ended', jsonb_build_object('seats_expired', n));
  return jsonb_build_object('status', 'expired', 'seats_expired', n);
end $$;

notify pgrst, 'reload schema';
