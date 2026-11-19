// Builds the app against the LOCAL mock backend (e2e-mock/server.mjs) into dist-mock/ for the localization acceptance run.
// The key below is a fake anon-role token for a local-only mock; it is not a Supabase credential.
import { spawnSync } from 'node:child_process';

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const fakeAnon = `${b64({ alg: 'HS256', typ: 'JWT' })}.${b64({ role: 'anon', iss: 'local-mock' })}.mock`;
const r = spawnSync('npx', ['vite', 'build', '--outDir', 'dist-mock', '--emptyOutDir'], {
  stdio: 'inherit', shell: true,
  env: { ...process.env, VITE_SUPABASE_URL: 'http://127.0.0.1:54399', VITE_SUPABASE_PUBLISHABLE_KEY: fakeAnon, VITE_APP_ENV: 'mock' },
});
if (r.status) process.exit(r.status);
// same CSP/headers as the real package, pointing at the mock origin, so the localization run also proves the CSP is not violated
const h = spawnSync('node', ['scripts/write-headers.mjs'], { stdio: 'inherit', env: { ...process.env, DIST: 'dist-mock', VITE_SUPABASE_URL: 'http://127.0.0.1:54399' } });
process.exit(h.status ?? 1);
