-- V5 lessons and resources.
-- Same conventions as V3/V4: reads through RLS, writes only through SECURITY DEFINER RPCs (search_path '',
-- auth.uid(), authenticated-only EXECUTE, PT4xx errors, optimistic `version`, PT409 on conflicts).
--   * Teachers (course owners) create, edit, publish / unpublish and delete lessons, and attach resource files.
--   * Students see a lesson only while it is published and they are an active member; a removed student loses
--     the lesson and its files at once; drafts never reach students.
--   * Files live in the private `course-files` bucket. Upload = server-issued ticket (validated type/size,
--     deterministic path) -> client uploads the bytes (Storage RLS allows exactly that path, once, for the
--     owning teacher) -> finalize_resource verifies the stored object's size and declared MIME (the Content-Type the client sent; contents are not inspected) and attaches it.
--   * Deleting a resource row revokes access immediately; the orphaned object is removed by the operator tool.

create type public.lesson_status as enum ('draft', 'published');
create type public.resource_status as enum ('pending', 'attached');

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  body text not null default '' check (char_length(body) <= 20000),
  position integer not null default 0,
  status public.lesson_status not null default 'draft',
  published_at timestamptz,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((status = 'published') = (published_at is not null))
);
create index lessons_course_idx on public.lessons (course_id, position, created_at);

create table public.lesson_resources (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null default '' check (char_length(title) <= 120),
  file_name text not null check (char_length(file_name) between 1 and 200),
  mime_type text not null,
  size_bytes bigint not null check (size_bytes between 1 and 10485760),
  storage_path text not null unique,
  status public.resource_status not null default 'pending',
  created_at timestamptz not null default now()
);
create index lesson_resources_lesson_idx on public.lesson_resources (lesson_id, created_at);

create trigger lessons_set_updated_at before update on public.lessons
  for each row execute function public.set_updated_at();

-- Authorization helpers (private schema) -----------------------------------------------------------
create function private.is_lesson_owner(p_lesson_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.lessons l join public.courses c on c.id = l.course_id
                  where l.id = p_lesson_id and c.owner_id = (select auth.uid()))
$$;

create function private.is_lesson_visible_to_member(p_lesson_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.lessons l
                   join public.course_members m on m.course_id = l.course_id
                  where l.id = p_lesson_id and l.status = 'published'
                    and m.student_id = (select auth.uid()) and m.status = 'active')
$$;

create function private.can_upload_resource_object(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.lesson_resources r
                  where r.storage_path = p_name and r.status = 'pending'
                    and r.created_at > now() - interval '24 hours'
                    and private.is_lesson_owner(r.lesson_id))
$$;

create function private.can_read_resource_object(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.lesson_resources r
                  where r.storage_path = p_name
                    and (private.is_lesson_owner(r.lesson_id)
                         or (r.status = 'attached' and private.is_lesson_visible_to_member(r.lesson_id))))
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'private.is_lesson_owner(uuid)', 'private.is_lesson_visible_to_member(uuid)',
    'private.can_upload_resource_object(text)', 'private.can_read_resource_object(text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- RLS ------------------------------------------------------------------------------------------
alter table public.lessons enable row level security;
alter table public.lesson_resources enable row level security;

create policy lessons_select on public.lessons for select to authenticated
  using (private.is_lesson_owner(id) or private.is_lesson_visible_to_member(id));
create policy lesson_resources_select on public.lesson_resources for select to authenticated
  using (private.is_lesson_owner(lesson_id)
         or (status = 'attached' and private.is_lesson_visible_to_member(lesson_id)));

grant select on public.lessons, public.lesson_resources to authenticated;

-- Storage: two narrow policies on the private course bucket (no UPDATE/DELETE: no overwrite, no client delete).
create policy course_files_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'course-files' and private.can_upload_resource_object(name));
create policy course_files_select on storage.objects for select to authenticated
  using (bucket_id = 'course-files' and private.can_read_resource_object(name));

update storage.buckets set file_size_limit = 10485760 where id = 'course-files';

-- RPCs -------------------------------------------------------------------------------------------
create function public.create_lesson(p_course_id uuid, p_title text, p_body text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_course public.courses;
  v_l public.lessons;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select * into v_course from public.courses where id = p_course_id and owner_id = v_uid;
  if not found then raise exception 'Course not found' using errcode = 'PT404'; end if;
  if v_course.status <> 'active' then raise exception 'Course is archived' using errcode = 'PT409'; end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Title must be 1-120 characters' using errcode = 'PT400'; end if;
  if char_length(coalesce(p_body, '')) > 20000 then
    raise exception 'Lesson text is too long' using errcode = 'PT400'; end if;
  if (select count(*) from public.lessons where course_id = p_course_id) >= 200 then
    raise exception 'A course can have at most 200 lessons' using errcode = 'PT409'; end if;
  insert into public.lessons (course_id, title, body, position)
  values (p_course_id, btrim(p_title), coalesce(p_body, ''),
          coalesce((select max(position) from public.lessons where course_id = p_course_id), 0) + 1)
  returning * into v_l;
  return jsonb_build_object('id', v_l.id, 'version', v_l.version, 'status', v_l.status);
end $$;

create function public.update_lesson(
  p_lesson_id uuid, p_expected_version integer, p_title text default null, p_body text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_l public.lessons;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select l.* into v_l from public.lessons l join public.courses c on c.id = l.course_id
   where l.id = p_lesson_id and c.owner_id = v_uid for update of l;
  if not found then raise exception 'Lesson not found' using errcode = 'PT404'; end if;
  if v_l.version is distinct from p_expected_version then
    raise exception 'Lesson changed; reload and retry' using errcode = 'PT409'; end if;
  if p_title is not null and char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Title must be 1-120 characters' using errcode = 'PT400'; end if;
  if p_body is not null and char_length(p_body) > 20000 then
    raise exception 'Lesson text is too long' using errcode = 'PT400'; end if;
  update public.lessons
     set title = coalesce(btrim(p_title), title), body = coalesce(p_body, body), version = version + 1
   where id = p_lesson_id returning * into v_l;
  return jsonb_build_object('id', v_l.id, 'version', v_l.version, 'status', v_l.status);
end $$;

create function public.set_lesson_status(
  p_lesson_id uuid, p_expected_version integer, p_status public.lesson_status
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_l public.lessons;
  v_course_status public.course_status;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select l.* into v_l from public.lessons l join public.courses c on c.id = l.course_id
   where l.id = p_lesson_id and c.owner_id = v_uid for update of l;
  if not found then raise exception 'Lesson not found' using errcode = 'PT404'; end if;
  if v_l.version is distinct from p_expected_version then
    raise exception 'Lesson changed; reload and retry' using errcode = 'PT409'; end if;
  if v_l.status = p_status then raise exception 'Lesson is already %', p_status using errcode = 'PT409'; end if;
  select status into v_course_status from public.courses where id = v_l.course_id;
  if p_status = 'published' and v_course_status <> 'active' then
    raise exception 'Course is archived' using errcode = 'PT409'; end if;
  update public.lessons
     set status = p_status, published_at = case when p_status = 'published' then now() else null end,
         version = version + 1
   where id = p_lesson_id returning * into v_l;
  return jsonb_build_object('id', v_l.id, 'version', v_l.version, 'status', v_l.status);
end $$;

create function public.delete_lesson(p_lesson_id uuid, p_expected_version integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_l public.lessons;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select l.* into v_l from public.lessons l join public.courses c on c.id = l.course_id
   where l.id = p_lesson_id and c.owner_id = v_uid for update of l;
  if not found then raise exception 'Lesson not found' using errcode = 'PT404'; end if;
  if v_l.version is distinct from p_expected_version then
    raise exception 'Lesson changed; reload and retry' using errcode = 'PT409'; end if;
  delete from public.lessons where id = p_lesson_id;  -- resource rows cascade: access is revoked at once
  return jsonb_build_object('id', p_lesson_id, 'deleted', true);
end $$;

create function public.prepare_resource_upload(
  p_lesson_id uuid, p_file_name text, p_mime_type text, p_size_bytes bigint
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_l public.lessons;
  v_name text := btrim(coalesce(p_file_name, ''));
  v_ext text;
  v_expected_mime text;
  v_id uuid := gen_random_uuid();
  v_path text;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select l.* into v_l from public.lessons l join public.courses c on c.id = l.course_id
   where l.id = p_lesson_id and c.owner_id = v_uid for update of l;  -- serializes the quota checks below
  if not found then raise exception 'Lesson not found' using errcode = 'PT404'; end if;
  if exists (select 1 from public.courses where id = v_l.course_id and status <> 'active') then
    raise exception 'Course is archived' using errcode = 'PT409'; end if;
  if char_length(v_name) not between 1 and 200 or v_name ~ '[\\/\x00-\x1f\x7f​-‏‪-‮⁦-⁩]' then
    raise exception 'Invalid file name' using errcode = 'PT400'; end if;
  v_ext := lower(substring(v_name from '\.([A-Za-z0-9]+)$'));
  v_expected_mime := case v_ext
    when 'pdf' then 'application/pdf'
    when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when 'zip' then 'application/zip'
    when 'png' then 'image/png'
    when 'jpg' then 'image/jpeg'
    when 'jpeg' then 'image/jpeg'
    when 'webp' then 'image/webp'
    when 'txt' then 'text/plain'
    else null end;
  if v_expected_mime is null then
    raise exception 'File type not allowed (pdf, docx, zip, png, jpg, jpeg, webp, txt)' using errcode = 'PT400'; end if;
  if p_mime_type is distinct from v_expected_mime then
    raise exception 'File type does not match its extension' using errcode = 'PT400'; end if;
  if p_size_bytes is null or p_size_bytes not between 1 and 10485760 then
    raise exception 'File must be between 1 byte and 10 MiB' using errcode = 'PT400'; end if;
  if (select count(*) from public.lesson_resources
       where lesson_id = p_lesson_id and status = 'pending' and created_at > now() - interval '1 hour') >= 10 then
    raise exception 'Too many pending uploads; try again later' using errcode = 'PT429'; end if;
  if (select count(*) from public.lesson_resources where lesson_id = p_lesson_id and status = 'attached') >= 20 then
    raise exception 'A lesson can have at most 20 files' using errcode = 'PT409'; end if;

  v_path := v_l.course_id::text || '/' || p_lesson_id::text || '/' || v_id::text || '/'
            || left(regexp_replace(v_name, '[^A-Za-z0-9._-]', '_', 'g'), 100);
  insert into public.lesson_resources (id, lesson_id, course_id, file_name, mime_type, size_bytes, storage_path)
  values (v_id, p_lesson_id, v_l.course_id, v_name, v_expected_mime, p_size_bytes, v_path);
  return jsonb_build_object('resource_id', v_id, 'bucket', 'course-files', 'path', v_path);
end $$;

create function public.finalize_resource(p_resource_id uuid, p_title text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_r public.lesson_resources;
  v_obj_size bigint;
  v_obj_mime text;
  v_title text := btrim(coalesce(p_title, ''));
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select r.* into v_r from public.lesson_resources r join public.courses c on c.id = r.course_id
   where r.id = p_resource_id and c.owner_id = v_uid;
  if not found then raise exception 'Resource not found' using errcode = 'PT404'; end if;
  perform 1 from public.lessons where id = v_r.lesson_id for update;  -- lesson first: same lock order as prepare/delete_lesson
  select r.* into v_r from public.lesson_resources r where r.id = p_resource_id for update;
  if not found then raise exception 'Resource not found' using errcode = 'PT404'; end if;
  if char_length(v_title) > 120 then raise exception 'Title is too long' using errcode = 'PT400'; end if;
  if v_r.status = 'attached' then  -- idempotent: a retry after a lost response returns the same result
    return jsonb_build_object('resource_id', v_r.id, 'title', v_r.title, 'status', v_r.status, 'replayed', true);
  end if;
  if (select count(*) from public.lesson_resources where lesson_id = v_r.lesson_id and status = 'attached') >= 20 then
    raise exception 'A lesson can have at most 20 files' using errcode = 'PT409'; end if;
  if v_r.created_at < now() - interval '24 hours' then
    raise exception 'Upload expired; attach the file again' using errcode = 'PT409'; end if;
  select (o.metadata ->> 'size')::bigint, o.metadata ->> 'mimetype' into v_obj_size, v_obj_mime
    from storage.objects o where o.bucket_id = 'course-files' and o.name = v_r.storage_path;
  if not found then raise exception 'The file was not uploaded; retry the upload' using errcode = 'PT409'; end if;
  if v_obj_size is distinct from v_r.size_bytes or v_obj_mime is distinct from v_r.mime_type then
    raise exception 'The uploaded file does not match what was declared' using errcode = 'PT409'; end if;
  update public.lesson_resources set status = 'attached', title = case when v_title = '' then file_name else v_title end
   where id = p_resource_id returning * into v_r;
  return jsonb_build_object('resource_id', v_r.id, 'title', v_r.title, 'status', v_r.status);
end $$;

create function public.delete_resource(p_resource_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  delete from public.lesson_resources r using public.courses c
   where r.id = p_resource_id and c.id = r.course_id and c.owner_id = v_uid;
  if not found then raise exception 'Resource not found' using errcode = 'PT404'; end if;
  return jsonb_build_object('resource_id', p_resource_id, 'deleted', true);
end $$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.create_lesson(uuid, text, text)',
    'public.update_lesson(uuid, integer, text, text)',
    'public.set_lesson_status(uuid, integer, public.lesson_status)',
    'public.delete_lesson(uuid, integer)',
    'public.prepare_resource_upload(uuid, text, text, bigint)',
    'public.finalize_resource(uuid, text)',
    'public.delete_resource(uuid)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Operator listing of orphaned course-files objects for the Storage-API purge tool: expired pending tickets,
-- and objects whose resource row was deleted (delete_resource / delete_lesson revoke access, not bytes).
create function private.orphan_resource_objects(p_older_than interval default interval '24 hours')
returns table (storage_path text)
language sql stable security definer set search_path = '' as $$
  select r.storage_path from public.lesson_resources r
   where r.status = 'pending' and r.created_at < now() - greatest(p_older_than, interval '24 hours')
  union
  select o.name from storage.objects o
   where o.bucket_id = 'course-files' and o.created_at < now() - greatest(p_older_than, interval '24 hours')
     and not exists (select 1 from public.lesson_resources r where r.storage_path = o.name)
$$;
revoke all on function private.orphan_resource_objects(interval) from public, anon, authenticated, service_role;

notify pgrst, 'reload schema';
