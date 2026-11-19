import i18n from '../i18n';

export type ErrorKind =
  | 'network' | 'timeout' | 'unauthenticated' | 'forbidden' | 'notFound' | 'validation' | 'conflict'
  | 'rateLimited' | 'invalidCredentials' | 'emailNotConfirmed' | 'weakPassword' | 'signupDisabled'
  | 'contract' | 'unknown';

/**
 * A user-presentable failure. Never carries tokens, SQL or server internals; not-found never reveals existence.
 * `message` is the English text (logs/tests); what the user sees comes from `errorText()`, which translates `key` at render time,
 * so a visible error switches language together with the interface. `detail` is the server's own wording for input problems
 * (PT400): it describes the user's input and is shown as written (server-authored text is not translated).
 */
export class AppError extends Error {
  constructor(public kind: ErrorKind, message: string, public code?: string, public key?: string, public detail?: string) {
    super(message);
    this.name = 'AppError';
  }
  /** Safe to retry with the same request id (the server replays or applies once). */
  get retryable() {
    return this.kind === 'network' || this.kind === 'timeout';
  }
}

/** The error as shown to the user, in the current interface language. */
export function errorText(e: unknown): string {
  const err = e instanceof AppError ? e : toAppError(e);
  const base = i18n.t((err.key ?? `errors:${err.kind}`) as 'errors:unknown');
  return err.detail && err.detail !== base ? `${base} (${err.detail})` : base;
}

interface ErrLike { code?: string; message?: string; status?: number; name?: string; statusCode?: string | number }

const NET = /failed to fetch|network|load failed|fetch failed|internet|offline/i;
const E = (kind: ErrorKind, message: string, code?: string, key?: string, detail?: string) => new AppError(kind, message, code, key ?? `errors:${kind}`, detail);

export function toAppError(e: unknown): AppError {
  if (e instanceof AppError) return e;
  const x = (e ?? {}) as ErrLike;
  const msg = typeof x.message === 'string' ? x.message : '';
  if (x.name === 'AbortError' || x.name === 'TimeoutError') {
    return E('timeout', 'The server took too long to answer. Try again in a moment.');
  }
  switch (x.code) {
    case 'PT429':
      return E('rateLimited', 'Too many attempts. Please wait a few minutes and try again.', x.code);
    case 'PT403':
    case '42501':
      return E('forbidden', 'You do not have permission to do that.', x.code);
    case 'PT404':
      return E('notFound', 'That item was not found, or you no longer have access to it.', x.code);
    case 'PT400':
      return E('validation', msg || 'Please check the details and try again.', x.code, undefined, msg || undefined);
    case 'PT409':
      return E('conflict', msg || 'This changed elsewhere. Reload and try again.', x.code, undefined, msg || undefined);
    case 'PT401':
    case 'PGRST301':
    case 'PGRST303':
      return E('unauthenticated', 'Your session has expired. Please sign in again.', x.code);
    case 'invalid_credentials':
      return E('invalidCredentials', 'Email or password is incorrect.', x.code);
    case 'email_not_confirmed':
      return E('emailNotConfirmed', 'Please confirm your email address first.', x.code);
    case 'weak_password':
      return E('weakPassword', 'Choose a stronger password.', x.code);
    case 'signup_disabled':
      return E('signupDisabled', 'Registration is currently closed.', x.code);
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return E('rateLimited', 'Too many attempts. Please wait a moment and try again.', x.code);
  }
  if (x.status === 429 || String(x.statusCode) === '429') return E('rateLimited', 'Too many attempts.');
  if (x.status === 401) return E('unauthenticated', 'Your session has expired. Please sign in again.');
  const sc = String(x.statusCode ?? '');
  if (sc === '413') return E('validation', 'That file is too large (10 MB maximum).', undefined, 'errors:fileTooLarge');
  if (sc === '415') return E('validation', 'That file type is not allowed.', undefined, 'errors:fileType');
  if (sc === '401' || sc === '403' || /row-level security/i.test(msg)) {
    return E('forbidden', 'You are not allowed to upload or open that file.', undefined, 'errors:fileForbidden');
  }
  // Browsers word a dead connection differently (Chromium/Firefox/WebKit); the browser's own online flag settles the rest.
  if (NET.test(msg) || e instanceof TypeError || (typeof navigator !== 'undefined' && navigator.onLine === false)) {
    return E('network', 'No connection to the server. Check your network and try again.');
  }
  return E('unknown', 'Something went wrong. Please try again.');
}
