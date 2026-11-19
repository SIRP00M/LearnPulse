import { z } from 'zod';
import { supabase } from '../supabase';
import { rpc, read } from '../rpc';
import { toAppError } from '../errors';
import { config } from '../../config';

const BUCKET = 'avatars';
const PATH_TTL_MS = 60_000; // another user's replaced photo shows up within a minute; own changes drop the entry at once
const MAX_BLOBS = 200;

const avatarResult = z.object({ avatar_path: z.string().nullable(), stale: z.array(z.string()) });

// ── path lookup: one batched profiles query per tick (RLS decides whose avatar_path is visible) ──
const paths = new Map<string, { path: string | null; at: number }>();
const waiting = new Map<string, Array<(p: string | null) => void>>();
let timer: ReturnType<typeof setTimeout> | undefined;

function flush() {
  const batch = new Map(waiting);
  waiting.clear();
  timer = undefined;
  read(
    supabase.from('profiles').select('id, avatar_path').in('id', [...batch.keys()]),
    z.array(z.object({ id: z.string(), avatar_path: z.string().nullable() })),
  ).then((rows) => {
    const found = new Map(rows.map((r) => [r.id, r.avatar_path]));
    for (const [id, cbs] of batch) {
      const p = found.get(id) ?? null;
      paths.set(id, { path: p, at: Date.now() });
      cbs.forEach((cb) => cb(p));
    }
  }, () => { for (const cbs of batch.values()) cbs.forEach((cb) => cb(null)); }); // initials; the next render retries
}

export function avatarPath(userId: string): Promise<string | null> {
  const hit = paths.get(userId);
  if (hit && Date.now() - hit.at < PATH_TTL_MS) return Promise.resolve(hit.path);
  return new Promise((resolve) => {
    waiting.set(userId, [...(waiting.get(userId) ?? []), resolve]);
    timer ??= setTimeout(flush, 15);
  });
}

// ── bytes: a path never changes content (every upload is a new path), so a blob URL is cached per path ──
const blobs = new Map<string, Promise<string | null>>();

/**
 * Not storage.download(): Cloudflare answers a repeat GET of the same URL and token from its cache even after the object was
 * deleted or access was revoked (measured on DEV, 20 s+), skipping the RLS check. A unique query value makes every fetch a
 * cache miss, so the database authorises each one; bytes are cached per immutable path in the page instead.
 */
async function download(path: string): Promise<Blob | null> {
  const token = (await supabase.auth.getSession()).data.session?.access_token;
  if (!token) return null;
  const r = await fetch(`${config.supabaseUrl}/storage/v1/object/authenticated/${BUCKET}/${path}?cb=${crypto.randomUUID()}`, {
    headers: { apikey: config.publishableKey, Authorization: `Bearer ${token}` }, cache: 'no-store',
  });
  return r.ok ? r.blob() : null;
}

export function avatarBlobUrl(path: string): Promise<string | null> {
  let p = blobs.get(path);
  if (!p) {
    // shortcut: evicted blob URLs are not revoked (a few KB each); revoke if avatars grow beyond rosters of ~200
    if (blobs.size >= MAX_BLOBS) blobs.delete(blobs.keys().next().value as string);
    p = download(path).then((b) => (b ? URL.createObjectURL(b) : null), () => null);
    blobs.set(path, p);
    void p.then((u) => { if (!u) blobs.delete(path); }); // do not cache a failure
  }
  return p;
}

/** Account-scoped: nothing of one user's photos may survive into the next session. */
export function clearAvatarCaches() {
  paths.clear();
  for (const p of blobs.values()) void p.then((u) => { if (u) URL.revokeObjectURL(u); });
  blobs.clear();
}

// ── mutations: upload a NEW object, let the server validate and switch the pointer, then delete what it calls stale ──
async function deleteStale(stale: string[]) {
  if (stale.length === 0) return;
  try { await supabase.storage.from(BUCKET).remove(stale); } catch { /* the next set/remove reports them again */ }
}

export async function saveAvatar(userId: string, blob: Blob, ext: 'webp' | 'jpg'): Promise<string> {
  const path = `${userId}/${crypto.randomUUID()}.${ext}`;
  const { error } = await supabase.storage.from(BUCKET).upload(path, blob, {
    contentType: ext === 'webp' ? 'image/webp' : 'image/jpeg', upsert: false, cacheControl: '60',
  });
  if (error) throw toAppError(error);
  try {
    const r = await rpc('set_my_avatar', { p_path: path }, avatarResult);
    paths.delete(userId);
    void deleteStale(r.stale);
    return r.avatar_path ?? path;
  } catch (e) {
    await deleteStale([path]); // do not leave an unreferenced object behind
    throw e;
  }
}

export async function dropAvatar(userId: string): Promise<void> {
  const r = await rpc('remove_my_avatar', undefined, avatarResult);
  paths.delete(userId);
  void deleteStale(r.stale);
}
