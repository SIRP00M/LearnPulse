import { useMemo } from 'react';
import { Link } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import type { ColumnDef } from '@tanstack/react-table';
import { useAuth } from '../auth/AuthProvider';
import { q } from '../lib/queries';
import { v9 } from '../lib/api/v9';
import { windowFor, addDays, startOfDay, formatInstant, percent, ymd, fmtNumber } from '../lib/dates';
import { Frame, PageHead, Query, Stat, EmptyState, LinkButton, ProgressBar, Chip, Banner } from '../ui/kit';
import { TaskChip } from '../ui/status';
import { DataTable } from '../ui/DataTable';
import { taskTarget } from '../lib/links';
import type { Deadline, TaskItem } from '../lib/schemas';

function Deadlines({ items }: { items: Deadline[] }) {
  const { t } = useTranslation('dashboard');
  if (items.length === 0) return <EmptyState icon="event_available" title={t('noDeadlines')}>{t('noDeadlinesText')}</EmptyState>;
  return (
    <ul className="list">
      {items.map((d, i) => (
        <li key={i}>
          <div className="grow"><strong>{d.title}</strong><div className="muted small">{t('deadlineLine', { course: d.course_title, when: formatInstant(d.due_at) })}</div></div>
          {d.expected != null && <Chip icon="inbox">{t('receivedOf', { received: fmtNumber(d.received ?? 0), expected: fmtNumber(d.expected) })}</Chip>}
          {d.status && <TaskChip status={d.status} />}
        </li>
      ))}
    </ul>
  );
}

export function TodayList() {
  const { t } = useTranslation(['dashboard', 'tasks']);
  const win = useMemo(() => { const s = startOfDay(new Date()); return windowFor(s, addDays(s, 1)); }, []);
  const { profile } = useAuth();
  const today = useQuery({ queryKey: ['tasks', 'today', ymd(win.from)], queryFn: () => v9.myTasks('range', win) });
  return (
    <Frame title={t('dashboard:today')} actions={<LinkButton to="/tasks" variant="text">{t('dashboard:openTasks')}</LinkButton>}>
      <Query q={today} rows={3}>
        {(d) => d.items.length === 0 ? (
          <EmptyState icon="celebration" title={t('dashboard:nothingDueToday')}>{t('dashboard:caughtUp')}</EmptyState>
        ) : (
          <ul className="list" style={{ margin: '-16px' }}>
            {d.items.map((i: TaskItem) => {
              const tg = taskTarget(i.kind, i.course_id, i.id, profile?.role ?? 'student', i.occurrence_date);
              return (
                <li key={`${i.kind}-${i.id}-${i.key2 ?? ''}`}>
                  <Link className="item" to={tg.to} params={tg.params} search={tg.search}><strong>{i.title}</strong><div className="muted small">{i.course_title} · {t(`tasks:kind.${i.kind}`)}</div></Link>
                  <TaskChip status={i.status} />
                </li>
              );
            })}
          </ul>
        )}
      </Query>
    </Frame>
  );
}

function StudentDashboardView() {
  const { t } = useTranslation('dashboard');
  const d = useQuery(q.studentDashboard());
  return (
    <>
      <PageHead title={t('title')} sub={t('studentSub')} />
      <Query q={d}>
        {(s) => (
          <div className="stack">
            <div className="stats">
              <Stat value={fmtNumber(s.courses_active)} label={t('activeCourses')} />
              <Stat value={t('ofTotal', { done: fmtNumber(s.done), total: fmtNumber(s.published_assignments) })} label={t('assignmentsSubmitted')} />
              <Stat value={fmtNumber(s.needs_revision)} label={t('needRevision')} tone={s.needs_revision ? 'err' : undefined} />
              <Stat value={fmtNumber(s.overdue)} label={t('overdue')} tone={s.overdue ? 'err' : undefined} />
              <Stat value={percent(s.average_percent)} label={t('averageScore')} />
              <Stat value={percent(s.attendance_rate)} label={t('attendance')} />
            </div>
            <div className="cols">
              <div className="c6"><TodayList /></div>
              <div className="c6"><Frame title={t('upcomingDeadlines')} flush><Deadlines items={s.upcoming_deadlines} /></Frame></div>
              <div className="c6">
                <Frame title={t('recentlyGraded')} flush>
                  {s.recent_graded.length === 0 ? <EmptyState icon="grade" title={t('nothingGraded')} /> : (
                    <ul className="list">{s.recent_graded.map((g, i) => <li key={i}><div className="grow"><strong>{g.title}</strong><div className="muted small">{g.course_title}</div></div>
                      <Chip tone="ok" icon="grade">{fmtNumber(g.score ?? 0)}/{fmtNumber(g.max_score ?? 0)}</Chip>{g.has_feedback && <Chip icon="chat">{t('feedback')}</Chip>}</li>)}</ul>
                  )}
                </Frame>
              </div>
              <div className="c6">
                <Frame title={t('yourCourses')} flush>
                  {s.courses.length === 0 ? <EmptyState icon="school" title={t('noCoursesYet')} action={<LinkButton to="/courses" variant="primary">{t('joinCourse')}</LinkButton>}>{t('askCode')}</EmptyState> : (
                    <ul className="list">{s.courses.map((c, i) => <li key={i}><div className="grow"><strong>{c.title}</strong><div className="muted small">{t('courseLine', { teacher: c.teacher_name, done: fmtNumber(c.done), total: fmtNumber(c.assignments) })}</div>
                      <ProgressBar value={c.progress_percent} label={t('progressOf', { title: c.title })} /></div></li>)}</ul>
                  )}
                </Frame>
              </div>
            </div>
          </div>
        )}
      </Query>
    </>
  );
}

type CourseRow = { course_id: string; title: string; status?: string | null; students: number; assignments: number; awaiting_grading: number; attendance_sessions: number };

function TeacherDashboardView() {
  const { t } = useTranslation(['dashboard', 'status']);
  const d = useQuery(q.teacherDashboard());
  const pend = useQuery(q.pending());
  const cols: ColumnDef<CourseRow, unknown>[] = [
    { id: 'title', header: t('dashboard:colCourse'), accessorKey: 'title', cell: (c) => <Link to="/courses/$courseId" params={{ courseId: c.row.original.course_id }}><strong>{c.row.original.title}</strong></Link> },
    { accessorKey: 'students', header: t('dashboard:colStudents') },
    { accessorKey: 'assignments', header: t('dashboard:colAssignments') },
    { accessorKey: 'awaiting_grading', header: t('dashboard:colToGrade'), cell: (c) => (c.getValue() as number) > 0 ? <Chip tone="warn" icon="rate_review">{fmtNumber(c.getValue() as number)}</Chip> : fmtNumber(0) },
    { accessorKey: 'attendance_sessions', header: t('dashboard:colSessions') },
    { accessorKey: 'status', header: t('dashboard:colStatus'), cell: (c) => <Chip icon={c.getValue() === 'archived' ? 'archive' : 'check'}>{c.getValue() === 'archived' ? t('status:course.archived') : t('status:course.active')}</Chip> },
  ];
  return (
    <>
      <PageHead title={t('dashboard:title')} sub={t('dashboard:teacherSub')} actions={<LinkButton to="/courses" variant="primary" icon="add">{t('dashboard:newCourse')}</LinkButton>} />
      <Query q={d}>
        {(s) => (
          <div className="stack">
            <div className="stats">
              <Stat value={fmtNumber(s.courses_active)} label={t('dashboard:activeCourses')} />
              <Stat value={fmtNumber(s.active_students)} label={t('dashboard:students')} />
              <Stat value={fmtNumber(s.awaiting_grading)} label={t('dashboard:awaitingGrading')} tone={s.awaiting_grading ? 'err' : undefined} />
              <Stat value={pend.data ? fmtNumber(pend.data.items.length) + (pend.data.capped ? '+' : '') : '…'} label={t('dashboard:toVerify')} />
              <Stat value={t('dashboard:ofTotal', { done: fmtNumber(s.received_submissions), total: fmtNumber(s.expected_submissions) })} label={t('dashboard:submissionsReceived')} />
              <Stat value={percent(s.attendance_rate)} label={t('dashboard:attendance')} />
            </div>
            {(pend.data?.items.length ?? 0) > 0 && <Banner tone="warn" icon="fact_check">{t('dashboard:verifyBanner', { count: pend.data!.items.length })} <Link to="/verification">{t('dashboard:reviewThem')}</Link></Banner>}
            <Frame title={t('dashboard:courses')} flush>
              <DataTable<CourseRow> caption={t('dashboard:courses')} data={s.courses} columns={cols} filterLabel={t('dashboard:filterCourses')} getRowId={(r) => r.course_id}
                empty={<EmptyState icon="school" title={t('dashboard:noCoursesYet')} action={<LinkButton to="/courses" variant="primary">{t('dashboard:createCourse')}</LinkButton>} />} />
            </Frame>
            <div className="cols">
              <div className="c6"><Frame title={t('dashboard:upcomingDeadlines')} flush><Deadlines items={s.upcoming_deadlines} /></Frame></div>
              <div className="c6">
                <Frame title={t('dashboard:recentActivity')} flush>
                  {s.recent_activity.length === 0 ? <EmptyState icon="history" title={t('dashboard:noRecent')} /> : (
                    <ul className="list">{s.recent_activity.map((a, i) => <li key={i}><div className="grow"><strong>{a.student_name}</strong><div className="muted small">{a.assignment_title} · {a.course_title} · {formatInstant(a.at)}</div></div>{a.status && <TaskChip status={a.status === 'submitted' ? 'awaiting_review' : a.status === 'returned' ? 'needs_revision' : a.status} />}</li>)}</ul>
                  )}
                </Frame>
              </div>
            </div>
          </div>
        )}
      </Query>
    </>
  );
}

export function DashboardPage() {
  const { profile } = useAuth();
  return profile?.role === 'teacher' ? <TeacherDashboardView /> : <StudentDashboardView />;
}
