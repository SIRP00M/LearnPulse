import { describe, expect, it } from 'vitest';
import { keyProblem, validateConfig } from './config';

const jwt = (role: string) => `h.${btoa(JSON.stringify({ role }))}.s`;

describe('build configuration safety', () => {
  it('accepts a publishable/anon key over https', () => {
    expect(validateConfig('https://abc.supabase.co', jwt('anon'))).toBeNull();
    expect(validateConfig('https://abc.supabase.co', 'sb_publishable_abc')).toBeNull();
  });
  it('refuses a service_role JWT or a secret key so it can never ship in the bundle', () => {
    expect(keyProblem(jwt('service_role'))).toMatch(/service_role/);
    expect(keyProblem('sb_secret_abc')).toMatch(/secret key/);
  });
  it('requires https except for localhost', () => {
    expect(validateConfig('http://abc.supabase.co', jwt('anon'))).toMatch(/https/);
    expect(validateConfig('http://127.0.0.1:54321', jwt('anon'))).toBeNull();
    expect(validateConfig('', jwt('anon'))).toMatch(/missing or invalid/);
    expect(validateConfig('https://abc.supabase.co', '')).toMatch(/missing/);
  });
});
