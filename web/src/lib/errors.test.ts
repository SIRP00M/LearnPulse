import { describe, expect, it } from 'vitest';
import { AppError, toAppError } from './errors';

describe('toAppError', () => {
  it.each([
    ['PT400', 'validation'], ['PT401', 'unauthenticated'], ['PT403', 'forbidden'], ['42501', 'forbidden'],
    ['PT404', 'notFound'], ['PT409', 'conflict'], ['PT429', 'rateLimited'], ['PGRST301', 'unauthenticated'],
    ['invalid_credentials', 'invalidCredentials'], ['email_not_confirmed', 'emailNotConfirmed'], ['weak_password', 'weakPassword'],
    ['signup_disabled', 'signupDisabled'], ['over_email_send_rate_limit', 'rateLimited'],
  ])('maps %s to %s', (code, kind) => {
    expect(toAppError({ code, message: 'server text' }).kind).toBe(kind);
  });

  it('never reveals whether a hidden resource exists', () => {
    const e = toAppError({ code: 'PT404', message: 'Course 123 belongs to someone else' });
    expect(e.message).not.toMatch(/123|someone/);
    expect(e.message).toMatch(/not found, or you no longer have access/);
  });

  it('keeps server wording only for validation (it describes the user input), never for unknown errors', () => {
    expect(toAppError({ code: 'PT400', message: 'Title must be 1-120 characters' }).message).toBe('Title must be 1-120 characters');
    expect(toAppError({ code: 'XX000', message: 'relation "secret_table" does not exist' }).message).not.toMatch(/secret_table/);
  });

  it('treats fetch failures and timeouts as retryable', () => {
    expect(toAppError(new TypeError('Failed to fetch')).retryable).toBe(true);
    expect(toAppError({ message: 'TypeError: Failed to fetch' }).kind).toBe('network');
    expect(toAppError({ name: 'TimeoutError', message: 'x' }).kind).toBe('timeout');
    expect(toAppError({ code: 'PT409', message: 'x' }).retryable).toBe(false);
  });

  it('maps storage failures', () => {
    expect(toAppError({ statusCode: '413', message: 'x' }).message).toMatch(/10 MB/);
    expect(toAppError({ statusCode: '415', message: 'x' }).kind).toBe('validation');
    expect(toAppError({ message: 'new row violates row-level security policy' }).kind).toBe('forbidden');
  });

  it('passes an AppError through unchanged and defaults to a generic message', () => {
    const a = new AppError('conflict', 'x');
    expect(toAppError(a)).toBe(a);
    expect(toAppError(undefined).message).toBe('Something went wrong. Please try again.');
  });
});
