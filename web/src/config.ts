/** Build-time public configuration. Privileged keys are refused so they can never ship in the bundle. */
export interface AppConfig {
  supabaseUrl: string;
  publishableKey: string;
  env: string;
}

/** Returns a human-readable problem, or null when usable. Exported for tests. */
export function keyProblem(key: string): string | null {
  if (!key) return 'VITE_SUPABASE_PUBLISHABLE_KEY is missing.';
  if (key.startsWith('sb_secret_')) return 'A secret key must never be used in the browser.';
  const parts = key.split('.');
  if (parts.length === 3) {
    try {
      const payload = JSON.parse(atob(parts[1]!.replace(/-/g, '+').replace(/_/g, '/')));
      if (payload?.role === 'service_role') return 'A service_role key must never be used in the browser.';
    } catch {
      return 'The key is not a valid Supabase key.';
    }
  }
  return null;
}

export function validateConfig(url: string, key: string): string | null {
  let u: URL;
  try {
    u = new URL(url);
  } catch {
    return 'VITE_SUPABASE_URL is missing or invalid.';
  }
  const local = ['localhost', '127.0.0.1'].includes(u.hostname);
  if (u.protocol !== 'https:' && !(u.protocol === 'http:' && local)) return 'VITE_SUPABASE_URL must use https.';
  return keyProblem(key);
}

const env = import.meta.env;
export const config: AppConfig = {
  supabaseUrl: (env.VITE_SUPABASE_URL as string | undefined) ?? '',
  publishableKey: (env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined) ?? '',
  env: (env.VITE_APP_ENV as string | undefined) ?? 'dev',
};
export const configProblem = validateConfig(config.supabaseUrl, config.publishableKey);
export const APP_VERSION = '0.1.0-beta.1';
