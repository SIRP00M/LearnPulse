-- Run only on approved DEV. Every fixture and helper is rolled back.
BEGIN;
CREATE TEMP TABLE test_results(label text PRIMARY KEY);
GRANT INSERT,SELECT ON test_results TO authenticated,anon;
CREATE FUNCTION pg_temp.check_test(ok boolean,label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
 IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 INSERT INTO test_results VALUES(label);
END $$;
CREATE FUNCTION pg_temp.expect_error(command text,expected_state text,label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE caught text;
BEGIN
 BEGIN EXECUTE command;
 EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS caught=RETURNED_SQLSTATE;
 END;
 PERFORM pg_temp.check_test(caught=expected_state,label);
END $$;
DO $test$
DECLARE
 ta uuid:=gen_random_uuid(); tb uuid:=gen_random_uuid();
 sa uuid:=gen_random_uuid(); sb uuid:=gen_random_uuid();
 ca uuid:=gen_random_uuid(); cb uuid:=gen_random_uuid();
 ap uuid:=gen_random_uuid(); ad uuid:=gen_random_uuid(); af uuid:=gen_random_uuid();
 lp uuid:=gen_random_uuid(); ld uuid:=gen_random_uuid(); lf uuid:=gen_random_uuid();
 p uuid; stamp timestamptz; f text; js jsonb; first_result jsonb; sid uuid;
 rid uuid:=gen_random_uuid(); att uuid; attendance jsonb;
BEGIN
 INSERT INTO auth.users(id,raw_user_meta_data)
 SELECT v,jsonb_build_object('full_name','Rollback security fixture','role','student')
 FROM unnest(ARRAY[ta,tb,sa,sb]) v;
 UPDATE public.profiles SET role='teacher' WHERE id IN (ta,tb);
 INSERT INTO public.courses(id,teacher_id,title,status) VALUES
 (ca,ta,'Rollback A','published'),(cb,tb,'Rollback B','published');
 INSERT INTO public.course_members(course_id,student_id,joined_at) VALUES
 (ca,sa,now()-interval '1 day'),(cb,sb,now()-interval '1 day');
 INSERT INTO public.lessons(id,course_id,title,published_at) VALUES
 (lp,ca,'Published',now()-interval '1 hour'),(ld,ca,'Draft',NULL),(lf,ca,'Future',now()+interval '1 day');
 INSERT INTO public.assignments(id,course_id,title,published_at,due_at) VALUES
 (ap,ca,'Published',now()-interval '1 hour',now()+interval '1 day'),
 (ad,ca,'Draft',NULL,now()+interval '1 day'),
 (af,ca,'Future',now()+interval '1 day',now()+interval '2 days');
 INSERT INTO public.course_posts(course_id,author_id,title,content,published_at) VALUES
 (ca,ta,'Published','Published',now()-interval '1 hour'),(ca,ta,'Draft','Draft',NULL),
 (ca,ta,'Future','Future',now()+interval '1 day');
 INSERT INTO public.course_files(course_id,uploaded_by,file_name,storage_path,lesson_id,assignment_id)
 VALUES
 (ca,ta,'general.pdf',ca||'/general.pdf',NULL,NULL),
 (ca,ta,'published.pdf',ca||'/published.pdf',lp,ap),
 (ca,ta,'draft-lesson.pdf',ca||'/draft-lesson.pdf',ld,ap),
 (ca,ta,'future-lesson.pdf',ca||'/future-lesson.pdf',lf,ap),
 (ca,ta,'draft-work.pdf',ca||'/draft-work.pdf',lp,ad),
 (ca,ta,'future-work.pdf',ca||'/future-work.pdf',lp,af);
 INSERT INTO public.attendance_sessions(course_id,created_by,title,starts_at,ends_at,check_in_code)
 VALUES(ca,ta,'Rollback attendance',now()-interval '1 minute',now()+interval '1 hour',gen_random_uuid()::text) RETURNING id INTO att;
 -- Database rows only: no object bytes or Storage HTTP requests.
 INSERT INTO storage.objects(bucket_id,name)
 SELECT 'course-files',ca||'/'||v FROM unnest(ARRAY[
 'general.pdf','published.pdf','draft-lesson.pdf','future-lesson.pdf',
 'draft-work.pdf','future-work.pdf','pending-upload.pdf']) v;

 EXECUTE 'SET LOCAL ROLE authenticated';
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',sa,'role','authenticated')::text,true);
 PERFORM pg_temp.check_test((SELECT count(*)=1 FROM public.course_posts WHERE course_id=ca),'student posts publication');
 PERFORM pg_temp.check_test((SELECT count(*)=1 FROM public.lessons WHERE course_id=ca),'student lessons publication');
 PERFORM pg_temp.check_test((SELECT count(*)=1 FROM public.assignments WHERE course_id=ca),'student assignments publication');
 PERFORM pg_temp.check_test((SELECT count(*)=2 FROM public.course_files WHERE course_id=ca),'student linked file metadata');
 PERFORM pg_temp.check_test((SELECT count(*)=2 FROM storage.objects WHERE bucket_id='course-files' AND name LIKE ca||'/%'),'student linked storage rows');
 js:=public.get_learning_snapshot(ca);
 PERFORM pg_temp.check_test(jsonb_array_length(js->'students')=1 AND jsonb_array_length(js->'assignments')=1,'student scoped snapshot');
 PERFORM pg_temp.expect_error(format('SELECT public.get_learning_snapshot(%L,%L)',ca,sb),'42501','student cannot request another student');
 FOREACH f IN ARRAY ARRAY['report.pdf','REPORT.PDF','work.docx','archive.zip','photo.png','photo.jpg','photo.jpeg','photo.webp','answer.txt'] LOOP
  js:=public.prepare_submission_upload(ap,f);
  PERFORM pg_temp.check_test(js->>'file_name'=f AND js->>'path' LIKE sa||'/'||ap||'/%','prepare accepts '||f);
 END LOOP;
 PERFORM pg_temp.expect_error(format('SELECT public.prepare_submission_upload(%L,%L)',ap,'report.exe'),'22023','reject unsupported extension');
 PERFORM pg_temp.expect_error(format('SELECT public.prepare_submission_upload(%L,%L)',ad,'report.pdf'),'42501','reject draft upload');
 PERFORM pg_temp.expect_error(format('SELECT public.prepare_submission_upload(%L,%L)',af,'report.pdf'),'42501','reject future upload');
 first_result:=public.submit_assignment(ap,'First answer',NULL,0,rid); sid:=(first_result->>'id')::uuid;
 js:=public.submit_assignment(ap,'First answer',NULL,0,rid);
 PERFORM pg_temp.check_test(js=first_result,'idempotent submission replay');
 PERFORM pg_temp.check_test((SELECT count(*)=1 FROM public.submissions WHERE assignment_id=ap AND student_id=sa),'one submitted row');
 PERFORM pg_temp.expect_error(format('SELECT public.submit_assignment(%L,%L,NULL,0,%L)',ap,'Changed answer',rid),'22023','reject request key reuse');
 PERFORM pg_temp.expect_error(format('SELECT public.submit_assignment(%L,%L,NULL,0,%L)',ap,'Stale answer',gen_random_uuid()),'PT409','reject stale submission version');
 PERFORM pg_temp.expect_error(format('SELECT public.review_submission(%L,1,90,%L,false)',sid,'Forged grade'),'42501','student cannot grade');

 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',sb,'role','authenticated')::text,true);
 PERFORM pg_temp.check_test((SELECT count(*)=0 FROM public.course_files WHERE course_id=ca),'cross tenant metadata denied');
 PERFORM pg_temp.check_test((SELECT count(*)=0 FROM storage.objects WHERE bucket_id='course-files' AND name LIKE ca||'/%'),'cross tenant storage denied');
 PERFORM pg_temp.check_test((SELECT count(*)=0 FROM public.submissions WHERE id=sid),'cross student submission denied');
 PERFORM pg_temp.expect_error(format('SELECT public.get_learning_snapshot(%L)',ca),'42501','cross student snapshot denied');
 PERFORM pg_temp.expect_error(format('SELECT public.prepare_submission_upload(%L,%L)',ap,'report.pdf'),'42501','cross student upload denied');
 PERFORM pg_temp.expect_error(format('SELECT public.submit_assignment(%L,%L,NULL,0,%L)',ap,'Forged',gen_random_uuid()),'42501','cross student submit denied');

 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',tb,'role','authenticated')::text,true);
 PERFORM pg_temp.expect_error(format('SELECT public.get_learning_snapshot(%L)',ca),'42501','cross teacher snapshot denied');
 PERFORM pg_temp.expect_error(format('SELECT public.review_submission(%L,1,90,%L,false)',sid,'Forged'),'42501','cross teacher review denied');

 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',ta,'role','authenticated')::text,true);
 PERFORM pg_temp.check_test((SELECT count(*)=3 FROM public.lessons WHERE course_id=ca),'teacher keeps draft lesson reads');
 PERFORM pg_temp.check_test((SELECT count(*)=3 FROM public.assignments WHERE course_id=ca),'teacher keeps draft assignment reads');
 PERFORM pg_temp.check_test((SELECT count(*)=3 FROM public.course_posts WHERE course_id=ca),'teacher keeps draft post reads');
 PERFORM pg_temp.check_test((SELECT count(*)=6 FROM public.course_files WHERE course_id=ca),'teacher keeps draft metadata reads');
 PERFORM pg_temp.check_test((SELECT count(*)=7 FROM storage.objects WHERE bucket_id='course-files' AND name LIKE ca||'/%'),'teacher reads upload before metadata');
 js:=public.get_learning_snapshot(ca);
 PERFORM pg_temp.check_test(js->>'teacher'='true' AND jsonb_array_length(js->'students')=1,'teacher snapshot');
 attendance:=public.mark_learning_attendance(att,sa,'present','Verified fixture',NULL);
 PERFORM pg_temp.check_test(attendance->>'status'='present','teacher marks attendance');
 PERFORM pg_temp.expect_error(format('SELECT public.mark_learning_attendance(%L,%L,%L,%L,NULL)',att,sa,'absent','Stale'),'PT409','reject stale attendance');
 js:=public.review_submission(sid,1,90,'Good work',false);
 PERFORM pg_temp.check_test(js->>'status'='graded' AND (js->>'version')::int=2,'teacher grades work');
 PERFORM pg_temp.expect_error(format('SELECT public.review_submission(%L,1,95,%L,false)',sid,'Stale'),'PT409','reject stale review');
 js:=public.review_submission(sid,2,NULL,'Please revise',true);
 PERFORM pg_temp.check_test(js->>'status'='returned' AND (js->>'version')::int=3,'teacher returns work');

 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',sa,'role','authenticated')::text,true);
 js:=public.submit_assignment(ap,'Revised answer',NULL,3,gen_random_uuid());
 PERFORM pg_temp.check_test(js->>'status'='submitted' AND (js->>'version')::int=4,'student resubmits returned work');
 EXECUTE 'RESET ROLE';
 UPDATE public.course_members SET status='removed' WHERE course_id=ca AND student_id=sa;
 EXECUTE 'SET LOCAL ROLE authenticated';
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',sa,'role','authenticated')::text,true);
 PERFORM pg_temp.check_test((SELECT count(*)=0 FROM public.submissions WHERE id=sid),'removed member own submission denied');
 PERFORM pg_temp.check_test((SELECT count(*)=0 FROM public.course_files WHERE course_id=ca),'removed member files denied');
 PERFORM pg_temp.check_test((SELECT count(*)=0 FROM storage.objects WHERE bucket_id='course-files' AND name LIKE ca||'/%'),'removed member storage denied');
 PERFORM pg_temp.expect_error(format('SELECT public.get_learning_snapshot(%L)',ca),'42501','removed member snapshot denied');
 PERFORM pg_temp.expect_error(format('SELECT public.prepare_submission_upload(%L,%L)',ap,'report.pdf'),'42501','removed member upload denied');

 EXECUTE 'RESET ROLE';
 PERFORM pg_temp.expect_error(format('SELECT public.submit_assignment(%L,%L,NULL,0,%L)',ap,'First answer',rid),'42501','removed member cached replay denied');
 PERFORM pg_temp.expect_error(format('SELECT public.submit_assignment(%L,%L,NULL,4,%L)',ap,'After removal',gen_random_uuid()),'42501','removed member fresh submit denied');
 EXECUTE 'SET LOCAL ROLE anon';
 PERFORM set_config('request.jwt.claims','{}',true);
 PERFORM pg_temp.expect_error(format('SELECT public.get_learning_snapshot(%L)',ca),'42501','anon snapshot denied');
 PERFORM pg_temp.expect_error(format('SELECT public.prepare_submission_upload(%L,%L)',ap,'report.pdf'),'42501','anon upload denied');
 PERFORM pg_temp.expect_error(format('SELECT public.submit_assignment(%L,%L,NULL,0,%L)',ap,'Anon',gen_random_uuid()),'42501','anon submit denied');
 EXECUTE 'RESET ROLE';
END $test$;
SELECT count(*) AS passed, array_agg(label ORDER BY label) AS checks FROM test_results;
ROLLBACK;


