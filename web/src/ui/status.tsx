import { useTranslation } from 'react-i18next';
import { Chip, type Tone } from './kit';
import i18n from '../i18n';
import type { OccState, AttendanceStatus, Policy } from '../lib/schemas';

interface S { tone: Tone; icon: string }

/** One presentation per server status (tone + icon); the WORDS come from the `status` namespace. The status itself is always the server's. */
export const OCC: Record<OccState, S> = {
  upcoming: { tone: 'neutral', icon: 'event' },
  open: { tone: 'info', icon: 'radio_button_unchecked' },
  pending: { tone: 'warn', icon: 'hourglass_top' },
  completed: { tone: 'ok', icon: 'check_circle' },
  rejected: { tone: 'err', icon: 'undo' },
  not_done: { tone: 'err', icon: 'cancel' },
  missed: { tone: 'err', icon: 'error' },
};
/** Label outside React (aria-labels built in render helpers). Call inside a component that uses useTranslation so it re-renders on language change. */
export const occLabel = (s: OccState) => i18n.t(`status:occ.${s}`);
export const OccChip = ({ state }: { state: OccState }) => {
  const { t } = useTranslation('status');
  return <Chip tone={OCC[state].tone} icon={OCC[state].icon}>{t(`occ.${state}`)}</Chip>;
};

const TASK: Record<string, S> = {
  todo: { tone: 'info', icon: 'radio_button_unchecked' },
  overdue: { tone: 'err', icon: 'error' },
  needs_revision: { tone: 'err', icon: 'undo' },
  awaiting_review: { tone: 'warn', icon: 'hourglass_top' },
  graded: { tone: 'ok', icon: 'grade' },
  upcoming: { tone: 'neutral', icon: 'event' },
  done: { tone: 'ok', icon: 'check_circle' },
  missed: { tone: 'err', icon: 'error' },
  scheduled: { tone: 'neutral', icon: 'event' },
  held: { tone: 'ok', icon: 'how_to_reg' },
  not_started: { tone: 'info', icon: 'radio_button_unchecked' },
  published: { tone: 'ok', icon: 'public' },
  draft: { tone: 'neutral', icon: 'edit_note' },
};
export const TaskChip = ({ status }: { status: string }) => {
  const { t } = useTranslation('status');
  const s = TASK[status] ?? { tone: 'neutral' as Tone, icon: 'help' };
  return <Chip tone={s.tone} icon={s.icon}>{TASK[status] ? t(`task.${status as 'todo'}`) : status}</Chip>;
};

const SUB: Record<string, S> = {
  submitted: { tone: 'warn', icon: 'hourglass_top' },
  graded: { tone: 'ok', icon: 'grade' },
  returned: { tone: 'err', icon: 'undo' },
};
export const SubChip = ({ status }: { status: string }) => {
  const { t } = useTranslation('status');
  const s = SUB[status] ?? { tone: 'neutral' as Tone, icon: 'help' };
  return <Chip tone={s.tone} icon={s.icon}>{SUB[status] ? t(`sub.${status as 'graded'}`) : status}</Chip>;
};

export const ATT: Record<AttendanceStatus, S> = {
  present: { tone: 'ok', icon: 'check_circle' },
  late: { tone: 'warn', icon: 'schedule' },
  excused: { tone: 'info', icon: 'event_available' },
  absent: { tone: 'err', icon: 'cancel' },
};
export const attLabel = (s: AttendanceStatus) => i18n.t(`status:att.${s}`);
export const AttChip = ({ status }: { status?: AttendanceStatus | null }) => {
  const { t } = useTranslation('status');
  return status ? <Chip tone={ATT[status].tone} icon={ATT[status].icon}>{t(`att.${status}`)}</Chip> : <Chip icon="remove">{t('att.unmarked')}</Chip>;
};

export const policyLabel = (p: Policy) => i18n.t(`status:policy.${p}`);
export const policyHelp = (p: Policy) => i18n.t(`status:policyHelp.${p}`);
export const POLICIES: Policy[] = ['teacher_marked', 'self_reported', 'teacher_verified'];
