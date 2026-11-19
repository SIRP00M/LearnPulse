import { useMemo, useState } from 'react';
import { Link, useNavigate, useParams, useSearch } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/AuthProvider';
import { errorText } from '../lib/errors';
import { api } from '../lib/api/core';
import { q } from '../lib/queries';
import { AFTER_ATTENDANCE, useAction } from '../lib/hooks';
import { addDays, formatInstant, percent, fmtNumber, toIsoFromLocalInput, toLocalInput, weekStart, ymd, formatDay, parseYmd } from '../lib/dates';
import { validateTitle } from '../lib/validators';
import { Banner, Button, Chip, EmptyState, ErrorState, Frame, FormError, Icon, Modal, PageHead, Query, SkeletonBlock, Stat, TextArea, TextField } from '../ui/kit';
import { DataTable } from '../ui/DataTable';
import { AttChip } from '../ui/status';
import type { AttendanceStatus, AttRecord, AttSession, RosterEntry } from '../lib/schemas';
import { QrPanel, RulesPanel, ScanPanel } from './attendance-qr';

const useCourseId = () => (useParams({ strict: false }) as { courseId: string }).courseId;
const STATUSES = ['present', 'late', 'excused', 'absent'] as const;

function NewSession({ courseId, open, onClose }: { courseId: string; open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['attendance', 'common']);
  const nav = useNavigate();
  const [title, setTitle] = useState('');
  const [at, setAt] = useState(() => toLocalInput(new Date().toISOString()));
  const [err, setErr] = useState<{ t?: string | null; a?: string | null }>({});
  const a = useAction((id: string, ti: string, when: string) => api.createSession(courseId, id, ti.trim(), toIsoFromLocalInput(when)!), {
    topics: ['attendance', 'tasks', 'dashboard'], success: t('attendance:created'), onDone: () => { setTitle(''); onClose(); },
  });
  void nav;
  return (
    <Modal open={open} onClose={onClose} title={t('attendance:newSession')}>
      <form className="stack" noValidate onSubmit={(e) => {
        e.preventDefault();
        const v = { t: validateTitle(title, 120), a: toIsoFromLocalInput(at) ? null : 'validation:startRequired' };
        setErr(v);
        if (!v.t && !v.a) void a.run(title, at);
      }}>
        <TextField label={t('attendance:title')} value={title} onChange={(e) => setTitle(e.target.value)} error={err.t} autoFocus hint={t('attendance:titleHint')} />
        <TextField label={t('attendance:startsLocal')} type="datetime-local" value={at} onChange={(e) => setAt(e.target.value)} error={err.a} />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('attendance:createSession')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

export function AttendancePage() {
  const courseId = useCourseId();
  const { profile } = useAuth();
  return profile?.role === 'teacher' ? <TeacherAttendance courseId={courseId} /> : <StudentAttendance courseId={courseId} />;
}

function StudentAttendance({ courseId }: { courseId: string }) {
  const { t } = useTranslation(['attendance', 'status']);
  const recs = useQuery(q.myRecords(courseId));
  const sessions = useQuery(q.sessions(courseId));
  const rows = useMemo(() => {
    const byId = new Map((recs.data ?? []).map((r) => [r.session_id, r]));
    return (sessions.data ?? []).map((s) => ({ s, r: byId.get(s.id) }));
  }, [recs.data, sessions.data]);
  const prog = useQuery(q.myProgress(courseId)); // the server owns every figure; nothing is computed here
  const att = prog.data?.attendance;
  const counts = (st: AttendanceStatus) => att?.[st] ?? 0;
  const rate = att?.rate ?? null;
  if (recs.isPending || sessions.isPending) return <SkeletonBlock rows={5} />;
  if (recs.isError || sessions.isError) return <ErrorState error={recs.error ?? sessions.error} onRetry={() => { void recs.refetch(); void sessions.refetch(); }} />;
  return (
    <div className="stack">
      <ScanPanel />
      <div className="stats">
        <Stat value={percent(rate)} label={t('attendance:rate')} /><Stat value={fmtNumber(counts('present'))} label={t('status:att.present')} /><Stat value={fmtNumber(counts('late'))} label={t('status:att.late')} />
        <Stat value={fmtNumber(counts('excused'))} label={t('status:att.excused')} /><Stat value={fmtNumber(counts('absent'))} label={t('status:att.absent')} tone={counts('absent') ? 'err' : undefined} />
      </div>
      <p className="muted small">{t('attendance:rateNote')}</p>
      <Frame title={t('attendance:sessions')} flush>
        {rows.length === 0 ? <EmptyState icon="event_busy" title={t('attendance:noSessions')}>{t('attendance:noSessionsStudent')}</EmptyState> : (
          <ul className="list">{rows.map(({ s, r }) => (
            <li key={s.id}><div className="grow"><strong>{s.title}</strong><div className="muted small">{formatInstant(s.starts_at)}{r?.checked_in_at ? ` · ${t('attendance:timeIn', { time: formatInstant(r.checked_in_at) })}` : ''}{r?.checked_out_at ? ` · ${t('attendance:timeOut', { time: formatInstant(r.checked_out_at) })}` : ''}{r?.note ? ` · ${r.note}` : ''}</div></div>
              {r ? <AttChip status={r.status} /> : <Chip icon={s.status === 'closed' ? 'remove' : 'schedule'}>{s.status === 'closed' ? t('status:att.unmarked') : t('attendance:scheduled')}</Chip>}</li>))}
          </ul>
        )}
      </Frame>
    </div>
  );
}

function TeacherAttendance({ courseId }: { courseId: string }) {
  const { t } = useTranslation('attendance');
  const search = useSearch({ strict: false }) as { view?: string; week?: string };
  const nav = useNavigate();
  const view = search.view === 'grid' ? 'grid' : 'list';
  const [create, setCreate] = useState(false);
  const setView = (v: string) => void nav({ to: '/courses/$courseId/attendance', params: { courseId }, search: { ...search, view: v }, replace: true });
  return (
    <div className="stack">
      <div className="row between">
        <div className="row" role="group" aria-label={t('view')}>
          <Button variant={view === 'list' ? 'tonal' : 'outline'} aria-pressed={view === 'list'} icon="list" onClick={() => setView('list')}>{t('sessions')}</Button>
          <Button variant={view === 'grid' ? 'tonal' : 'outline'} aria-pressed={view === 'grid'} icon="grid_on" onClick={() => setView('grid')}>{t('weeklyGrid')}</Button>
        </div>
        <Button icon="add" onClick={() => setCreate(true)}>{t('newSessionBtn')}</Button>
      </div>
      {view === 'list' ? <SessionList courseId={courseId} /> : <WeeklyGrid courseId={courseId} week={search.week} />}
      <NewSession courseId={courseId} open={create} onClose={() => setCreate(false)} />
    </div>
  );
}

function SessionList({ courseId }: { courseId: string }) {
  const { t } = useTranslation(['attendance', 'status']);
  const sessions = useQuery(q.sessions(courseId));
  const summary = useQuery(q.attendanceSummary(courseId));
  const nav = useNavigate();
  const cols: ColumnDef<AttSession, unknown>[] = [
    { id: 'title', header: t('attendance:colSession'), accessorKey: 'title', cell: (c) => <Link to="/courses/$courseId/attendance/$id" params={{ courseId, id: c.row.original.id }}><strong>{c.row.original.title}</strong></Link> },
    { id: 'when', header: t('attendance:colStarts'), accessorKey: 'starts_at', cell: (c) => formatInstant(c.getValue() as string) },
    { id: 'status', header: t('attendance:colStatus'), accessorKey: 'status', cell: (c) => <Chip tone={c.getValue() === 'closed' ? 'ok' : 'info'} icon={c.getValue() === 'closed' ? 'lock' : 'lock_open'}>{c.getValue() === 'closed' ? t('status:session.closed') : t('status:session.open')}</Chip> },
  ];
  return (
    <>
      <Frame title={t('attendance:sessions')} flush>
        <Query q={sessions}>{(rows) => (
          <DataTable<AttSession> caption={t('attendance:captionSessions')} data={rows} columns={cols} getRowId={(r) => r.id} filterLabel={t('attendance:filterSessions')}
            onRowActivate={(r) => void nav({ to: '/courses/$courseId/attendance/$id', params: { courseId, id: r.id } })}
            empty={<EmptyState icon="event_busy" title={t('attendance:noSessions')}>{t('attendance:noSessionsTeacher')}</EmptyState>} />
        )}</Query>
      </Frame>
      <Frame title={t('attendance:byStudent')} flush>
        <Query q={summary}>{(s) => (
          <DataTable<(typeof s.students)[number]> caption={t('attendance:byStudent')} exportName="attendance-summary" getRowId={(r) => r.student_id} filterLabel={t('attendance:filterStudents')} data={s.students}
            columns={[
              { id: 'name', header: t('attendance:colStudent'), accessorFn: (r) => r.full_name ?? '' },
              { accessorKey: 'present', header: t('status:att.present') }, { accessorKey: 'late', header: t('status:att.late') }, { accessorKey: 'excused', header: t('status:att.excused') }, { accessorKey: 'absent', header: t('status:att.absent') },
              { id: 'rate', header: t('attendance:colRate'), accessorFn: (r) => r.rate ?? -1, cell: (c) => percent(c.row.original.rate) },
            ]}
            empty={<EmptyState icon="group" title={t('attendance:noStudents')} />} />
        )}</Query>
      </Frame>
    </>
  );
}

/** One select per cell: keyboard-operable, with the previous value kept visible while saving. */
function MarkSelect({ session, student, record, label }: { session: AttSession; student: string; record?: AttRecord; label: string }) {
  const { t } = useTranslation(['attendance', 'status']);
  const [pending, setPending] = useState<AttendanceStatus | null>(null);
  const a = useAction((id: string, st: AttendanceStatus, why?: string) => api.markAttendance({ sessionId: session.id, studentId: student, requestId: id, version: record?.version ?? 0, status: st, note: why ?? record?.note ?? '' }),
    { topics: AFTER_ATTENDANCE, success: t('attendance:saved'), onDone: () => setPending(null) });
  const locked = session.status === 'closed' && !record;
  return (
    <>
      <label className="sr-only" htmlFor={`m-${session.id}-${student}`}>{label}</label>
      <select id={`m-${session.id}-${student}`} className="input" style={{ minHeight: 34, minWidth: 110, padding: '2px 6px' }} value={record?.status ?? ''} disabled={a.busy || locked}
        aria-invalid={a.error ? true : undefined} title={a.error ? errorText(a.error) : undefined}
        onChange={(e) => { const st = e.target.value as AttendanceStatus; if (record) setPending(st); else void a.run(st); }}>
        <option value="" disabled>{locked ? t('attendance:closedOption') : t('status:att.unmarked')}</option>
        {STATUSES.map((s) => <option key={s} value={s}>{t(`status:att.${s}`)}</option>)}
      </select>
      {a.error && !pending && <span className="err-text small" role="alert">{errorText(a.error)}</span>}
      {pending && <CorrectDialog label={label} from={record?.status} to={pending} busy={a.busy} error={a.error}
        onCancel={() => setPending(null)} onSave={(why) => void a.run(pending, why)} />}
    </>
  );
}

/** Changing an existing record is a correction: it needs a reason, which the audit history keeps with who and when. */
function CorrectDialog({ label, from, to, busy, error, onCancel, onSave }: {
  label: string; from?: AttendanceStatus; to: AttendanceStatus; busy: boolean; error: unknown; onCancel: () => void; onSave: (why: string) => void;
}) {
  const { t } = useTranslation(['attendance', 'status', 'common']);
  const [why, setWhy] = useState('');
  const [err, setErr] = useState<string | null>(null);
  return (
    <Modal open onClose={onCancel} title={t('attendance:correctTitle')} description={label}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); if (why.trim().length < 3) { setErr('attendance:correctReasonRequired'); return; } setErr(null); onSave(why.trim()); }}>
        <p>{t('attendance:correctChange', { from: from ? t(`status:att.${from}`) : '—', to: t(`status:att.${to}`) })}</p>
        <TextArea label={t('attendance:correctReason')} value={why} onChange={(e) => setWhy(e.target.value)} maxLength={500} error={err} autoFocus />
        <FormError error={error} />
        <div className="row"><Button type="submit" busy={busy}>{t('attendance:correctSave')}</Button><Button variant="text" onClick={onCancel}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

function WeeklyGrid({ courseId, week }: { courseId: string; week?: string }) {
  const { t } = useTranslation(['attendance', 'status', 'common', 'table']);
  const nav = useNavigate();
  const start = weekStart(week ? parseYmd(week) : new Date());
  const end = addDays(start, 7);
  const sessions = useQuery(q.sessions(courseId));
  const roster = useQuery(q.roster(courseId));
  const inWeek = useMemo(() => (sessions.data ?? []).filter((s) => { const at = new Date(s.starts_at); return at >= start && at < end; }).sort((a, b) => a.starts_at.localeCompare(b.starts_at)), [sessions.data, start, end]);
  const recs = useQuery(q.courseRecords(inWeek.map((s) => s.id)));
  const go = (d: Date) => void nav({ to: '/courses/$courseId/attendance', params: { courseId }, search: { view: 'grid', week: ymd(d) }, replace: true });
  if (sessions.isPending || roster.isPending) return <SkeletonBlock rows={5} />;
  if (sessions.isError || roster.isError) return <ErrorState error={sessions.error ?? roster.error} onRetry={() => { void sessions.refetch(); void roster.refetch(); }} />;
  const students = (roster.data ?? []).filter((r: RosterEntry) => r.status === 'active');
  const rec = new Map((recs.data ?? []).map((r) => [`${r.session_id}:${r.student_id}`, r]));
  return (
    <Frame title={t('attendance:weekOf', { date: formatDay(ymd(start)) })} actions={<>
      <Button variant="outline" size="sm" icon="chevron_left" onClick={() => go(addDays(start, -7))} aria-label={t('attendance:prevWeek')} />
      <Button variant="outline" size="sm" onClick={() => go(new Date())}>{t('attendance:thisWeek')}</Button>
      <Button variant="outline" size="sm" icon="chevron_right" onClick={() => go(addDays(start, 7))} aria-label={t('attendance:nextWeek')} />
    </>} flush>
      {inWeek.length === 0 ? <EmptyState icon="event_busy" title={t('attendance:noSessionsWeek')}>{t('attendance:noSessionsWeekText')}</EmptyState>
        : students.length === 0 ? <EmptyState icon="group" title={t('attendance:noActiveStudents')} /> : (
          <div className="table-wrap" tabIndex={0} role="region" aria-label={t('table:scrollable', { caption: t('attendance:gridCaption') })}>
            <table className="tbl">
              <caption className="sr-only">{t('attendance:gridCaption')}</caption>
              <thead><tr><th scope="col" className="sticky-col">{t('attendance:colStudent')}</th>{inWeek.map((s) => (
                <th scope="col" key={s.id}><Link to="/courses/$courseId/attendance/$id" params={{ courseId, id: s.id }}>{s.title}</Link><div className="small muted">{formatInstant(s.starts_at)} · {s.status === 'closed' ? t('status:session.closed') : t('status:session.open')}</div></th>))}</tr></thead>
              <tbody>{students.map((st) => (
                <tr key={st.student_id}><th scope="row" className="sticky-col" style={{ textAlign: 'left', background: 'var(--lp-frame)' }}>{st.student?.full_name ?? t('common:student')}</th>
                  {inWeek.map((s) => <td key={s.id} className="cell"><MarkSelect session={s} student={st.student_id} record={rec.get(`${s.id}:${st.student_id}`)} label={t('attendance:cellLabel', { name: st.student?.full_name ?? t('common:student'), session: s.title })} /></td>)}</tr>))}
              </tbody>
            </table>
          </div>
        )}
    </Frame>
  );
}

export function AttendanceSessionPage() {
  const { t } = useTranslation(['attendance', 'status', 'common']);
  const courseId = useCourseId();
  const { id } = useParams({ strict: false }) as { id: string };
  const session = useQuery(q.session(id));
  const roster = useQuery(q.roster(courseId));
  const recs = useQuery(q.sessionRecords(id));
  const events = useQuery(q.sessionEvents(id));
  const [confirm, setConfirm] = useState(false);
  const [note, setNote] = useState<{ student: string; name: string } | null>(null);
  const close = useAction((rid: string) => api.closeSession(id, rid, session.data!.version), { topics: AFTER_ATTENDANCE, success: t('attendance:closedToast'), onDone: () => setConfirm(false) });
  if (session.isPending || roster.isPending || recs.isPending) return <SkeletonBlock rows={6} />;
  const failed = session.error ?? roster.error ?? recs.error;
  if (failed) return <ErrorState error={failed} onRetry={() => { void session.refetch(); void roster.refetch(); void recs.refetch(); }} />;
  const s = session.data;
  if (!s) return <ErrorState error={{ code: 'PT404' }} />;
  const rec = new Map((recs.data ?? []).map((r) => [r.student_id, r]));
  const students = (roster.data ?? []).filter((r) => r.status === 'active');
  const unmarked = students.filter((x) => !rec.has(x.student_id)).length;
  type Row = RosterEntry & { name: string };
  return (
    <div className="stack">
      <PageHead title={s.title} sub={`${formatInstant(s.starts_at)} · ${s.status === 'closed' ? t('status:session.closed') : t('status:session.open')}`}
        actions={<>
          <Link activeOptions={{ exact: true }} to="/courses/$courseId/attendance" params={{ courseId }} className="btn text"><Icon name="arrow_back" />{t('attendance:sessions')}</Link>
          {s.status === 'open' && <Button icon="lock" onClick={() => setConfirm(true)}>{t('attendance:closeSession')}</Button>}
        </>} />
      {s.status === 'closed' && <Banner icon="lock">{t('attendance:closedBanner')}</Banner>}
      {s.status === 'open' && <div className="cols"><div className="c6"><QrPanel session={s} /></div><div className="c6"><RulesPanel key={s.version} session={s} /></div></div>}
      <Frame title={t('attendance:students')} flush>
        <DataTable<Row> caption={t('attendance:markCaption')} exportName={`attendance-${s.title}`} filterLabel={t('attendance:filterStudents')} getRowId={(r) => r.student_id}
          data={students.map((r) => ({ ...r, name: r.student?.full_name ?? t('common:student') }))}
          columns={[
            { id: 'name', header: t('attendance:colStudent'), accessorKey: 'name' },
            { id: 'mark', header: t('attendance:colAttendance'), enableSorting: false, accessorFn: (r) => rec.get(r.student_id)?.status ?? '', cell: (c) => <MarkSelect session={s} student={c.row.original.student_id} record={rec.get(c.row.original.student_id)} label={t('attendance:markFor', { name: c.row.original.name })} /> },
            { id: 'times', header: t('attendance:colTimes'), enableSorting: false, accessorFn: (r) => rec.get(r.student_id)?.checked_in_at ?? '', cell: (c) => {
              const r = rec.get(c.row.original.student_id);
              if (!r) return '—';
              return <span className="small" data-testid="att-times">{r.checked_in_at ? t('attendance:timeIn', { time: formatInstant(r.checked_in_at) }) : t('attendance:noTimes')}{r.checked_out_at ? <><br />{t('attendance:timeOut', { time: formatInstant(r.checked_out_at) })}</> : null}{r.source === 'qr' ? <> <Chip icon="qr_code_2">{t('attendance:viaQr')}</Chip></> : null}</span>;
            } },
            { id: 'note', header: t('attendance:colNote'), accessorFn: (r) => rec.get(r.student_id)?.note ?? '', cell: (c) => (
              <Button size="sm" variant="text" icon="edit_note" disabled={!rec.get(c.row.original.student_id)} onClick={() => setNote({ student: c.row.original.student_id, name: c.row.original.name })}>
                {rec.get(c.row.original.student_id)?.note || (rec.get(c.row.original.student_id) ? t('attendance:addNote') : '—')}</Button>) },
          ]}
          empty={<EmptyState icon="group" title={t('attendance:noActiveStudents')} />} />
      </Frame>
      <Frame title={t('attendance:history')} flush>
        <Query q={events} rows={2}>{(ev) => ev.length === 0 ? <EmptyState icon="history" title={t('attendance:noChanges')} /> : (
          <ul className="list">{ev.map((e, i) => <li key={i}><div className="grow"><strong>{e.action === 'closed' ? t('attendance:eventClosed') : t(e.action === 'corrected' ? 'attendance:eventCorrected' : 'attendance:eventMarked', { status: e.new_status ? t(`status:att.${e.new_status as 'present'}`, { defaultValue: e.new_status }) : '' })}</strong>
            <div className="muted small">{formatInstant(e.created_at)}{e.old_status ? ` · ${t('attendance:wasStatus', { status: t(`status:att.${e.old_status as 'present'}`, { defaultValue: e.old_status }) })}` : ''}{e.note ? ` · ${e.note}` : ''}</div></div></li>)}</ul>
        )}</Query>
      </Frame>
      <Modal open={confirm} onClose={() => setConfirm(false)} title={t('attendance:closeTitle')} description={t('attendance:closeDesc')}>
        <Banner tone="warn">{unmarked > 0 ? `${t('attendance:closeUnmarked', { count: unmarked })} ` : ''}{t('attendance:closeCorrect')}</Banner>
        <FormError error={close.error} />
        <div className="row"><Button busy={close.busy} icon="lock" onClick={() => void close.run()}>{t('attendance:closeSession')}</Button><Button variant="text" onClick={() => setConfirm(false)}>{t('common:cancel')}</Button></div>
      </Modal>
      {note && <NoteDialog key={note.student} session={s} record={rec.get(note.student)!} name={note.name} onClose={() => setNote(null)} />}
    </div>
  );
}

function NoteDialog({ session, record, name, onClose }: { session: AttSession; record: AttRecord; name: string; onClose: () => void }) {
  const { t } = useTranslation(['attendance', 'common']);
  const [text, setText] = useState(record.note ?? '');
  const a = useAction((id: string, n: string) => api.markAttendance({ sessionId: session.id, studentId: record.student_id, requestId: id, version: record.version, status: record.status, note: n.trim() }),
    { topics: AFTER_ATTENDANCE, success: t('attendance:noteSaved'), onDone: onClose });
  return (
    <Modal open onClose={onClose} title={t('attendance:noteFor', { name })}>
      <form className="stack" onSubmit={(e) => { e.preventDefault(); void a.run(text); }}>
        <TextArea label={t('attendance:noteLabel')} value={text} onChange={(e) => setText(e.target.value)} maxLength={500} hint={t('common:countOf', { count: fmtNumber(text.length), max: fmtNumber(500) })} autoFocus />
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy}>{t('attendance:saveNote')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}
