// Static server that behaves like Cloudflare Pages for this app: serves dist/, applies dist/_headers, and, because
// there is NO 404.html, answers unknown paths with index.html (Pages' documented single-page-application mode).
// Used by the Playwright run so the production build is tested together with its real headers (CSP included).
import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import { join, extname, normalize } from 'node:path';

const root = join(process.cwd(), process.env.DIST ?? 'dist');
const port = Number(process.env.PORT ?? 4173);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.woff': 'font/woff', '.json': 'application/json', '.txt': 'text/plain', '.ico': 'image/x-icon' };

// parse _headers: blocks of "<path pattern>\n  Name: value"
const rules = [];
if (existsSync(join(root, '_headers'))) {
  let cur = null;
  for (const line of readFileSync(join(root, '_headers'), 'utf8').split(/\r?\n/)) {
    if (!line.trim() || line.startsWith('#')) continue;
    if (!line.startsWith(' ')) { cur = { pattern: line.trim(), headers: [] }; rules.push(cur); } else if (cur) { const i = line.indexOf(':'); cur.headers.push([line.slice(0, i).trim(), line.slice(i + 1).trim()]); }
  }
}
const matches = (pattern, path) => pattern === path || (pattern.endsWith('/*') && path.startsWith(pattern.slice(0, -1))) || (pattern === '/*');

createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let file = normalize(join(root, path));
  let servedPath = path;
  if (!file.startsWith(root)) { res.writeHead(400).end(); return; }
  if (!existsSync(file) || statSync(file).isDirectory()) { file = join(root, 'index.html'); servedPath = '/index.html'; } // SPA fallback
  const headers = { 'Content-Type': types[extname(file)] ?? 'application/octet-stream' };
  for (const r of rules) if (matches(r.pattern, servedPath) || matches(r.pattern, path)) for (const [k, v] of r.headers) headers[k] = v;
  res.writeHead(200, headers).end(readFileSync(file));
}).listen(port, '127.0.0.1', () => console.log(`serving dist on http://127.0.0.1:${port}`));
