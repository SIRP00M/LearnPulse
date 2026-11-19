import { useRef, useState } from 'react';
import { useParams } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/AuthProvider';
import { api, checkUpload, ALLOWED_UPLOADS } from '../lib/api/core';
import { q } from '../lib/queries';
import { useAction } from '../lib/hooks';
import { errorText, toAppError } from '../lib/errors';
import { fmtNumber } from '../lib/dates';
import { validateTitle } from '../lib/validators';
import { Banner, Button, Chip, EmptyState, ErrorState, Frame, FormError, Icon, Modal, Query, TextArea, TextField, useToast } from '../ui/kit';
import { tr } from '../i18n';
import type { Lesson, Resource } from '../lib/schemas';

/** Opens a short-lived signed URL in a new tab; the tab is opened synchronously so popup blockers allow it. */
export async function openSigned(getUrl: () => Promise<string>) {
  const w = window.open('about:blank', '_blank');
  try {
    const url = await getUrl();
    if (w) { w.opener = null; w.location.href = url; } else window.location.assign(url);
  } catch (e) {
    w?.close();
    throw toAppError(e);
  }
}

export const fileSize = (n?: number | null) => (n == null ? '' : n < 1024 * 1024 ? `${fmtNumber(Math.max(1, Math.round(n / 1024)))} KB` : `${fmtNumber(n / 1024 / 1024, { maximumFractionDigits: 1, minimumFractionDigits: 1 })} MB`);
export const ACCEPT = Object.keys(ALLOWED_UPLOADS).map((e) => `.${e}`).join(',');

export function FileLink({ name, size, path, source }: { name: string; size?: number | null; path: string; source: 'course' | 'submission' }) {
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  return (
    <Button variant="outline" size="sm" icon="attach_file" busy={busy}
      onClick={async () => {
        setBusy(true);
        try { await openSigned(() => (source === 'course' ? api.resourceUrl(path) : api.submissionUrl(path))); } catch (e) { toast(errorText(toAppError(e)), true); } finally { setBusy(false); }
      }}>{name}{size ? ` · ${fileSize(size)}` : ''}</Button>
  );
}

function LessonForm({ courseId, lesson, open, onClose }: { courseId: string; lesson?: Lesson; open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['lessons', 'common']);
  const [title, setTitle] = useState(lesson?.title ?? '');
  const [body, setBody] = useState(lesson?.body ?? '');
  const [err, setErr] = useState<string | null>(null);
  const a = useAction(async (_id: string, ti: string, b: string) => {
    if (lesson) await api.updateLesson(lesson.id, lesson.version, { title: ti.trim(), body: b });
    else await api.createLesson(courseId, ti.trim(), b);
  }, { topics: ['lessons', 'dashboard'], success: lesson ? t('lessons:saved') : t('lessons:createdDraft'), onDone: () => { if (!lesson) { setTitle(''); setBody(''); } onClose(); } });
  return (
    <Modal open={open} onClose={onClose} title={lesson ? t('lessons:editLesson') : t('lessons:newLesson')}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); const v = validateTitle(title); setErr(v); if (!v) void a.run(title, body); }}>
        <TextField label={t('lessons:title')} value={title} onChange={(e) => setTitle(e.target.value)} error={err} autoFocus />
        <TextArea label={t('lessons:lessonText')} value={body} onChange={(e) => setBody(e.target.value)} style={{ minHeight: 180 }} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('common:save')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function ResourceUpload({ lesson }: { lesson: Lesson }) {
  const { t } = useTranslation(['lessons', 'common']);
  const input = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const a = useAction(async (_id: string, f: File) => api.addResource(lesson.id, f, f.name), {
    topics: ['lessons'], success: t('lessons:attached'), onDone: () => { setFile(null); if (input.current) input.current.value = ''; },
  });
  return (
    <div className="stack-s">
      <div className="row">
        <input ref={input} type="file" accept={ACCEPT} aria-label={t('lessons:attachLabel', { title: lesson.title })}
          onChange={(e) => { const f = e.target.files?.[0] ?? null; const bad = f ? checkUpload(f) : null; setErr(bad); setFile(bad ? null : f); }} />
        <Button size="sm" icon="upload" disabled={!file} busy={a.busy} onClick={() => file && void a.run(file)}>{t('lessons:upload')}</Button>
      </div>
      {err && <span className="err-text" role="alert">{tr(err)}</span>}
      <FormError error={a.error} />
      <span className="hint">{t('common:uploadHint')}</span>
    </div>
  );
}

function LessonCard({ lesson, resources, teacher, courseId }: { lesson: Lesson; resources: Resource[]; teacher: boolean; courseId: string }) {
  const { t } = useTranslation(['lessons', 'common', 'status']);
  const [edit, setEdit] = useState(false);
  const [confirm, setConfirm] = useState(false);
  const pub = useAction((_id: string) => api.setLessonStatus(lesson.id, lesson.version, lesson.status !== 'published'), {
    topics: ['lessons', 'dashboard'], success: lesson.status === 'published' ? t('lessons:unpublished') : t('lessons:published'),
  });
  const del = useAction((_id: string) => api.deleteLesson(lesson.id, lesson.version), { topics: ['lessons'], success: t('lessons:deleted'), onDone: () => setConfirm(false) });
  const rmRes = useAction((_id: string, id: string) => api.deleteResource(id), { topics: ['lessons'], success: t('lessons:removed') });
  return (
    <Frame title={<>{lesson.title} {teacher && <Chip tone={lesson.status === 'published' ? 'ok' : 'neutral'} icon={lesson.status === 'published' ? 'public' : 'edit_note'}>{lesson.status === 'published' ? t('status:task.published') : t('status:task.draft')}</Chip>}</>}
      actions={teacher && (<>
        <Button size="sm" variant="outline" icon="edit" onClick={() => setEdit(true)}>{t('common:edit')}</Button>
        <Button size="sm" variant="tonal" icon={lesson.status === 'published' ? 'visibility_off' : 'publish'} busy={pub.busy} onClick={() => void pub.run()}>{lesson.status === 'published' ? t('lessons:unpublish') : t('lessons:publish')}</Button>
        <Button size="sm" variant="text" icon="delete" onClick={() => setConfirm(true)}>{t('common:delete')}</Button>
      </>)}>
      <div className="stack">
        {lesson.body ? <p className="pre">{lesson.body}</p> : <p className="muted">{t('lessons:noText')}</p>}
        <FormError error={pub.error ?? rmRes.error} />
        {resources.length > 0 && (
          <div className="stack-s"><strong>{t('lessons:files')}</strong>
            <div className="row">{resources.map((r) => (
              <span className="row" key={r.id}>
                <FileLink name={r.title || r.file_name} size={r.size_bytes} path={r.storage_path} source="course" />
                {teacher && <Button size="sm" variant="text" icon="close" aria-label={t('lessons:removeFile', { name: r.title || r.file_name })} onClick={() => void rmRes.run(r.id)} />}
              </span>))}
            </div>
          </div>
        )}
        {teacher && <ResourceUpload lesson={lesson} />}
      </div>
      {teacher && <LessonForm courseId={courseId} lesson={lesson} open={edit} onClose={() => setEdit(false)} />}
      <Modal open={confirm} onClose={() => setConfirm(false)} title={t('lessons:deleteTitle')} description={t('lessons:deleteDesc')}>
        <FormError error={del.error} />
        <div className="row"><Button variant="danger" busy={del.busy} onClick={() => void del.run()}>{t('lessons:deleteLesson')}</Button><Button variant="text" onClick={() => setConfirm(false)}>{t('common:cancel')}</Button></div>
      </Modal>
    </Frame>
  );
}

export function LessonsPage() {
  const { t } = useTranslation(['lessons', 'common']);
  const { courseId } = useParams({ strict: false }) as { courseId: string };
  const { profile } = useAuth();
  const teacher = profile?.role === 'teacher';
  const lessons = useQuery(q.lessons(courseId));
  const resources = useQuery(q.resources(courseId));
  const [create, setCreate] = useState(false);
  if (lessons.isError) return <ErrorState error={lessons.error} onRetry={() => void lessons.refetch()} />;
  return (
    <div className="stack">
      {teacher && <div><Button icon="add" onClick={() => setCreate(true)}>{t('lessons:newLesson')}</Button></div>}
      {resources.isError && <Banner tone="warn">{t('lessons:filesFailed')} <Button size="sm" variant="text" onClick={() => void resources.refetch()}>{t('common:retry')}</Button></Banner>}
      <Query q={lessons}>
        {(rows) => rows.length === 0
          ? <Frame><EmptyState icon="menu_book" title={t('lessons:empty')}>{teacher ? t('lessons:emptyTeacher') : t('lessons:emptyStudent')}</EmptyState></Frame>
          : <>{rows.map((l) => <LessonCard key={l.id} lesson={l} teacher={teacher} courseId={courseId} resources={(resources.data ?? []).filter((r) => r.lesson_id === l.id && r.status === 'attached')} />)}</>}
      </Query>
      {teacher && <LessonForm courseId={courseId} open={create} onClose={() => setCreate(false)} />}
      <span className="sr-only"><Icon name="menu_book" /></span>
    </div>
  );
}
