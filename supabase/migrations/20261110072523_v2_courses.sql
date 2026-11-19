-- V2 courses and enrollment: the minimum extra contracts on top of V0/V1.
-- Existing: create_course, join_course_by_code (throttled), RLS reads of courses / course_members / profiles.
-- Added here:
--   * join_code is no longer selectable by clients (a student could otherwise re-share the code);
--     the owning teacher reads it through get_course_join_code.
--   * update_course (edit / archive), remove_course_member (roster management).
-- All three RPCs follow the V0 convention: SECURITY DEFINER, search_path '', auth.uid() check,
-- authenticated-only EXECUTE, PT4xx errors. "Not yours" and "does not exist" both answer PT404
-- so course ids cannot be probed.

revoke select on public.courses from authenticated;
grant select (id, owner_id, title, description, status, created_at, updated_at)
  on public.courses to authenticated;

create function public.get_course_join_code(p_course_id uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_code text;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select join_code into v_code from public.courses where id = p_course_id and owner_id = v_uid;
  if not found then raise exception 'Course not found' using errcode = 'PT404'; end if;
  return v_code;
end $$;

create function public.update_course(
  p_course_id uuid,
  p_title text default null,
  p_description text default null,
  p_status public.course_status default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_course public.courses;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_title is not null and char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Title must be 1-120 characters' using errcode = 'PT400';
  end if;
  if p_description is not null and char_length(p_description) > 2000 then
    raise exception 'Description is too long' using errcode = 'PT400';
  end if;

  update public.courses
     set title = coalesce(btrim(p_title), title),
         description = coalesce(p_description, description),
         status = coalesce(p_status, status)
   where id = p_course_id and owner_id = v_uid
   returning * into v_course;
  if not found then raise exception 'Course not found' using errcode = 'PT404'; end if;

  return jsonb_build_object('id', v_course.id, 'title', v_course.title,
                            'description', v_course.description, 'status', v_course.status);
end $$;

create function public.remove_course_member(p_course_id uuid, p_student_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.courses where id = p_course_id and owner_id = v_uid) then
    raise exception 'Course not found' using errcode = 'PT404';
  end if;
  update public.course_members
     set status = 'removed', removed_at = now()
   where course_id = p_course_id and student_id = p_student_id and status = 'active';
  if not found then raise exception 'Member not found' using errcode = 'PT404'; end if;
  return jsonb_build_object('course_id', p_course_id, 'student_id', p_student_id, 'status', 'removed');
end $$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.get_course_join_code(uuid)',
    'public.update_course(uuid, text, text, public.course_status)',
    'public.remove_course_member(uuid, uuid)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
