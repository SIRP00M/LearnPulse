import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/AuthProvider';
import { att2 } from '../lib/api/att2';
import { q } from '../lib/queries';
import { AFTER_STAFF, useAction } from '../lib/hooks';
import { addDays, fmtNumber, formatDay, formatInstant, toIsoFromLocalInput, ymd } from '../lib/dates';
import { Banner, Button, Chip, EmptyState, ErrorState, Frame, FormError, Modal, PageHead, Query, SkeletonBlock, Stat, TextArea, TextField, type Tone } from '../ui/kit';
import { DataTable } from '../ui/DataTable';
import type { StaffContext, StaffRequest, StaffRow, StaffState, StaffTotals } from '../lib/schemas';

const TONE: Record<StaffState, Tone> = {
  on_time: 'ok', late: 'warn', missing_checkout: 'err', in_progress: 'info', absent: 'err', leave: 'info', unscheduled: 'neutral', upcoming: 'neutral',
};
const ICON: Record<StaffState, string> = {
  on_time: 'check_circle', late: 'schedule', missing_checkout: 'error', in_progress: 'timelapse', absent: 'cancel', leave: 'beach_access', unscheduled: 'help', upcoming: 'event',
};
const hours = (mins: number) => fmtNumber(Math.round(mins / 6) / 10);
const timeOnly = (iso?: string | null) => (iso ? formatInstant(iso) : '—');

function StateChip({ s }: { s: StaffState }) {
  const { t } = useTranslation('staff');
  return <Chip tone={TONE[s]} icon={ICON[s]}>{t(s)}</Chip>;
}

export function StaffPage() {
  const { t } = useTranslation('staff');
  const { profile } = useAuth();
  const ctx = useQuery(q.staffContext());
  if (profile?.role !== 'teacher') return <ErrorState error={{ code: 'PT403' }} />;
  return (
    <>
      <PageHead title={t('title')} sub={t('subtitle')} />
      <Query q={ctx}>{(c) => (c.is_staff ? <StaffBody ctx={c} /> : <EmptyState icon="badge" title={t('notStaff')} />)}</Query>
    </>
  );
}

function StaffBody({ ctx }: { ctx: StaffContext }) {
  return (
    <div className="stack">
      <ClockCard ctx={ctx} />
      <History />
      <Requests ctx={ctx} />
      {ctx.is_supervisor && <Manager ctx={ctx} />}
    </div>
  );
}

function ClockCard({ ctx }: { ctx: StaffContext }) {
  const { t } = useTranslation('staff');
  const open = ctx.open_punch;
  const inn = useAction((rid: string) => att2.clockIn(rid), { topics: AFTER_STAFF, success: t('clockedIn') });
  const out = useAction((rid: string) => att2.clockOut(rid), { topics: AFTER_STAFF, success: t('clockedOut') });
  const dayList = (w: number[]) => w.map((d) => t(`d${d}` as 'd1')).join(' ');
  return (
    <Frame title={t('today')}>
      <div className="stack">
        <div className="row between">
          <div>
            <div role="status" aria-live="polite"><strong>{open ? t('statusIn', { time: formatInstant(open.clock_in_at) }) : t('statusOut')}</strong></div>
            {open && open.late_minutes > 0 && <Chip tone="warn" icon="schedule">{t('statusLate', { minutes: fmtNumber(open.late_minutes) })}</Chip>}
          </div>
          {open
            ? <Button icon="logout" busy={out.busy} onClick={() => void out.run()}>{t('clockOut')}</Button>
            : <Button icon="login" busy={inn.busy} onClick={() => void inn.run()}>{t('clockIn')}</Button>}
        </div>
        <FormError error={inn.error ?? out.error} />
        <p className="muted small">{t('serverTime')}</p>
        <div>
          <h3>{t('schedule')}</h3>
          {ctx.schedules.length === 0 ? <p className="muted">{t('noSchedule')}</p> : (
            <ul className="list">{ctx.schedules.map((s) => (
              <li key={s.id}><div className="grow"><strong>{s.label || t('schedule')}</strong>
                <div className="muted small">{t('scheduleLine', { days: dayList(s.weekdays), start: s.start_time.slice(0, 5), end: s.end_time.slice(0, 5), zone: s.timezone, grace: s.late_grace_minutes })}</div></div></li>))}
            </ul>
          )}
        </div>
      </div>
    </Frame>
  );
}

function Totals({ tt }: { tt: StaffTotals }) {
  const { t } = useTranslation('staff');
  return (
    <div className="stats">
      <Stat value={fmtNumber(tt.on_time)} label={t('on_time')} /><Stat value={fmtNumber(tt.late)} label={t('late')} tone={tt.late ? 'warn' : undefined} />
      <Stat value={fmtNumber(tt.missing_checkout)} label={t('missing_checkout')} tone={tt.missing_checkout ? 'err' : undefined} />
      <Stat value={fmtNumber(tt.absent)} label={t('absent')} tone={tt.absent ? 'err' : undefined} /><Stat value={fmtNumber(tt.leave)} label={t('leave')} />
      <Stat value={hours(tt.worked_minutes)} label={t('worked')} />
    </div>
  );
}

function History({ staffId }: { staffId?: string }) {
  const { t } = useTranslation(['staff', 'common']);
  const [from, setFrom] = useState(() => ymd(addDays(new Date(), -13)));
  const [to, setTo] = useState(() => ymd(new Date()));
  const valid = from <= to && new Date(to).getTime() - new Date(from).getTime() <= 92 * 86_400_000;
  const rep = useQuery({ ...q.staffReport(from, to, staffId), enabled: valid });
  const cols = useMemo<ColumnDef<StaffRow, unknown>[]>(() => [
    { id: 'day', header: t('staff:colDate'), accessorKey: 'day', cell: (c) => formatDay(c.getValue() as string) },
    { id: 'shift', header: t('staff:colShift'), accessorFn: (r) => r.start_time ?? '', cell: (c) => (c.row.original.start_time ? `${c.row.original.start_time.slice(0, 5)}–${(c.row.original.end_time ?? '').slice(0, 5)}` : '—') },
    { id: 'in', header: t('staff:colIn'), accessorFn: (r) => r.clock_in_at ?? '', cell: (c) => timeOnly(c.row.original.clock_in_at) },
    { id: 'out', header: t('staff:colOut'), accessorFn: (r) => r.clock_out_at ?? '', cell: (c) => timeOnly(c.row.original.clock_out_at) },
    { id: 'late', header: t('staff:colLate'), accessorFn: (r) => r.late_minutes ?? 0, cell: (c) => (c.row.original.late_minutes ? fmtNumber(c.row.original.late_minutes) : '—') },
    { id: 'state', header: t('staff:colState'), accessorKey: 'state', cell: (c) => <StateChip s={c.row.original.state} /> },
  ], [t]);
  return (
    <Frame title={rep.data?.name && staffId ? `${t('staff:history')} · ${rep.data.name}` : t('staff:history')}>
      <div className="stack">
        <div className="cols">
          <div className="c4"><TextField label={t('staff:from')} type="date" value={from} onChange={(e) => setFrom(e.target.value)} /></div>
          <div className="c4"><TextField label={t('staff:to')} type="date" value={to} onChange={(e) => setTo(e.target.value)} error={valid ? null : 'staff:fixDates'} /></div>
        </div>
        {rep.isPending && valid ? <SkeletonBlock rows={4} /> : rep.isError ? <ErrorState error={rep.error} onRetry={() => void rep.refetch()} /> : rep.data && (
          <>
            <Totals tt={rep.data.totals} />
            <DataTable<StaffRow> caption={t('staff:history')} exportName="staff-attendance" filterLabel={t('staff:history')} data={rep.data.rows} columns={cols}
              getRowId={(r) => `${r.day}-${r.schedule_id ?? 'x'}-${r.clock_in_at ?? ''}`}
              empty={<EmptyState icon="event_busy" title={t('staff:noRows')} />} />
          </>
        )}
      </div>
    </Frame>
  );
}

function Requests({ ctx }: { ctx: StaffContext }) {
  const { t } = useTranslation(['staff', 'common']);
  const mine = useQuery(q.staffRequests('mine'));
  const [kind, setKind] = useState<'leave' | 'correction' | null>(null);
  const cancel = useAction((_rid: string, id: string) => att2.cancelRequest(id), { topics: AFTER_STAFF, success: t('staff:cancelled') });
  return (
    <Frame title={t('staff:requests')} actions={<>
      <Button size="sm" variant="outline" icon="beach_access" onClick={() => setKind('leave')}>{t('staff:newLeave')}</Button>
      <Button size="sm" variant="outline" icon="edit_calendar" onClick={() => setKind('correction')}>{t('staff:newCorrection')}</Button></>}>
      <div className="stack">
        <p className="muted small">{ctx.supervisors.length ? t('staff:selfNote') : t('staff:noSupervisor')}</p>
        <Query q={mine} rows={2}>{(rows) => rows.length === 0 ? <EmptyState icon="inbox" title={t('staff:noRequests')} /> : (
          <ul className="list">{rows.map((r) => <RequestItem key={r.id} r={r} action={r.status === 'pending'
            ? <Button size="sm" variant="text" busy={cancel.busy} onClick={() => void cancel.run(r.id)}>{t('staff:cancelRequest')}</Button> : null} />)}</ul>
        )}</Query>
        <FormError error={cancel.error} />
      </div>
      {kind && <RequestForm kind={kind} onClose={() => setKind(null)} />}
    </Frame>
  );
}

function RequestItem({ r, action, showStaff }: { r: StaffRequest; action?: React.ReactNode; showStaff?: boolean }) {
  const { t } = useTranslation('staff');
  return (
    <li><div className="grow">
      <strong>{showStaff ? `${r.staff_name ?? ''} · ` : ''}{t(`kind_${r.kind}` as 'kind_leave')}</strong>{' '}
      <span className="muted small">{r.date_from === r.date_to ? formatDay(r.date_from) : `${formatDay(r.date_from)} – ${formatDay(r.date_to)}`}</span>
      {r.kind === 'correction' && <div className="small">{t('colIn')}: {timeOnly(r.proposed_clock_in)} · {t('colOut')}: {timeOnly(r.proposed_clock_out)}</div>}
      <div className="small">{r.reason}</div>
      {r.decision_note ? <div className="muted small">{t('decisionNote', { note: r.decision_note })}</div> : null}
    </div>
      <Chip tone={r.status === 'approved' ? 'ok' : r.status === 'rejected' ? 'err' : r.status === 'pending' ? 'info' : 'neutral'}>{t(`st_${r.status}` as 'st_pending')}</Chip>
      {action}
    </li>
  );
}

function RequestForm({ kind, onClose }: { kind: 'leave' | 'correction'; onClose: () => void }) {
  const { t } = useTranslation(['staff', 'common']);
  const today = ymd(new Date());
  const [from, setFrom] = useState(today);
  const [to, setTo] = useState(today);
  const [cin, setCin] = useState('');
  const [cout, setCout] = useState('');
  const [reason, setReason] = useState('');
  const [err, setErr] = useState<Record<string, string | null>>({});
  const a = useAction((rid: string) => att2.submitRequest(rid, {
    kind, from, to: kind === 'correction' ? from : to, reason: reason.trim(),
    clockIn: cin ? (toIsoFromLocalInput(cin) ?? undefined) : undefined, clockOut: cout ? (toIsoFromLocalInput(cout) ?? undefined) : undefined,
  }), { topics: AFTER_STAFF, success: t('staff:submitted'), onDone: onClose });
  return (
    <Modal open onClose={onClose} title={kind === 'leave' ? t('staff:newLeave') : t('staff:newCorrection')}>
      <form className="stack" noValidate onSubmit={(e) => {
        e.preventDefault();
        const v: Record<string, string | null> = {
          dates: from && to && from <= to && (kind === 'leave' || from <= today) ? null : 'staff:fixDates',
          reason: reason.trim().length >= 3 ? null : 'staff:needReason',
          times: kind === 'correction' && !cin && !cout ? 'staff:needTime' : null,
        };
        setErr(v);
        if (!v.dates && !v.reason && !v.times) void a.run();
      }}>
        <TextField label={kind === 'leave' ? t('staff:fromDate') : t('staff:correctDate')} type="date" value={from} onChange={(e) => setFrom(e.target.value)} error={err.dates} max={kind === 'correction' ? today : undefined} />
        {kind === 'leave' && <TextField label={t('staff:toDate')} type="date" value={to} min={from} onChange={(e) => setTo(e.target.value)} />}
        {kind === 'correction' && <>
          <TextField label={t('staff:correctIn')} type="datetime-local" value={cin} onChange={(e) => setCin(e.target.value)} error={err.times} />
          <TextField label={t('staff:correctOut')} type="datetime-local" value={cout} onChange={(e) => setCout(e.target.value)} />
        </>}
        <TextArea label={t('staff:reason')} value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} hint={t('staff:reasonHint')} error={err.reason} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('staff:submit')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function Manager({ ctx }: { ctx: StaffContext }) {
  const { t } = useTranslation(['staff', 'common']);
  const from = ymd(addDays(new Date(), -13));
  const to = ymd(new Date());
  const team = useQuery(q.staffTeam(from, to));
  const pending = useQuery(q.staffRequests('decide', 'pending'));
  const [sel, setSel] = useState<string>(ctx.supervisees[0]?.id ?? '');
  const [deciding, setDeciding] = useState<{ r: StaffRequest; decision: 'approve' | 'reject' } | null>(null);
  return (
    <Frame title={t('staff:manager')}>
      <div className="stack">
        <h3>{t('staff:team')}</h3>
        <Query q={team} rows={2}>{(d) => d.staff.length === 0 ? <EmptyState icon="group" title={t('staff:noTeam')} /> : (
          <DataTable<(typeof d.staff)[number]> caption={t('staff:team')} filterLabel={t('staff:team')} getRowId={(r) => r.staff_id} data={d.staff}
            columns={[
              { id: 'name', header: t('staff:staffMember'), accessorFn: (r) => r.name ?? '' },
              { id: 'on_time', header: t('staff:on_time'), accessorFn: (r) => r.totals.on_time }, { id: 'late', header: t('staff:late'), accessorFn: (r) => r.totals.late },
              { id: 'miss', header: t('staff:missing_checkout'), accessorFn: (r) => r.totals.missing_checkout }, { id: 'abs', header: t('staff:absent'), accessorFn: (r) => r.totals.absent },
              { id: 'leave', header: t('staff:leave'), accessorFn: (r) => r.totals.leave },
            ]} />
        )}</Query>
        <h3>{t('staff:toDecide')}</h3>
        <Query q={pending} rows={2}>{(rows) => rows.length === 0 ? <p className="muted">{t('staff:noneToDecide')}</p> : (
          <ul className="list">{rows.map((r) => <RequestItem key={r.id} r={r} showStaff action={<>
            <Button size="sm" icon="check" onClick={() => setDeciding({ r, decision: 'approve' })}>{t('staff:approve')}</Button>
            <Button size="sm" variant="outline" icon="close" onClick={() => setDeciding({ r, decision: 'reject' })}>{t('staff:reject')}</Button></>} />)}</ul>
        )}</Query>
        {ctx.supervisees.length > 0 && <>
          <label className="field"><span>{t('staff:staffMember')}</span>
            <select className="input" value={sel} onChange={(e) => setSel(e.target.value)}>{ctx.supervisees.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}</select></label>
          {sel && <History key={sel} staffId={sel} />}
          {sel && <Schedules key={`s-${sel}`} staffId={sel} />}
        </>}
      </div>
      {deciding && <DecideDialog r={deciding.r} decision={deciding.decision} onClose={() => setDeciding(null)} />}
    </Frame>
  );
}

function DecideDialog({ r, decision, onClose }: { r: StaffRequest; decision: 'approve' | 'reject'; onClose: () => void }) {
  const { t } = useTranslation(['staff', 'common']);
  const [note, setNote] = useState('');
  const a = useAction((rid: string) => att2.decide(r.id, rid, decision, note.trim()), { topics: AFTER_STAFF, success: t('staff:decided'), onDone: onClose });
  return (
    <Modal open onClose={onClose} title={`${t(decision === 'approve' ? 'staff:approve' : 'staff:reject')} · ${r.staff_name ?? ''}`}>
      <form className="stack" onSubmit={(e) => { e.preventDefault(); void a.run(); }}>
        <p>{r.reason}</p>
        <TextArea label={t('staff:noteOptional')} value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t(decision === 'approve' ? 'staff:approve' : 'staff:reject')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function Schedules({ staffId }: { staffId: string }) {
  const { t } = useTranslation(['staff', 'common']);
  const list = useQuery(q.staffSchedules(staffId));
  const [adding, setAdding] = useState(false);
  const end = useAction((_rid: string, id: string) => att2.endSchedule(id, ymd(new Date())), { topics: AFTER_STAFF, success: t('staff:scheduleEnded') });
  return (
    <Frame title={t('staff:schedules')} actions={<Button size="sm" variant="outline" icon="add" onClick={() => setAdding(true)}>{t('staff:addSchedule')}</Button>}>
      <Query q={list} rows={2}>{(rows) => rows.length === 0 ? <p className="muted">{t('staff:noSchedules')}</p> : (
        <ul className="list">{rows.map((s) => (
          <li key={s.id}><div className="grow"><strong>{s.label || t('staff:schedule')}</strong>
            <div className="muted small">{t('staff:scheduleLine', { days: s.weekdays.map((d: number) => t(`staff:d${d}` as 'd1')).join(' '), start: s.start_time.slice(0, 5), end: s.end_time.slice(0, 5), zone: s.timezone, grace: s.late_grace_minutes })}
              {s.effective_to ? ` · → ${formatDay(s.effective_to)}` : ''}</div></div>
            {!s.effective_to && <Button size="sm" variant="text" busy={end.busy} onClick={() => void end.run(s.id)}>{t('staff:endSchedule')}</Button>}</li>))}
        </ul>
      )}</Query>
      <FormError error={end.error} />
      {adding && <ScheduleForm staffId={staffId} onClose={() => setAdding(false)} />}
    </Frame>
  );
}

function ScheduleForm({ staffId, onClose }: { staffId: string; onClose: () => void }) {
  const { t } = useTranslation(['staff', 'common']);
  const [label, setLabel] = useState('');
  const [days, setDays] = useState<number[]>([1, 2, 3, 4, 5]);
  const [start, setStart] = useState('08:30');
  const [endT, setEndT] = useState('16:30');
  const [zone, setZone] = useState('Asia/Bangkok');
  const [grace, setGrace] = useState('10');
  const [eff, setEff] = useState(ymd(new Date()));
  const [err, setErr] = useState<string | null>(null);
  const a = useAction((rid: string) => att2.saveSchedule(staffId, rid, { label: label.trim(), weekdays: days, start, end: endT, timezone: zone.trim(), grace: Number(grace), from: eff }),
    { topics: AFTER_STAFF, success: t('staff:scheduleSaved'), onDone: onClose });
  return (
    <Modal open onClose={onClose} title={t('staff:addSchedule')}>
      <form className="stack" noValidate onSubmit={(e) => {
        e.preventDefault();
        const bad = days.length === 0 ? 'staff:needDays' : !(start && endT && start < endT) ? 'staff:fixTimes' : !Number.isInteger(Number(grace)) || Number(grace) < 0 || Number(grace) > 120 ? 'staff:fixDates' : null;
        setErr(bad);
        if (!bad) void a.run();
      }}>
        <TextField label={t('staff:label')} value={label} onChange={(e) => setLabel(e.target.value)} maxLength={60} />
        <fieldset style={{ border: 0, padding: 0, margin: 0 }}><legend style={{ fontWeight: 500 }}>{t('staff:weekdays')}</legend>
          <div className="checks">{[1, 2, 3, 4, 5, 6, 7].map((d) => (
            <label key={d} className="check"><input type="checkbox" checked={days.includes(d)} onChange={(e) => setDays(e.target.checked ? [...days, d].sort() : days.filter((x) => x !== d))} />{t(`staff:d${d}` as 'd1')}</label>))}
          </div></fieldset>
        <div className="cols">
          <div className="c6"><TextField label={t('staff:start')} type="time" value={start} onChange={(e) => setStart(e.target.value)} /></div>
          <div className="c6"><TextField label={t('staff:end')} type="time" value={endT} onChange={(e) => setEndT(e.target.value)} error={err === 'staff:fixTimes' ? err : null} /></div>
        </div>
        <TextField label={t('staff:zone')} value={zone} onChange={(e) => setZone(e.target.value)} />
        <div className="cols">
          <div className="c6"><TextField label={t('staff:grace')} inputMode="numeric" value={grace} onChange={(e) => setGrace(e.target.value)} /></div>
          <div className="c6"><TextField label={t('staff:effectiveFrom')} type="date" value={eff} onChange={(e) => setEff(e.target.value)} /></div>
        </div>
        {err && err !== 'staff:fixTimes' && <Banner tone="err">{t(err as 'staff:fixDates')}</Banner>}
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('staff:saveSchedule')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}
