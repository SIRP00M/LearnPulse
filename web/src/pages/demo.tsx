import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useNavigate } from '@tanstack/react-router';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { demo } from '../lib/api/demo';
import { supabase } from '../lib/supabase';
import { toAppError, errorText, type AppError } from '../lib/errors';
import { useAuth } from '../auth/AuthProvider';
import { Banner, Button, Frame, FormError, Icon, TextField, SkeletonBlock } from '../ui/kit';
import { QrCode } from '../ui/QrCode';
import { LanguageSelector } from '../ui/LanguageSelector';
import { Center } from '../layout/Shell';
import { validateEmail, validatePasswordPresent } from '../lib/validators';

const NONCE_KEY = 'lp-demo-nonce';
let memoryNonce: string | null = null;

/** 24 random bytes (CSPRNG) as base64url = 32 chars. Persisted ONLY so a refresh/retry from the same browser can recover its own seat. */
function getNonce(): string {
  for (const store of [() => localStorage, () => sessionStorage]) {
    try { const v = store().getItem(NONCE_KEY); if (v && /^[A-Za-z0-9_-]{22,64}$/.test(v)) return v; } catch { /* blocked: fall through */ }
  }
  if (memoryNonce) return memoryNonce;
  const b = crypto.getRandomValues(new Uint8Array(24));
  const n = btoa(String.fromCharCode(...b)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  memoryNonce = n;
  for (const store of [() => localStorage, () => sessionStorage]) {
    try { store().setItem(NONCE_KEY, n); break; } catch { /* try the next store */ }
  }
  return n;
}
function clearNonce() {
  memoryNonce = null;
  for (const store of [() => localStorage, () => sessionStorage]) { try { store().removeItem(NONCE_KEY); } catch { /* ignore */ } }
}
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** Public chooser: Student Demo or Presenter Demo. Neither path ever signs a visitor into a privileged account. */
export function DemoSelectorPage() {
  const { t } = useTranslation(['demo', 'landing']);
  return (
    <Center>
      <div className="frame auth-card">
        <div className="body stack">
          <div className="row" style={{ justifyContent: 'flex-end' }}><LanguageSelector compact /></div>
          <h1>{t('demo:selectorTitle')}</h1>
          <p className="muted">{t('demo:selectorSub')}</p>
          <Link className="btn" to="/demo"><Icon name="school" /> {t('demo:studentDemo')}</Link>
          <p className="muted small">{t('demo:studentDemoText')}</p>
          <Link className="btn tonal" to="/demo-presenter"><Icon name="co_present" /> {t('demo:presenterDemo')}</Link>
          <p className="muted small">{t('demo:presenterDemoText')}</p>
          <div className="row between small"><Link to="/">{t('landing:home')}</Link><Link to="/login">{t('demo:continueEmail')}</Link></div>
        </div>
      </div>
    </Center>
  );
}

const PRESENTER_EMAIL_KEY = 'lp-presenter-email';
/** Presenter sign-in: the normal Auth login with the email remembered on this device (never a password). A signed-in Teacher is sent straight to /demo-host. */
export function PresenterAccessPage() {
  const { t } = useTranslation(['demo', 'auth', 'landing']);
  const { signIn } = useAuth();
  const remembered = (() => { try { return localStorage.getItem(PRESENTER_EMAIL_KEY) ?? ''; } catch { return ''; } })();
  const [email, setEmail] = useState(remembered || (import.meta.env.VITE_DEMO_PRESENTER_EMAIL as string | undefined) || '');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  const [errs, setErrs] = useState<{ email?: string | null; password?: string | null }>({});
  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const v = { email: validateEmail(email), password: validatePasswordPresent(password) };
    setErrs(v);
    if (v.email || v.password || busy) return;
    setBusy(true); setError(null);
    try { await signIn(email, password); try { localStorage.setItem(PRESENTER_EMAIL_KEY, email.trim()); } catch { /* not remembered */ } }
    catch (x) { setError(toAppError(x)); } finally { setBusy(false); }
  }
  return (
    <Center>
      <div className="frame auth-card">
        <div className="body stack">
          <div className="row" style={{ justifyContent: 'flex-end' }}><LanguageSelector compact /></div>
          <h1>{t('demo:presenterTitle')}</h1>
          <p className="muted">{t('demo:presenterSub')}</p>
          <form className="stack" onSubmit={submit} noValidate>
            <TextField label={t('auth:email')} type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} error={errs.email} />
            <TextField label={t('auth:password')} type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} error={errs.password} />
            <FormError error={error} />
            <Button type="submit" busy={busy}>{t('demo:presenterDemo')}</Button>
          </form>
          <p className="muted small">{t('demo:presenterGuest')}</p>
          <div className="row between small"><Link to="/try">{t('demo:selectorTitle')}</Link><Link to="/forgot">{t('auth:forgotLink')}</Link></div>
        </div>
      </div>
    </Center>
  );
}

/** Public page: /demo?t=<code>. The code is removed from the address bar immediately; credentials live only in this function's memory. */
export function DemoJoinPage() {
  const { t } = useTranslation('demo');
  const navigate = useNavigate();
  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [phase, setPhase] = useState<'idle' | 'claiming' | 'signing' | 'waiting'>('idle');
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => {
    const p = new URLSearchParams(window.location.search).get('t');
    if (p) { setCode(p.replace(/[^A-Za-z0-9]/g, '').toUpperCase()); window.history.replaceState(null, '', '/demo'); }
  }, []);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setMsg(null);
    const n = name.trim();
    if (n.length < 1 || n.length > 40 || /[<>]/.test(n)) return setMsg(t('badName'));
    setPhase('claiming');
    const r = await demo.claim(code, n, getNonce());
    if (!r.ok || !r.email || !r.password) {
      setPhase('idle');
      if (r.already_active) return setMsg(t('already'));
      const key = ({ invalid: 'invalid', closed: 'closed', full: 'full', busy: 'busy', bad_name: 'badName', already_signed_in: 'signedIn' } as Record<string, string>)[r.reason ?? ''] ?? 'failed';
      return setMsg(t(key as 'failed'));
    }
    setPhase('signing');
    let ok = false; let limited = false;
    for (let i = 0; i < 8 && !ok; i++) {
      const { error } = await supabase.auth.signInWithPassword({ email: r.email, password: r.password });
      if (!error) { ok = true; break; }
      limited = (error as { status?: number }).status === 429 || /rate/i.test(error.message);
      if (!limited) break;
      setPhase('waiting');
      await sleep(1500 + Math.random() * 1000 * (i + 2));   // jittered back-off, bounded: a whole room signing in at once shares one Auth rate limit
    }
    if (!ok) { setPhase('idle'); return setMsg(limited ? t('rateBusy') : t('authFailed')); }
    try {
      const a = await demo.activate();
      if (!a.ok) { await supabase.auth.signOut({ scope: 'local' }); clearNonce(); setPhase('idle'); return setMsg(t('expired')); }
      clearNonce();
      void navigate({ to: a.workshop_course_id ? '/courses/$courseId' : '/dashboard', params: a.workshop_course_id ? { courseId: a.workshop_course_id } : {} } as never);
    } catch (err) { setPhase('idle'); setMsg(errorText(err)); }
  };

  const busy = phase !== 'idle';
  return (
    <Center>
      <div className="frame auth-card">
        <div className="body stack">
          <div className="row" style={{ justifyContent: 'flex-end' }}><LanguageSelector compact /></div>
          <h1>{t('joinTitle')}</h1>
          <p className="muted">{t('joinSub')}</p>
          <form className="stack" onSubmit={submit} noValidate>
            <TextField label={t('codeLabel')} hint={t('codeHint')} value={code} onChange={(e) => setCode(e.target.value.replace(/[^A-Za-z0-9]/g, '').toUpperCase().slice(0, 12))}
              autoComplete="off" autoCapitalize="characters" spellCheck={false} inputMode="text" required />
            <TextField label={t('name')} hint={t('nameHint')} value={name} onChange={(e) => setName(e.target.value)} maxLength={40} autoComplete="off" required />
            {msg && <Banner tone="err" icon="error">{msg}</Banner>}
            {phase === 'waiting' && <Banner tone="info" icon="hourglass_top">{t('waiting')}</Banner>}
            <Button type="submit" disabled={busy || code.length !== 12 || !name.trim()}>
              {phase === 'claiming' ? t('joining') : phase === 'signing' || phase === 'waiting' ? t('signingIn') : t('join')}
            </Button>
          </form>
          <div className="row between small"><Link to="/try">{t('selectorTitle')}</Link><Link to="/login">{t('continueEmail')}</Link></div>
        </div>
      </div>
    </Center>
  );
}

const mmss = (ms: number) => { const s = Math.max(0, Math.floor(ms / 1000)); return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`; };
const hms = (ms: number) => { const s = Math.max(0, Math.floor(ms / 1000)); return `${Math.floor(s / 3600)}:${String(Math.floor((s % 3600) / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`; };

/** Presenter console (teacher-only route): Start, rotating join code + QR, counters, pause/resume, end. Every action is the same server RPC the Flutter app uses. */
export function DemoHostPage() {
  const { t } = useTranslation(['demo', 'common']);
  const qc = useQueryClient();
  const sessions = useQuery({ queryKey: ['demo', 'mine'], queryFn: demo.mySessions });
  const sid = sessions.data?.find((s) => s.status !== 'expired' && s.status !== 'deleted')?.id ?? sessions.data?.[0]?.id;
  const ov = useQuery({ queryKey: ['demo', 'ov', sid], queryFn: () => demo.overview(sid!), enabled: !!sid, refetchInterval: 5000 });
  const [tok, setTok] = useState<{ display: string; token: string } | null>(null);
  const [left, setLeft] = useState(60);
  const [now, setNow] = useState(() => Date.now());
  const [err, setErr] = useState<unknown>(null);
  const [copied, setCopied] = useState(false);
  const [busy, setBusy] = useState(false);
  const status = ov.data?.status;
  const live = status === 'open' || status === 'paused';
  const last = useRef(0);

  const refresh = useCallback(async () => {
    if (!sid) return;
    try { const r = await demo.token(sid); setTok({ display: r.display, token: r.token }); setErr(null); last.current = Date.now(); }
    catch (e) { setErr(toAppError(e)); }
  }, [sid]);
  useEffect(() => {
    if (!live) return;
    void refresh();
    const iv = setInterval(() => { setLeft(Math.max(0, 60 - Math.floor((Date.now() - last.current) / 1000))); if (Date.now() - last.current >= 60_000) void refresh(); }, 1000);
    return () => clearInterval(iv);
  }, [live, refresh]);
  useEffect(() => { const iv = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(iv); }, []);

  const act = async (f: () => Promise<unknown>) => {
    if (busy) return;   // double-clicks never send a second request; the server is idempotent as well
    setBusy(true);
    try { await f(); setErr(null); } catch (e) { setErr(toAppError(e)); }
    setBusy(false);
    void qc.invalidateQueries({ queryKey: ['demo'] });
  };
  if (sessions.isLoading) return <SkeletonBlock rows={3} />;
  if (!sid || !ov.data) return <Frame title={t('demo:hostTitle')}><p>{t('demo:noSession')}</p></Frame>;
  const o = ov.data;
  const skew = Date.parse(o.server_now) - ov.dataUpdatedAt;   // keep countdowns on the SERVER clock
  const serverNow = now + skew;
  const joinLeft = Date.parse(o.joins_close_at) - serverNow;
  const lifeLeft = Date.parse(o.expires_at) - serverNow;
  const url = tok ? `${window.location.origin}/demo?t=${tok.token}` : '';
  const c = (k: string) => o.counts[k] ?? 0;
  const taken = c('active') + c('claimed');
  const copy = async (text: string) => { try { await navigator.clipboard.writeText(text); setCopied(true); setTimeout(() => setCopied(false), 1500); } catch { /* clipboard blocked: the text stays visible */ } };
  const params = { join: Math.round(o.join_window_seconds / 60), life: +(o.lifetime_seconds / 3600).toFixed(1).replace(/\.0$/, '') };
  const statusKey = (['open', 'paused', 'closed', 'expired'] as const).includes(status as 'open') ? (status as 'open') : null;
  return (
    <div className="stack">
      <Frame title={`${t('demo:hostTitle')} — ${o.workshop_title ?? o.label}`}>
        <p className="muted">{t('demo:hostSub')}</p>
        <p>
          <strong>{statusKey ? t(`demo:status_${statusKey}`) : t('demo:readyTitle')}</strong>
          {live && <> · {t('demo:remainingJoin')} <strong>{mmss(joinLeft)}</strong> · {t('demo:remainingLife')} <strong>{hms(lifeLeft)}</strong></>}
        </p>
        {err ? <FormError error={err as AppError} /> : null}
        {status === 'provisioning' && (
          <div className="stack">
            <Banner tone="warn" icon="schedule">{t('demo:readyText', params)}</Banner>
            <Button busy={busy} onClick={() => { if (window.confirm(t('demo:startConfirm', params))) void act(() => demo.start(sid)); }}>{t('demo:startDemo')}</Button>
          </div>
        )}
        {live && tok && (
          <div className="stack" style={{ alignItems: 'center' }}>
            <QrCode value={url} label={tok.display} size={320} />
            <div style={{ fontSize: '2.5rem', letterSpacing: '0.12em', fontWeight: 700 }} aria-live="off">{tok.display}</div>
            <div className="muted small">{t('demo:codeExpires', { s: left })}</div>
            <p className="muted small">{t('demo:projectHint')}</p>
            <div className="row" style={{ flexWrap: 'wrap', gap: 8 }}>
              <Button variant="outline" icon="content_copy" onClick={() => void copy(tok.token)}>{copied ? t('demo:copied') : t('demo:copyCode')}</Button>
              <Button variant="outline" icon="link" onClick={() => void copy(url)}>{t('demo:copyLink')}</Button>
            </div>
            <p className="muted small" style={{ wordBreak: 'break-all' }}>{t('demo:joinUrl')}: {url}</p>
          </div>
        )}
        {status === 'expired' && <Banner tone="info" icon="event_busy">{t('demo:ended')}</Banner>}
        {status === 'closed' && <Banner tone="info" icon="lock">{t('demo:status_closed')}</Banner>}
        {live && joinLeft <= 0 && <Banner tone="warn" icon="timer_off">{t('demo:joinWindowOver')}</Banner>}
        <div className="row" style={{ flexWrap: 'wrap', gap: 8 }}>
          {status === 'open' && <Button variant="outline" disabled={busy} onClick={() => void act(() => demo.setJoins(sid, 'paused'))}>{t('demo:pause')}</Button>}
          {status === 'paused' && <Button variant="outline" disabled={busy || joinLeft <= 0} onClick={() => void act(() => demo.setJoins(sid, 'open'))}>{t('demo:resume')}</Button>}
          {live && <Button variant="outline" disabled={busy} onClick={() => void act(() => demo.setJoins(sid, 'closed'))}>{t('demo:closeJoins')}</Button>}
          {(live || status === 'closed') && <Button variant="danger" disabled={busy} onClick={() => { if (window.confirm(t('demo:endConfirm'))) void act(() => demo.end(sid)); }}>{t('demo:endDemo')}</Button>}
          {o.workshop_course_id && status !== 'expired' && <a className="btn" href={`/courses/${o.workshop_course_id}`}>{t('demo:open')}</a>}
        </div>
      </Frame>
      <Frame title={t('demo:seatsTaken')}>
        <p>{t('demo:seatsTotal')}: <strong>{o.seats}</strong> · {t('demo:available')}: <strong>{c('available')}</strong> · {t('demo:claimedSeats')}: <strong>{c('claimed')}</strong> · {t('demo:activeSeats')}: <strong>{c('active')}</strong> · {t('demo:disabledSeats')}: <strong>{c('disabled')}</strong> · {taken}/{o.capacity}</p>
        <p className="muted small">{t('demo:recent', { claims: o.recent.claims, refused: o.recent.refused })}</p>
        <ul className="stack" style={{ listStyle: 'none', padding: 0 }}>
          {o.seats_list.filter((s) => s.state === 'claimed' || s.state === 'active').map((s) => (
            <li key={s.seat_no} className="row" style={{ justifyContent: 'space-between' }}>
              <span>{t('demo:seat', { n: s.seat_no })}{s.reserve ? ` (${t('demo:reserve')})` : ''} — {s.name ?? ''} <span className="muted">· {s.state}</span></span>
              <Button variant="text" onClick={() => void act(() => demo.disable(sid, s.seat_no))}>{t('demo:disable')}</Button>
            </li>
          ))}
        </ul>
      </Frame>
    </div>
  );
}
