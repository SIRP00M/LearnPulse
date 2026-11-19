// Fails the build if the deploy folder could leak a privileged credential or source maps.
// Usage: node scripts/secret-scan.mjs [dir]   (default: dist)
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

const root = process.argv[2] ?? 'dist';
const problems = [];
const jwts = new Set();

function walk(dir) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) { walk(p); continue; }
    if (name.endsWith('.map')) problems.push(`${p}: source map shipped`);
    if (['.woff', '.woff2', '.png', '.jpg', '.ico'].includes(extname(name))) continue;
    const text = readFileSync(p, 'utf8');
    if (/sb_secret_[A-Za-z0-9_-]{8,}/.test(text)) problems.push(`${p}: Supabase secret key`);
    if (/-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(text)) problems.push(`${p}: private key block`);
    if (/(?:SUPABASE_)?SERVICE_ROLE_KEY|SUPABASE_ACCESS_TOKEN|sbp_[a-f0-9]{30,}/.test(text)) problems.push(`${p}: privileged variable name or access token`);
    for (const m of text.matchAll(/eyJ[A-Za-z0-9_-]{10,}\.([A-Za-z0-9_-]{10,})\.[A-Za-z0-9_-]{10,}/g)) {
      try {
        const role = JSON.parse(Buffer.from(m[1], 'base64url').toString('utf8')).role;
        jwts.add(`${role}`);
        if (role !== 'anon') problems.push(`${p}: JWT with role "${role}"`);
      } catch { /* not a JWT payload */ }
    }
  }
}
walk(root);
console.log(`secret scan of ${root}: JWT roles found = [${[...jwts].join(', ')}] (only "anon", the public key, is acceptable)`);
if (problems.length) { console.error('FAILED:\n' + problems.join('\n')); process.exit(1); }
console.log('secret scan: PASS');
