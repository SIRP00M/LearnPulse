import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useNavigate, useParams, useSearch } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import type { ColumnDef } from '@tanstack/react-table';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/AuthProvider';
import { tr } from '../i18n';
import { api, checkUpload } from '../lib/api/core';
import { q } from '../lib/queries';
import { AFTER_ASSIGNMENT, useAction } from '../lib/hooks';
import { fmtNumber, formatInstant, toIsoFromLocalInput, toLocalInput } from '../lib/dates';
import { validateTitle } from '../lib/validators';
import { Banner, Button, Chip, EmptyState, ErrorState, Frame, FormError, Icon, Modal, PageHead, Query, SkeletonBlock, TextArea, TextField } from '../ui/kit';
import { DataTable } from '../ui/DataTable';
import { SubChip, TaskChip } from '../ui/status';
import { ACCEPT, FileLink } from './lessons';
import { Avatar } from '../ui/Avatar';
import type { Assignment, Submission } from '../lib/schemas';

const FEEDBACK_MAX = 5000;
const ANSWER_MAX = 20000;
const useCourseId = () => (useParams({ strict: false }) as { courseId: string }).courseId;

function AssignmentForm({ courseId, a, open, onClose }: { courseId: string; a?: Assignment; open: boolean; onClose: () => void }) {
  const { t } = useTranslation(['assignments', 'common', 'validation']);
  const [title, setTitle] = useState(a?.title ?? '');
  const [ins, setIns] = useState(a?.instructions ?? '');
  const [max, setMax] = useState(String(a?.max_score ?? 100));
  const [due, setDue] = useState(toLocalInput(a?.due_at));
  const [errs, setErrs] = useState<{ t?: string | null; m?: string | null; d?: string | null }>({});
  const act = useAction(async (_id: string, ti: string, i: string, m: number, d: string) => {
    const dueAt = toIsoFromLocalInput(d);
    if (a) await api.updateAssignment(a.id, a.version, { title: ti.trim(), instructions: i, maxScore: m, dueAt: dueAt });
    else await api.createAssignment({ courseId, title: ti.trim(), instructions: i, maxScore: m, dueAt });
  }, { topics: ['assignments', 'tasks', 'dashboard'], success: a ? t('assignments:savedToast') : t('assignments:createdDraft'), onDone: onClose });
  return (
    <Modal open={open} onClose={onClose} title={a ? t('assignments:editAssignment') : t('assignments:newAssignment')}>
      <form className="stack" noValidate onSubmit={(e) => {
        e.preventDefault();
        const m = Number(max);
        const v = { t: validateTitle(title, 120), m: Number.isInteger(m) && m >= 1 && m <= 1000 ? null : 'validation:maxScoreRange', d: due && !toIsoFromLocalInput(due) ? 'validation:dateInvalid' : null };
        setErrs(v);
        if (!v.t && !v.m && !v.d) void act.run(title, ins, m, due);
      }}>
        <TextField label={t('assignments:title')} value={title} onChange={(e) => setTitle(e.target.value)} error={errs.t} autoFocus />
        <TextArea label={t('assignments:instructions')} value={ins} onChange={(e) => setIns(e.target.value)} maxLength={10000} style={{ minHeight: 140 }} />
        <div className="row">
          <div className="grow"><TextField label={t('assignments:maxScore')} inputMode="numeric" value={max} onChange={(e) => setMax(e.target.value)} error={errs.m} /></div>
          <div className="grow"><TextField label={t('assignments:dueLocal')} type="datetime-local" value={due} onChange={(e) => setDue(e.target.value)} error={errs.d} hint={a ? t('assignments:dueHintEdit') : t('common:optional')} /></div>
        </div>
        <FormError error={act.error} />
        <div className="row"><Button type="submit" busy={act.busy}>{t('common:save')}</Button><Button variant="text" onClick={onClose}>{t('common:cancel')}</Button></div>
      </form>
    </Modal>
  );
}

export function AssignmentsPage() {
  const { t } = useTranslation(['assignments', 'status', 'common']);
  const courseId = useCourseId();
  const { profile } = useAuth();
  const teacher = profile?.role === 'teacher';
  const list = useQuery(q.assignments(courseId));
  const mine = useQuery({ ...q.mySubmissions(), enabled: !teacher });
  const [create, setCreate] = useState(false);
  const nav = useNavigate();
  type Row = Assignment & { sub?: Submission };
  const subs = new Map((mine.data ?? []).map((s) => [s.assignment_id, s]));
  const cols: ColumnDef<Row, unknown>[] = [
    { id: 'title', header: t('assignments:colAssignment'), accessorKey: 'title', cell: (c) => <Link to="/courses/$courseId/assignments/$id" params={{ courseId, id: c.row.original.id }}><strong>{c.row.original.title}</strong></Link> },
    { id: 'due', header: t('assignments:colDue'), accessorFn: (r) => r.due_at ?? '', cell: (c) => (c.row.original.due_at ? formatInstant(c.row.original.due_at) : t('common:noDueDate')) },
    { accessorKey: 'max_score', header: t('assignments:colMaxScore') },
    teacher
      ? { id: 'status', header: t('assignments:colStatus'), accessorKey: 'status', cell: (c) => <TaskChip status={c.getValue() as string} /> }
      : { id: 'status', header: t('assignments:colYourStatus'), accessorFn: (r) => r.sub?.status ?? 'none', cell: (c) => (c.row.original.sub ? <SubChip status={c.row.original.sub.status} /> : <Chip icon="radio_button_unchecked">{t('assignments:notSubmitted')}</Chip>) },
    ...(teacher ? [] : [{ id: 'score', header: t('assignments:colScore'), accessorFn: (r: Row) => r.sub?.score ?? '', cell: (c: { row: { original: Row } }) => (c.row.original.sub?.status === 'graded' ? `${fmtNumber(c.row.original.sub.score ?? 0)}/${fmtNumber(c.row.original.max_score)}` : '—') } as ColumnDef<Row, unknown>]),
  ];
  return (
    <>
      {teacher && <div style={{ marginBottom: 16 }}><Button icon="add" onClick={() => setCreate(true)}>{t('assignments:newAssignment')}</Button></div>}
      <Frame flush>
        <Query q={list}>
          {(rows) => (
            <DataTable<Row> caption={t('assignments:caption')} data={rows.map((r) => ({ ...r, sub: subs.get(r.id) }))} columns={cols} getRowId={(r) => r.id} filterLabel={t('assignments:filter')}
              onRowActivate={(r) => void nav({ to: '/courses/$courseId/assignments/$id', params: { courseId, id: r.id } })}
              empty={<EmptyState icon="assignment" title={t('assignments:empty')}>{teacher ? t('assignments:emptyTeacher') : t('assignments:emptyStudent')}</EmptyState>} />
          )}
        </Query>
      </Frame>
      {teacher && <AssignmentForm courseId={courseId} open={create} onClose={() => setCreate(false)} />}
    </>
  );
}

export function AssignmentDetailPage() {
  const courseId = useCourseId();
  const { id } = useParams({ strict: false }) as { id: string };
  const { profile } = useAuth();
  const list = useQuery(q.assignments(courseId));
  if (list.isPending) return <SkeletonBlock rows={5} />;
  if (list.isError) return <ErrorState error={list.error} onRetry={() => void list.refetch()} />;
  const a = list.data.find((x) => x.id === id);
  if (!a) return <ErrorState error={{ code: 'PT404' }} />;
  return profile?.role === 'teacher' ? <TeacherAssignment a={a} courseId={courseId} /> : <StudentAssignment a={a} />;
}

function Instructions({ a }: { a: Assignment }) {
  const { t } = useTranslation(['assignments', 'common']);
  return (
    <Frame title={t('assignments:instructionsTitle')}>
      <div className="stack">
        {a.instructions ? <p className="pre">{a.instructions}</p> : <p className="muted">{t('assignments:noInstructions')}</p>}
        <div className="row"><Chip icon="event">{a.due_at ? t('common:dueAt', { when: formatInstant(a.due_at) }) : t('common:noDueDate')}</Chip><Chip icon="grade">{t('assignments:maxScoreChip', { score: fmtNumber(a.max_score) })}</Chip></div>
      </div>
    </Frame>
  );
}

function StudentAssignment({ a }: { a: Assignment }) {
  const { t } = useTranslation(['assignments', 'common']);
  const mine = useQuery(q.mySubmissions());
  const sub = mine.data?.find((s) => s.assignment_id === a.id);
  const [answer, setAnswer] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [fileErr, setFileErr] = useState<string | null>(null);
  const [clear, setClear] = useState(false);
  const input = useRef<HTMLInputElement>(null);
  const seeded = useRef<string | null>(null);
  useEffect(() => { // seed the editor once per saved version, never overwriting what the student is typing
    if (sub && seeded.current !== sub.id) { seeded.current = sub.id; setAnswer(sub.answer ?? ''); }
  }, [sub]);
  const returned = sub?.status === 'returned';
  const graded = sub?.status === 'graded';
  const closed = !!a.due_at && Date.now() > new Date(a.due_at).getTime() && !returned;
  const act = useAction((requestId: string, ans: string, f: File | null, expectedVersion: number | undefined, clr: boolean) =>
    api.submit({ assignmentId: a.id, requestId, answer: ans, file: f, expectedVersion, clearAttachment: clr }), {
    topics: AFTER_ASSIGNMENT, success: sub ? t('assignments:resubmitted') : t('assignments:submitted'),
    onDone: () => { setFile(null); setClear(false); if (input.current) input.current.value = ''; },
  });
  if (mine.isPending) return <SkeletonBlock rows={5} />;
  if (mine.isError) return <ErrorState error={mine.error} onRetry={() => void mine.refetch()} />;
  const canSubmit = !closed && !graded;
  return (
    <div className="cols">
      <div className="c8 stack">
        <Instructions a={a} />
        <Frame title={t('assignments:yourWork')}>
          <div className="stack">
            {sub && <div className="row"><SubChip status={sub.status} /><span className="muted small">{t('assignments:submittedAt', { when: formatInstant(sub.submitted_at) })}</span></div>}
            {graded && <Banner tone="ok" icon="grade"><strong>{t('assignments:scoreBanner', { score: fmtNumber(sub!.score ?? 0), max: fmtNumber(a.max_score) })}</strong>{sub!.feedback ? <p className="pre" style={{ marginTop: 4 }}>{sub!.feedback}</p> : null}</Banner>}
            {returned && <Banner tone="warn" icon="undo"><strong>{t('assignments:returnedBanner')}</strong>{sub!.feedback ? <p className="pre" style={{ marginTop: 4 }}>{sub!.feedback}</p> : null}{t('assignments:reviseHint')}</Banner>}
            {closed && !sub && <Banner tone="warn">{t('assignments:closed')}</Banner>}
            {closed && sub && !graded && <Banner tone="info">{t('assignments:locked')}</Banner>}
            {sub?.upload && <div><FileLink name={sub.upload.file_name} size={sub.upload.size_bytes} path={sub.upload.storage_path} source="submission" /></div>}
            {canSubmit ? (
              <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); if (!answer.trim() && !file && !(sub?.upload && !clear)) return; void act.run(answer, file, sub?.version, clear); }}>
                <TextArea label={t('assignments:yourAnswer')} value={answer} onChange={(e) => setAnswer(e.target.value)} maxLength={ANSWER_MAX} style={{ minHeight: 180 }}
                  hint={t('common:characters', { count: fmtNumber(answer.length), max: fmtNumber(ANSWER_MAX) })} />
                <div className="stack-s">
                  <label htmlFor="up" className="lbl" style={{ fontWeight: 500 }}>{t('assignments:attachOptional')}</label>
                  <input id="up" ref={input} type="file" accept={ACCEPT} onChange={(e) => { const f = e.target.files?.[0] ?? null; const bad = f ? checkUpload(f) : null; setFileErr(bad); setFile(bad ? null : f); }} />
                  {fileErr && <span className="err-text" role="alert">{tr(fileErr)}</span>}
                  <span className="hint">{t('common:uploadHint')}</span>
                  {sub?.upload && !file && <label className="check" style={{ alignSelf: 'flex-start' }}><input type="checkbox" checked={clear} onChange={(e) => setClear(e.target.checked)} />{t('assignments:removeAttachment')}</label>}
                </div>
                <FormError error={act.error} />
                {act.error?.kind === 'conflict' && <Banner tone="warn">{t('assignments:conflictBanner')}</Banner>}
                <div className="row"><Button type="submit" busy={act.busy} icon="send" disabled={!answer.trim() && !file && !(sub?.upload && !clear)}>{sub ? t('assignments:resubmit') : t('assignments:submit')}</Button></div>
              </form>
            ) : sub?.answer ? <div><strong>{t('assignments:yourAnswer')}</strong><p className="pre">{sub.answer}</p></div> : null}
          </div>
        </Frame>
      </div>
      <div className="c4">
        <Frame title={t('assignments:details')}>
          <dl className="kv"><dt>{t('assignments:detailMax')}</dt><dd>{fmtNumber(a.max_score)}</dd><dt>{t('assignments:detailDue')}</dt><dd>{a.due_at ? formatInstant(a.due_at) : t('common:noDueDate')}</dd>
            <dt>{t('assignments:detailStatus')}</dt><dd>{sub ? <SubChip status={sub.status} /> : t('assignments:notSubmitted')}</dd></dl>
        </Frame>
      </div>
    </div>
  );
}

function TeacherAssignment({ a, courseId }: { a: Assignment; courseId: string }) {
  const { t } = useTranslation(['assignments', 'common']);
  const subs = useQuery(q.submissions(a.id));
  const [edit, setEdit] = useState(false);
  const nav = useNavigate();
  const pub = useAction((_id: string) => api.publishAssignment(a.id, a.version), { topics: ['assignments', 'tasks', 'dashboard'], success: t('assignments:published') });
  type Row = Submission & { name: string };
  const cols: ColumnDef<Row, unknown>[] = [
    { id: 'name', header: t('assignments:colStudent'), accessorKey: 'name', cell: (c) => <Link to="/courses/$courseId/assignments/$id/grade" params={{ courseId, id: a.id }} search={{ s: c.row.original.id }}><strong>{c.row.original.name}</strong></Link> },
    { id: 'status', header: t('assignments:colStatus'), accessorKey: 'status', cell: (c) => <SubChip status={c.getValue() as string} /> },
    { id: 'score', header: t('assignments:colScore'), accessorFn: (r) => r.score ?? '', cell: (c) => (c.row.original.score != null ? `${fmtNumber(c.row.original.score)}/${fmtNumber(a.max_score)}` : '—') },
    { id: 'at', header: t('assignments:colSubmitted'), accessorKey: 'submitted_at', cell: (c) => formatInstant(c.getValue() as string) },
    { id: 'file', header: t('assignments:colFile'), accessorFn: (r) => r.upload?.file_name ?? '' , cell: (c) => (c.row.original.upload ? <Icon name="attach_file" label={t('assignments:hasAttachment')} /> : '') },
  ];
  const awaiting = (subs.data ?? []).filter((s) => s.status === 'submitted').length;
  return (
    <div className="stack">
      <div className="row">
        <Button variant="outline" icon="edit" onClick={() => setEdit(true)}>{t('common:edit')}</Button>
        {a.status === 'draft' && <Button icon="publish" busy={pub.busy} onClick={() => void pub.run()}>{t('assignments:publishToStudents')}</Button>}
        <TaskChip status={a.status} />
        {a.status === 'published' && <Link activeOptions={{ exact: true }} to="/courses/$courseId/assignments/$id/grade" params={{ courseId, id: a.id }} search={{}} className="btn tonal"><Icon name="rate_review" />{awaiting ? t('assignments:openGradingCount', { count: awaiting }) : t('assignments:openGrading')}</Link>}
      </div>
      <FormError error={pub.error} />
      <Instructions a={a} />
      <Frame title={t('assignments:submissions')} flush>
        <Query q={subs}>
          {(rows) => (
            <DataTable<Row> caption={t('assignments:submissions')} exportName={`submissions-${a.title}`} data={rows.map((r) => ({ ...r, name: r.student?.full_name ?? t('common:student') }))} columns={cols} getRowId={(r) => r.id} filterLabel={t('assignments:filterStudents')}
              onRowActivate={(r) => void nav({ to: '/courses/$courseId/assignments/$id/grade', params: { courseId, id: a.id }, search: { s: r.id } })}
              empty={<EmptyState icon="inbox" title={t('assignments:noSubmissions')}>{a.status === 'draft' ? t('assignments:noSubmissionsDraft') : t('assignments:noSubmissionsPublished')}</EmptyState>} />
          )}
        </Query>
      </Frame>
      <AssignmentForm courseId={courseId} a={a} open={edit} onClose={() => setEdit(false)} />
    </div>
  );
}

// ── Desktop grading workspace ─────────────────────────────────
export function GradingWorkspace() {
  const { t } = useTranslation(['assignments', 'common']);
  const courseId = useCourseId();
  const { id } = useParams({ strict: false }) as { id: string };
  const search = useSearch({ strict: false }) as { s?: string };
  const nav = useNavigate();
  const list = useQuery(q.assignments(courseId));
  const subs = useQuery(q.submissions(id));
  const a = list.data?.find((x) => x.id === id);
  const [filter, setFilter] = useState<'all' | 'submitted' | 'returned' | 'graded'>('submitted');
  const [live, setLive] = useState('');
  const shown = useMemo(() => (subs.data ?? []).filter((s) => filter === 'all' || s.status === filter), [subs.data, filter]);
  const sel = (subs.data ?? []).find((s) => s.id === search.s) ?? shown[0];
  const go = (s?: Submission) => { if (s) { void nav({ to: '/courses/$courseId/assignments/$id/grade', params: { courseId, id }, search: { s: s.id }, replace: true }); setLive(`${s.student?.full_name ?? t('common:student')}, ${s.status === 'graded' ? t('assignments:filterGraded') : s.status === 'returned' ? t('assignments:filterReturned') : t('assignments:queueAwaiting')}`); } };
  const idx = sel ? shown.findIndex((s) => s.id === sel.id) : -1;
  function onKey(e: React.KeyboardEvent) {
    if (!e.altKey) return;
    if (e.key === 'ArrowDown') { e.preventDefault(); go(shown[Math.min(shown.length - 1, idx + 1)]); }
    if (e.key === 'ArrowUp') { e.preventDefault(); go(shown[Math.max(0, idx - 1)]); }
  }
  if (list.isPending || subs.isPending) return <SkeletonBlock rows={6} />;
  if (list.isError || subs.isError) return <ErrorState error={list.error ?? subs.error} onRetry={() => { void list.refetch(); void subs.refetch(); }} />;
  if (!a) return <ErrorState error={{ code: 'PT404' }} />;
  return (
    <div onKeyDown={onKey}>
      <PageHead title={t('assignments:gradeTitle', { title: a.title })} sub={t('assignments:gradeSub')} actions={<Link activeOptions={{ exact: true }} to="/courses/$courseId/assignments/$id" params={{ courseId, id }} className="btn text"><Icon name="arrow_back" />{t('assignments:assignmentLink')}</Link>} />
      <div className="sr-only" aria-live="polite">{live}</div>
      <div className="split three">
        <Frame title={t('assignments:queue')} flush>
          <div className="tbl-tools">
            <label className="sr-only" htmlFor="qf">{t('assignments:show')}</label>
            <select id="qf" className="input" style={{ minHeight: 36 }} value={filter} onChange={(e) => setFilter(e.target.value as typeof filter)}>
              <option value="submitted">{t('assignments:filterAwaiting', { count: (subs.data ?? []).filter((s) => s.status === 'submitted').length })}</option>
              <option value="returned">{t('assignments:filterReturned')}</option><option value="graded">{t('assignments:filterGraded')}</option><option value="all">{t('assignments:filterAll')}</option>
            </select>
          </div>
          {shown.length === 0 ? <EmptyState icon="done_all" title={t('assignments:nothingHere')} /> : (
            <ul className="queue" aria-label={t('assignments:submissions')}>
              {shown.map((s) => (
                <li key={s.id}><button aria-current={sel?.id === s.id} onClick={() => go(s)}>
                  <span className="row" style={{ flexWrap: 'nowrap' }}><Avatar userId={s.student_id} name={s.student?.full_name ?? ''} size={24} /><strong>{s.student?.full_name ?? t('common:student')}</strong></span>
                  <span className="small">{s.status === 'graded' ? t('assignments:queueGraded', { score: fmtNumber(s.score ?? 0), max: fmtNumber(a.max_score) }) : s.status === 'returned' ? t('assignments:queueReturned') : t('assignments:queueAwaiting')} · {formatInstant(s.submitted_at)}</span>
                </button></li>
              ))}
            </ul>
          )}
        </Frame>
        {sel ? <GradePanel key={`${sel.id}-${sel.version}`} s={sel} a={a} /> : <Frame><EmptyState icon="rate_review" title={t('assignments:selectSubmission')} /></Frame>}
      </div>
    </div>
  );
}

function GradePanel({ s, a }: { s: Submission; a: Assignment }) {
  const { t } = useTranslation(['assignments', 'common']);
  const [score, setScore] = useState(s.score != null ? String(s.score) : '');
  const [fb, setFb] = useState(s.feedback ?? '');
  const [err, setErr] = useState<{ s?: string | null; f?: string | null }>({});
  const events = useQuery(q.submissionEvents(s.id));
  const grade = useAction((requestId: string, sc: number, f: string) => api.grade({ submissionId: s.id, requestId, version: s.version, score: sc, feedback: f.trim() }), {
    topics: AFTER_ASSIGNMENT, success: t('assignments:gradeSaved'),
  });
  const ret = useAction((requestId: string, f: string) => api.returnForRevision({ submissionId: s.id, requestId, version: s.version, feedback: f.trim() }), {
    topics: AFTER_ASSIGNMENT, success: t('assignments:returnedToast'),
  });
  const fbErr = fb.length > FEEDBACK_MAX ? 'validation:feedbackTooLong' : null;
  return (
    <>
      <Frame title={s.student?.full_name ?? t('common:student')} actions={<SubChip status={s.status} />}>
        <div className="stack">
          <div className="muted small">{t('assignments:submittedLine', { when: formatInstant(s.submitted_at) })}{a.due_at ? ` · ${t('assignments:dueSuffix', { when: formatInstant(a.due_at) })}` : ''}</div>
          <div><strong>{t('assignments:answer')}</strong>{s.answer ? <p className="pre">{s.answer}</p> : <p className="muted">{t('assignments:noAnswer')}</p>}</div>
          {s.upload ? <div><FileLink name={s.upload.file_name} size={s.upload.size_bytes} path={s.upload.storage_path} source="submission" /></div> : <p className="muted small">{t('assignments:noFile')}</p>}
        </div>
      </Frame>
      <Frame title={t('assignments:gradeAndFeedback')}>
        <form className="stack" noValidate onSubmit={(e) => {
          e.preventDefault();
          const n = Number(score);
          const v = { s: score !== '' && Number.isInteger(n) && n >= 0 && n <= a.max_score ? null : 'validation:scoreRange', f: fbErr };
          setErr(v);
          if (!v.s && !v.f) void grade.run(n, fb);
        }}>
          <TextField label={t('assignments:scoreLabel', { max: fmtNumber(a.max_score) })} inputMode="numeric" value={score} onChange={(e) => setScore(e.target.value)} error={err.s} errorValues={{ max: fmtNumber(a.max_score) }} />
          <TextArea label={t('assignments:feedback')} value={fb} onChange={(e) => setFb(e.target.value)} error={err.f ?? fbErr} errorValues={{ max: fmtNumber(FEEDBACK_MAX) }} hint={t('common:countOf', { count: fmtNumber(fb.length), max: fmtNumber(FEEDBACK_MAX) })} style={{ minHeight: 140 }} />
          <FormError error={grade.error ?? ret.error} />
          {(grade.error?.kind === 'conflict' || ret.error?.kind === 'conflict') && <Banner tone="warn">{t('assignments:gradeConflict')}</Banner>}
          <div className="row">
            <Button type="submit" icon="check" busy={grade.busy}>{t('assignments:saveGrade')}</Button>
            <Button variant="outline" icon="undo" busy={ret.busy} onClick={() => { if (!fb.trim()) setErr({ f: 'validation:returnFeedbackRequired' }); else if (!fbErr) void ret.run(fb); }}>{t('assignments:returnForRevision')}</Button>
          </div>
        </form>
        <div style={{ marginTop: 16 }}>
          <h3>{t('assignments:history')}</h3>
          <Query q={events} rows={2}>{(ev) => ev.length === 0 ? <p className="muted small">{t('assignments:noHistory')}</p> : (
            <ul className="list">{ev.map((e, i) => <li key={i}><div className="grow"><strong>{e.action === 'graded' ? t('assignments:histGraded', { score: fmtNumber(e.score ?? 0), max: fmtNumber(a.max_score) }) : e.action === 'returned' ? t('assignments:histReturned') : t('assignments:histSubmitted')}</strong><div className="muted small">{formatInstant(e.created_at)}</div>{e.feedback ? <p className="pre small">{e.feedback}</p> : null}</div></li>)}</ul>
          )}</Query>
        </div>
      </Frame>
    </>
  );
}
