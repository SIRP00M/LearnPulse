import { Link, useParams } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { q } from '../lib/queries';
import { formatInstant, fmtNumber, percent } from '../lib/dates';
import { Banner, Chip, EmptyState, Frame, Icon, PageHead, Query, Stat } from '../ui/kit';
import { AttChip, TaskChip } from '../ui/status';
import { DataTable } from '../ui/DataTable';
import type { Progress, AttendanceStatus } from '../lib/schemas';

function ProgressView({ p, mine }: { p: Progress; mine: boolean }) {
  const { t } = useTranslation(['progress', 'status', 'common']);
  const a = p.attendance;
  const w = p.assignments;
  return (
    <div className="stack">
      <Banner icon="lock">{mine ? t('progress:privateMine') : t('progress:privateTeacher')}</Banner>
      <div className="stats">
        <Stat value={percent(a.rate)} label={t('progress:attendanceRate')} />
        <Stat value={t('common:countOf', { count: fmtNumber(w.done), max: fmtNumber(w.published) })} label={t('progress:submittedOf')} />
        <Stat value={fmtNumber(w.graded)} label={t('progress:graded')} />
        <Stat value={percent(w.average_percent)} label={t('progress:avgScore')} />
        <Stat value={fmtNumber(w.needs_revision)} label={t('progress:needRevision')} tone={w.needs_revision ? 'err' : undefined} />
        <Stat value={fmtNumber(w.overdue)} label={t('progress:overdue')} tone={w.overdue ? 'err' : undefined} />
      </div>
      <div className="cols">
        <div className="c6">
          <Frame title={t('progress:attendance')} flush>
            <div className="body">
              <div className="row">
                <Chip icon="check_circle" tone="ok">{t('progress:present', { count: fmtNumber(a.present) })}</Chip><Chip icon="schedule" tone="warn">{t('progress:late', { count: fmtNumber(a.late) })}</Chip>
                <Chip icon="event_available" tone="info">{t('progress:excused', { count: fmtNumber(a.excused) })}</Chip><Chip icon="cancel" tone="err">{t('progress:absent', { count: fmtNumber(a.absent) })}</Chip><Chip icon="remove">{t('progress:notMarked', { count: fmtNumber(a.unmarked) })}</Chip>
              </div>
              <p className="muted small" style={{ marginTop: 8 }}>{t('progress:sessionsClosed', { closed: fmtNumber(a.sessions_closed), total: fmtNumber(a.sessions_total) })}</p>
            </div>
            {a.recent.length === 0 ? <EmptyState icon="event_busy" title={t('progress:noSessions')} /> : (
              <ul className="list">{a.recent.map((s) => <li key={s.session_id}><div className="grow"><strong>{s.title}</strong><div className="muted small">{formatInstant(s.starts_at)}</div></div><AttChip status={s.status as AttendanceStatus | null} /></li>)}</ul>
            )}
          </Frame>
        </div>
        <div className="c6">
          <Frame title={t('progress:activities')} flush>
            {p.activities.activities.length === 0 ? <EmptyState icon="today" title={t('progress:noActivities')} /> : (
              <ul className="list">{p.activities.activities.map((x) => (
                <li key={x.activity_id}><div className="grow"><strong>{x.title}</strong><div className="muted small">{t(`status:policy.${x.policy}`)}{x.status === 'inactive' ? ` · ${t('progress:paused')}` : ''}</div></div>
                  {x.streak?.current == null ? <span className="muted small">{t('progress:noStreakDeadline')}</span>
                    : <Chip tone={x.streak.current > 0 ? 'ok' : 'neutral'} icon="local_fire_department">{t('progress:streak', { current: fmtNumber(x.streak.current), best: fmtNumber(x.streak.best ?? 0) })}</Chip>}</li>))}</ul>
            )}
            {p.activities.pending_verification > 0 && <div className="body"><Chip tone="warn" icon="hourglass_top">{t('progress:awaitingReview', { count: fmtNumber(p.activities.pending_verification) })}</Chip></div>}
          </Frame>
        </div>
      </div>
      <Frame title={t('progress:assignments')} flush>
        <DataTable<(typeof w.items)[number]> caption={t('progress:assignments')} data={w.items} getRowId={(r) => r.id} filterLabel={t('progress:filterAssignments')}
          columns={[
            { id: 'title', header: t('progress:colAssignment'), accessorKey: 'title' },
            { id: 'due', header: t('progress:colDue'), accessorFn: (r) => r.due_at ?? '', cell: (c) => (c.row.original.due_at ? formatInstant(c.row.original.due_at) : t('common:noDueDate')) },
            { id: 'score', header: t('progress:colScore'), accessorFn: (r) => r.score ?? -1, cell: (c) => (c.row.original.score == null ? '—' : `${fmtNumber(c.row.original.score)}/${fmtNumber(c.row.original.max_score ?? 0)}`) },
            { id: 'status', header: t('progress:colStatus'), accessorKey: 'status', cell: (c) => <TaskChip status={c.getValue() as string} /> },
          ]}
          empty={<EmptyState icon="assignment" title={t('progress:noPublished')} />} />
        {w.items_total > w.items.length && <div className="body"><Banner tone="warn">{t('progress:latest', { shown: fmtNumber(w.items.length), total: fmtNumber(w.items_total) })}</Banner></div>}
      </Frame>
    </div>
  );
}

export function MyProgressPage() {
  const { courseId } = useParams({ strict: false }) as { courseId: string };
  const p = useQuery(q.myProgress(courseId));
  return <Query q={p}>{(d) => <ProgressView p={d} mine />}</Query>;
}

export function StudentProgressPage() {
  const { t } = useTranslation('progress');
  const { courseId, studentId } = useParams({ strict: false }) as { courseId: string; studentId: string };
  const p = useQuery(q.studentProgress(courseId, studentId));
  return (
    <>
      <PageHead title={p.data?.student.full_name ?? t('studentProgress')} sub={p.data ? t('joined', { when: formatInstant(p.data.enrollment.joined_at) }) : undefined}
        actions={<Link activeOptions={{ exact: true }} to="/courses/$courseId/people" params={{ courseId }} className="btn text"><Icon name="arrow_back" />{t('people')}</Link>} />
      <Query q={p}>{(d) => <ProgressView p={d} mine={false} />}</Query>
    </>
  );
}
