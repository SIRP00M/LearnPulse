import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { att2 } from '../lib/api/att2';
import { errorText, toAppError } from '../lib/errors';
import { useQueryClient } from '@tanstack/react-query';
import { AFTER_ATTENDANCE, invalidate, useAction } from '../lib/hooks';
import { formatInstant } from '../lib/dates';
import { Banner, Button, Frame, FormError, TextField } from '../ui/kit';
import { QrCode } from '../ui/QrCode';
import type { AttSession, ScanResult } from '../lib/schemas';

/** The server refreshes every 30 s and accepts a code for 45 s; the display asks again just before it would lapse. */
const REFRESH_MS = 30_000;

/** Classroom display: a fresh opaque code every 30 s. Stops when the session closes or the tab is hidden. */
export function QrPanel({ session }: { session: AttSession }) {
  const { t } = useTranslation(['attendance', 'common']);
  const [action, setAction] = useState<'in' | 'out'>('in');
  const [token, setToken] = useState<{ value: string; at: number } | null>(null);
  const [error, setError] = useState<unknown>(null);
  const [left, setLeft] = useState(30);
  const box = useRef<HTMLDivElement>(null);
  const open = session.status === 'open';

  const fetchToken = useCallback(async () => {
    try {
      const r = await att2.issueQr(session.id, action);
      setToken({ value: r.token, at: Date.now() });
      setError(null);
    } catch (e) { setError(toAppError(e)); }
  }, [session.id, action]);

  useEffect(() => {
    if (!open) { setToken(null); return; }
    setToken(null);
    void fetchToken();
    const id = window.setInterval(() => { if (document.visibilityState === 'visible') void fetchToken(); }, REFRESH_MS);
    return () => window.clearInterval(id);
  }, [open, fetchToken]);

  useEffect(() => {
    const id = window.setInterval(() => setLeft(token ? Math.max(0, Math.ceil((REFRESH_MS - (Date.now() - token.at)) / 1000)) : 30), 500);
    return () => window.clearInterval(id);
  }, [token]);

  if (!open) return <Frame title={t('attendance:qrTitle')}><p className="muted">{t('attendance:qrClosed')}</p></Frame>;
  return (
    <Frame title={t('attendance:qrTitle')} actions={
      <Button variant="outline" size="sm" icon="fullscreen" onClick={() => void box.current?.requestFullscreen?.()}>{t('attendance:qrFullscreen')}</Button>}>
      <div className="stack" ref={box} style={{ alignItems: 'center', background: 'var(--lp-frame)', padding: 8 }}>
        {session.requires_checkout && (
          <div className="row" role="group" aria-label={t('attendance:qrAction')}>
            <Button variant={action === 'in' ? 'tonal' : 'outline'} aria-pressed={action === 'in'} onClick={() => setAction('in')}>{t('attendance:qrIn')}</Button>
            <Button variant={action === 'out' ? 'tonal' : 'outline'} aria-pressed={action === 'out'} onClick={() => setAction('out')}>{t('attendance:qrOut')}</Button>
          </div>
        )}
        {token ? (
          <>
            <QrCode value={token.value} label={t('attendance:qrAlt', { title: session.title })} />
            <div className="small muted" aria-live="off">{t('attendance:qrExpires', { seconds: left })}</div>
            <div className="small"><span className="muted">{t('attendance:qrCodeText')}: </span><code data-testid="qr-code-text" style={{ userSelect: 'all', wordBreak: 'break-all' }}>{token.value}</code></div>
          </>
        ) : error ? null : <div className="muted" role="status">{t('common:loading')}</div>}
        {error ? <div className="stack"><Banner tone="err">{errorText(error)}</Banner><Button variant="outline" onClick={() => void fetchToken()}>{t('attendance:qrRetry')}</Button></div> : null}
      </div>
      <p className="muted small" style={{ marginTop: 8 }}>{t('attendance:qrHint')} {t('attendance:qrNotice')}</p>
    </Frame>
  );
}

const num = (v: string) => (v.trim() === '' ? NaN : Number(v));

export function RulesPanel({ session }: { session: AttSession }) {
  const { t } = useTranslation(['attendance', 'common']);
  const [checkout, setCheckout] = useState(session.requires_checkout);
  const [late, setLate] = useState(String(session.late_after_minutes));
  const [opens, setOpens] = useState(String(session.checkin_opens_minutes));
  const [win, setWin] = useState(session.checkin_window_minutes == null ? '' : String(session.checkin_window_minutes));
  const [err, setErr] = useState<Record<string, string | null>>({});
  const a = useAction((rid: string) => att2.setRules(session.id, rid, session.version, {
    requiresCheckout: checkout, lateAfter: num(late), opens: num(opens), window: win.trim() === '' ? null : num(win),
  }), { topics: AFTER_ATTENDANCE, success: t('attendance:rulesSaved') });
  const bad = (v: number, lo: number, hi: number) => (Number.isInteger(v) && v >= lo && v <= hi ? null : 'attendance:rulesRange');
  return (
    <Frame title={t('attendance:rulesTitle')}>
      <form className="stack" noValidate onSubmit={(e) => {
        e.preventDefault();
        const v = { late: bad(num(late), 0, 240), opens: bad(num(opens), 0, 240), win: win.trim() === '' ? null : bad(num(win), 1, 720) };
        setErr(v);
        if (!v.late && !v.opens && !v.win) void a.run();
      }}>
        <label className="check"><input type="checkbox" checked={checkout} onChange={(e) => setCheckout(e.target.checked)} />{t('attendance:rulesCheckout')}</label>
        <div className="cols">
          <div className="c4"><TextField label={t('attendance:rulesLateAfter')} inputMode="numeric" value={late} onChange={(e) => setLate(e.target.value)} error={err.late} /></div>
          <div className="c4"><TextField label={t('attendance:rulesOpens')} inputMode="numeric" value={opens} onChange={(e) => setOpens(e.target.value)} error={err.opens} /></div>
          <div className="c4"><TextField label={t('attendance:rulesWindow')} inputMode="numeric" value={win} onChange={(e) => setWin(e.target.value)} error={err.win} /></div>
        </div>
        <FormError error={a.error} />
        <div className="row"><Button type="submit" busy={a.busy} disabled={session.status !== 'open'}>{t('attendance:rulesSave')}</Button></div>
      </form>
    </Frame>
  );
}

/** Secure alternative to the camera on Web: the SAME `scan_attendance` RPC with the code text the classroom display shows. */
export function ScanPanel() {
  const { t } = useTranslation(['attendance', 'status']);
  const [code, setCode] = useState('');
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<ScanResult | null>(null);
  const [error, setError] = useState<unknown>(null);
  const qc = useQueryClient();
  async function submit() {
    if (busy || !code.trim()) return;
    setBusy(true); setError(null); setResult(null);
    try { setResult(await att2.scan(code)); setCode(''); void invalidate(qc, ...AFTER_ATTENDANCE); } catch (e) { setError(toAppError(e)); } finally { setBusy(false); }
  }
  const msg = (r: ScanResult) => {
    if (!r.ok) return t(`attendance:reason_${r.reason ?? 'invalid'}` as 'attendance:reason_invalid', { defaultValue: t('attendance:reason_invalid') });
    const st = t(`status:att.${(r.status ?? 'present') as 'present'}`);
    if (r.action === 'out') return r.already ? t('attendance:scanOutAlready') : t('attendance:scanOut', { time: formatInstant(r.checked_out_at ?? '') });
    return r.already ? t('attendance:scanAlready', { status: st }) : t('attendance:scanOk', { status: st, time: formatInstant(r.checked_in_at ?? '') });
  };
  return (
    <Frame title={t('attendance:scanTitle')}>
      <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); void submit(); }}>
        <p className="muted small">{t('attendance:scanHint')}</p>
        <TextField label={t('attendance:scanLabel')} value={code} onChange={(e) => setCode(e.target.value)} placeholder="LP1.…" autoComplete="off" spellCheck={false} />
        <FormError error={error} />
        {result && <Banner tone={result.ok ? 'ok' : 'warn'} role="status">{msg(result)}</Banner>}
        <div className="row"><Button type="submit" busy={busy} disabled={!code.trim()} icon="qr_code_scanner">{t('attendance:scanButton')}</Button></div>
      </form>
    </Frame>
  );
}
