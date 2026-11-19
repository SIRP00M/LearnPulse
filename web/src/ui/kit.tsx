import {
  createContext, forwardRef, useCallback, useContext, useEffect, useId, useMemo, useState,
  type ButtonHTMLAttributes, type ReactNode, type InputHTMLAttributes, type TextareaHTMLAttributes, type SelectHTMLAttributes,
} from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { Link } from '@tanstack/react-router';
import type { UseQueryResult } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { AppError, errorText, toAppError } from '../lib/errors';
import { tr } from '../i18n';

export const Icon = ({ name, label }: { name: string; label?: string }) => (
  <span className="mi" aria-hidden={label ? undefined : true} aria-label={label} role={label ? 'img' : undefined}>{name}</span>
);

type BtnProps = ButtonHTMLAttributes<HTMLButtonElement> & { variant?: 'primary' | 'tonal' | 'outline' | 'text' | 'danger'; size?: 'sm'; icon?: string; busy?: boolean };
export const Button = forwardRef<HTMLButtonElement, BtnProps>(function Button({ variant = 'primary', size, icon, busy, children, className, disabled, type = 'button', ...rest }, ref) {
  const cls = ['btn', variant === 'primary' ? '' : variant, size ?? '', className ?? ''].filter(Boolean).join(' ');
  return (
    <button ref={ref} type={type} className={cls} disabled={disabled || busy} aria-busy={busy || undefined} {...rest}>
      {icon && <Icon name={busy ? 'hourglass_empty' : icon} />}{children}
    </button>
  );
});

export const LinkButton = ({ to, params, search, children, variant = 'tonal', icon }: { to: string; params?: Record<string, string>; search?: Record<string, unknown>; children: ReactNode; variant?: BtnProps['variant']; icon?: string }) => (
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  <Link to={to as any} params={params as any} search={search as any} activeOptions={{ exact: true }} className={`btn ${variant === 'primary' ? '' : variant}`}>{icon && <Icon name={icon} />}{children}</Link>
);

interface FieldShell { label: string; error?: string | null; errorValues?: Record<string, unknown>; hint?: string; children: (p: { id: string; 'aria-invalid'?: boolean; 'aria-describedby'?: string }) => ReactNode }
export function FieldShell({ label, error, errorValues, hint, children }: FieldShell) {
  const id = useId();
  useTranslation(); // re-render (and re-translate the message) when the language changes
  const desc = [error ? `${id}-e` : '', hint ? `${id}-h` : ''].filter(Boolean).join(' ') || undefined;
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {children({ id, 'aria-invalid': error ? true : undefined, 'aria-describedby': desc })}
      {hint && <span id={`${id}-h`} className="hint">{hint}</span>}
      {error && <span id={`${id}-e`} className="err-text" role="alert">{tr(error, errorValues)}</span>}
    </div>
  );
}
type TF = { label: string; error?: string | null; errorValues?: Record<string, unknown>; hint?: string } & InputHTMLAttributes<HTMLInputElement>;
export function TextField({ label, error, errorValues, hint, ...rest }: TF) {
  return <FieldShell label={label} error={error} errorValues={errorValues} hint={hint}>{(p) => <input className="input" {...p} {...rest} />}</FieldShell>;
}
type TA = { label: string; error?: string | null; errorValues?: Record<string, unknown>; hint?: string } & TextareaHTMLAttributes<HTMLTextAreaElement>;
export function TextArea({ label, error, errorValues, hint, ...rest }: TA) {
  return <FieldShell label={label} error={error} errorValues={errorValues} hint={hint}>{(p) => <textarea className="input" {...p} {...rest} />}</FieldShell>;
}
type SF = { label: string; error?: string | null; hint?: string } & SelectHTMLAttributes<HTMLSelectElement>;
export function SelectField({ label, error, hint, children, ...rest }: SF) {
  return <FieldShell label={label} error={error} hint={hint}>{(p) => <select className="input" {...p} {...rest}>{children}</select>}</FieldShell>;
}

export type Tone = 'info' | 'ok' | 'warn' | 'err' | 'neutral';
export const Chip = ({ tone = 'neutral', icon, children }: { tone?: Tone; icon?: string; children: ReactNode }) => (
  <span className={`chip ${tone === 'neutral' ? '' : tone}`}>{icon && <Icon name={icon} />}{children}</span>
);

export function Frame({ title, actions, children, flush }: { title?: ReactNode; actions?: ReactNode; children: ReactNode; flush?: boolean }) {
  const id = useId();
  return (
    <section className="frame" aria-labelledby={title ? id : undefined}>
      {(title || actions) && <header>{title && <h2 id={id}>{title}</h2>}{actions && <div className="row">{actions}</div>}</header>}
      <div className={`body${flush ? ' flush' : ''}`}>{children}</div>
    </section>
  );
}

export const PageHead = ({ title, sub, actions }: { title: ReactNode; sub?: ReactNode; actions?: ReactNode }) => (
  <div className="page-head">
    <div className="grow"><h1>{title}</h1>{sub && <p className="sub">{sub}</p>}</div>
    {actions && <div className="row">{actions}</div>}
  </div>
);

export const Banner = ({ tone = 'info', icon, children, role }: { tone?: 'info' | 'warn' | 'err' | 'ok'; icon?: string; children: ReactNode; role?: string }) => (
  <div className={`banner ${tone === 'info' ? '' : tone}`} role={role ?? (tone === 'err' ? 'alert' : 'status')}>
    <Icon name={icon ?? (tone === 'err' ? 'error' : tone === 'warn' ? 'warning' : tone === 'ok' ? 'check_circle' : 'info')} /><div className="grow">{children}</div>
  </div>
);

export const Skeleton = ({ h = 16, w = '100%' }: { h?: number; w?: number | string }) => <div className="skel" style={{ height: h, width: w }} aria-hidden />;
export const SkeletonBlock = ({ rows = 4 }: { rows?: number }) => {
  const { t } = useTranslation('common');
  return (
  <div className="stack-s" role="status" aria-label={t('loading')}>
    {Array.from({ length: rows }, (_, i) => <Skeleton key={i} h={i === 0 ? 22 : 16} w={i === 0 ? '40%' : `${90 - i * 7}%`} />)}
  </div>
  );
};

export const EmptyState = ({ icon = 'inbox', title, children, action }: { icon?: string; title: string; children?: ReactNode; action?: ReactNode }) => (
  <div className="state"><Icon name={icon} /><h3>{title}</h3>{children && <p>{children}</p>}{action}</div>
);

const ERR_ICON: Record<string, string> = { network: 'cloud_off', timeout: 'schedule', forbidden: 'lock', notFound: 'search_off', unauthenticated: 'logout', conflict: 'sync_problem' };
export const ErrorState = ({ error, onRetry }: { error: unknown; onRetry?: () => void }) => {
  const { t } = useTranslation('common');
  const e = toAppError(error);
  return (
    <div className="state" role="alert">
      <Icon name={ERR_ICON[e.kind] ?? 'error'} /><h3>{e.kind === 'notFound' ? t('notFoundTitle') : e.kind === 'forbidden' ? t('forbiddenTitle') : t('loadFailedTitle')}</h3>
      <p>{errorText(e)}</p>
      {onRetry && e.kind !== 'forbidden' && e.kind !== 'notFound' && <Button variant="tonal" icon="refresh" onClick={onRetry}>{t('tryAgain')}</Button>}
    </div>
  );
};

/** Loading skeleton -> error -> data. Old data stays visible while a refresh fails or runs. */
export function Query<T>({ q, children, empty, rows }: { q: UseQueryResult<T>; children: (data: T) => ReactNode; empty?: (data: T) => ReactNode | null; rows?: number }) {
  const { t } = useTranslation('common');
  if (q.data === undefined) {
    if (q.isError) return <ErrorState error={q.error} onRetry={() => void q.refetch()} />;
    return <SkeletonBlock rows={rows ?? 4} />;
  }
  const em = empty?.(q.data);
  return (
    <>
      {q.isError && <Banner tone="warn">{t('staleData')} {errorText(q.error)} <Button size="sm" variant="text" onClick={() => void q.refetch()}>{t('retry')}</Button></Banner>}
      {em ?? children(q.data)}
    </>
  );
}

// ── Toasts ────────────────────────────────────────────────────
interface Toast { id: number; text: string; err?: boolean }
const ToastCtx = createContext<(text: string, err?: boolean) => void>(() => {});
export const useToast = () => useContext(ToastCtx);
export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<Toast[]>([]);
  const push = useCallback((text: string, err?: boolean) => {
    const id = Date.now() + Math.random();
    setItems((x) => [...x.slice(-3), { id, text, err }]);
    setTimeout(() => setItems((x) => x.filter((t) => t.id !== id)), err ? 8000 : 4500);
  }, []);
  return (
    <ToastCtx.Provider value={push}>
      {children}
      <div className="toasts" role="status" aria-live="polite">{items.map((t) => <div key={t.id} className={`toast${t.err ? ' err' : ''}`}>{t.text}</div>)}</div>
    </ToastCtx.Provider>
  );
}

// ── Modal ─────────────────────────────────────────────────────
export function Modal({ open, onClose, title, description, children }: { open: boolean; onClose: () => void; title: string; description?: string; children: ReactNode }) {
  return (
    <Dialog.Root open={open} onOpenChange={(o) => { if (!o) onClose(); }}>
      <Dialog.Portal>
        <Dialog.Overlay className="overlay" />
        <Dialog.Content className="dialog" aria-describedby={description ? undefined : undefined}>
          <Dialog.Title asChild><h2>{title}</h2></Dialog.Title>
          {description ? <Dialog.Description className="muted">{description}</Dialog.Description> : <Dialog.Description className="sr-only">{title}</Dialog.Description>}
          <div className="stack" style={{ marginTop: 12 }}>{children}</div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

export const Stat = ({ value, label, tone }: { value: ReactNode; label: string; tone?: Tone }) => (
  <div className="stat" role="group" aria-label={`${label}: ${typeof value === 'string' || typeof value === 'number' ? value : ''}`}>
    <div className="v" style={tone === 'err' ? { color: 'var(--lp-err)' } : undefined}>{value}</div><div className="k">{label}</div>
  </div>
);
export const ProgressBar = ({ value, label }: { value: number | null | undefined; label: string }) => (
  <div className="bar" role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={100} aria-valuenow={value == null ? undefined : Math.round(value)}>
    <i style={{ width: `${Math.max(0, Math.min(100, value ?? 0))}%` }} />
  </div>
);

/** Error text for forms; `conflict` errors are surfaced with a reload hint by the caller. */
export const FormError = ({ error }: { error: unknown }) => {
  if (!error) return null;
  const e = error instanceof AppError ? error : toAppError(error);
  return <Banner tone="err">{errorText(e)}</Banner>;
};

export function useDebounced<T>(v: T, ms = 250): T {
  const [d, setD] = useState(v);
  useEffect(() => { const t = setTimeout(() => setD(v), ms); return () => clearTimeout(t); }, [v, ms]);
  return d;
}
export const useStable = <T,>(v: T) => useMemo(() => v, [v]);
