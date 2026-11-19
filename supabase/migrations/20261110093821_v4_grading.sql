-- V4 grading, feedback and revision.
-- State machine (status of public.submissions; every transition bumps `version`):
--   submitted --grade--> graded        graded --grade (regrade)--> graded
--   submitted --return--> returned     graded --return--> returned
--   returned --student resubmits--> submitted (score and feedback cleared; history keeps them)
--   graded and returned rows cannot be graded/returned incorrectly: a returned row must be resubmitted first.
-- Rules: max_score is locked once any submission exists; a returned submission may be revised after the
-- deadline (the teacher opened the revision window); a graded submission is locked for the student.
-- Teacher actions take a client request id (idempotent replay after a lost response) and the expected
-- version (PT409 on stale or concurrent grading). Clients never write these columns.

alter table public.submissions
  add column score integer check (score is null or score >= 0),
  add column feedback text check (feedback is null or char_length(feedback) <= 5000),
  add column graded_at timestamptz,
  add column graded_by uuid references public.profiles (id) on delete set null,
  add constraint submissions_graded_has_score check ((status = 'graded') = (score is not null));

-- Append-only grading history; request_id makes teacher actions idempotent.
create table public.submission_events (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.submissions (id) on delete cascade,
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  actor_id uuid not null references public.profiles (id) on delete cascade,
  action text not null check (action in ('graded', 'returned')),
  score integer,
  feedback text not null default '',
  version_after integer not null,
  request_id uuid not null unique,
  response jsonb not null,
  created_at timestamptz not null default now()
);
create index submission_events_submission_idx on public.submission_events (submission_id, created_at);

alter table public.submission_events enable row level security;
create policy submission_events_select on public.submission_events for select to authenticated
  using (private.is_assignment_owner(assignment_id));
grant select on public.submission_events to authenticated;

-- Teacher RPCs --------------------------------------------------------------------------------
create function public.grade_submission(
  p_submission_id uuid, p_request_id uuid, p_expected_version integer, p_score integer,
  p_feedback text default ''
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_sub public.submissions;
  v_max integer;
  v_ev public.submission_events;
  v_feedback text := btrim(coalesce(p_feedback, ''));
  v_response jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  select s.* into v_sub
    from public.submissions s join public.assignments a on a.id = s.assignment_id
    join public.courses c on c.id = a.course_id
   where s.id = p_submission_id and c.owner_id = v_uid for update of s;
  if not found then raise exception 'Submission not found' using errcode = 'PT404'; end if;
  select max_score into v_max from public.assignments where id = v_sub.assignment_id;

  select * into v_ev from public.submission_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.submission_id <> p_submission_id or v_ev.action <> 'graded'
       or v_ev.score is distinct from p_score or v_ev.feedback <> v_feedback then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.response || jsonb_build_object('replayed', true);
  end if;

  if v_sub.version is distinct from p_expected_version then
    raise exception 'The submission changed; reload and try again' using errcode = 'PT409'; end if;
  if v_sub.status not in ('submitted', 'graded') then
    raise exception 'A returned submission must be resubmitted by the student before it can be graded'
      using errcode = 'PT409'; end if;
  if p_score is null or p_score < 0 or p_score > v_max then
    raise exception 'Score must be between 0 and %', v_max using errcode = 'PT400'; end if;
  if char_length(v_feedback) > 5000 then
    raise exception 'Feedback is too long (5000 characters maximum)' using errcode = 'PT400'; end if;

  update public.submissions
     set status = 'graded', score = p_score, feedback = nullif(v_feedback, ''),
         graded_at = now(), graded_by = v_uid, version = version + 1
   where id = p_submission_id returning * into v_sub;
  v_response := jsonb_build_object('submission_id', v_sub.id, 'version', v_sub.version, 'status', v_sub.status,
                                   'score', v_sub.score, 'feedback', v_sub.feedback, 'graded_at', v_sub.graded_at);
  insert into public.submission_events (submission_id, assignment_id, actor_id, action, score, feedback, version_after, request_id, response)
  values (v_sub.id, v_sub.assignment_id, v_uid, 'graded', p_score, v_feedback, v_sub.version, p_request_id, v_response);
  return v_response;
end $$;

create function public.return_submission(
  p_submission_id uuid, p_request_id uuid, p_expected_version integer, p_feedback text
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := (select auth.uid());
  v_sub public.submissions;
  v_ev public.submission_events;
  v_feedback text := btrim(coalesce(p_feedback, ''));
  v_response jsonb;
begin
  if v_uid is null then raise exception 'Not authenticated' using errcode = 'PT401'; end if;
  if p_request_id is null then raise exception 'Request id required' using errcode = 'PT400'; end if;
  select s.* into v_sub
    from public.submissions s join public.assignments a on a.id = s.assignment_id
    join public.courses c on c.id = a.course_id
   where s.id = p_submission_id and c.owner_id = v_uid for update of s;
  if not found then raise exception 'Submission not found' using errcode = 'PT404'; end if;

  select * into v_ev from public.submission_events where request_id = p_request_id;
  if found then
    if v_ev.actor_id <> v_uid or v_ev.submission_id <> p_submission_id or v_ev.action <> 'returned'
       or v_ev.feedback <> v_feedback then
      raise exception 'Request id was already used for different content' using errcode = 'PT409'; end if;
    return v_ev.response || jsonb_build_object('replayed', true);
  end if;

  if v_sub.version is distinct from p_expected_version then
    raise exception 'The submission changed; reload and try again' using errcode = 'PT409'; end if;
  if v_sub.status not in ('submitted', 'graded') then
    raise exception 'This submission is already returned' using errcode = 'PT409'; end if;
  if v_feedback = '' then
    raise exception 'Explain what to revise before returning the work' using errcode = 'PT400'; end if;
  if char_length(v_feedback) > 5000 then
    raise exception 'Feedback is too long (5000 characters maximum)' using errcode = 'PT400'; end if;

  update public.submissions
     set status = 'returned', score = null, feedback = v_feedback,
         graded_at = now(), graded_by = v_uid, version = version + 1
   where id = p_submission_id returning * into v_sub;
  v_response := jsonb_build_object('submission_id', v_sub.id, 'version', v_sub.version, 'status', v_sub.status,
                                   'score', null, 'feedback', v_sub.feedback, 'graded_at', v_sub.graded_at);
  insert into public.submission_events (submission_id, assignment_id, actor_id, action, score, feedback, version_after, request_id, response)
  values (v_sub.id, v_sub.assignment_id, v_uid, 'returned', null, v_feedback, v_sub.version, p_request_id, v_response);
  return v_response;
end $$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'public.grade_submission(uuid, uuid, integer, integer, text)',
    'public.return_submission(uuid, uuid, integer, text)'] loop
    execute format('revoke all on function %s from public, anon, authenticated, service_role', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- max_score is locked once students have submitted ----------------------------------------------
create or replace function public.update_assignment(
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
  if p_max_score is not null and p_max_score <> v_a.max_score
     and exists (select 1 from public.submissions where assignment_id = p_assignment_id) then
    raise exception 'The maximum score cannot change once students have submitted' using errcode = 'PT409'; end if;
  update public.assignments
     set title = coalesce(btrim(p_title), title),
         instructions = coalesce(p_instructions, instructions),
         max_score = coalesce(p_max_score, max_score),
         due_at = case when p_clear_due then null else coalesce(p_due_at, due_at) end,
         version = version + 1
   where id = p_assignment_id returning * into v_a;
  return jsonb_build_object('id', v_a.id, 'version', v_a.version, 'status', v_a.status);
end $$;

-- Upload tickets: a returned submission may be revised after the deadline -----------------------
create or replace function public.prepare_submission_upload(
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
  if v_a.due_at is not null and now() > v_a.due_at
     and not exists (select 1 from public.submissions s
                      where s.assignment_id = p_assignment_id and s.student_id = v_uid and s.status = 'returned') then
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

-- submit_assignment: returned work can be revised (even after the deadline); graded work is locked;
-- a resubmission clears the current score and feedback (the history table keeps them) ---------------
create or replace function public.submit_assignment(
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
  v_exists boolean;
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
  if char_length(coalesce(p_answer, '')) > 20000 then
    raise exception 'Answer is too long' using errcode = 'PT400'; end if;
  if p_upload_id is not null and coalesce(p_clear_attachment, false) then
    raise exception 'Choose either a new attachment or removal' using errcode = 'PT400'; end if;

  select * into v_sub from public.submissions
   where assignment_id = p_assignment_id and student_id = v_uid for update;
  v_exists := found;
  if v_a.due_at is not null and now() > v_a.due_at and not (v_exists and v_sub.status = 'returned') then
    raise exception 'The deadline has passed' using errcode = 'PT409'; end if;
  if v_exists then
    if v_sub.version is distinct from p_expected_version then
      raise exception 'Your submission changed elsewhere; reload and retry' using errcode = 'PT409'; end if;
    if v_sub.status = 'graded' then
      raise exception 'This submission has been graded and can no longer be changed' using errcode = 'PT409'; end if;
  elsif p_expected_version is not null and p_expected_version <> 0 then
    raise exception 'Your submission changed elsewhere; reload and retry' using errcode = 'PT409';
  end if;

  v_upload_id := case when v_exists and not coalesce(p_clear_attachment, false) then v_sub.upload_id
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

  if not v_exists then
    begin
      insert into public.submissions (assignment_id, student_id, answer, upload_id)
      values (p_assignment_id, v_uid, coalesce(p_answer, ''), v_upload_id) returning * into v_sub;
    exception when unique_violation then
      raise exception 'Your submission changed elsewhere; reload and retry' using errcode = 'PT409';
    end;
  else
    update public.submissions
       set answer = coalesce(p_answer, ''), upload_id = v_upload_id, version = version + 1, submitted_at = now(),
           status = 'submitted', score = null, feedback = null, graded_at = null, graded_by = null
     where id = v_sub.id returning * into v_sub;
  end if;

  v_response := jsonb_build_object(
    'submission_id', v_sub.id, 'version', v_sub.version, 'status', v_sub.status,
    'submitted_at', v_sub.submitted_at, 'answer', v_sub.answer, 'upload_id', v_sub.upload_id);
  update public.submission_requests set response = v_response where request_id = p_request_id;
  return v_response;
end $$;

notify pgrst, 'reload schema';
