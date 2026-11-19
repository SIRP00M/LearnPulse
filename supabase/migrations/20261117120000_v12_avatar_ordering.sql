-- V12 Avatar concurrency hardening (additive; replaces only the two V11 RPC bodies, adds one column).
--
-- PROBLEM (found in the Profile final audit): V11 returned as `stale` every other object in the caller's folder. With two overlapping
-- saves A (older upload) and B (newer upload), A's response could list B; if B's pointer was then set, A's client deleted the ACTIVE
-- object and avatar_path pointed at nothing. The same race existed between remove_my_avatar and an in-flight upload.
--
-- FIX: a monotonic floor. profiles.avatar_floor = created_at of the newest accepted object (or the instant of the last removal).
--   * set_my_avatar refuses an object that is not newer than the floor (it can never become current again, so deleting it is safe).
--   * `stale` contains only objects OLDER than the new floor, i.e. objects that can never be set again. A newer in-flight upload is
--     never listed, so no client can delete an object that may still become (or already is) the active one.
--   * remove_my_avatar moves the floor to now(): every existing object becomes stale and unsettable; an upload that starts later is fine.
-- Failure modes: a refused or abandoned upload is deleted by its own client or listed by the next newer save; the folder cap (3) bounds orphans.

alter table public.profiles add column avatar_floor timestamptz;

create or replace function public.set_my_avatar(p_path text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_size bigint;
  v_mime text;
  v_created timestamptz;
  v_floor timestamptz;
  v_stale jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_path is null or p_path !~ ('^' || v_uid::text || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(webp|jpg)$') then
    raise exception 'Invalid avatar path' using errcode = 'PT400';
  end if;
  select avatar_floor into v_floor from public.profiles where id = v_uid for update;  -- serializes concurrent saves
  select (o.metadata ->> 'size')::bigint, o.metadata ->> 'mimetype', o.created_at into v_size, v_mime, v_created
    from storage.objects o where o.bucket_id = 'avatars' and o.name = p_path;
  if not found then raise exception 'The photo was not uploaded; retry the upload' using errcode = 'PT409'; end if;
  if v_size is null or v_size > 524288 or v_size < 1 then
    raise exception 'The photo must be at most 512 KB' using errcode = 'PT400'; end if;
  if (v_mime, right(p_path, 4)) not in (('image/webp', 'webp'), ('image/jpeg', '.jpg')) then
    raise exception 'The photo must be JPEG or WebP' using errcode = 'PT400'; end if;
  if v_floor is not null and v_created <= v_floor then
    raise exception 'A newer photo was already saved; choose the photo again' using errcode = 'PT409'; end if;
  update public.profiles set avatar_path = p_path, avatar_floor = v_created where id = v_uid;
  select coalesce(jsonb_agg(o.name order by o.created_at), '[]') into v_stale
    from storage.objects o
   where o.bucket_id = 'avatars' and o.name like v_uid::text || '/%' and o.created_at < v_created;
  return jsonb_build_object('avatar_path', p_path, 'stale', v_stale);
end $$;

create or replace function public.remove_my_avatar() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_floor timestamptz := clock_timestamp();
  v_stale jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  perform 1 from public.profiles where id = v_uid for update;
  update public.profiles set avatar_path = null, avatar_floor = v_floor where id = v_uid;
  select coalesce(jsonb_agg(o.name order by o.created_at), '[]') into v_stale
    from storage.objects o where o.bucket_id = 'avatars' and o.name like v_uid::text || '/%' and o.created_at <= v_floor;
  return jsonb_build_object('avatar_path', null, 'stale', v_stale);
end $$;

notify pgrst, 'reload schema';
