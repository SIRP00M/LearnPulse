import { createClient } from '@supabase/supabase-js';
import { config, configProblem } from '../config';

// A bad config must not construct a working client; the app shows a configuration screen instead.
export const supabase = createClient(
  configProblem ? 'https://invalid.example' : config.supabaseUrl,
  configProblem ? 'invalid' : config.publishableKey,
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: 'pkce' } },
);

// Capture recovery before React mounts: a fast PKCE exchange can precede AuthProvider's subscription.
export let recoveryUserId: string | null = null;
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'PASSWORD_RECOVERY') recoveryUserId = session?.user.id ?? null;
  else if (event === 'SIGNED_OUT' || event === 'USER_UPDATED' || event === 'SIGNED_IN') recoveryUserId = null;
});
