import { useState } from 'react';
import { Link, Outlet, useNavigate, useParams, useRouterState } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import type { ColumnDef } from '@tanstack/react-table';
import { useAuth } from '../auth/AuthProvider';
import { api } from '../lib/api/core';
import { q, useCourse, useCourses } from '../lib/queries';
import { useAction } from '../lib/hooks';
import { formatInstant, percent } from '../lib/dates';
import { validateTitle } from '../lib/validators';
import { Avatar } from '../ui/Avatar';
import { Button, Chip, EmptyState, ErrorState, Frame, FormError, Icon, Modal, PageHead, Query, SkeletonBlock, TextArea, TextField, Banner, useToast } from '../ui/kit';
import { DataTable } from '../ui/DataTable';
import type { Course, RosterEntry } from '../lib/schemas';

function CreateCourse({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['courses', 'common']);
  const nav = useNavigate();
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const a = useAction((_id: string, ti: string, d: string) => api.createCourse(ti.trim(), d.trim()), {
    topics: ['courses', 'dashboard'], success: t('courses:created'),
    onDone: (c) => { setTitle(''); setDesc(''); onClose(); void nav({ to: '/courses/$courseId', params: { courseId: c.id } }); },
  });
  return (
    <Modal open={open} onClose={onClose} title={t('courses:newCourse')}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); const v = validateTitle(title, 120); setErr(v); if (!v) void a.run(title, desc); }}>
        <TextField label={t('courses:courseTitle')} value={title} onChange={(e) => setTitle(e.target.value)} error={err} autoFocus />
        <TextArea label={t('courses:descOptional')} value={desc} onChange={(e) => setDesc(e.target.value)} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('courses:createCourse')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function JoinCourse({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['courses', 'common']);
  const [code, setCode] = useState('');
  const [msg, setMsg] = useState<string | null>(null);
  const nav = useNavigate();
  const courses = useCourses();
  const a = useAction(async (_id: string, c: string) => api.joinByCode(c.trim()), {
    topics: ['courses', 'dashboard', 'tasks', 'progress'],
    onDone: async (r) => {
      if (r.joined === false || (!r.title && r.reason)) {
        setMsg(r.reason === 'removed' ? 'courses:codeRemoved' : 'courses:codeUnknown');
        return;
      }
      const fresh = await courses.refetch();
      setCode(''); setMsg(null); onClose();
      const c = fresh.data?.find((x) => x.title === r.title);
      if (c) void nav({ to: '/courses/$courseId', params: { courseId: c.id } });
    },
  });
  return (
    <Modal open={open} onClose={onClose} title={t('courses:joinTitle')} description={t('courses:joinDesc')}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); if (code.trim()) { setMsg(null); void a.run(code); } else setMsg('validation:codeRequired'); }}>
        <TextField label={t('courses:joinCodeLabel')} value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} autoFocus autoComplete="off" error={msg} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('courses:join')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

export function CoursesPage() {
  const { t } = useTranslation(['courses', 'status']);
  const { profile } = useAuth();
  const teacher = profile?.role === 'teacher';
  const courses = useQuery(q.courses());
  const [dlg, setDlg] = useState(false);
  const nav = useNavigate();
  const cols: ColumnDef<Course, unknown>[] = [
    { id: 'title', header: t('courses:colCourse'), accessorKey: 'title', cell: (c) => <Link to="/courses/$courseId" params={{ courseId: c.row.original.id }}><strong>{c.row.original.title}</strong></Link> },
    ...(teacher ? [] : [{ id: 'teacher', header: t('courses:colTeacher'), accessorFn: (r: Course) => r.owner?.full_name ?? '' } as ColumnDef<Course, unknown>]),
    { id: 'status', header: t('courses:colStatus'), accessorKey: 'status', cell: (c) => <Chip icon={c.getValue() === 'archived' ? 'archive' : 'check'}>{c.getValue() === 'archived' ? t('status:course.archived') : t('status:course.active')}</Chip> },
    { id: 'created', header: t('courses:colCreated'), accessorKey: 'created_at', cell: (c) => formatInstant(c.getValue() as string) },
  ];
  return (
    <>
      <PageHead title={t('courses:title')} sub={teacher ? t('courses:subTeacher') : t('courses:subStudent')}
        actions={teacher ? <Button icon="add" onClick={() => setDlg(true)}>{t('courses:newCourse')}</Button> : <Button icon="group_add" onClick={() => setDlg(true)}>{t('courses:joinCourse')}</Button>} />
      <Frame flush>
        <Query q={courses}>
          {(rows) => (
            <DataTable<Course> caption={t('courses:title')} data={rows} columns={cols} getRowId={(r) => r.id} filterLabel={t('courses:filter')} exportName={teacher ? 'courses' : undefined}
              onRowActivate={(r) => void nav({ to: '/courses/$courseId', params: { courseId: r.id } })}
              empty={<EmptyState icon="school" title={t('courses:noCourses')} action={<Button onClick={() => setDlg(true)}>{teacher ? t('courses:createFirst') : t('courses:joinCourse')}</Button>}>
                {teacher ? t('courses:createHint') : t('courses:askCode')}</EmptyState>} />
          )}
        </Query>
      </Frame>
      {teacher ? <CreateCourse open={dlg} onClose={() => setDlg(false)} /> : <JoinCourse open={dlg} onClose={() => setDlg(false)} />}
    </>
  );
}

export function CourseLayout() {
  const { t } = useTranslation(['courses', 'status']);
  const { courseId } = useParams({ strict: false }) as { courseId: string };
  const { profile } = useAuth();
  const { course, isPending, isError, error, refetch } = useCourse(courseId);
  const path = useRouterState({ select: (s) => s.location.pathname });
  if (isPending) return <SkeletonBlock rows={5} />;
  if (isError) return <ErrorState error={error} onRetry={() => void refetch()} />;
  if (!course) return <ErrorState error={{ code: 'PT404' }} />;
  const base = `/courses/${courseId}`;
  const teacher = profile?.role === 'teacher';
  const tabs = [
    { to: '/courses/$courseId', label: t('courses:tabOverview'), end: true },
    { to: '/courses/$courseId/lessons', label: t('courses:tabLessons') },
    { to: '/courses/$courseId/assignments', label: t('courses:tabAssignments') },
    { to: '/courses/$courseId/attendance', label: t('courses:tabAttendance') },
    { to: '/courses/$courseId/activities', label: t('courses:tabActivities') },
    teacher ? { to: '/courses/$courseId/people', label: t('courses:tabPeople') } : { to: '/courses/$courseId/progress', label: t('courses:tabProgress') },
  ];
  return (
    <>
      <PageHead title={course.title} sub={<>{course.owner?.full_name ? `${course.owner.full_name} · ` : ''}{course.status === 'archived' ? t('status:course.archived') : t('status:course.active')}</>}
        actions={<Link activeOptions={{ exact: true }} to="/courses" className="btn text"><Icon name="arrow_back" />{t('courses:allCourses')}</Link>} />
      <nav className="tabs" aria-label={t('courses:sections')}>
        {tabs.map((tab) => {
          const href = tab.to.replace('$courseId', courseId);
          const active = tab.end ? path === base : path === href || path.startsWith(href + '/');
          return <Link key={tab.to} to={tab.to} params={{ courseId }} activeOptions={{ exact: !!tab.end }} aria-current={active ? 'page' : undefined}>{tab.label}</Link>;
        })}
      </nav>
      <Outlet />
    </>
  );
}

export function CourseOverview() {
  const { t } = useTranslation(['courses', 'common']);
  const { courseId } = useParams({ strict: false }) as { courseId: string };
  const { profile } = useAuth();
  const { course } = useCourse(courseId);
  const teacher = profile?.role === 'teacher';
  const [edit, setEdit] = useState(false);
  if (!course) return null;
  return (
    <div className="cols">
      <div className="c8">
        <Frame title={t('courses:about')} actions={teacher && <Button variant="outline" size="sm" icon="edit" onClick={() => setEdit(true)}>{t('common:edit')}</Button>}>
          {course.description ? <p className="pre">{course.description}</p> : <p className="muted">{t('courses:noDescription')}</p>}
        </Frame>
      </div>
      <div className="c4">
        {teacher ? <TeacherCourseControls course={course} /> : (
          <Frame title={t('courses:yourProgress')}><p className="muted">{t('courses:yourProgressText')}</p>
            <div style={{ marginTop: 12 }}><Link activeOptions={{ exact: true }} className="btn tonal" to="/courses/$courseId/progress" params={{ courseId }}>{t('courses:openProgress')}</Link></div></Frame>
        )}
      </div>
      {teacher && <EditCourse course={course} open={edit} onClose={() => setEdit(false)} />}
    </div>
  );
}

function TeacherCourseControls({ course }: { course: Course }) {
  const { t } = useTranslation('courses');
  const [show, setShow] = useState(false);
  const toast = useToast();
  const code = useQuery({ ...q.joinCode(course.id), enabled: show });
  const archived = course.status === 'archived';
  const a = useAction((_id: string) => api.updateCourse(course.id, { status: archived ? 'active' : 'archived' }), {
    topics: ['courses', 'dashboard', 'tasks'], success: archived ? t('restored') : t('archivedToast'),
  });
  async function copy() {
    try { await navigator.clipboard.writeText(code.data ?? ''); toast(t('codeCopied')); } catch { toast(t('copyFailed'), true); }
  }
  return (
    <div className="stack">
      <Frame title={t('joinCodeTitle')}>
        <p className="muted small">{t('joinCodeText')}</p>
        {show ? (code.isPending ? <SkeletonBlock rows={1} /> : code.isError ? <ErrorState error={code.error} onRetry={() => void code.refetch()} /> : (
          <div className="row" style={{ marginTop: 8 }}>
            <code style={{ fontSize: 24, letterSpacing: 2 }} data-testid="join-code">{code.data}</code>
            <Button variant="outline" size="sm" icon="content_copy" onClick={() => void copy()}>{t('copy')}</Button>
          </div>
        )) : <div style={{ marginTop: 8 }}><Button variant="tonal" icon="visibility" onClick={() => setShow(true)}>{t('showJoinCode')}</Button></div>}
      </Frame>
      <Frame title={t('courseStatus')}>
        <p className="muted small">{archived ? t('archivedHelp') : t('archiveHelp')}</p>
        <FormError error={a.error} />
        <div style={{ marginTop: 8 }}><Button variant="outline" icon={archived ? 'unarchive' : 'archive'} busy={a.busy} onClick={() => void a.run()}>{archived ? t('restore') : t('archive')}</Button></div>
      </Frame>
    </div>
  );
}

function EditCourse({ course, open, onClose }: { course: Course; open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['courses', 'common']);
  const [title, setTitle] = useState(course.title);
  const [desc, setDesc] = useState(course.description ?? '');
  const [err, setErr] = useState<string | null>(null);
  const a = useAction((_id: string, ti: string, d: string) => api.updateCourse(course.id, { title: ti.trim(), description: d.trim() }), {
    topics: ['courses', 'dashboard', 'tasks'], success: t('courses:saved'), onDone: onClose,
  });
  return (
    <Modal open={open} onClose={onClose} title={t('courses:editCourse')}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); const v = validateTitle(title, 120); setErr(v); if (!v) void a.run(title, desc); }}>
        <TextField label={t('courses:courseTitle')} value={title} onChange={(e) => setTitle(e.target.value)} error={err} />
        <TextArea label={t('courses:description')} value={desc} onChange={(e) => setDesc(e.target.value)} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('common:save')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

export function PeoplePage() {
  const { t } = useTranslation(['courses', 'common', 'status']);
  const { courseId } = useParams({ strict: false }) as { courseId: string };
  const roster = useQuery(q.roster(courseId));
  const summary = useQuery(q.attendanceSummary(courseId));
  const [remove, setRemove] = useState<RosterEntry | null>(null);
  const nav = useNavigate();
  const rm = useAction((_id: string, sid: string) => api.removeMember(courseId, sid), {
    topics: ['roster', 'dashboard', 'attendance', 'activities', 'progress', 'tasks'], success: t('courses:removedToast'), onDone: () => setRemove(null),
  });
  type Row = RosterEntry & { name: string; rate: number | null };
  const rates = new Map((summary.data?.students ?? []).map((s) => [s.student_id, s.rate ?? null]));
  const cols: ColumnDef<Row, unknown>[] = [
    { id: 'name', header: t('courses:colStudent'), accessorKey: 'name', cell: (c) => <Link to="/courses/$courseId/people/$studentId" params={{ courseId, studentId: c.row.original.student_id }}><span className="row" style={{ flexWrap: 'nowrap' }}><Avatar userId={c.row.original.student_id} name={c.row.original.name} size={28} /><strong>{c.row.original.name}</strong></span></Link> },
    { id: 'status', header: t('courses:colStatus'), accessorKey: 'status', cell: (c) => <Chip icon={c.getValue() === 'active' ? 'check' : 'person_off'}>{c.getValue() === 'active' ? t('status:roster.active') : t('status:roster.removed')}</Chip> },
    { id: 'joined', header: t('courses:colJoined'), accessorKey: 'joined_at', cell: (c) => formatInstant(c.getValue() as string) },
    { id: 'rate', header: t('courses:colAttendance'), accessorKey: 'rate', cell: (c) => (c.getValue() == null ? '—' : percent(c.getValue() as number)) },
    { id: 'actions', header: '', enableSorting: false, cell: (c) => c.row.original.status === 'active' && <Button size="sm" variant="text" icon="person_remove" onClick={() => setRemove(c.row.original)}>{t('common:remove')}</Button> },
  ];
  return (
    <Frame title={t('courses:students')} flush>
      <Query q={roster}>
        {(rows) => (
          <DataTable<Row> caption={t('courses:students')} exportName="students" filterLabel={t('courses:students')} getRowId={(r) => r.student_id} columns={cols}
            data={rows.map((r) => ({ ...r, name: r.student?.full_name ?? t('common:student'), rate: rates.get(r.student_id) ?? null }))}
            onRowActivate={(r) => void nav({ to: '/courses/$courseId/people/$studentId', params: { courseId, studentId: r.student_id } })}
            empty={<EmptyState icon="group" title={t('courses:noStudents')}>{t('courses:noStudentsText')}</EmptyState>} />
        )}
      </Query>
      <Modal open={!!remove} onClose={() => setRemove(null)} title={t('courses:removeTitle')} description={t('courses:removeDesc')}>
        <Banner tone="warn">{t('courses:removeBanner', { name: remove?.student?.full_name ?? t('courses:thisStudent') })}</Banner>
        <FormError error={rm.error} />
        <div className="row"><Button variant="danger" icon="person_remove" busy={rm.busy} onClick={() => remove && void rm.run(remove.student_id)}>{t('courses:removeStudent')}</Button><Button variant="text" onClick={() => setRemove(null)}>{t('common:cancel')}</Button></div>
      </Modal>
    </Frame>
  );
}
