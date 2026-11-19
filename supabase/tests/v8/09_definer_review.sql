-- V8 SECURITY DEFINER review: structural rules every function reachable from the API must satisfy.
-- Complements 01_privilege_audit.sql (who may EXECUTE) by checking what the functions DO.
\set ON_ERROR_STOP 1
do $$
declare
  v_bad text;
  v_n integer;
begin
  -- 1. Every public function is SECURITY DEFINER, owned by postgres, with search_path pinned to ''.
  select string_agg(p.oid::regprocedure::text, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prokind = 'f' and p.prorettype <> 'trigger'::regtype
     and not (p.prosecdef and pg_get_userbyid(p.proowner) = 'postgres' and coalesce(p.proconfig, '{}') @> array['search_path=""']);
  if v_bad is not null then raise exception 'FAIL definer/owner/search_path: %', v_bad; end if;
  -- Trigger functions are internal (never client-callable, see the privilege audit); they must still pin search_path.
  select string_agg(p.oid::regprocedure::text, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prorettype = 'trigger'::regtype
     and (not coalesce(p.proconfig, '{}') @> array['search_path=""'] or has_function_privilege('authenticated', p.oid, 'EXECUTE'));
  if v_bad is not null then raise exception 'FAIL trigger function search_path or client EXECUTE: %', v_bad; end if;

  -- 2. Every API-callable RPC authenticates inside the function (auth.uid() + PT401) before touching data.
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prokind = 'f' and p.prorettype <> 'trigger'::regtype
     and has_function_privilege('authenticated', p.oid, 'EXECUTE')
     and not (p.prosrc like '%auth.uid()%' and p.prosrc like '%PT401%');
  if v_bad is not null then raise exception 'FAIL RPC without an in-function auth check: %', v_bad; end if;

  -- 3. No dynamic SQL in an API-callable function (nothing to inject into), no role switching, no config writes.
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private') and p.prokind = 'f'
     and (p.prosrc ~* '\mexecute\M' or p.prosrc ~* 'set\s+(local\s+)?role\s+[a-z_"]+' or p.prosrc ~* 'set_config\s*\(' or p.prosrc ~* 'reset\s+role');
  if v_bad is not null then raise exception 'FAIL dynamic SQL / role switch in: %', v_bad; end if;

  -- 4. Every API-callable RPC that writes takes an ownership or role gate: its body must mention one of the gates.
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prokind = 'f' and p.prorettype <> 'trigger'::regtype
     and has_function_privilege('authenticated', p.oid, 'EXECUTE')
     and p.prosrc ~* '\m(insert into|update public|delete from)\M'
     and not (p.prosrc ~* 'owner_id\s*=\s*v_uid' or p.prosrc ~* 'role\s*=\s*''student''' or p.prosrc ~* 'role\s*=\s*''teacher'''
              or p.prosrc ~* 'student_id\s*=\s*v_uid' or p.prosrc ~* 'private\.is_\w+' or p.prosrc ~* 'c\.owner_id\s*=\s*v_uid'
              or p.prosrc ~* 'is_course_owner' or p.prosrc ~* 'is_lesson_owner');
  if v_bad is not null then raise exception 'FAIL writing RPC without ownership/role gate: %', v_bad; end if;

  -- 5. Mutating RPCs that clients can retry carry an idempotency or version guard.
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname in
         ('submit_assignment', 'grade_submission', 'return_submission', 'mark_attendance',
          'create_attendance_session', 'close_attendance_session')
     and not (p.prosrc like '%request_id%' and p.prosrc like '%PT409%');
  if v_bad is not null then raise exception 'FAIL retryable RPC without request_id + PT409: %', v_bad; end if;
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname in ('update_assignment', 'publish_assignment', 'update_lesson', 'set_lesson_status', 'delete_lesson')
     and not (p.prosrc like '%p_expected_version%' and p.prosrc like '%PT409%');
  if v_bad is not null then raise exception 'FAIL versioned RPC without stale-version PT409: %', v_bad; end if;

  -- 6. Read-only dashboards and summaries are STABLE (cannot write).
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname in ('get_teacher_dashboard', 'get_student_dashboard', 'get_attendance_summary')
     and p.provolatile <> 's';
  if v_bad is not null then raise exception 'FAIL read-only RPC is not STABLE: %', v_bad; end if;

  -- 7. Client errors use PT4xx codes only; 40001 (retried forever by PostgREST) must never appear.
  select string_agg(p.proname, ', ') into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public', 'private') and (p.prosrc like '%40001%' or p.prosrc like '%serialization_failure%');
  if v_bad is not null then raise exception 'FAIL 40001 used in: %', v_bad; end if;

  -- 8. Join-code secrecy: only get_course_join_code and create_course/join may mention join_code.
  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prosrc like '%join_code%'
     and p.proname not in ('get_course_join_code', 'create_course', 'join_course_by_code', 'generate_join_code');
  if v_n <> 0 then raise exception 'FAIL % unexpected function(s) touch join_code', v_n; end if;

  select count(*) into v_n from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and has_function_privilege('authenticated', p.oid, 'EXECUTE');
  raise notice 'PASS V8 definer review: % exposed RPCs checked (definer/owner/search_path, in-function auth, no dynamic SQL, ownership gate, idempotency/version guards, STABLE reads, no 40001, join_code secrecy)', v_n;
end $$;
