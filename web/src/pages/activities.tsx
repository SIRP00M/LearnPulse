import { useMemo, useState } from 'react';
import { Link, useNavigate, useParams, useSearch } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { useTranslation } from 'react-i18next';
import i18n from '../i18n';
import { useAuth } from '../auth/AuthProvider';
import { v9, type ScheduleInput } from '../lib/api/v9';
import { q } from '../lib/queries';
import { AFTER_ACTIVITY, useAction } from '../lib/hooks';
import { WEEKDAY_NUMBERS, isoWeekdayShort, fmtNumber, addDays, earliestChange, formatDay, formatDayLong, formatInstant, formatTime, parseYmd, timeZones, todayIn, weekStart, ymd } from '../lib/dates';
import { validateTitle } from '../lib/validators';
import { Banner, Button, Chip, EmptyState, ErrorState, Frame, FormError, Icon, Modal, PageHead, Query, SelectField, SkeletonBlock, TextArea, TextField } from '../ui/kit';
import { DataTable } from '../ui/DataTable';
import { OCC, OccChip, POLICIES } from '../ui/status';
import type { OccurrenceItem, OverviewActivity, Policy, Register, Streak } from '../lib/schemas';

const useCourseId = () => (useParams({ strict: false }) as { courseId: string }).courseId;
const DEFAULT_TZ = 'Asia/Bangkok';

// ── schedule editor shared by create + change-schedule ────────
interface Sched { weekdays: number[]; mode: 'day_end' | 'time' | 'none'; time: string; tz: string; end: string }
const initialSched = (): Sched => ({ weekdays: [1, 2, 3, 4, 5], mode: 'day_end', time: '17:00', tz: DEFAULT_TZ, end: '' });
function validateSched(s: Sched): string | null {
  if (s.weekdays.length === 0) return 'validation:weekdaysRequired';
  if (s.mode === 'time' && !s.time) return 'validation:deadlineTimeRequired';
  return null;
}
const toInput = (s: Sched): ScheduleInput => ({ weekdays: [...s.weekdays].sort(), deadlineMode: s.mode, deadlineTime: s.mode === 'time' ? s.time : null, timezone: s.tz, endDate: s.end || null });

function ScheduleFields({ value, onChange, error }: { value: Sched; onChange: (s: Sched) => void; error?: string | null }) {
  const { t } = useTranslation(['activities', 'validation']);
  const zones = useMemo(timeZones, []);
  const toggle = (d: number) => onChange({ ...value, weekdays: value.weekdays.includes(d) ? value.weekdays.filter((x) => x !== d) : [...value.weekdays, d] });
  return (
    <div className="stack">
      <fieldset style={{ border: 0, padding: 0, margin: 0 }}>
        <legend style={{ fontWeight: 500, marginBottom: 6 }}>{t('activities:repeatsOn')}</legend>
        <div className="checks">{WEEKDAY_NUMBERS.map((n) => <label key={n} className="check"><input type="checkbox" checked={value.weekdays.includes(n)} onChange={() => toggle(n)} />{isoWeekdayShort(n)}</label>)}</div>
        {error && <span className="err-text" role="alert">{t(error as 'validation:weekdaysRequired')}</span>}
      </fieldset>
      <div className="row">
        <div className="grow"><SelectField label={t('activities:deadline')} value={value.mode} onChange={(e) => onChange({ ...value, mode: e.target.value as Sched['mode'] })}>
          <option value="day_end">{t('activities:deadlineDayEnd')}</option><option value="time">{t('activities:deadlineTime')}</option><option value="none">{t('activities:deadlineNone')}</option></SelectField></div>
        {value.mode === 'time' && <div className="grow"><TextField label={t('activities:deadlineTimeLabel')} type="time" value={value.time} onChange={(e) => onChange({ ...value, time: e.target.value })} /></div>}
      </div>
      <div className="row">
        <div className="grow"><TextField label={t('activities:timeZone')} list="tzs" value={value.tz} onChange={(e) => onChange({ ...value, tz: e.target.value })} hint={t('activities:tzHint')} /><datalist id="tzs">{zones.map((z) => <option key={z} value={z} />)}</datalist></div>
        <div className="grow"><TextField label={t('activities:endsOn')} type="date" value={value.end} onChange={(e) => onChange({ ...value, end: e.target.value })} /></div>
      </div>
      {value.mode === 'none' && <Banner>{t('activities:noDeadlineBanner')}</Banner>}
    </div>
  );
}

function CreateActivity({ courseId, open, onClose }: { courseId: string; open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['activities', 'common', 'status']);
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [policy, setPolicy] = useState<Policy>('teacher_marked');
  const [sched, setSched] = useState<Sched>(initialSched);
  const [start, setStart] = useState('');
  const [errs, setErrs] = useState<{ t?: string | null; s?: string | null }>({});
  const a = useAction((id: string, ti: string, d: string, p: Policy, s: Sched, st: string) =>
    v9.createActivity({ courseId, requestId: id, title: ti.trim(), description: d.trim(), policy: p, startDate: st || todayIn(s.tz), ...toInput(s) }),
    { topics: AFTER_ACTIVITY, success: t('activities:created'), onDone: () => { setTitle(''); setDesc(''); onClose(); } });
  const tzOk = (() => { try { new Intl.DateTimeFormat('en', { timeZone: sched.tz }); return true; } catch { return false; } })();
  return (
    <Modal open={open} onClose={onClose} title={t('activities:newActivity')}>
      <form className="stack" noValidate onSubmit={(e) => {
        e.preventDefault();
        const v = { t: validateTitle(title, 120), s: validateSched(sched) ?? (tzOk ? null : 'validation:timezoneInvalid') };
        setErrs(v);
        if (!v.t && !v.s) void a.run(title, desc, policy, sched, start);
      }}>
        <TextField label={t('activities:title')} value={title} onChange={(e) => setTitle(e.target.value)} error={errs.t} maxLength={120} autoFocus />
        <TextArea label={t('activities:descOptional')} value={desc} onChange={(e) => setDesc(e.target.value)} maxLength={2000} />
        <fieldset style={{ border: 0, padding: 0, margin: 0 }}>
          <legend style={{ fontWeight: 500, marginBottom: 6 }}>{t('activities:whoRecords')}</legend>
          <div className="stack-s">{POLICIES.map((p) => (
            <label key={p} className="check" style={{ alignItems: 'flex-start' }}><input type="radio" name="policy" checked={policy === p} onChange={() => setPolicy(p)} />
              <span><strong>{t(`status:policy.${p}`)}</strong><br /><span className="muted small">{t(`status:policyHelp.${p}`)}</span></span></label>))}
          </div>
        </fieldset>
        <ScheduleFields value={sched} onChange={setSched} error={errs.s} />
        <TextField label={t('activities:startsOn')} type="date" value={start} min={todayIn(sched.tz)} onChange={(e) => setStart(e.target.value)} hint={t('activities:startsHint')} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('activities:createActivity')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function EditActivity({ act, open, onClose }: { act: OverviewActivity; open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['activities', 'common']);
  const [title, setTitle] = useState(act.title);
  const [desc, setDesc] = useState(act.description ?? '');
  const [err, setErr] = useState<string | null>(null);
  const a = useAction((id: string, ti: string, d: string) => v9.updateActivity({ id: act.id, requestId: id, version: act.version, title: ti.trim(), description: d.trim() }), { topics: AFTER_ACTIVITY, success: t('activities:saved'), onDone: onClose });
  return (
    <Modal open={open} onClose={onClose} title={t('activities:editActivity')} description={t('activities:editDesc')}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); const v = validateTitle(title, 120); setErr(v); if (!v) void a.run(title, desc); }}>
        <TextField label={t('activities:title')} value={title} onChange={(e) => setTitle(e.target.value)} error={err} maxLength={120} autoFocus />
        <TextArea label={t('activities:description')} value={desc} onChange={(e) => setDesc(e.target.value)} maxLength={2000} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('common:save')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function ChangeSchedule({ act, open, onClose }: { act: OverviewActivity; open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['activities', 'common']);
  const cur = act.schedule;
  const tz = cur?.timezone ?? DEFAULT_TZ;
  const [sched, setSched] = useState<Sched>({ weekdays: cur?.weekdays ?? [1, 2, 3, 4, 5], mode: cur?.deadline_mode ?? 'day_end', time: cur?.deadline_time?.slice(0, 5) ?? '17:00', tz, end: cur?.end_date ?? '' });
  const [from, setFrom] = useState(earliestChange(tz, cur?.effective_from));
  const [err, setErr] = useState<string | null>(null);
  const a = useAction((id: string, s: Sched, f: string) => v9.addSchedule({ id: act.id, requestId: id, version: act.version, effectiveFrom: f, ...toInput(s) }), { topics: AFTER_ACTIVITY, success: t('activities:scheduleChanged'), onDone: onClose });
  return (
    <Modal open={open} onClose={onClose} title={t('activities:changeSchedule')} description={t('activities:changeDesc')}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); const v = validateSched(sched); setErr(v); if (!v) void a.run(sched, from); }}>
        <ScheduleFields value={sched} onChange={setSched} error={err} />
        <TextField label={t('activities:effectiveFrom')} type="date" value={from} min={earliestChange(sched.tz, cur?.effective_from)} onChange={(e) => setFrom(e.target.value)} hint={t('activities:effectiveHint')} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('activities:applySchedule')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function StatusMenu({ act }: { act: OverviewActivity }) {
  const { t } = useTranslation(['activities', 'common']);
  const [open, setOpen] = useState<null | 'inactive' | 'archived' | 'active'>(null);
  const tz = act.schedule?.timezone ?? DEFAULT_TZ;
  const [from, setFrom] = useState(earliestChange(tz, act.schedule?.effective_from));
  const a = useAction((id: string, st: 'active' | 'inactive' | 'archived', f?: string) => v9.setStatus({ id: act.id, requestId: id, version: act.version, status: st, effectiveFrom: f }),
    { topics: AFTER_ACTIVITY, success: t('activities:updated'), onDone: () => setOpen(null) });
  const label = open === 'archived' ? t('activities:archiveTitle') : open === 'inactive' ? t('activities:pauseTitle') : t('activities:resumeTitle');
  return (
    <>
      {act.status === 'active' && <Button size="sm" variant="text" icon="pause" onClick={() => setOpen('inactive')}>{t('activities:pause')}</Button>}
      {act.status === 'inactive' && <Button size="sm" variant="text" icon="play_arrow" onClick={() => setOpen('active')}>{t('activities:resume')}</Button>}
      {act.status !== 'archived' && <Button size="sm" variant="text" icon="archive" onClick={() => setOpen('archived')}>{t('activities:archive')}</Button>}
      <Modal open={!!open} onClose={() => setOpen(null)} title={label} description={open === 'archived' ? t('activities:archiveDesc') : t('activities:pauseDesc')}>
        {open && open !== 'archived' && <TextField label={t('activities:effectiveFrom')} type="date" value={from} min={earliestChange(tz, act.schedule?.effective_from)} onChange={(e) => setFrom(e.target.value)} hint={t('activities:effectiveHint')} />}
        <FormError error={a.error} />
        <div className="row"><Button busy={a.busy} variant={open === 'archived' ? 'danger' : 'primary'} onClick={() => open && void a.run(open, open === 'archived' ? undefined : from)}>{t('common:confirm')}</Button><Button variant="text" onClick={() => setOpen(null)}>{t('common:cancel')}</Button></div>
      </Modal>
    </>
  );
}

const describeSchedule = (a: OverviewActivity) => {
  const s = a.schedule;
  if (!s) return '—';
  const days = s.weekdays.length === 7 ? i18n.t('activities:everyDay') : WEEKDAY_NUMBERS.filter((n) => s.weekdays.includes(n)).map((n) => isoWeekdayShort(n)).join(' ');
  const dl = s.deadline_mode === 'none' ? i18n.t('activities:dlNone') : s.deadline_mode === 'time' ? i18n.t('activities:dlTime', { time: s.deadline_time?.slice(0, 5) }) : i18n.t('activities:dlDayEnd');
  return `${days} · ${dl} · ${s.timezone}`;
};

// ── teacher: overview ─────────────────────────────────────────
export function ActivitiesPage() {
  const courseId = useCourseId();
  const { profile } = useAuth();
  return profile?.role === 'teacher' ? <TeacherActivities courseId={courseId} /> : <StudentActivities courseId={courseId} />;
}

function TeacherActivities({ courseId }: { courseId: string }) {
  const { t } = useTranslation(['activities', 'common', 'status']);
  const ov = useQuery(q.overview(courseId));
  const [create, setCreate] = useState(false);
  const [edit, setEdit] = useState<OverviewActivity | null>(null);
  const [sched, setSched] = useState<OverviewActivity | null>(null);
  const nav = useNavigate();
  const cols: ColumnDef<OverviewActivity, unknown>[] = [
    { id: 'title', header: t('activities:colActivity'), accessorKey: 'title', cell: (c) => <Link to="/courses/$courseId/activities/$id" params={{ courseId, id: c.row.original.id }}><strong>{c.row.original.title}</strong></Link> },
    { id: 'policy', header: t('activities:colWho'), accessorFn: (r) => t(`status:policy.${r.policy}`), cell: (c) => <Chip icon={c.row.original.policy === 'teacher_verified' ? 'fact_check' : c.row.original.policy === 'self_reported' ? 'person' : 'edit_note'}>{t(`status:policy.${c.row.original.policy}`)}</Chip> },
    { id: 'schedule', header: t('activities:colSchedule'), accessorFn: describeSchedule },
    { id: 'today', header: t('activities:colToday'), accessorFn: (r) => (r.today.scheduled ? r.today.completed : -1), cell: (c) => { const td = c.row.original.today; return td.scheduled ? `${t('activities:todayDone', { done: fmtNumber(td.completed), expected: fmtNumber(td.expected) })}${td.pending ? ` · ${t('activities:todayPending', { count: td.pending })}` : ''}` : t('activities:notScheduled'); } },
    { id: 'pending', header: t('activities:colToVerify'), accessorKey: 'pending_total', cell: (c) => (c.row.original.pending_total > 0 ? <Chip tone="warn" icon="hourglass_top">{fmtNumber(c.row.original.pending_total)}</Chip> : '—') },
    { id: 'status', header: t('activities:colStatus'), accessorKey: 'status', cell: (c) => <Chip tone={c.getValue() === 'active' ? 'ok' : 'neutral'} icon={c.getValue() === 'active' ? 'play_arrow' : c.getValue() === 'inactive' ? 'pause' : 'archive'}>{c.getValue() === 'active' ? t('status:activity.active') : c.getValue() === 'inactive' ? t('status:activity.inactive') : t('status:activity.archived')}</Chip> },
    { id: 'actions', header: '', enableSorting: false, cell: (c) => c.row.original.status !== 'archived' && (
      <div className="row"><Button size="sm" variant="text" icon="edit" onClick={() => setEdit(c.row.original)}>{t('common:edit')}</Button>
        <Button size="sm" variant="text" icon="calendar_month" onClick={() => setSched(c.row.original)}>{t('activities:scheduleBtn')}</Button><StatusMenu act={c.row.original} /></div>) },
  ];
  return (
    <>
      <div className="row between" style={{ marginBottom: 16 }}>
        <p className="muted">{t('activities:intro')}</p>
        <Button icon="add" onClick={() => setCreate(true)}>{t('activities:newBtn')}</Button>
      </div>
      <Frame flush>
        <Query q={ov}>{(d) => (
          <DataTable<OverviewActivity> caption={t('activities:caption')} data={d.activities} columns={cols} getRowId={(r) => r.id} filterLabel={t('activities:filter')}
            onRowActivate={(r) => void nav({ to: '/courses/$courseId/activities/$id', params: { courseId, id: r.id } })}
            empty={<EmptyState icon="today" title={t('activities:empty')}>{t('activities:emptyText')}</EmptyState>} />
        )}</Query>
      </Frame>
      <CreateActivity courseId={courseId} open={create} onClose={() => setCreate(false)} />
      {edit && <EditActivity key={`${edit.id}-${edit.version}`} act={edit} open onClose={() => setEdit(null)} />}
      {sched && <ChangeSchedule key={`${sched.id}-${sched.version}`} act={sched} open onClose={() => setSched(null)} />}
    </>
  );
}

// ── teacher: weekly register ──────────────────────────────────
export function ActivityDetailPage() {
  const { profile } = useAuth();
  const courseId = useCourseId();
  const { id } = useParams({ strict: false }) as { id: string };
  return profile?.role === 'teacher' ? <RegisterPage /> : <StudentActivities courseId={courseId} activityId={id} />;
}

function CellDialog({ reg, student, name, cell, onClose }: { reg: Register; student: string; name: string; cell: Register['students'][number]['cells'][number]; onClose: () => void }) {
  const { t } = useTranslation(['activities', 'common']);
  const [reason, setReason] = useState('');
  const [note, setNote] = useState(cell.note ?? '');
  const [rErr, setRErr] = useState<string | null>(null);
  const common = { activityId: reg.activity_id, studentId: student, date: cell.date, version: cell.version };
  const mark = useAction((id: string, result: 'completed' | 'not_done') => v9.mark({ ...common, requestId: id, result, note: note.trim() || undefined }), { topics: AFTER_ACTIVITY, success: t('activities:savedToast'), onDone: onClose });
  const review = useAction((id: string, decision: 'approve' | 'reject', r?: string) => v9.review({ ...common, requestId: id, decision, reason: r }), { topics: AFTER_ACTIVITY, success: t('activities:decisionSaved'), onDone: onClose });
  const pending = cell.completion_status === 'pending';
  return (
    <Modal open onClose={onClose} title={`${name} · ${formatDayLong(cell.date)}`} description={reg.title}>
      <div className="row"><OccChip state={cell.state} />{cell.completion_status && <span className="muted small">{t('activities:recorded', { status: t(`activities:recordStatus.${cell.completion_status}`) })}</span>}</div>
      {cell.note && <div><strong>{t('activities:studentNote')}</strong><p className="pre">{cell.note}</p></div>}
      {cell.reason && <div><strong>{t('activities:rejectionReason')}</strong><p className="pre">{cell.reason}</p></div>}
      {pending ? (
        <div className="stack">
          <TextArea label={t('activities:reasonLabel')} value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} error={rErr} />
          <FormError error={review.error} />
          <div className="row">
            <Button icon="check" busy={review.busy} onClick={() => void review.run('approve')}>{t('activities:approve')}</Button>
            <Button variant="danger" icon="undo" busy={review.busy} onClick={() => { if (!reason.trim()) setRErr('validation:reasonRequired'); else { setRErr(null); void review.run('reject', reason.trim()); } }}>{t('activities:reject')}</Button>
          </div>
        </div>
      ) : cell.state === 'upcoming' ? <Banner>{t('activities:upcomingBanner')}</Banner> : (
        <div className="stack">
          <TextArea label={t('activities:noteOptional')} value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} />
          <FormError error={mark.error} />
          <div className="row">
            <Button icon="check_circle" busy={mark.busy} onClick={() => void mark.run('completed')}>{t('activities:markDone')}</Button>
            <Button variant="outline" icon="cancel" busy={mark.busy} onClick={() => void mark.run('not_done')}>{t('activities:markNotDone')}</Button>
          </div>
        </div>
      )}
    </Modal>
  );
}

function RegisterPage() {
  const { t } = useTranslation(['activities', 'common', 'status', 'table']);
  const courseId = useCourseId();
  const { id } = useParams({ strict: false }) as { id: string };
  const search = useSearch({ strict: false }) as { week?: string };
  const nav = useNavigate();
  const start = weekStart(search.week ? parseYmd(search.week) : new Date());
  const reg = useQuery(q.register(id, ymd(start)));
  const ov = useQuery(q.overview(courseId));
  const [open, setOpen] = useState<{ student: string; name: string; date: string } | null>(null);
  const go = (d: Date) => void nav({ to: '/courses/$courseId/activities/$id', params: { courseId, id }, search: { week: ymd(d) }, replace: true });
  const act = ov.data?.activities.find((a) => a.id === id);
  if (reg.data === undefined) return reg.isError ? <ErrorState error={reg.error} onRetry={() => void reg.refetch()} /> : <SkeletonBlock rows={6} />;
  const r = reg.data;
  const sel = open ? r.students.find((s) => s.student_id === open.student)?.cells.find((c) => c.date === open.date) : null;
  return (
    <div className="stack">
      <PageHead title={r.title} sub={<>{t(`status:policy.${r.policy}`)}{act ? ` · ${describeSchedule(act)}` : ''}</>} actions={<Link activeOptions={{ exact: true }} to="/courses/$courseId/activities" params={{ courseId }} className="btn text"><Icon name="arrow_back" />{t('activities:allActivities')}</Link>} />
      {reg.isError && <Banner tone="warn">{t('activities:staleWeek')} <Button size="sm" variant="text" onClick={() => void reg.refetch()}>{t('common:retry')}</Button></Banner>}
      <Frame title={t('activities:weekOf', { date: formatDay(ymd(start)) })} flush actions={<>
        <Button variant="outline" size="sm" icon="chevron_left" aria-label={t('activities:prevWeek')} onClick={() => go(addDays(start, -7))} />
        <Button variant="outline" size="sm" onClick={() => go(new Date())}>{t('activities:thisWeek')}</Button>
        <Button variant="outline" size="sm" icon="chevron_right" aria-label={t('activities:nextWeek')} onClick={() => go(addDays(start, 7))} /></>}>
        {r.days.length === 0 ? <EmptyState icon="event_busy" title={t('activities:notScheduledWeek')}>{t('activities:notScheduledWeekText')}</EmptyState>
          : r.students.length === 0 ? <EmptyState icon="group" title={t('activities:noActiveStudents')}>{t('activities:noActiveStudentsText')}</EmptyState> : (
            <div className="table-wrap" tabIndex={0} role="region" aria-label={t('table:scrollable', { caption: t('activities:registerCaption') })}>
              <table className="tbl">
                <caption className="sr-only">{t('activities:registerCaption')}</caption>
                <thead><tr><th scope="col" className="sticky-col">{t('activities:colStudent')}</th>{r.days.map((d) => <th scope="col" key={d.date}>{formatDay(d.date)}<div className="small muted">{d.deadline_mode === 'none' ? t('activities:headNone') : d.deadline_mode === 'day_end' ? t('activities:headDayEnd') : t('activities:headTime', { time: formatTime(d.due_at) })}</div></th>)}</tr></thead>
                <tbody>{r.students.map((s) => (
                  <tr key={s.student_id}><th scope="row" className="sticky-col" style={{ textAlign: 'left', background: 'var(--lp-frame)' }}>{s.full_name ?? t('common:student')}</th>
                    {r.days.map((d) => {
                      const c = s.cells.find((x) => x.date === d.date);
                      if (!c) return <td key={d.date} />;
                      return (
                        <td key={d.date} className="cell"><button className="cellbtn" onClick={() => setOpen({ student: s.student_id, name: s.full_name ?? t('common:student'), date: d.date })}
                          aria-label={t('activities:cellLabel', { name: s.full_name ?? t('common:student'), date: formatDayLong(d.date), state: t(`status:occ.${c.state}`) })}>
                          <Icon name={OCC[c.state].icon} /><span>{t(`status:occ.${c.state}`)}</span></button></td>
                      );
                    })}</tr>))}
                </tbody>
              </table>
            </div>
          )}
      </Frame>
      {open && sel && <CellDialog key={`${open.student}-${open.date}-${sel.version}`} reg={r} student={open.student} name={open.name} cell={sel} onClose={() => setOpen(null)} />}
    </div>
  );
}

// ── student: weekly list + actions ────────────────────────────
function StreakChip({ s }: { s: Streak }) {
  const { t } = useTranslation('activities');
  if (!s || s.current == null) return <span className="muted small">{t('noStreak')}</span>;
  return <Chip tone={s.current > 0 ? 'ok' : 'neutral'} icon="local_fire_department">{t('streak', { current: fmtNumber(s.current), best: fmtNumber(s.best ?? 0) })}</Chip>;
}

function OccurrenceRow({ it }: { it: OccurrenceItem }) {
  const { t } = useTranslation(['activities', 'common', 'status']);
  const [note, setNote] = useState('');
  const [dlg, setDlg] = useState(false);
  const complete = useAction((id: string, n?: string) => v9.complete({ activityId: it.activity_id, date: it.occurrence_date, requestId: id, version: it.version, note: n }), { topics: AFTER_ACTIVITY, success: it.policy === 'teacher_verified' ? t('activities:submitted') : t('activities:markedDone'), onDone: () => setDlg(false) });
  const retract = useAction((id: string) => v9.retract({ activityId: it.activity_id, date: it.occurrence_date, requestId: id, version: it.version }), { topics: AFTER_ACTIVITY, success: t('activities:withdrawn') });
  const canAct = it.policy !== 'teacher_marked' && (it.state === 'open' || it.state === 'rejected');
  const canRetract = (it.state === 'pending' || (it.state === 'completed' && it.completion_status === 'self_reported')) && it.policy !== 'teacher_marked';
  return (
    <li>
      <div className="grow">
        <strong>{it.title}</strong>
        <div className="muted small">{formatDayLong(it.occurrence_date)} · {it.deadline_mode === 'none' ? t('activities:dueNone') : it.deadline_mode === 'day_end' ? t('activities:dueDayEnd') : t('common:dueAt', { when: formatInstant(it.due_at) })}</div>
        {it.state === 'rejected' && it.reason && <Banner tone="err" icon="undo"><strong>{t('activities:teacherAsked')}</strong> <span className="pre">{it.reason}</span></Banner>}
        {it.note && it.state !== 'rejected' && <div className="small muted">{t('activities:yourNote', { note: it.note })}</div>}
        {(complete.error || retract.error) && <FormError error={complete.error ?? retract.error} />}
      </div>
      <OccChip state={it.state} />
      {it.policy === 'teacher_marked' && <span className="muted small">{t('activities:recordedByTeacher')}</span>}
      {canAct && (it.policy === 'teacher_verified'
        ? <Button size="sm" icon="send" onClick={() => setDlg(true)}>{it.state === 'rejected' ? t('status:occ.rejected') : t('activities:submitForReview')}</Button>
        : <Button size="sm" icon="check" busy={complete.busy} onClick={() => void complete.run()}>{t('activities:markDone')}</Button>)}
      {canRetract && <Button size="sm" variant="text" busy={retract.busy} onClick={() => void retract.run()}>{t('activities:withdraw')}</Button>}
      <Modal open={dlg} onClose={() => setDlg(false)} title={t('activities:submitTitle', { title: it.title })} description={t('activities:submitDesc')}>
        <form className="stack" onSubmit={(e) => { e.preventDefault(); void complete.run(note.trim() || undefined); }}>
          <TextArea label={t('activities:noteOptional')} value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} autoFocus />
          <FormError error={complete.error} />
          <div className="row"><Button type="submit" busy={complete.busy}>{t('common:submit')}</Button><Button variant="text" onClick={() => setDlg(false)}>{t('common:cancel')}</Button></div>
        </form>
      </Modal>
    </li>
  );
}

function StudentActivities({ courseId, activityId }: { courseId: string; activityId?: string }) {
  const { t } = useTranslation('activities');
  const search = useSearch({ strict: false }) as { week?: string };
  const nav = useNavigate();
  const start = weekStart(search.week ? parseYmd(search.week) : new Date());
  const items = useQuery(q.myActivities(ymd(start), ymd(addDays(start, 6)), courseId));
  const streaks = useQuery(q.streaks(courseId));
  const go = (d: Date) => void nav({ to: activityId ? '/courses/$courseId/activities/$id' : '/courses/$courseId/activities', params: activityId ? { courseId, id: activityId } : { courseId }, search: { week: ymd(d) }, replace: true });
  const rows = (items.data?.items ?? []).filter((i) => !activityId || i.activity_id === activityId);
  const byDate = useMemo(() => { const m = new Map<string, OccurrenceItem[]>(); for (const r of rows) m.set(r.occurrence_date, [...(m.get(r.occurrence_date) ?? []), r]); return [...m.entries()].sort(([a], [b]) => a.localeCompare(b)); }, [rows]);
  return (
    <div className="cols">
      <div className="c8">
        <Frame title={t('weekOf', { date: formatDay(ymd(start)) })} flush actions={<>
          <Button variant="outline" size="sm" icon="chevron_left" aria-label={t('prevWeek')} onClick={() => go(addDays(start, -7))} />
          <Button variant="outline" size="sm" onClick={() => go(new Date())}>{t('thisWeek')}</Button>
          <Button variant="outline" size="sm" icon="chevron_right" aria-label={t('nextWeek')} onClick={() => go(addDays(start, 7))} /></>}>
          <Query q={items}>{(d) => (
            byDate.length === 0 ? <EmptyState icon="today" title={t('noActivitiesWeek')}>{activityId ? t('notScheduledActivity') : t('notScheduledAll')}</EmptyState> : (
              <>{d.capped && <Banner tone="warn">{t('capped')}</Banner>}
                {byDate.map(([date, list]) => (<div key={date}><h3 style={{ padding: '12px 16px 0' }}>{formatDayLong(date)}</h3><ul className="list">{list.map((it) => <OccurrenceRow key={`${it.activity_id}-${it.occurrence_date}-${it.version}`} it={it} />)}</ul></div>))}</>
            )
          )}</Query>
        </Frame>
      </div>
      <div className="c4">
        <Frame title={t('streaks')}>
          <Query q={streaks} rows={2}>{(s) => s.activities.length === 0 ? <p className="muted">{t('noActivitiesYet')}</p> : (
            <ul className="list" style={{ margin: -16 }}>{s.activities.map((a) => <li key={a.activity_id}><div className="grow"><strong>{a.title}</strong><div style={{ marginTop: 4 }}><StreakChip s={a.streak} /></div></div></li>)}</ul>
          )}</Query>
          <p className="muted small" style={{ marginTop: 24 }}>{t('streakNote')}</p>
        </Frame>
      </div>
    </div>
  );
}
