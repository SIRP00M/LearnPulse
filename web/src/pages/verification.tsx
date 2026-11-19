import { useState } from 'react';
import { Link } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import type { ColumnDef } from '@tanstack/react-table';
import { v9 } from '../lib/api/v9';
import { q } from '../lib/queries';
import { AFTER_ACTIVITY, useAction } from '../lib/hooks';
import { errorText } from '../lib/errors';
import { formatDay, formatInstant, fmtNumber } from '../lib/dates';
import { Banner, Button, EmptyState, Frame, FormError, Modal, PageHead, Query, TextArea } from '../ui/kit';
import { DataTable } from '../ui/DataTable';
import type { PendingItem } from '../lib/schemas';

function ReviewButtons({ it }: { it: PendingItem }) {
  const { t } = useTranslation(['verification', 'common']);
  const [reject, setReject] = useState(false);
  const [reason, setReason] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const name = it.full_name ?? t('common:student');
  const base = { activityId: it.activity_id, studentId: it.student_id, date: it.occurrence_date, version: it.version };
  const approve = useAction((id: string) => v9.review({ ...base, requestId: id, decision: 'approve' }), { topics: AFTER_ACTIVITY, success: t('verification:approved') });
  const rej = useAction((id: string, r: string) => v9.review({ ...base, requestId: id, decision: 'reject', reason: r }), { topics: AFTER_ACTIVITY, success: t('verification:rejected'), onDone: () => setReject(false) });
  return (
    <div className="row">
      <Button size="sm" icon="check" busy={approve.busy} aria-label={t('verification:approveAria', { name, activity: it.activity_title })} onClick={() => void approve.run()}>{t('verification:approve')}</Button>
      <Button size="sm" variant="outline" icon="undo" aria-label={t('verification:rejectAria', { name, activity: it.activity_title })} onClick={() => setReject(true)}>{t('verification:reject')}</Button>
      {approve.error && <span className="err-text small" role="alert">{errorText(approve.error)}</span>}
      <Modal open={reject} onClose={() => setReject(false)} title={t('verification:rejectTitle')} description={`${name} · ${it.activity_title} · ${formatDay(it.occurrence_date)}`}>
        <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); if (!reason.trim()) { setErr('validation:reasonRequired'); return; } setErr(null); void rej.run(reason.trim()); }}>
          <TextArea label={t('verification:reasonLabel')} value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} error={err} autoFocus />
          <FormError error={rej.error} />
          <div className="row"><Button type="submit" variant="danger" busy={rej.busy}>{t('verification:reject')}</Button><Button variant="text" onClick={() => setReject(false)}>{t('common:cancel')}</Button></div>
        </form>
      </Modal>
    </div>
  );
}

export function VerificationPage() {
  const { t } = useTranslation('verification');
  const queue = useQuery(q.pending());
  const cols: ColumnDef<PendingItem, unknown>[] = [
    { id: 'student', header: t('colStudent'), accessorFn: (r) => r.full_name ?? '' },
    { id: 'activity', header: t('colActivity'), accessorKey: 'activity_title', cell: (c) => <Link to="/courses/$courseId/activities/$id" params={{ courseId: c.row.original.course_id, id: c.row.original.activity_id }} search={{ week: c.row.original.occurrence_date }}>{c.row.original.activity_title}</Link> },
    { id: 'course', header: t('colCourse'), accessorFn: (r) => r.course_title ?? '' },
    { id: 'day', header: t('colDay'), accessorKey: 'occurrence_date', cell: (c) => formatDay(c.getValue() as string) },
    { id: 'sub', header: t('colSubmitted'), accessorKey: 'submitted_at', cell: (c) => formatInstant(c.getValue() as string | undefined) },
    { id: 'note', header: t('colNote'), accessorFn: (r) => r.note ?? '', cell: (c) => <span className="pre">{c.row.original.note || '—'}</span> },
    { id: 'actions', header: '', enableSorting: false, cell: (c) => <ReviewButtons it={c.row.original} /> },
  ];
  return (
    <>
      <PageHead title={t('title')} sub={t('sub')} />
      <Frame flush>
        <Query q={queue}>{(d) => (
          <>
            {d.capped && <Banner tone="warn">{t('capped', { count: fmtNumber(d.items.length) })}</Banner>}
            <DataTable<PendingItem> caption={t('caption')} data={d.items} columns={cols} getRowId={(r) => `${r.activity_id}|${r.student_id}|${r.occurrence_date}`} filterLabel={t('filter')}
              empty={<EmptyState icon="task_alt" title={t('empty')}>{t('emptyText')}</EmptyState>} />
          </>
        )}</Query>
      </Frame>
    </>
  );
}
