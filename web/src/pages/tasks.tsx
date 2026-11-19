import { useMemo } from 'react';
import { Link, useNavigate, useSearch } from '@tanstack/react-router';
import { keepPreviousData, useInfiniteQuery, useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import i18n from '../i18n';
import { useAuth } from '../auth/AuthProvider';
import { v9 } from '../lib/api/v9';
import { taskTarget } from '../lib/links';
import { addDays, fmtNumber, formatDay, formatInstant, formatMonth, monthGrid, parseYmd, relativeDay, startOfDay, weekStart, weekdayShort, windowFor, ymd } from '../lib/dates';
import { Banner, Button, EmptyState, ErrorState, Frame, Icon, PageHead, Query, SkeletonBlock } from '../ui/kit';
import { TaskChip } from '../ui/status';
import type { CalendarItem, Role, TaskItem } from '../lib/schemas';

type View = 'today' | 'week' | 'month' | 'upcoming' | 'overdue' | 'completed';
const STUDENT_VIEWS: View[] = ['today', 'week', 'month', 'upcoming', 'overdue', 'completed'];
const TEACHER_VIEWS: View[] = ['today', 'week', 'month'];
const VIEW_LABEL: Record<View, 'tasks:viewToday' | 'tasks:viewWeek' | 'tasks:viewMonth' | 'tasks:viewUpcoming' | 'tasks:viewOverdue' | 'tasks:viewCompleted'> = { today: 'tasks:viewToday', week: 'tasks:viewWeek', month: 'tasks:viewMonth', upcoming: 'tasks:viewUpcoming', overdue: 'tasks:viewOverdue', completed: 'tasks:viewCompleted' };

/** A uniform row for both the student task feed and the teacher calendar. */
interface Row { key: string; kind: string; id: string; courseId: string; course: string; title: string; status: string; date: string; at?: string | null; extra?: string }

const dateOf = (occ: string | null | undefined, at: string | null | undefined) => occ ?? (at ? ymd(new Date(at)) : '');
const fromTask = (t: TaskItem): Row => ({ key: `${t.kind}-${t.id}-${t.key2 ?? ''}`, kind: t.kind, id: t.id, courseId: t.course_id, course: t.course_title ?? '', title: t.title, status: t.status, date: dateOf(t.occurrence_date, t.task_at ?? t.due_at), at: t.due_at ?? t.task_at });
const fromCal = (c: CalendarItem): Row => ({
  key: `${c.kind}-${c.id}-${c.key2 ?? ''}`, kind: c.kind, id: c.id, courseId: c.course_id, course: c.course_title ?? '', title: c.title, status: c.status ?? '', date: dateOf(c.occurrence_date, c.task_at), at: c.task_at,
  extra: c.expected != null ? `${i18n.t('tasks:extraDone', { received: fmtNumber(c.received ?? 0), expected: fmtNumber(c.expected) })}${c.pending ? ` · ${i18n.t('tasks:extraPending', { count: fmtNumber(c.pending) })}` : ''}` : undefined,
});
const TONE = (s: string) => (['overdue', 'needs_revision', 'missed'].includes(s) ? 'err' : ['awaiting_review', 'pending'].includes(s) ? 'warn' : ['graded', 'done', 'held'].includes(s) ? 'ok' : '');

function RowLink({ r, role }: { r: Row; role: Role }) {
  const { t } = useTranslation('tasks');
  const tg = taskTarget(r.kind, r.courseId, r.id, role, r.date);
  return <Link className="item" to={tg.to} params={tg.params} search={tg.search}><strong>{r.title}</strong><div className="muted small">{r.course} · {t(`kind.${r.kind as 'assignment'}`, { defaultValue: r.kind })}{r.at ? ` · ${formatInstant(r.at)}` : ''}{r.extra ? ` · ${r.extra}` : ''}</div></Link>;
}
const StatusChip = ({ r }: { r: Row }) => (r.status ? <TaskChip status={r.status} /> : null);

function groupByDate(rows: Row[]) {
  const m = new Map<string, Row[]>();
  for (const r of rows) m.set(r.date, [...(m.get(r.date) ?? []), r]);
  return [...m.entries()].sort(([a], [b]) => a.localeCompare(b));
}

function AgendaList({ rows, role, empty }: { rows: Row[]; role: Role; empty: string }) {
  const { t } = useTranslation(['tasks', 'common']);
  if (rows.length === 0) return <EmptyState icon="event_available" title={empty} />;
  return (
    <div>{groupByDate(rows).map(([date, list]) => (
      <div key={date}><h3 style={{ padding: '12px 16px 0' }}>{date ? (relativeDay(date) ? `${relativeDay(date)} · ${formatDay(date)}` : formatDay(date)) : t('common:noDate')}</h3>
        <ul className="list">{list.map((r) => <li key={r.key}><RowLink r={r} role={role} /><StatusChip r={r} /></li>)}</ul></div>))}
    </div>
  );
}

function MonthGrid({ rows, anchor, role }: { rows: Row[]; anchor: Date; role: Role }) {
  const { t } = useTranslation('tasks');
  const { start } = monthGrid(anchor);
  const by = new Map(groupByDate(rows));
  const today = ymd(new Date());
  const weeks = Array.from({ length: 6 }, (_, w) => Array.from({ length: 7 }, (_, d) => addDays(start, w * 7 + d)));
  return (
    <div className="body" style={{ padding: 8 }}>
      <table className="cal">
        <caption className="sr-only">{formatMonth(anchor)}</caption>
        <thead><tr>{weeks[0]!.map((d) => <th scope="col" key={d.getDay()}>{weekdayShort(d)}</th>)}</tr></thead>
        <tbody>
          {weeks.map((wk) => (
            <tr key={ymd(wk[0]!)}>
              {wk.map((d) => {
                const k = ymd(d);
                const list = by.get(k) ?? [];
                return (
                  <td key={k} className={`${d.getMonth() !== anchor.getMonth() ? 'out' : ''} ${k === today ? 'today' : ''}`}>
                    <time dateTime={k} className="dn"><span className="sr-only">{formatDay(k)}, </span><span aria-hidden>{fmtNumber(d.getDate())}</span></time>
                    {list.slice(0, 3).map((r) => { const tg = taskTarget(r.kind, r.courseId, r.id, role, r.date); return <Link key={r.key} className={`ev ${TONE(r.status)}`} to={tg.to} params={tg.params} search={tg.search} title={`${r.title} · ${r.course}`}>{r.title}</Link>; })}
                    {list.length > 3 && <span className="small muted">{t('moreItems', { count: fmtNumber(list.length - 3) })}</span>}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function useViewState(allowed: View[]) {
  const search = useSearch({ strict: false }) as { view?: string; date?: string };
  const nav = useNavigate();
  const view = (allowed.find((v) => v === search.view) ?? 'today') as View;
  const anchor = search.date ? parseYmd(search.date) : startOfDay(new Date());
  const set = (patch: { view?: View; date?: string }) => void nav({ to: '/tasks', search: { view: patch.view ?? view, date: patch.date ?? (patch.view ? undefined : search.date) }, replace: true });
  return { view, anchor, set };
}

function rangeFor(view: View, anchor: Date) {
  if (view === 'week') { const s = weekStart(anchor); return windowFor(s, addDays(s, 7)); }
  if (view === 'month') { const g = monthGrid(anchor); return windowFor(g.start, g.end); }
  const s = startOfDay(anchor);
  return windowFor(s, addDays(s, 1));
}

function Switcher({ views, view, anchor, set }: { views: View[]; view: View; anchor: Date; set: ReturnType<typeof useViewState>['set'] }) {
  const { t } = useTranslation('tasks');
  const step = (dir: number) => set({ date: ymd(view === 'month' ? new Date(anchor.getFullYear(), anchor.getMonth() + dir, 1) : addDays(anchor, dir * (view === 'week' ? 7 : 1))) });
  const ranged = view === 'today' || view === 'week' || view === 'month';
  const title = view === 'month' ? formatMonth(anchor) : view === 'week' ? t('weekOf', { date: formatDay(ymd(weekStart(anchor))) }) : view === 'today' ? (relativeDay(ymd(anchor)) ? `${relativeDay(ymd(anchor))} · ${formatDay(ymd(anchor))}` : formatDay(ymd(anchor))) : '';
  return (
    <div className="row between" style={{ marginBottom: 16 }}>
      <div className="row" role="group" aria-label={t('view')}>{views.map((v) => <Button key={v} variant={v === view ? 'tonal' : 'outline'} aria-pressed={v === view} onClick={() => set({ view: v })}>{t(VIEW_LABEL[v].slice(6) as 'viewToday')}</Button>)}</div>
      {ranged && (
        <div className="row">
          <Button variant="outline" size="sm" icon="chevron_left" aria-label={t('previous')} onClick={() => step(-1)} />
          <strong aria-live="polite" style={{ minWidth: 140, textAlign: 'center' }}>{title}</strong>
          <Button variant="outline" size="sm" icon="chevron_right" aria-label={t('next')} onClick={() => step(1)} />
          <Button variant="outline" size="sm" onClick={() => set({ date: ymd(new Date()) })}>{t('today')}</Button>
        </div>
      )}
    </div>
  );
}

function StudentTasks() {
  const { t } = useTranslation('tasks');
  const { view, anchor, set } = useViewState(STUDENT_VIEWS);
  const ranged = view === 'today' || view === 'week' || view === 'month';
  const win = rangeFor(view, anchor);
  const range = useQuery({ queryKey: ['tasks', 'range', view, ymd(win.from)], enabled: ranged, placeholderData: keepPreviousData, queryFn: () => v9.myTasks('range', win) });
  const paged = useInfiniteQuery({
    queryKey: ['tasks', 'feed', view], enabled: !ranged, initialPageParam: undefined as unknown,
    queryFn: ({ pageParam }) => v9.myTasksPage(view as 'upcoming' | 'overdue' | 'completed', pageParam),
    getNextPageParam: (l) => l.next_cursor ?? undefined,
  });
  const feed = useMemo(() => (paged.data?.pages.flatMap((p) => p.items) ?? []).map(fromTask), [paged.data]);
  return (
    <>
      <PageHead title={t('title')} sub={t('sub')} />
      <Switcher views={STUDENT_VIEWS} view={view} anchor={anchor} set={set} />
      <Frame flush>
        {ranged ? (
          <Query q={range}>{(d) => {
            const rows = d.items.map(fromTask);
            return <>{d.capped && <Banner tone="warn">{t('capped')}</Banner>}
              {view === 'month' ? <MonthGrid rows={rows} anchor={anchor} role="student" /> : <AgendaList rows={rows} role="student" empty={view === 'today' ? t('emptyToday') : t('emptyWeek')} />}</>;
          }}</Query>
        ) : paged.isPending ? <div className="body"><SkeletonBlock rows={5} /></div> : paged.isError && !paged.data ? <ErrorState error={paged.error} onRetry={() => void paged.refetch()} /> : (
          <>
            <AgendaList rows={feed} role="student" empty={view === 'upcoming' ? t('emptyUpcoming') : view === 'overdue' ? t('emptyOverdue') : t('emptyCompleted')} />
            {paged.hasNextPage && <div className="body"><Button variant="outline" busy={paged.isFetchingNextPage} onClick={() => void paged.fetchNextPage()}>{t('loadMore')}</Button></div>}
          </>
        )}
      </Frame>
    </>
  );
}

function TeacherCalendar() {
  const { t } = useTranslation('tasks');
  const { view, anchor, set } = useViewState(TEACHER_VIEWS);
  const win = rangeFor(view, anchor);
  const cal = useQuery({ queryKey: ['tasks', 'calendar', view, ymd(win.from)], placeholderData: keepPreviousData, queryFn: () => v9.calendarWindow(win.from, win.to, win.fromDate, win.toDate) });
  return (
    <>
      <PageHead title={t('calendarTitle')} sub={t('calendarSub')}
        actions={cal.data && cal.data.pending > 0 ? <Link activeOptions={{ exact: true }} to="/verification" className="btn tonal"><Icon name="fact_check" />{t('toVerify', { count: fmtNumber(cal.data.pending) })}</Link> : undefined} />
      <Switcher views={TEACHER_VIEWS} view={view} anchor={anchor} set={set} />
      <Frame flush>
        <Query q={cal}>{(d) => {
          const rows = d.items.map(fromCal);
          return <>{d.capped && <Banner tone="warn">{t('capped')}</Banner>}
            {view === 'month' ? <MonthGrid rows={rows} anchor={anchor} role="teacher" /> : <AgendaList rows={rows} role="teacher" empty={view === 'today' ? t('emptyCalToday') : t('emptyWeek')} />}</>;
        }}</Query>
      </Frame>
    </>
  );
}

export function TasksPage() {
  const { profile } = useAuth();
  return profile?.role === 'teacher' ? <TeacherCalendar /> : <StudentTasks />;
}
