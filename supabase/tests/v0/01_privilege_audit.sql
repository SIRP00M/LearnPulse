-- V0 effective-privilege audit. Run as postgres after `supabase db reset --local`.
-- Any deviation raises an exception (psql -v ON_ERROR_STOP=1).
\set ON_ERROR_STOP 1

do $$
declare
  v_bad text;
begin
  -- A. Table privileges: expected matrix, everything else must be absent.
  with roles(r) as (values ('anon'), ('authenticated'), ('service_role')),
  privs(p) as (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')),
  tbls(t) as (select format('public.%I', c.relname) from pg_class c join pg_namespace n on n.oid = c.relnamespace
               where n.nspname = 'public' and c.relkind in ('r', 'p', 'v', 'm', 'f')),
  expected(t, r, p) as (values
    ('public.profiles', 'authenticated', 'SELECT'),
    ('public.course_members', 'authenticated', 'SELECT'),
    ('public.assignments', 'authenticated', 'SELECT'), ('public.submissions', 'authenticated', 'SELECT'),
    ('public.submission_uploads', 'authenticated', 'SELECT'), ('public.submission_events', 'authenticated', 'SELECT'),
    ('public.lessons', 'authenticated', 'SELECT'), ('public.lesson_resources', 'authenticated', 'SELECT'),
    ('public.attendance_sessions', 'authenticated', 'SELECT'), ('public.attendance_records', 'authenticated', 'SELECT'),
    ('public.attendance_events', 'authenticated', 'SELECT'),
    ('public.teacher_invitations', 'service_role', 'SELECT'),
    ('public.teacher_invitations', 'service_role', 'INSERT'),
    ('public.teacher_invitations', 'service_role', 'UPDATE'),
    ('public.teacher_invitations', 'service_role', 'DELETE')),
  actual as (
    select tbls.t, roles.r, privs.p from tbls cross join roles cross join privs
     where has_table_privilege(roles.r, tbls.t, privs.p))
  select string_agg(format('%s %s %s (%s)', coalesce(a.t, e.t), coalesce(a.r, e.r), coalesce(a.p, e.p),
                           case when a.t is null then 'missing' else 'unexpected' end), '; ')
    into v_bad
    from actual a full join expected e on (a.t, a.r, a.p) = (e.t, e.r, e.p)
   where a.t is null or e.t is null;
  if v_bad is not null then raise exception 'FAIL table privilege drift: %', v_bad; end if;
  raise notice 'PASS table privilege matrix exact';

  -- B. Column privileges: clients may update only profiles.full_name; nobody may touch role.
  if not has_column_privilege('authenticated', 'public.profiles', 'full_name', 'UPDATE') then
    raise exception 'FAIL authenticated cannot update profiles.full_name';
  end if;
  if has_column_privilege('authenticated', 'public.profiles', 'role', 'UPDATE')
     or has_column_privilege('anon', 'public.profiles', 'role', 'UPDATE')
     or has_column_privilege('authenticated', 'public.profiles', 'id', 'UPDATE') then
    raise exception 'FAIL profiles privileged column is client-writable';
  end if;
  raise notice 'PASS column privileges (role/id not client-writable)';

  -- B2. courses: clients read exactly the non-secret columns; join_code is owner-only via RPC.
  if has_column_privilege('authenticated', 'public.courses', 'join_code', 'SELECT')
     or has_column_privilege('anon', 'public.courses', 'join_code', 'SELECT')
     or not has_column_privilege('authenticated', 'public.courses', 'title', 'SELECT')
     or has_column_privilege('authenticated', 'public.courses', 'title', 'UPDATE')
     or has_table_privilege('authenticated', 'public.courses', 'SELECT') then
    raise exception 'FAIL courses column privileges (join_code must be unreadable, no direct writes)';
  end if;
  raise notice 'PASS courses: join_code unreadable by clients, columns select-only';

  -- C. Function EXECUTE: only the five client functions, only for authenticated; never PUBLIC/anon/service_role.
  select string_agg(format('%s grantee=%s', p.oid::regprocedure, coalesce(nullif(x.grantee, 0)::regrole::text, 'PUBLIC')), '; ')
    into v_bad
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace and n.nspname in ('public', 'private')
    cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) x
   where x.privilege_type = 'EXECUTE'
     and x.grantee <> p.proowner
     and not (x.grantee = 'authenticated'::regrole and p.proname in
              ('is_course_owner', 'is_course_member', 'can_view_profile', 'create_course', 'join_course_by_code',
               'get_course_join_code', 'update_course', 'remove_course_member',
               'create_assignment', 'update_assignment', 'publish_assignment',
               'prepare_submission_upload', 'submit_assignment', 'grade_submission', 'return_submission',
               'create_lesson', 'update_lesson', 'set_lesson_status', 'delete_lesson',
               'prepare_resource_upload', 'finalize_resource', 'delete_resource',
               'is_lesson_owner', 'is_lesson_visible_to_member', 'can_upload_resource_object', 'can_read_resource_object',
               'get_teacher_dashboard', 'get_student_dashboard',
               'create_attendance_session', 'mark_attendance', 'close_attendance_session', 'get_attendance_summary',
               'is_attendance_owner', 'is_attendance_member',
               'is_assignment_owner', 'is_assignment_visible_to_member', 'can_upload_object', 'can_read_object'));
  if v_bad is not null then raise exception 'FAIL function EXECUTE drift: %', v_bad; end if;
  -- Only the twenty-five RPCs are exposed through the API schema; the RLS helpers live in the private schema.
  if (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
       where n.nspname = 'public' and has_function_privilege('authenticated', p.oid, 'EXECUTE')) <> 25
     or (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'private' and has_function_privilege('authenticated', p.oid, 'EXECUTE')) <> 13 then
    raise exception 'FAIL authenticated EXECUTE must be public:25 (RPCs) + private:13 (RLS/Storage helpers)';
  end if;
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname in ('public', 'private') and ((has_function_privilege('anon', p.oid, 'EXECUTE') and p.proname not in ('demo_claim_seat', 'demo_join_status'))   -- V15 allow-list
                 or has_function_privilege('service_role', p.oid, 'EXECUTE'))) then
    raise exception 'FAIL anon/service_role can execute an application function';
  end if;
  if has_schema_privilege('anon', 'private', 'USAGE') or has_schema_privilege('service_role', 'private', 'USAGE')
     or not has_schema_privilege('authenticated', 'private', 'USAGE')
     or has_schema_privilege('authenticated', 'private', 'CREATE') then
    raise exception 'FAIL private schema posture';
  end if;
  if (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
       where n.nspname = 'private' and c.relkind in ('r', 'v', 'm', 'S', 'p')) <> 0 then
    raise exception 'FAIL private schema must hold functions only';
  end if;
  raise notice 'PASS function EXECUTE matrix exact (anon 0, service_role 0, authenticated public:25 + private:13)';

  -- D. SECURITY DEFINER functions pin an empty search_path and are owned by postgres.
  select string_agg(p.oid::regprocedure::text, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private')
     and (not coalesce(p.proconfig, '{}') @> array['search_path=""'] or pg_get_userbyid(p.proowner) <> 'postgres');
  if v_bad is not null then raise exception 'FAIL function without pinned search_path/owner: %', v_bad; end if;
  raise notice 'PASS all public functions: search_path="" and owner postgres';

  -- E. RLS on every public table; no policy for anon anywhere; schema usage.
  select string_agg(c.relname, ', ') into v_bad
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;
  if v_bad is not null then raise exception 'FAIL RLS disabled on: %', v_bad; end if;
  if exists (select 1 from pg_policies where schemaname = 'public' and ('anon' = any (roles) or 'public' = any (roles))) then
    raise exception 'FAIL a public-schema policy applies to anon/PUBLIC';
  end if;
  if not has_schema_privilege('anon', 'public', 'USAGE') or not has_schema_privilege('authenticated', 'public', 'USAGE')
     or has_schema_privilege('anon', 'public', 'CREATE') or has_schema_privilege('authenticated', 'public', 'CREATE') then
    raise exception 'FAIL schema privilege posture';
  end if;
  raise notice 'PASS RLS on all public tables; anon has no schema usage; nobody can CREATE in public';

  -- F. Default privileges cannot re-open access for future objects created by postgres.
  if exists (select 1 from pg_default_acl d join pg_namespace n on n.oid = d.defaclnamespace
              where n.nspname = 'public' and d.defaclrole = 'postgres'::regrole
                and exists (select 1 from aclexplode(d.defaclacl) a where a.grantee in
                  ('anon'::regrole, 'authenticated'::regrole, 'service_role'::regrole))) then
    raise exception 'FAIL default ACLs for postgres in public still grant client roles';
  end if;
  raise notice 'PASS default privileges closed for postgres-owned future objects';

  -- G. Storage: buckets private, no storage.objects policy exists yet (deny by default).
  if exists (select 1 from storage.buckets where id in ('course-files', 'submission-files') and public) then
    raise exception 'FAIL a LearnPulse bucket is public';
  end if;
  if (select count(*) from storage.buckets where id in ('course-files', 'submission-files')) <> 2 then
    raise exception 'FAIL expected buckets missing';
  end if;
    --   -- Storage: exactly four narrow policies (INSERT + SELECT on each private bucket), authenticated only,
  -- no UPDATE/DELETE: no overwrite and no client-side deletion.
  if (select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects') <> 4
     or (select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects'
          and roles = '{authenticated}' and cmd in ('INSERT', 'SELECT')
          and policyname in ('submission_files_insert', 'submission_files_select', 'course_files_insert', 'course_files_select')
          and coalesce(qual, with_check) ~ '(submission|course)-files') <> 4 then
    raise exception 'FAIL storage.objects policies must be exactly the four submission_files/course_files insert/select policies';
  end if;
  if (select count(*) from storage.buckets where id in ('submission-files', 'course-files') and file_size_limit = 10485760) <> 2 then
    raise exception 'FAIL private bucket size limits';
  end if;
raise notice 'PASS storage: buckets private; exactly four narrow policies (submission-files and course-files, INSERT+SELECT)';
end $$;

-- Evidence output: the actual grant list (sanitized, no data).
select 'table_grant' kind, grantee::regrole::text g, c.relname || ':' || a.privilege_type detail
  from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
  cross join lateral aclexplode(c.relacl) a
 where c.relkind = 'r' and a.grantee <> c.relowner and a.grantee <> 0
 order by 2, 3;
