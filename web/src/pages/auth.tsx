import { useState, type FormEvent, type ReactNode } from 'react';
import { Link, useNavigate } from '@tanstack/react-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/AuthProvider';
import { authSettings } from '../lib/api/core';
import { Button, Banner, TextField, FormError, Frame } from '../ui/kit';
import { LanguageSelector } from '../ui/LanguageSelector';
import { Center } from '../layout/Shell';
import { toAppError, type AppError } from '../lib/errors';
import { validateEmail, validatePassword, validatePasswordPresent, validateName } from '../lib/validators';

function Card({ title, children, sub }: { title: string; sub?: string; children: ReactNode }) {
  return (
    <Center>
      <div className="auth-card frame">
        <div className="body stack">
          <div className="row between">
            <div className="wordmark" style={{ padding: 0 }}>Learn<b>Pulse</b></div>
            <LanguageSelector compact />
          </div>
          <div><h1 style={{ fontSize: 22 }}>{title}</h1>{sub && <p className="muted" style={{ marginTop: 4 }}>{sub}</p>}</div>
          {children}
        </div>
      </div>
    </Center>
  );
}

export function SignInPage() {
  const { t } = useTranslation(['auth', 'common', 'landing', 'demo']);
  const { signIn, sessionExpired, dismissExpired } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errs, setErrs] = useState<{ email?: string | null; password?: string | null }>({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  const nav = useNavigate();
  const settings = useQuery({ queryKey: ['auth', 'settings'], queryFn: authSettings, staleTime: 5 * 60_000 });

  async function submit(e: FormEvent) {
    e.preventDefault();
    const v = { email: validateEmail(email), password: validatePasswordPresent(password) };
    setErrs(v);
    if (v.email || v.password || busy) return;
    setBusy(true); setError(null);
    try { await signIn(email, password); } catch (x) { setError(toAppError(x)); } finally { setBusy(false); }
  }
  return (
    <Card title={t('signIn')} sub={t('signInSub')}>
      {sessionExpired && <Banner tone="warn">{t('expired')}</Banner>}
      <form className="stack" onSubmit={submit} noValidate onChange={dismissExpired}>
        <p className="muted small">{t('demo:continueEmail')}</p>
        <TextField label={t('email')} type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} error={errs.email} />
        <TextField label={t('password')} type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} error={errs.password} />
        <FormError error={error} />
        {error?.kind === 'emailNotConfirmed' && <Button variant="text" onClick={() => void nav({ to: '/confirm-email', search: { email } })}>{t('resendLink')}</Button>}
        <Button type="submit" busy={busy}>{t('signIn')}</Button>
      </form>
      <div className="stack" role="group" aria-label={t('demo:orTryDemo')}>
        <p className="muted small">{t('demo:orTryDemo')}</p>
        <Link className="btn tonal" to="/demo">{t('demo:studentDemo')}</Link>
        <Link className="btn tonal" to="/demo-presenter">{t('demo:presenterDemo')}</Link>
      </div>
      <div className="row between small">
        <Link to="/">{t('landing:home')}</Link>
        <Link to="/forgot">{t('forgotLink')}</Link>
        {settings.data?.signupDisabled === false && <Link to="/signup">{t('createLink')}</Link>}
      </div>
    </Card>
  );
}

export function SignUpPage() {
  const { t } = useTranslation(['auth', 'common', 'landing']);
  const { signUp } = useAuth();
  const nav = useNavigate();
  const [f, setF] = useState({ name: '', email: '', password: '' });
  const [errs, setErrs] = useState<Record<string, string | null>>({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  const settings = useQuery({ queryKey: ['auth', 'settings'], queryFn: authSettings, staleTime: 5 * 60_000 });
  const closed = settings.data?.signupDisabled === true;
  const open = settings.data?.signupDisabled === false;
  async function submit(e: FormEvent) {
    e.preventDefault();
    const v = { name: validateName(f.name), email: validateEmail(f.email), password: validatePassword(f.password) };
    setErrs(v);
    if (v.name || v.email || v.password || busy) return;
    setBusy(true); setError(null);
    try {
      const r = await signUp(f.email, f.password, f.name);
      if (r.needsConfirmation) void nav({ to: '/confirm-email', search: { email: f.email } });
    } catch (x) { setError(toAppError(x)); } finally { setBusy(false); }
  }
  return (
    <Card title={t('signUp')} sub={t('signUpSub')}>
      {closed && <Banner tone="warn" icon="lock">{t('closed')}</Banner>}
      {settings.isPending && <p role="status">{t('landing:checking')}</p>}
      {!settings.isPending && !closed && !open && <Banner tone="warn">{t('landing:unavailable')} <Button variant="text" onClick={() => void settings.refetch()}>{t('common:retry')}</Button></Banner>}
      {open && (
        <form className="stack" onSubmit={submit} noValidate>
          <TextField label={t('fullName')} autoComplete="name" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} error={errs.name} />
          <TextField label={t('email')} type="email" autoComplete="username" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} error={errs.email} />
          <TextField label={t('password')} type="password" autoComplete="new-password" value={f.password} onChange={(e) => setF({ ...f, password: e.target.value })} error={errs.password}
            hint={t('passwordHint')} />
          <FormError error={error} />
          <Button type="submit" busy={busy}>{t('createAccount')}</Button>
        </form>
      )}
      <Link to="/login" className="small">{closed ? t('signIn') : t('haveAccount')}</Link>
    </Card>
  );
}

export function ConfirmEmailPage({ email }: { email?: string }) {
  const { t } = useTranslation('auth');
  const { resendConfirmation } = useAuth();
  const [state, setState] = useState<'idle' | 'sent'>('idle');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  async function resend() {
    if (!email || busy) return;
    setBusy(true); setError(null);
    try { await resendConfirmation(email); setState('sent'); } catch (x) { setError(toAppError(x)); } finally { setBusy(false); }
  }
  return (
    <Card title={t('confirmTitle')} sub={email ? t('confirmSubEmail', { email }) : t('confirmSub')}>
      <p className="muted">{t('confirmText')}</p>
      {state === 'sent' && <Banner tone="ok">{t('confirmResent')}</Banner>}
      <FormError error={error} />
      <div className="row">
        {email && <Button variant="tonal" busy={busy} onClick={() => void resend()}>{t('resendEmail')}</Button>}
        <Link to="/login" className="btn outline">{t('backToSignIn')}</Link>
      </div>
    </Card>
  );
}

export function ForgotPage() {
  const { t } = useTranslation('auth');
  const { requestReset } = useAuth();
  const [email, setEmail] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  async function submit(e: FormEvent) {
    e.preventDefault();
    const v = validateEmail(email);
    setErr(v);
    if (v || busy) return;
    setBusy(true); setError(null);
    try { await requestReset(email); setSent(true); } catch (x) { setError(toAppError(x)); } finally { setBusy(false); }
  }
  return (
    <Card title={t('forgotTitle')} sub={t('forgotSub')}>
      {sent ? (
        <Banner tone="ok">{t('forgotSent')}</Banner>
      ) : (
        <form className="stack" onSubmit={submit} noValidate>
          <TextField label={t('email')} type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} error={err} />
          <FormError error={error} />
          <Button type="submit" busy={busy}>{t('sendReset')}</Button>
        </form>
      )}
      <Link to="/login" className="small">{t('backToSignIn')}</Link>
    </Card>
  );
}

export function SetPasswordPage() {
  const { t } = useTranslation('auth');
  const { setNewPassword, signOut } = useAuth();
  const [pw, setPw] = useState('');
  const [pw2, setPw2] = useState('');
  const [errs, setErrs] = useState<{ pw?: string | null; pw2?: string | null }>({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  async function submit(e: FormEvent) {
    e.preventDefault();
    const v = { pw: validatePassword(pw), pw2: pw2 === pw ? null : 'validation:passwordMismatch' };
    setErrs(v);
    if (v.pw || v.pw2 || busy) return;
    setBusy(true); setError(null);
    try { await setNewPassword(pw); } catch (x) { setError(toAppError(x)); } finally { setBusy(false); }
  }
  return (
    <Card title={t('newPasswordTitle')}>
      <form className="stack" onSubmit={submit} noValidate>
        <TextField label={t('newPassword')} type="password" autoComplete="new-password" value={pw} onChange={(e) => setPw(e.target.value)} error={errs.pw}
          hint={t('passwordHint')} />
        <TextField label={t('repeatPassword')} type="password" autoComplete="new-password" value={pw2} onChange={(e) => setPw2(e.target.value)} error={errs.pw2} />
        <FormError error={error} />
        <Button type="submit" busy={busy}>{t('savePassword')}</Button>
      </form>
      <Button variant="text" onClick={() => void signOut()}>{t('cancel')}</Button>
    </Card>
  );
}

/** Landing for confirmation / recovery links: the SDK exchanges the code in the URL; this page waits and explains. */
export function CallbackPage() {
  const { t } = useTranslation('auth');
  const params = new URLSearchParams(window.location.search + window.location.hash.replace('#', '&'));
  const problem = params.get('error_description') ?? params.get('error');
  return (
    <Card title={problem ? t('callbackBadTitle') : t('callbackWait')}>
      {problem ? (
        <>
          <Banner tone="err">{t('callbackBad')}</Banner>
          <div className="row"><Link to="/forgot" className="btn tonal">{t('resetPassword')}</Link><Link to="/login" className="btn outline">{t('signIn')}</Link></div>
        </>
      ) : (
        <>
          <p className="muted" role="status">{t('callbackWaitText')}</p>
          <Frame><p className="small muted">{t('callbackNote')} <Link to="/login">{t('callbackSignInWith')}</Link></p></Frame>
        </>
      )}
    </Card>
  );
}
