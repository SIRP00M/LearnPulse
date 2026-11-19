-- LearnPulse Option E / V0 foundation: ONE atomic migration = PART 1 legacy teardown + PART 2 baseline.
-- Part 1 is a guarded no-op on a fresh database and replaces the legacy schema on the old DEV project;
-- it refuses to run if any public table holds rows or the LearnPulse buckets hold objects, so a
-- populated V0 database can never be wiped by re-running it. Never SQL-delete managed Auth/Storage
-- rows: the legacy `avatars` bucket is removed through the Storage API beforehand.

-- ===== PART 1: legacy teardown =====
-- Guards: aborts unless every public table is empty and the LearnPulse buckets hold no objects.
-- Auth users must already be gone (profiles cascade from auth.users). See docs/V0_RECONCILIATION.md.
do $$
declare
  r record;
  n bigint;
begin
  for r in select c.relname from pg_class c join pg_namespace s on s.oid = c.relnamespace
            where s.nspname = 'public' and c.relkind = 'r' loop
    execute format('select count(*) from public.%I', r.relname) into n;
    if n > 0 then raise exception 'Teardown refused: public.% holds % row(s)', r.relname, n; end if;
  end loop;
  if exists (select 1 from storage.objects where bucket_id in ('avatars', 'course-files', 'submission-files')) then
    raise exception 'Teardown refused: LearnPulse buckets still hold objects';
  end if;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_auth_user_confirmed on auth.users;

drop policy if exists "Course teachers can upload course storage" on storage.objects;
drop policy if exists "Course teachers can update course storage" on storage.objects;
drop policy if exists "Course teachers can delete course storage" on storage.objects;
drop policy if exists "Users can upload own avatar" on storage.objects;
drop policy if exists "Users can update own avatar" on storage.objects;
drop policy if exists "Users can delete own avatar" on storage.objects;
drop policy if exists "submission_file_insert" on storage.objects;
drop policy if exists "submission_file_read" on storage.objects;
drop policy if exists "Course members can read course storage" on storage.objects;

-- Removes every legacy table, type, function, policy, grant and schema-level default ACL at once.
drop schema public cascade;
create schema public;
-- Match a stock Supabase project (owner pg_database_owner, usage for postgres).
alter schema public owner to pg_database_owner;
grant usage on schema public to postgres;

-- ===== PART 2: V0 baseline =====

-- LearnPulse Option E / V0 foundation baseline.
-- Replaces the legacy seven-migration chain; it assumes an empty `public` schema.
-- Conventions:
--   * No client privilege exists unless it is granted explicitly below.
--   * Clients never write tables directly; writes go through SECURITY DEFINER RPCs.
--   * Every RPC: owner postgres, search_path '', auth.uid() checked, EXECUTE only for
--     `authenticated`, business errors use SQLSTATE PT4xx (PostgREST maps them to HTTP 4xx).
--   * Roles come only from server state (teacher_invitations), never from signup metadata.

-- 0. Privilege posture (defends against restore/default-privilege drift) -----------------
revoke all on schema public from public, anon, authenticated, service_role;
grant usage on schema public to authenticated, service_role;

alter default privileges for role postgres in schema public revoke all on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public revoke all on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public revoke all on functions from anon, authenticated, service_role;
alter default privileges for role postgres revoke execute on functions from public;

-- 1. Types and tables -----------------------------------------------------------------
create type public.app_role as enum ('student', 'teacher');
create type public.course_status as enum ('active', 'archived');
create type public.member_status as enum ('active', 'removed');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null default 'student',
  full_name text not null default '' check (char_length(full_name) <= 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Server-side allow-list: a confirmed email with an open invitation becomes a Teacher.
create table public.teacher_invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null check (email = lower(btrim(email)) and email ~ '^[^@\s]+@[^@\s]+$'),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '14 days',
  consumed_at timestamptz,
  consumed_by uuid references public.profiles (id) on delete set null
);
create unique index teacher_invitations_one_open_per_email
  on public.teacher_invitations (email) where consumed_at is null;

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  description text not null default '' check (char_length(description) <= 2000),
  join_code text not null unique check (join_code ~ '^[A-HJ-NP-Z2-9]{8}$'),
  status public.course_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index courses_owner_id_idx on public.courses (owner_id);

create table public.course_members (
  course_id uuid not null references public.courses (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  status public.member_status not null default 'active',
  joined_at timestamptz not null default now(),
  removed_at timestamptz,
  primary key (course_id, student_id),
  check ((status = 'removed') = (removed_at is not null))
);
create index course_members_student_active_idx on public.course_members (student_id) where status = 'active';

-- Join-code brute-force throttle; written only by join_course_by_code.
create table public.course_join_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  attempted_at timestamptz not null default now()
);
create index course_join_attempts_user_time_idx on public.course_join_attempts (user_id, attempted_at desc);

-- 2. Internal trigger functions (never callable by clients) ---------------------------
create function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger courses_set_updated_at before update on public.courses
  for each row execute function public.set_updated_at();

create function public.enforce_course_owner_is_teacher() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.profiles p where p.id = new.owner_id and p.role = 'teacher') then
    raise exception 'Course owner must be a teacher' using errcode = 'PT403';
  end if;
  return new;
end $$;

create trigger courses_owner_is_teacher before insert or update of owner_id on public.courses
  for each row execute function public.enforce_course_owner_is_teacher();

create function public.enforce_member_is_student() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.profiles p where p.id = new.student_id and p.role = 'student') then
    raise exception 'Only students can be course members' using errcode = 'PT403';
  end if;
  return new;
end $$;

create trigger course_members_student_only before insert or update of student_id on public.course_members
  for each row execute function public.enforce_member_is_student();

-- Profile creation and server-controlled role assignment. Signup metadata supplies only
-- the display name; `role` in metadata is ignored.
create function public.sync_profile_from_auth() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_rows integer;
begin
  if tg_op = 'INSERT' then
    insert into public.profiles (id, full_name)
    values (new.id, left(btrim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), 120))
    on conflict (id) do nothing;
  end if;

  if new.email_confirmed_at is not null and new.email is not null then
    update public.teacher_invitations i
       set consumed_at = now(), consumed_by = new.id
     where i.email = lower(btrim(new.email)) and i.consumed_at is null and i.expires_at > now();
    get diagnostics v_rows = row_count;
    if v_rows > 0 then
      update public.profiles set role = 'teacher' where id = new.id;
    end if;
  end if;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.sync_profile_from_auth();
create trigger on_auth_user_confirmed after update of email_confirmed_at on auth.users
  for each row when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  execute function public.sync_profile_from_auth();

create function public.generate_join_code() returns text
language sql volatile security definer set search_path = '' as $$
  select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + (get_byte(b.bytes, g.i) % 32), 1), '')
  from (select extensions.gen_random_bytes(8) as bytes) b, generate_series(0, 7) as g(i)
$$;

-- 3. Authorization helpers used by RLS (security definer to avoid policy recursion) ----
create function public.is_course_owner(p_course_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.courses c
                  where c.id = p_course_id and c.owner_id = (select auth.uid()))
$$;

create function public.is_course_member(p_course_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.course_members m
                  where m.course_id = p_course_id and m.student_id = (select auth.uid()) and m.status = 'active')
$$;

create function public.can_view_profile(p_profile_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select p_profile_id = (select auth.uid())
      or exists (
        select 1
          from public.course_members m
          join public.courses c on c.id = m.course_id
         where m.status = 'active'
           and ((c.owner_id = (select auth.uid()) and m.student_id = p_profile_id)
             or (m.student_id = (select auth.uid()) and c.owner_id = p_profile_id)))
$$;

-- 4. RPCs -------------------------------------------------------------------------------
create function public.create_course(p_title text, p_description text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_course public.courses;
  v_try integer := 0;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'teacher') then
    raise exception 'Only teachers can create courses' using errcode = 'PT403';
  end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Title must be 1-120 characters' using errcode = 'PT400';
  end if;
  if char_length(coalesce(p_description, '')) > 2000 then
    raise exception 'Description is too long' using errcode = 'PT400';
  end if;

  loop
    begin
      insert into public.courses (owner_id, title, description, join_code)
      values (v_uid, btrim(p_title), coalesce(p_description, ''), public.generate_join_code())
      returning * into v_course;
      exit;
    exception when unique_violation then
      v_try := v_try + 1;
      if v_try >= 5 then raise exception 'Could not allocate a join code' using errcode = 'PT409'; end if;
    end;
  end loop;

  return jsonb_build_object('id', v_course.id, 'title', v_course.title, 'join_code', v_course.join_code);
end $$;

create function public.join_course_by_code(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_course public.courses;
  v_member public.course_members;
  v_code text := upper(btrim(coalesce(p_code, '')));
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'student') then
    raise exception 'Only students can join courses' using errcode = 'PT403';
  end if;
  if (select count(*) from public.course_join_attempts
       where user_id = v_uid and attempted_at > now() - interval '10 minutes') >= 10 then
    raise exception 'Too many join attempts; try again later' using errcode = 'PT429';
  end if;
  -- Logged before the lookup and answered without raising, so failed attempts persist.
  insert into public.course_join_attempts (user_id) values (v_uid);

  select * into v_course from public.courses where join_code = v_code and status = 'active';
  if not found then
    return jsonb_build_object('joined', false, 'reason', 'invalid_code');
  end if;

  select * into v_member from public.course_members where course_id = v_course.id and student_id = v_uid;
  if found and v_member.status = 'removed' then
    return jsonb_build_object('joined', false, 'reason', 'removed');
  end if;
  if not found then
    insert into public.course_members (course_id, student_id) values (v_course.id, v_uid);
  end if;
  return jsonb_build_object('joined', true, 'course_id', v_course.id, 'title', v_course.title);
end $$;

-- 5. Row level security ------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.teacher_invitations enable row level security;
alter table public.courses enable row level security;
alter table public.course_members enable row level security;
alter table public.course_join_attempts enable row level security;

create policy profiles_select on public.profiles for select to authenticated
  using (public.can_view_profile(id));
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy courses_select on public.courses for select to authenticated
  using (owner_id = (select auth.uid()) or public.is_course_member(id));
create policy course_members_select on public.course_members for select to authenticated
  using (student_id = (select auth.uid()) or public.is_course_owner(course_id));
-- teacher_invitations and course_join_attempts: RLS on, no policies, no client grants.

-- 6. Explicit grants ---------------------------------------------------------------------
grant select on public.profiles, public.courses, public.course_members to authenticated;
grant update (full_name) on public.profiles to authenticated;  -- role is not client-writable
grant select, insert, update, delete on public.teacher_invitations to service_role;

do $$
declare
  f text;
begin
  -- Trigger and internal functions: nobody can EXECUTE them directly.
  foreach f in array array[
    'public.set_updated_at()', 'public.enforce_course_owner_is_teacher()',
    'public.enforce_member_is_student()', 'public.sync_profile_from_auth()',
    'public.generate_join_code()'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
  end loop;
  -- Client-callable functions: authenticated only.
  foreach f in array array[
    'public.is_course_owner(uuid)', 'public.is_course_member(uuid)', 'public.can_view_profile(uuid)',
    'public.create_course(text, text)', 'public.join_course_by_code(text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- 7. Private Storage buckets (objects are denied until slice policies are added) --------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('course-files', 'course-files', false, 52428800,
   array['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
         'application/zip', 'image/png', 'image/jpeg', 'image/webp', 'text/plain']),
  ('submission-files', 'submission-files', false, 52428800,
   array['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
         'application/zip', 'image/png', 'image/jpeg', 'image/webp', 'text/plain'])
on conflict (id) do update
  set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

notify pgrst, 'reload schema';
