import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthProvider';
import { avatarBlobUrl, avatarPath } from '../lib/api/avatar';

const initials = (name: string) => {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  return ((parts[0]![0] ?? '') + (parts.length > 1 ? (parts[parts.length - 1]![0] ?? '') : '')).toUpperCase();
};

/**
 * Decorative (the name is always shown beside it). Photos are private: only the owner and the course teacher can read them,
 * so everyone else — and any load failure — gets the initials without issuing a request.
 */
export function Avatar({ userId, name, size = 32 }: { userId: string | null | undefined; name: string; size?: number }) {
  const { userId: me, profile } = useAuth();
  const isMe = !!userId && userId === me;
  const allowed = !!userId && (isMe || profile?.role === 'teacher');
  const ownPath = isMe ? (profile?.avatarPath ?? null) : null;
  const [url, setUrl] = useState<string | null>(null);

  useEffect(() => {
    let live = true;
    setUrl(null);
    if (!allowed || !userId) return;
    void (async () => {
      const p = isMe ? ownPath : await avatarPath(userId);
      const u = p ? await avatarBlobUrl(p) : null;
      if (live) setUrl(u);
    })();
    return () => { live = false; };
  }, [allowed, isMe, ownPath, userId]);

  return (
    <span className="avatar" style={{ width: size, height: size, fontSize: Math.round(size * 0.4) }} aria-hidden data-photo={url ? 'true' : 'false'}>
      {url ? <img src={url} alt="" width={size} height={size} draggable={false} onError={() => setUrl(null)} /> : initials(name)}
    </span>
  );
}
