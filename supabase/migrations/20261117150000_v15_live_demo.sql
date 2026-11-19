-- V15 Live Demo (Option B: pre-provisioned seat pool + one-time claim). See docs/LIVE_DEMO_OPTION_B_SECURITY_DESIGN.md. Additive.
--   * 5 tables (no client grants), 10 public RPCs, private helpers.
--   * Credentials are DERIVED (HMAC-SHA256 of session:seat:generation keyed by a per-session Vault secret); no per-seat password is stored anywhere.
--   * Exactly TWO functions are granted to `anon` (demo_claim_seat, demo_join_status) plus USAGE on schema public (anon has none today).
--   * Expiry is SERVER-ENFORCED: private.demo_gate() is called by wrappers around every student-reachable RPC, and restrictive SELECT policies cover
--     the tables/Storage buckets students read directly. postgres has BYPASSRLS, so RLS alone could not stop the existing SECURITY DEFINER RPCs.
-- Errors: PT401 unauthenticated, PT403 not allowed / session ended, PT404 not yours.

create table public.demo_sessions (
  id uuid primary key default gen_random_uuid(),
  label text not null check (char_length(btrim(label)) between 1 and 80),
  presenter_id uuid not null references public.profiles (id) on delete cascade,
  workshop_course_id uuid unique references public.courses (id) on delete set null,
  status text not null default 'provisioning' check (status in ('provisioning', 'open', 'paused', 'closed', 'expired', 'deleted')),
  seats integer not null check (seats between 1 and 100),
  capacity integer not null,
  vault_secret_id uuid not null,
  joins_open_at timestamptz not null,
  joins_close_at timestamptz not null,
  expires_at timestamptz not null,
  protected_user_ids uuid[] not null,
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  check (capacity between 1 and seats),
  check (joins_open_at < joins_close_at and joins_close_at <= expires_at)
);

create table public.demo_seats (
  session_id uuid not null references public.demo_sessions (id) on delete cascade,
  seat_no integer not null check (seat_no between 1 and 100),
  is_reserve boolean not null default false,
  user_id uuid unique references auth.users (id) on delete set null,
  email text unique,
  state text not null default 'provisioning' check (state in ('provisioning', 'available', 'claimed', 'active', 'expired', 'disabled')),
  generation integer not null default 1 check (generation >= 1),
  nonce_hash bytea,
  claimed_at timestamptz,
  reserve_expires_at timestamptz,
  activated_at timestamptz,
  display_name text,
  disabled_reason text,
  client_ip_hash bytea,
  retry_window timestamptz,
  retries integer not null default 0,
  primary key (session_id, seat_no),
  check (state not in ('available', 'claimed', 'active') or (user_id is not null and email is not null)),
  check (state <> 'disabled' or disabled_reason is not null)
);
create unique index demo_seats_nonce_uq on public.demo_seats (session_id, nonce_hash) where nonce_hash is not null;
create index demo_seats_state_idx on public.demo_seats (session_id, state, is_reserve, seat_no);

create table public.demo_join_tokens (
  token_hash bytea primary key,
  session_id uuid not null references public.demo_sessions (id) on delete cascade,
  expires_at timestamptz not null
);
create index demo_join_tokens_session_idx on public.demo_join_tokens (session_id, expires_at);

-- Counters only (one row per session per minute): a flood of attempts cannot bloat storage. The all-zero session id collects unknown-token attempts.
create table public.demo_claim_stats (
  session_id uuid not null,
  minute timestamptz not null,
  claims integer not null default 0,
  refused integer not null default 0,
  primary key (session_id, minute)
);

create table public.demo_events (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.demo_sessions (id) on delete cascade,
  actor_id uuid,
  action text not null,
  details jsonb not null default '{}',
  at timestamptz not null default now()
);
create index demo_events_session_idx on public.demo_events (session_id, at);

alter table public.demo_sessions enable row level security;
alter table public.demo_seats enable row level security;
alter table public.demo_join_tokens enable row level security;
alter table public.demo_claim_stats enable row level security;
alter table public.demo_events enable row level security;
-- No policies and no grants: only the SECURITY DEFINER functions below can touch these tables.

-- Seat lifecycle is monotonic; protected/immutable fields are write-once ---------------------------------------------------
create function private.demo_seat_guard() returns trigger language plpgsql set search_path = '' as $$
begin
  if old.state = new.state then
    if old.user_id is not null and new.user_id is distinct from old.user_id then raise exception 'seat user is immutable' using errcode = 'PT409'; end if;
    return new;
  end if;
  if not ((old.state = 'provisioning' and new.state in ('available', 'disabled', 'expired'))
       or (old.state = 'available' and new.state in ('claimed', 'disabled', 'expired'))
       or (old.state = 'claimed' and new.state in ('active', 'disabled', 'expired'))
       or (old.state = 'active' and new.state in ('disabled', 'expired'))
       or (old.state = 'disabled' and new.state = 'available' and new.generation > old.generation and new.nonce_hash is null)) then
    raise exception 'illegal seat transition % -> %', old.state, new.state using errcode = 'PT409';
  end if;
  return new;
end $$;
create trigger demo_seat_guard before update on public.demo_seats for each row execute function private.demo_seat_guard();

create function private.demo_session_guard() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.protected_user_ids is distinct from old.protected_user_ids or new.vault_secret_id is distinct from old.vault_secret_id
     or new.presenter_id is distinct from old.presenter_id then
    raise exception 'protected session fields are immutable' using errcode = 'PT409'; end if;
  return new;
end $$;
create trigger demo_session_guard before update on public.demo_sessions for each row execute function private.demo_session_guard();

-- Key handling and derivation (private schema; NOT granted to any API role) -------------------------------------------------
create function private.demo_derive(p_session uuid, p_seat_no integer, p_generation integer) returns text
language plpgsql stable security definer set search_path = '' as $$
declare v_key text;
begin
  select v.decrypted_secret into v_key
    from public.demo_sessions d join vault.decrypted_secrets v on v.id = d.vault_secret_id where d.id = p_session;
  if v_key is null then raise exception 'session key unavailable' using errcode = 'PT404'; end if;
  return 'Dm1-' || translate(encode(extensions.hmac(p_session::text || ':' || p_seat_no::text || ':' || p_generation::text, v_key, 'sha256'), 'base64'), '+/=', '-_');
end $$;

-- Operator verification without plaintext: the SHA-256 of a seat's derived password (compare with a locally derived one).
create function private.demo_seat_password_sha256(p_session uuid, p_seat_no integer) returns text
language sql stable security definer set search_path = '' as $$
  select encode(extensions.digest(private.demo_derive(s.session_id, s.seat_no, s.generation), 'sha256'), 'hex')
    from public.demo_seats s where s.session_id = p_session and s.seat_no = p_seat_no
$$;

create function private.demo_user_ok() returns boolean
language sql stable security definer set search_path = '' as $$
  select not exists (select 1 from public.demo_seats s where s.user_id = (select auth.uid()))
      or exists (select 1 from public.demo_seats s join public.demo_sessions d on d.id = s.session_id
                  where s.user_id = (select auth.uid()) and s.state in ('claimed', 'active')
                    and d.status in ('open', 'paused', 'closed') and now() < d.expires_at)
$$;

create function private.demo_gate() returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.demo_user_ok() then raise exception 'This demo session has ended' using errcode = 'PT403'; end if;
end $$;

-- Operator-only (management SQL): create a session, its Vault key (generated INSIDE the database), and the seat rows.
create function private.demo_create_session(p_label text, p_presenter uuid, p_audience integer, p_reserve integer, p_join_minutes integer, p_lifetime_minutes integer)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid := gen_random_uuid(); v_secret uuid; i integer;
begin
  if not exists (select 1 from public.profiles where id = p_presenter and role = 'teacher') then raise exception 'presenter must be a teacher' using errcode = 'PT403'; end if;
  select vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'demo-key-' || v_id, 'live demo session key') into v_secret;
  insert into public.demo_sessions (id, label, presenter_id, seats, capacity, vault_secret_id, joins_open_at, joins_close_at, expires_at, protected_user_ids)
  values (v_id, p_label, p_presenter, p_audience + p_reserve, p_audience, v_secret, now(), now() + make_interval(mins => p_join_minutes),
          now() + make_interval(mins => p_lifetime_minutes), (select coalesce(array_agg(u.id), '{}') from auth.users u));
  for i in 1 .. p_audience + p_reserve loop
    insert into public.demo_seats (session_id, seat_no, is_reserve) values (v_id, i, i > p_audience);
  end loop;
  insert into public.demo_events (session_id, action, details) values (v_id, 'created', jsonb_build_object('audience', p_audience, 'reserve', p_reserve));
  return v_id;
end $$;

create function private.demo_attach_user(p_session uuid, p_seat_no integer, p_user uuid, p_email text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.demo_seats set user_id = p_user, email = p_email where session_id = p_session and seat_no = p_seat_no and user_id is null;
  if not found then raise exception 'seat already attached or missing' using errcode = 'PT409'; end if;
end $$;

-- Only after a successful canary sign-in (operator): PROVISIONING -> AVAILABLE
create function private.demo_mark_available(p_session uuid, p_seat_no integer) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.demo_seats set state = 'available' where session_id = p_session and seat_no = p_seat_no and state = 'provisioning' and user_id is not null;
  if not found then raise exception 'seat is not in provisioning with a user' using errcode = 'PT409'; end if;
end $$;

create function private.demo_open_session(p_session uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.demo_sessions set status = 'open', joins_open_at = now(), joins_close_at = now() + (joins_close_at - joins_open_at),
         expires_at = now() + (expires_at - created_at) where id = p_session and status = 'provisioning';
  if not found then raise exception 'session is not in provisioning' using errcode = 'PT409'; end if;
end $$;

-- Operator: server-side cleanup plan (dry run). Pure read; the operator tool executes the deletions through the Auth Admin API.
create function private.demo_cleanup_plan(p_session uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare d public.demo_sessions; v_users uuid[]; v_viol jsonb := '[]'; v_course uuid;
begin
  select * into d from public.demo_sessions where id = p_session;
  if not found then raise exception 'session not found' using errcode = 'PT404'; end if;
  select coalesce(array_agg(user_id), '{}') into v_users from public.demo_seats where session_id = p_session and user_id is not null;
  v_course := d.workshop_course_id;
  if exists (select 1 from unnest(v_users) u where u = any (d.protected_user_ids)) then v_viol := v_viol || '"a seat user is in the protected snapshot"'; end if;
  if exists (select 1 from public.profiles p where p.id = any (v_users) and p.role <> 'student') then v_viol := v_viol || '"a seat user is not a student"'; end if;
  if exists (select 1 from public.courses c where c.owner_id = any (v_users)) then v_viol := v_viol || '"a seat user owns a course"'; end if;
  if exists (select 1 from public.course_members m where m.student_id = any (v_users) and m.course_id is distinct from v_course) then v_viol := v_viol || '"a seat user is a member of another course"'; end if;
  if v_course is not null and not exists (select 1 from public.courses c where c.id = v_course and c.owner_id = d.presenter_id) then v_viol := v_viol || '"the workshop is not owned by the presenter"'; end if;
  if v_course is not null and exists (select 1 from public.course_members m where m.course_id = v_course and m.student_id <> all (v_users)) then v_viol := v_viol || '"the workshop has a member that is not a seat user"'; end if;
  return jsonb_build_object('session_id', p_session, 'label', d.label, 'status', d.status, 'workshop_course_id', v_course, 'seat_user_ids', to_jsonb(v_users),
    'violations', v_viol, 'ok', jsonb_array_length(v_viol) = 0,
    'counts', jsonb_build_object('seat_users', coalesce(array_length(v_users, 1), 0),
      'memberships', (select count(*) from public.course_members where course_id = v_course),
      'assignments', (select count(*) from public.assignments where course_id = v_course),
      'submissions', (select count(*) from public.submissions s where s.student_id = any (v_users)),
      'attendance_sessions', (select count(*) from public.attendance_sessions where course_id = v_course),
      'attendance_records', (select count(*) from public.attendance_records r where r.student_id = any (v_users)),
      'upload_rows', (select count(*) from public.submission_uploads u where u.student_id = any (v_users))));
end $$;

create function private.demo_destroy_key(p_session uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v uuid;
begin
  select vault_secret_id into v from public.demo_sessions where id = p_session;
  if v is not null then
    perform vault.update_secret(v, encode(extensions.gen_random_bytes(32), 'hex'));   -- overwrite first (cryptographic erase)
    delete from vault.secrets where id = v;
  end if;
end $$;

-- Public RPCs ---------------------------------------------------------------------------------------------------------------
create function private.demo_group(p_token text) returns text language sql immutable as $$ select substr(p_token, 1, 4) || '-' || substr(p_token, 5, 4) || '-' || substr(p_token, 9, 4) $$;

create function private.demo_count(p_session uuid, p_ok boolean) returns void
language sql security definer set search_path = '' as $$
  insert into public.demo_claim_stats (session_id, minute, claims, refused) values (p_session, date_trunc('minute', now()), case when p_ok then 1 else 0 end, case when p_ok then 0 else 1 end)
  on conflict (session_id, minute) do update set claims = public.demo_claim_stats.claims + excluded.claims, refused = public.demo_claim_stats.refused + excluded.refused
$$;

create function public.demo_join_status(p_join_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_tok text := upper(regexp_replace(coalesce(p_join_token, ''), '[^A-Za-z0-9]', '', 'g')); d public.demo_sessions;
begin
  if v_tok !~ '^[A-Z2-9]{12}$' then return jsonb_build_object('status', 'invalid'); end if;
  select d2.* into d from public.demo_join_tokens t join public.demo_sessions d2 on d2.id = t.session_id
   where t.token_hash = extensions.digest(v_tok, 'sha256') and t.expires_at > now();
  if not found then return jsonb_build_object('status', 'invalid'); end if;
  if d.status <> 'open' or now() >= d.joins_close_at or now() >= d.expires_at then return jsonb_build_object('status', 'closed'); end if;
  return jsonb_build_object('status', 'open', 'closes_at', d.joins_close_at);
end $$;

create function public.demo_claim_seat(p_join_token text, p_name text, p_client_nonce text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_tok text := upper(regexp_replace(coalesce(p_join_token, ''), '[^A-Za-z0-9]', '', 'g'));
  v_name text := btrim(coalesce(p_name, ''));
  d public.demo_sessions; s public.demo_seats; n integer; v_nonce bytea; v_minute timestamptz := date_trunc('minute', now()); v_ip bytea;
  zero constant uuid := '00000000-0000-0000-0000-000000000000';
begin
  if (select auth.uid()) is not null then return jsonb_build_object('ok', false, 'reason', 'already_signed_in'); end if;
  if v_tok !~ '^[A-Z2-9]{12}$' then perform private.demo_count(zero, false); return jsonb_build_object('ok', false, 'reason', 'invalid'); end if;
  if p_client_nonce is null or p_client_nonce !~ '^[A-Za-z0-9_-]{22,64}$' then return jsonb_build_object('ok', false, 'reason', 'bad_nonce'); end if;
  if char_length(v_name) not between 1 and 40 or v_name ~ '[[:cntrl:]<>]' then return jsonb_build_object('ok', false, 'reason', 'bad_name'); end if;
  select d2.* into d from public.demo_join_tokens t join public.demo_sessions d2 on d2.id = t.session_id
   where t.token_hash = extensions.digest(v_tok, 'sha256') and t.expires_at > now();
  if not found then perform private.demo_count(zero, false); return jsonb_build_object('ok', false, 'reason', 'invalid'); end if;
  v_nonce := extensions.digest(p_client_nonce, 'sha256');
  begin v_ip := extensions.digest(coalesce((current_setting('request.headers', true)::jsonb) ->> 'cf-connecting-ip', 'unknown'), 'sha256');
  exception when others then v_ip := null; end;   -- forensic signal only; never used for a decision

  update public.demo_seats set state = 'disabled', disabled_reason = 'orphaned'
   where session_id = d.id and state = 'claimed' and reserve_expires_at < now();   -- credentials may have been seen: never reissued

  -- idempotent retry by the SAME browser (nonce); a different nonce can never receive this seat
  select * into s from public.demo_seats where session_id = d.id and nonce_hash = v_nonce for update;
  if found then
    if s.state = 'claimed' and s.reserve_expires_at > now() and d.status in ('open', 'paused', 'closed') and now() < d.expires_at then
      if s.retry_window = v_minute and s.retries >= 5 then return jsonb_build_object('ok', false, 'reason', 'busy'); end if;
      update public.demo_seats set retry_window = v_minute, retries = case when retry_window = v_minute then retries + 1 else 1 end
       where session_id = s.session_id and seat_no = s.seat_no;
      return jsonb_build_object('ok', true, 'retry', true, 'email', s.email, 'password', private.demo_derive(d.id, s.seat_no, s.generation),
                                'seat_no', s.seat_no, 'workshop_course_id', d.workshop_course_id);
    elsif s.state = 'active' then
      return jsonb_build_object('ok', true, 'already_active', true);   -- credentials are NEVER returned again
    end if;
    return jsonb_build_object('ok', false, 'reason', 'closed');
  end if;

  -- new claim: serialised per session so the capacity check cannot race
  perform 1 from public.demo_sessions where id = d.id for update;
  select * into d from public.demo_sessions where id = d.id;
  if d.status <> 'open' or now() < d.joins_open_at or now() >= d.joins_close_at or now() >= d.expires_at then
    perform private.demo_count(d.id, false); return jsonb_build_object('ok', false, 'reason', 'closed'); end if;
  select count(*) into n from public.demo_seats where session_id = d.id and state in ('claimed', 'active');
  if n >= d.capacity then perform private.demo_count(d.id, false); return jsonb_build_object('ok', false, 'reason', 'full'); end if;
  select * into s from public.demo_seats where session_id = d.id and state = 'available' order by is_reserve, seat_no limit 1 for update;
  if not found then perform private.demo_count(d.id, false); return jsonb_build_object('ok', false, 'reason', 'full'); end if;
  update public.demo_seats set state = 'claimed', nonce_hash = v_nonce, claimed_at = now(), reserve_expires_at = now() + interval '10 minutes',
         display_name = v_name, client_ip_hash = v_ip, retry_window = v_minute, retries = 1
   where session_id = s.session_id and seat_no = s.seat_no;
  update public.profiles set full_name = v_name where id = s.user_id;   -- only the seat just locked
  perform private.demo_count(d.id, true);
  insert into public.demo_events (session_id, action, details) values (d.id, 'claimed', jsonb_build_object('seat_no', s.seat_no));
  return jsonb_build_object('ok', true, 'email', s.email, 'password', private.demo_derive(d.id, s.seat_no, s.generation),
                            'seat_no', s.seat_no, 'workshop_course_id', d.workshop_course_id);
end $$;

create function public.demo_activate_seat() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := (select auth.uid()); s public.demo_seats; d public.demo_sessions;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select * into s from public.demo_seats where user_id = v_uid for update;
  if not found then return jsonb_build_object('ok', false, 'reason', 'not_a_seat'); end if;
  select * into d from public.demo_sessions where id = s.session_id;
  if s.state = 'active' and d.status in ('open', 'paused', 'closed') and now() < d.expires_at then
    return jsonb_build_object('ok', true, 'workshop_course_id', d.workshop_course_id, 'expires_at', d.expires_at); end if;
  if s.state = 'claimed' and d.status in ('open', 'paused', 'closed') and now() < d.expires_at then
    update public.demo_seats set state = 'active', activated_at = now() where session_id = s.session_id and seat_no = s.seat_no;
    insert into public.demo_events (session_id, actor_id, action, details) values (d.id, v_uid, 'activated', jsonb_build_object('seat_no', s.seat_no));
    return jsonb_build_object('ok', true, 'workshop_course_id', d.workshop_course_id, 'expires_at', d.expires_at);
  end if;
  return jsonb_build_object('ok', false, 'reason', 'ended');
end $$;

-- Presenter controls (owner of the session, role teacher) ---------------------------------------------------------------------
create function private.demo_presenter_session(p_session uuid) returns public.demo_sessions
language plpgsql stable security definer set search_path = '' as $$
declare d public.demo_sessions; v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select * into d from public.demo_sessions where id = p_session and presenter_id = v_uid
     and exists (select 1 from public.profiles p where p.id = v_uid and p.role = 'teacher');
  if not found then raise exception 'Session not found' using errcode = 'PT404'; end if;
  return d;
end $$;

create function public.demo_my_sessions() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', d.id, 'label', d.label, 'status', d.status, 'workshop_course_id', d.workshop_course_id,
            'joins_close_at', d.joins_close_at, 'expires_at', d.expires_at, 'capacity', d.capacity, 'seats', d.seats) order by d.created_at desc), '[]')
            from public.demo_sessions d where d.presenter_id = v_uid and d.status in ('open', 'paused', 'closed', 'expired')
             and exists (select 1 from public.profiles p where p.id = v_uid and p.role = 'teacher'));
end $$;

create function public.demo_join_token(p_session uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions; v_tok text; v_exp timestamptz := now() + interval '150 seconds'; v_alpha constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; b bytea := extensions.gen_random_bytes(12); i integer;
begin
  d := private.demo_presenter_session(p_session);
  if d.status not in ('open', 'paused') or now() >= d.joins_close_at or now() >= d.expires_at then raise exception 'Joining is closed' using errcode = 'PT409'; end if;
  delete from public.demo_join_tokens where session_id = d.id and expires_at < now() - interval '10 minutes';
  if (select count(*) from public.demo_join_tokens where session_id = d.id and expires_at > now()) >= 20 then raise exception 'Too many live codes' using errcode = 'PT429'; end if;
  v_tok := '';
  for i in 0 .. 11 loop v_tok := v_tok || substr(v_alpha, 1 + (get_byte(b, i) % 32), 1); end loop;
  insert into public.demo_join_tokens (token_hash, session_id, expires_at) values (extensions.digest(v_tok, 'sha256'), d.id, v_exp);
  return jsonb_build_object('token', v_tok, 'display', private.demo_group(v_tok), 'expires_at', v_exp, 'refresh_seconds', 60, 'joins_close_at', d.joins_close_at, 'status', d.status);
end $$;

create function public.demo_session_overview(p_session uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions;
begin
  d := private.demo_presenter_session(p_session);
  update public.demo_seats set state = 'disabled', disabled_reason = 'orphaned' where session_id = d.id and state = 'claimed' and reserve_expires_at < now();
  return jsonb_build_object('id', d.id, 'label', d.label, 'status', d.status, 'capacity', d.capacity, 'seats', d.seats, 'workshop_course_id', d.workshop_course_id,
    'joins_close_at', d.joins_close_at, 'expires_at', d.expires_at, 'server_now', now(),
    'counts', (select coalesce(jsonb_object_agg(state, c), '{}') from (select state, count(*) c from public.demo_seats where session_id = d.id group by state) x),
    'recent', (select jsonb_build_object('claims', coalesce(sum(claims), 0), 'refused', coalesce(sum(refused), 0)) from public.demo_claim_stats where session_id = d.id and minute > now() - interval '10 minutes'),
    'seats_list', (select coalesce(jsonb_agg(jsonb_build_object('seat_no', seat_no, 'state', state, 'name', display_name, 'reserve', is_reserve) order by seat_no), '[]') from public.demo_seats where session_id = d.id));
end $$;

create function public.demo_set_joins(p_session uuid, p_mode text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions;
begin
  d := private.demo_presenter_session(p_session);
  if p_mode not in ('open', 'paused', 'closed') then raise exception 'Mode must be open, paused or closed' using errcode = 'PT400'; end if;
  if d.status in ('expired', 'deleted', 'provisioning') then raise exception 'This session cannot change joins' using errcode = 'PT409'; end if;
  if p_mode = 'open' and d.status = 'closed' then raise exception 'Closed joins cannot be reopened' using errcode = 'PT409'; end if;
  update public.demo_sessions set status = p_mode where id = d.id;
  insert into public.demo_events (session_id, actor_id, action, details) values (d.id, (select auth.uid()), 'joins_' || p_mode, '{}');
  return jsonb_build_object('status', p_mode);
end $$;

-- Level 2 of the design: END the session. Workshop data access stops immediately for every still-valid Auth session.
create function public.demo_end_session(p_session uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions; n integer;
begin
  d := private.demo_presenter_session(p_session);
  if d.status in ('expired', 'deleted') then return jsonb_build_object('status', d.status, 'already', true); end if;
  update public.demo_sessions set status = 'expired', ended_at = now() where id = d.id;
  update public.demo_seats set state = 'expired' where session_id = d.id and state in ('available', 'claimed', 'active');
  get diagnostics n = row_count;
  delete from public.demo_join_tokens where session_id = d.id;
  if d.workshop_course_id is not null then update public.courses set status = 'archived' where id = d.workshop_course_id; end if;
  insert into public.demo_events (session_id, actor_id, action, details) values (d.id, (select auth.uid()), 'ended', jsonb_build_object('seats_expired', n));
  return jsonb_build_object('status', 'expired', 'seats_expired', n);
end $$;

create function public.demo_disable_seat(p_session uuid, p_seat_no integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions;
begin
  d := private.demo_presenter_session(p_session);
  update public.demo_seats set state = 'disabled', disabled_reason = 'presenter' where session_id = d.id and seat_no = p_seat_no and state in ('available', 'claimed', 'active');
  if not found then raise exception 'Seat not found or already out of circulation' using errcode = 'PT404'; end if;
  insert into public.demo_events (session_id, actor_id, action, details) values (d.id, (select auth.uid()), 'seat_disabled', jsonb_build_object('seat_no', p_seat_no));
  return jsonb_build_object('seat_no', p_seat_no, 'state', 'disabled');
end $$;

create function public.demo_set_capacity(p_session uuid, p_capacity integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare d public.demo_sessions;
begin
  d := private.demo_presenter_session(p_session);
  if p_capacity is null or p_capacity < 1 or p_capacity > d.seats then raise exception 'Capacity must be between 1 and the pool size' using errcode = 'PT400'; end if;
  update public.demo_sessions set capacity = p_capacity where id = d.id;
  return jsonb_build_object('capacity', p_capacity);
end $$;

-- Grants: the ONLY anonymous surface is the two functions below ------------------------------------------------------------------
do $$
declare f text;
begin
  foreach f in array array[
    'public.demo_join_status(text)', 'public.demo_claim_seat(text, text, text)', 'public.demo_activate_seat()', 'public.demo_my_sessions()',
    'public.demo_join_token(uuid)', 'public.demo_session_overview(uuid)', 'public.demo_set_joins(uuid, text)', 'public.demo_end_session(uuid)',
    'public.demo_disable_seat(uuid, integer)', 'public.demo_set_capacity(uuid, integer)',
    'private.demo_user_ok()', 'private.demo_gate()', 'private.demo_derive(uuid, integer, integer)', 'private.demo_seat_password_sha256(uuid, integer)',
    'private.demo_create_session(text, uuid, integer, integer, integer, integer)', 'private.demo_attach_user(uuid, integer, uuid, text)',
    'private.demo_mark_available(uuid, integer)', 'private.demo_open_session(uuid)', 'private.demo_cleanup_plan(uuid)', 'private.demo_destroy_key(uuid)',
    'private.demo_presenter_session(uuid)', 'private.demo_count(uuid, boolean)', 'private.demo_group(text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
  end loop;
  foreach f in array array['public.demo_activate_seat()', 'public.demo_my_sessions()', 'public.demo_join_token(uuid)', 'public.demo_session_overview(uuid)',
    'public.demo_set_joins(uuid, text)', 'public.demo_end_session(uuid)', 'public.demo_disable_seat(uuid, integer)', 'public.demo_set_capacity(uuid, integer)'] loop
    execute format('grant execute on function %s to authenticated', f);
  end loop;
  grant execute on function public.demo_claim_seat(text, text, text) to anon, authenticated;
  grant execute on function public.demo_join_status(text) to anon, authenticated;
  grant execute on function private.demo_user_ok() to authenticated;   -- evaluated inside the restrictive policies below
end $$;
grant usage on schema public to anon;   -- required for the two functions; anon still has NO table or other function access

-- Server-enforced expiry --------------------------------------------------------------------------------------------------------
-- (1) wrap every student-reachable RPC: the original keeps its body under the name <fn>__core (not executable by API roles)
do $$
declare f record; v_call text;
begin
  for f in select p.oid, p.proname, pg_get_function_arguments(p.oid) as args, pg_get_function_identity_arguments(p.oid) as ident,
                  pg_get_function_result(p.oid) as ret, p.provolatile as vol, p.proargnames as names
             from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname = any (array[
               'complete_activity', 'retract_activity_completion', 'get_attendance_summary', 'get_my_activities', 'get_my_progress', 'get_my_tasks',
               'get_student_dashboard', 'get_student_progress', 'get_activity_streaks', 'join_course_by_code', 'prepare_submission_upload',
               'submit_assignment', 'scan_attendance', 'set_my_avatar', 'remove_my_avatar', 'get_my_staff_context']) loop
    execute format('alter function public.%I(%s) rename to %I', f.proname, f.ident, f.proname || '__core');
    execute format('revoke all on function public.%I(%s) from public, anon, authenticated, service_role', f.proname || '__core', f.ident);
    select string_agg(format('%1$I => %1$I', n), ', ') into v_call from unnest(f.names) n;
    execute format('create function public.%I(%s) returns %s language plpgsql %s security definer set search_path = '''' as $w$ begin perform private.demo_gate(); return public.%I(%s); end $w$',
                   f.proname, f.args, f.ret, case f.vol when 's' then 'stable' when 'i' then 'immutable' else 'volatile' end, f.proname || '__core', coalesce(v_call, ''));
    execute format('revoke all on function public.%I(%s) from public, anon, authenticated, service_role', f.proname, f.ident);
    execute format('grant execute on function public.%I(%s) to authenticated', f.proname, f.ident);
  end loop;
end $$;

-- (2) a seat user may never join another course by code (they are pre-enrolled in their Workshop only)
create or replace function private.demo_no_join() returns void language plpgsql stable security definer set search_path = '' as $$
begin
  if exists (select 1 from public.demo_seats s where s.user_id = (select auth.uid())) then raise exception 'Demo accounts cannot join other courses' using errcode = 'PT403'; end if;
end $$;
revoke all on function private.demo_no_join() from public, anon, authenticated, service_role;
create or replace function public.join_course_by_code(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  perform private.demo_no_join();
  perform private.demo_gate();
  return public.join_course_by_code__core(p_code => p_code);
end $$;
revoke all on function public.join_course_by_code(text) from public, anon, authenticated, service_role;
grant execute on function public.join_course_by_code(text) to authenticated;

-- (3) restrictive SELECT policies: tables students read directly, and the Storage buckets with course/submission files
do $$
declare t text;
begin
  foreach t in array array['courses', 'course_members', 'lessons', 'lesson_resources', 'assignments', 'submissions', 'submission_uploads', 'submission_events',
                           'attendance_sessions', 'attendance_records', 'activities', 'activity_completions', 'activity_schedules'] loop
    execute format('create policy demo_expiry on public.%I as restrictive for select to authenticated using ((select private.demo_user_ok()))', t);
  end loop;
end $$;
create policy demo_expiry_files on storage.objects as restrictive for select to authenticated
  using (bucket_id not in ('submission-files', 'course-files') or (select private.demo_user_ok()));

notify pgrst, 'reload schema';
