-- V11 Profile avatars. Additive: one nullable profiles column, one private bucket, three storage policies, two RPCs.
--
-- MODEL
--   Bucket `avatars` is private (512 KB, JPEG/WebP). Objects are immutable: every upload is a NEW object
--   `{user_id}/{random uuid}.{webp|jpg}`; nothing is ever overwritten, so `profiles.avatar_path` doubles as the cache key.
--   Clients cannot write profiles.avatar_path (column privileges are unchanged: only full_name is updatable); they upload an
--   object, then call set_my_avatar(path), which validates ownership, size and type and returns the now-stale objects to delete.
--
-- VISIBILITY (Owner decision): the owner, and a teacher who owns a course in which the user is an ACTIVE member.
--   No classmate-to-classmate and no student-to-teacher viewing. A teacher can read only the user's CURRENT avatar object,
--   so a replaced or removed photo stops being readable immediately, before the old object is physically deleted.
--
-- LIMITS / CLEANUP
--   INSERT is refused once a user's folder holds 3 objects (current + at most two orphans). set_my_avatar / remove_my_avatar
--   return every other object in the folder (`stale`); the client deletes them through the Storage API (owner DELETE policy).
--   Objects orphaned by an auth-user deletion are found with the read-only query in docs/AVATARS_STAGE1_ACCEPTANCE.md.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('avatars', 'avatars', false, 524288, array['image/jpeg', 'image/webp'])
on conflict (id) do update
  set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

alter table public.profiles add column avatar_path text;
alter table public.profiles add constraint profiles_avatar_path_valid check (
  avatar_path is null
  or avatar_path ~ ('^' || id::text || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(webp|jpg)$'));

-- Storage helpers (private schema: functions only) ---------------------------------------------
create function private.can_upload_avatar_object(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select case
    when p_name !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(webp|jpg)$'
      then false
    else split_part(p_name, '/', 1) = (select auth.uid())::text
         and (select count(*) from storage.objects o
               where o.bucket_id = 'avatars' and o.name like split_part(p_name, '/', 1) || '/%') < 3
  end
$$;

create function private.can_read_avatar_object(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select case
    when p_name !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(webp|jpg)$'
      then false
    -- The owner sees every object in their folder (needed to clean up); a teacher only the current avatar.
    when split_part(p_name, '/', 1) = (select auth.uid())::text then true
    else exists (select 1
                   from public.profiles p
                   join public.course_members m on m.student_id = p.id and m.status = 'active'
                   join public.courses c on c.id = m.course_id
                  where p.avatar_path = p_name and c.owner_id = (select auth.uid()))
  end
$$;

do $$
declare
  f text;
begin
  foreach f in array array['private.can_upload_avatar_object(text)', 'private.can_read_avatar_object(text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

create policy avatars_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and private.can_upload_avatar_object(name));
create policy avatars_select on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and private.can_read_avatar_object(name));
create policy avatars_delete on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and split_part(name, '/', 1) = (select auth.uid())::text);

-- RPCs ---------------------------------------------------------------------------------------------
create function public.set_my_avatar(p_path text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_size bigint;
  v_mime text;
  v_stale jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_path is null or p_path !~ ('^' || v_uid::text || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(webp|jpg)$') then
    raise exception 'Invalid avatar path' using errcode = 'PT400';
  end if;
  perform 1 from public.profiles where id = v_uid for update;
  select (o.metadata ->> 'size')::bigint, o.metadata ->> 'mimetype' into v_size, v_mime
    from storage.objects o where o.bucket_id = 'avatars' and o.name = p_path;
  if not found then raise exception 'The photo was not uploaded; retry the upload' using errcode = 'PT409'; end if;
  if v_size is null or v_size > 524288 or v_size < 1 then
    raise exception 'The photo must be at most 512 KB' using errcode = 'PT400'; end if;
  if (v_mime, right(p_path, 4)) not in (('image/webp', 'webp'), ('image/jpeg', '.jpg')) then
    raise exception 'The photo must be JPEG or WebP' using errcode = 'PT400'; end if;
  update public.profiles set avatar_path = p_path where id = v_uid;
  select coalesce(jsonb_agg(o.name order by o.created_at), '[]') into v_stale
    from storage.objects o
   where o.bucket_id = 'avatars' and o.name like v_uid::text || '/%' and o.name <> p_path;
  return jsonb_build_object('avatar_path', p_path, 'stale', v_stale);
end $$;

create function public.remove_my_avatar() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_stale jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  perform 1 from public.profiles where id = v_uid for update;
  update public.profiles set avatar_path = null where id = v_uid;
  select coalesce(jsonb_agg(o.name order by o.created_at), '[]') into v_stale
    from storage.objects o where o.bucket_id = 'avatars' and o.name like v_uid::text || '/%';
  return jsonb_build_object('avatar_path', null, 'stale', v_stale);
end $$;

do $$
declare
  f text;
begin
  foreach f in array array['public.set_my_avatar(text)', 'public.remove_my_avatar()'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

notify pgrst, 'reload schema';
