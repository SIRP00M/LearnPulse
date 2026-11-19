-- V3 assignments and submissions.
-- Design (V4-compatible: grading adds score/feedback columns and uses the same version counter):
--   * Clients read through RLS and mutate only through SECURITY DEFINER RPCs (V0 conventions:
--     search_path '', auth.uid(), authenticated-only EXECUTE, PT4xx errors, PT409 for business conflicts).
--   * Drafts are invisible to students. A student sees a published assignment only while an active member;
--     a removed student loses assignment, submission and file access immediately.
--   * Files: prepare_submission_upload (validated ticket + deterministic private path) -> client uploads the
--     bytes to the private bucket (Storage RLS allows exactly that path, once, for that student) ->
--     submit_assignment verifies the stored object (size and MIME) and attaches it.
--   * submit_assignment is idempotent per request id and optimistic-concurrent per submission version.

create type public.assignment_status as enum ('draft', 'published');
create type public.submission_status as enum ('submitted', 'graded', 'returned');
create type public.upload_status as enum ('pending', 'attached');

create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  instructions text not null default '' check (char_length(instructions) <= 10000),
  max_score integer not null default 100 check (max_score between 1 and 1000),
  due_at timestamptz,
  status public.assignment_status not null default 'draft',
  published_at timestamptz,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((status = 'published') = (published_at is not null))
);
create index assignments_course_idx on public.assignments (course_id, created_at desc);

create table public.submission_uploads (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null unique,
  file_name text not null check (char_length(file_name) between 1 and 200),
  mime_type text not null,
  size_bytes bigint not null check (size_bytes between 1 and 10485760),
  status public.upload_status not null default 'pending',
  created_at timestamptz not null default now()
);
create index submission_uploads_owner_idx on public.submission_uploads (student_id, assignment_id, created_at desc);

create table public.submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  answer text not null default '' check (char_length(answer) <= 20000),
  upload_id uuid references public.submission_uploads (id) on delete set null,
  status public.submission_status not null default 'submitted',
  version integer not null default 1,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (assignment_id, student_id)
);
create index submissions_assignment_idx on public.submissions (assignment_id);

-- Idempotency ledger; written only by submit_assignment.
create table public.submission_requests (
  request_id uuid primary key,
  student_id uuid not null references public.profiles (id) on delete cascade,
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  request_hash text not null,
  response jsonb,
  created_at timestamptz not null default now()
);

create trigger assignments_set_updated_at before update on public.assignments
  for each row execute function public.set_updated_at();
create trigger submissions_set_updated_at before update on public.submissions
  for each row execute function public.set_updated_at();

-- Authorization helpers (private schema: not reachable through the API, usable by RLS) ----------
create function private.is_assignment_owner(p_assignment_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.assignments a join public.courses c on c.id = a.course_id
                  where a.id = p_assignment_id and c.owner_id = (select auth.uid()))
$$;

create function private.is_assignment_visible_to_member(p_assignment_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.assignments a
                   join public.course_members m on m.course_id = a.course_id
                  where a.id = p_assignment_id and a.status = 'published'
                    and m.student_id = (select auth.uid()) and m.status = 'active')
$$;

-- Object-level Storage checks. Object names are assignment_id/student_id/upload_id/file.
create function private.can_upload_object(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.submission_uploads u
                  where u.storage_path = p_name and u.student_id = (select auth.uid())
                    and u.status = 'pending' and u.created_at > now() - interval '24 hours'
                    and private.is_assignment_visible_to_member(u.assignment_id))
$$;

create function private.can_read_object(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.submission_uploads u
                  where u.storage_path = p_name
                    and ((u.student_id = (select auth.uid()) and private.is_assignment_visible_to_member(u.assignment_id))
                         or private.is_assignment_owner(u.assignment_id)))
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'private.is_assignment_owner(uuid)', 'private.is_assignment_visible_to_member(uuid)',
    'private.can_upload_object(text)', 'private.can_read_object(text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- RLS ------------------------------------------------------------------------------------------
alter table public.assignments enable row level security;
alter table public.submission_uploads enable row level security;
alter table public.submissions enable row level security;
alter table public.submission_requests enable row level security;

create policy assignments_select on public.assignments for select to authenticated
  using (private.is_assignment_owner(id) or private.is_assignment_visible_to_member(id));
create policy submissions_select on public.submissions for select to authenticated
  using ((student_id = (select auth.uid()) and private.is_assignment_visible_to_member(assignment_id))
         or private.is_assignment_owner(assignment_id));
create policy submission_uploads_select on public.submission_uploads for select to authenticated
  using ((student_id = (select auth.uid()) and private.is_assignment_visible_to_member(assignment_id))
         or private.is_assignment_owner(assignment_id));
-- submission_requests: RLS on, no policies, no grants.

grant select on public.assignments, public.submissions, public.submission_uploads to authenticated;

-- Storage: two narrow policies on the private submission bucket. No UPDATE/DELETE (no upsert, no
-- client deletion); uploads exist only for a prepared, pending, unexpired ticket of the caller.
create policy submission_files_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'submission-files' and private.can_upload_object(name));
create policy submission_files_select on storage.objects for select to authenticated
  using (bucket_id = 'submission-files' and private.can_read_object(name));

update storage.buckets set file_size_limit = 10485760 where id = 'submission-files';

-- Teacher RPCs ---------------------------------------------------------------------------------
create function public.create_assignment(
  p_course_id uuid, p_title text, p_instructions text default '',
  p_max_score integer default 100, p_due_at timestamptz default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_course public.courses;
  v_a public.assignments;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select * into v_course from public.courses where id = p_course_id and owner_id = v_uid;
  if not found then raise exception 'Course not found' using errcode = 'PT404'; end if;
  if v_course.status <> 'active' then raise exception 'Course is archived' using errcode = 'PT409'; end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Title must be 1-120 characters' using errcode = 'PT400'; end if;
  if char_length(coalesce(p_instructions, '')) > 10000 then
    raise exception 'Instructions are too long' using errcode = 'PT400'; end if;
  if p_max_score is null or p_max_score not between 1 and 1000 then
    raise exception 'Maximum score must be 1-1000' using errcode = 'PT400'; end if;
  insert into public.assignments (course_id, title, instructions, max_score, due_at)
  values (p_course_id, btrim(p_title), coalesce(p_instructions, ''), p_max_score, p_due_at)
  returning * into v_a;
  return jsonb_build_object('id', v_a.id, 'version', v_a.version, 'status', v_a.status);
end $$;

create function public.update_assignment(
  p_assignment_id uuid, p_expected_version integer,
  p_title text default null, p_instructions text default null, p_max_score integer default null,
  p_due_at timestamptz default null, p_clear_due boolean default false
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_a public.assignments;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select a.* into v_a from public.assignments a join public.courses c on c.id = a.course_id
   where a.id = p_assignment_id and c.owner_id = v_uid for update of a;
  if not found then raise exception 'Assignment not found' using errcode = 'PT404'; end if;
  if v_a.version is distinct from p_expected_version then
    raise exception 'Assignment changed; reload and retry' using errcode = 'PT409'; end if;
  if p_title is not null and char_length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Title must be 1-120 characters' using errcode = 'PT400'; end if;
  if p_instructions is not null and char_length(p_instructions) > 10000 then
    raise exception 'Instructions are too long' using errcode = 'PT400'; end if;
  if p_max_score is not null and p_max_score not between 1 and 1000 then
    raise exception 'Maximum score must be 1-1000' using errcode = 'PT400'; end if;
  update public.assignments
     set title = coalesce(btrim(p_title), title),
         instructions = coalesce(p_instructions, instructions),
         max_score = coalesce(p_max_score, max_score),
         due_at = case when p_clear_due then null else coalesce(p_due_at, due_at) end,
         version = version + 1
   where id = p_assignment_id returning * into v_a;
  return jsonb_build_object('id', v_a.id, 'version', v_a.version, 'status', v_a.status);
end $$;

create function public.publish_assignment(p_assignment_id uuid, p_expected_version integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_a public.assignments;
  v_course_status public.course_status;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  select a.* into v_a from public.assignments a join public.courses c on c.id = a.course_id
   where a.id = p_assignment_id and c.owner_id = v_uid for update of a;
  if not found then raise exception 'Assignment not found' using errcode = 'PT404'; end if;
  select status into v_course_status from public.courses where id = v_a.course_id;
  if v_a.version is distinct from p_expected_version then
    raise exception 'Assignment changed; reload and retry' using errcode = 'PT409'; end if;
  if v_a.status = 'published' then raise exception 'Already published' using errcode = 'PT409'; end if;
  if v_course_status <> 'active' then raise exception 'Course is archived' using errcode = 'PT409'; end if;
  update public.assignments set status = 'published', published_at = now(), version = version + 1
   where id = p_assignment_id returning * into v_a;
  return jsonb_build_object('id', v_a.id, 'version', v_a.version, 'status', v_a.status);
end $$;

-- Student RPCs ---------------------------------------------------------------------------------
create function public.prepare_submission_upload(
  p_assignment_id uuid, p_file_name text, p_mime_type text, p_size_bytes bigint
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_a public.assignments;
  v_name text := btrim(coalesce(p_file_name, ''));
  v_ext text;
  v_expected_mime text;
  v_id uuid := gen_random_uuid();
  v_safe text;
  v_path text;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'student') then
    raise exception 'Only students can upload submissions' using errcode = 'PT403'; end if;
  if not private.is_assignment_visible_to_member(p_assignment_id) then
    raise exception 'Assignment not found' using errcode = 'PT404'; end if;
  select * into v_a from public.assignments where id = p_assignment_id;
  if exists (select 1 from public.courses where id = v_a.course_id and status <> 'active') then
    raise exception 'Course is archived' using errcode = 'PT409'; end if;
  if v_a.due_at is not null and now() > v_a.due_at then
    raise exception 'The deadline has passed' using errcode = 'PT409'; end if;

  if char_length(v_name) not between 1 and 200 or v_name ~ '[\\/\x00-\x1f]' then
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
  if (select count(*) from public.submission_uploads
       where student_id = v_uid and assignment_id = p_assignment_id and status = 'pending'
         and created_at > now() - interval '1 hour') >= 10 then
    raise exception 'Too many pending uploads; try again later' using errcode = 'PT429'; end if;

  v_safe := left(regexp_replace(v_name, '[^A-Za-z0-9._-]', '_', 'g'), 100);
  v_path := p_assignment_id::text || '/' || v_uid::text || '/' || v_id::text || '/' || v_safe;
  insert into public.submission_uploads (id, assignment_id, student_id, storage_path, file_name, mime_type, size_bytes)
  values (v_id, p_assignment_id, v_uid, v_path, v_name, v_expected_mime, p_size_bytes);
  return jsonb_build_object('upload_id', v_id, 'bucket', 'submission-files', 'path', v_path);
end $$;

create function public.submit_assignment(
  p_assignment_id uuid, p_request_id uuid, p_answer text,
  p_upload_id uuid default null, p_expected_version integer default null,
  p_clear_attachment boolean default false
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_a public.assignments;
  v_hash text;
  v_rows integer;
  v_req public.submission_requests;
  v_sub public.submissions;
  v_up public.submission_uploads;
  v_obj_size bigint;
  v_obj_mime text;
  v_upload_id uuid;
  v_response jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  if not exists (select 1 from public.profiles where id = v_uid and role = 'student') then
    raise exception 'Only students can submit' using errcode = 'PT403'; end if;
  if not private.is_assignment_visible_to_member(p_assignment_id) then
    raise exception 'Assignment not found' using errcode = 'PT404'; end if;
  select * into v_a from public.assignments where id = p_assignment_id;

  v_hash := md5(concat_ws('|', p_assignment_id, coalesce(p_answer, ''), coalesce(p_upload_id::text, '-'),
                          coalesce(p_expected_version::text, '-'), coalesce(p_clear_attachment, false)));
  insert into public.submission_requests (request_id, student_id, assignment_id, request_hash)
  values (p_request_id, v_uid, p_assignment_id, v_hash) on conflict (request_id) do nothing;
  get diagnostics v_rows = row_count;
  if v_rows = 0 then
    select * into v_req from public.submission_requests where request_id = p_request_id;
    if v_req.student_id <> v_uid or v_req.assignment_id <> p_assignment_id or v_req.request_hash <> v_hash
       or v_req.response is null then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_req.response || jsonb_build_object('replayed', true);
  end if;

  if exists (select 1 from public.courses where id = v_a.course_id and status <> 'active') then
    raise exception 'Course is archived' using errcode = 'PT409'; end if;
  if v_a.due_at is not null and now() > v_a.due_at then
    raise exception 'The deadline has passed' using errcode = 'PT409'; end if;
  if char_length(coalesce(p_answer, '')) > 20000 then
    raise exception 'Answer is too long' using errcode = 'PT400'; end if;
  if p_upload_id is not null and coalesce(p_clear_attachment, false) then
    raise exception 'Choose either a new attachment or removal' using errcode = 'PT400'; end if;

  select * into v_sub from public.submissions
   where assignment_id = p_assignment_id and student_id = v_uid for update;
  if found then
    if v_sub.version is distinct from p_expected_version then
      raise exception 'Your submission changed elsewhere; reload and retry' using errcode = 'PT409'; end if;
    if v_sub.status <> 'submitted' then
      raise exception 'This submission can no longer be changed' using errcode = 'PT409'; end if;
  elsif p_expected_version is not null and p_expected_version <> 0 then
    raise exception 'Your submission changed elsewhere; reload and retry' using errcode = 'PT409';
  end if;

  v_upload_id := case when found and not coalesce(p_clear_attachment, false) then v_sub.upload_id
                      else null end;
  if p_upload_id is not null then
    select * into v_up from public.submission_uploads
     where id = p_upload_id and student_id = v_uid and assignment_id = p_assignment_id for update;
    if not found then raise exception 'Upload not found' using errcode = 'PT404'; end if;
    if v_up.status = 'pending' and v_up.created_at < now() - interval '24 hours' then
      raise exception 'Upload expired; attach the file again' using errcode = 'PT409'; end if;
    select (o.metadata ->> 'size')::bigint, o.metadata ->> 'mimetype' into v_obj_size, v_obj_mime
      from storage.objects o where o.bucket_id = 'submission-files' and o.name = v_up.storage_path;
    if not found then raise exception 'The file was not uploaded; retry the upload' using errcode = 'PT409'; end if;
    if v_obj_size is distinct from v_up.size_bytes or v_obj_mime is distinct from v_up.mime_type then
      raise exception 'The uploaded file does not match what was declared' using errcode = 'PT409'; end if;
    update public.submission_uploads set status = 'attached' where id = p_upload_id;
    v_upload_id := p_upload_id;
  end if;

  if btrim(coalesce(p_answer, '')) = '' and v_upload_id is null then
    raise exception 'Write an answer or attach a file' using errcode = 'PT400'; end if;

  if v_sub.id is null then
    begin
      insert into public.submissions (assignment_id, student_id, answer, upload_id)
      values (p_assignment_id, v_uid, coalesce(p_answer, ''), v_upload_id) returning * into v_sub;
    exception when unique_violation then
      raise exception 'Your submission changed elsewhere; reload and retry' using errcode = 'PT409';
    end;
  else
    update public.submissions
       set answer = coalesce(p_answer, ''), upload_id = v_upload_id, version = version + 1, submitted_at = now()
     where id = v_sub.id returning * into v_sub;
  end if;

  v_response := jsonb_build_object(
    'submission_id', v_sub.id, 'version', v_sub.version, 'status', v_sub.status,
    'submitted_at', v_sub.submitted_at, 'answer', v_sub.answer, 'upload_id', v_sub.upload_id);
  update public.submission_requests set response = v_response where request_id = p_request_id;
  return v_response;
end $$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.create_assignment(uuid, text, text, integer, timestamptz)',
    'public.update_assignment(uuid, integer, text, text, integer, timestamptz, boolean)',
    'public.publish_assignment(uuid, integer)',
    'public.prepare_submission_upload(uuid, text, text, bigint)',
    'public.submit_assignment(uuid, uuid, text, uuid, integer, boolean)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Orphan recovery: uploads that stay 'pending' beyond 24 hours can no longer be attached
-- (submit_assignment rejects them) and their objects are deletable. Read-only listing for the
-- operator tool (supabase/tools/purge_orphan_uploads.py); Storage rows are removed only through the
-- Storage API, never by SQL.
create function private.stale_pending_uploads(p_older_than interval default interval '24 hours')
returns table (upload_id uuid, storage_path text, created_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select u.id, u.storage_path, u.created_at from public.submission_uploads u
   where u.status = 'pending' and u.created_at < now() - p_older_than
$$;
revoke all on function private.stale_pending_uploads(interval) from public, anon, authenticated, service_role;

notify pgrst, 'reload schema';
