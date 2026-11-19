import { AppError } from './errors';

/** Avatar pipeline: pick -> square crop -> 256x256 re-encode (strips EXIF) -> upload. The server re-checks type and size. */
export const AVATAR_SIZE = 256;
export const AVATAR_MAX_BYTES = 512 * 1024;
export const AVATAR_MAX_INPUT_BYTES = 10 * 1024 * 1024; // decode-safety cap on the picked file, not on the upload
export const AVATAR_INPUT_TYPES = ['image/jpeg', 'image/webp'];

/** Returns a translation KEY (errors:…) or null. */
export function checkAvatarFile(f: { type: string; size: number }): string | null {
  if (!AVATAR_INPUT_TYPES.includes(f.type)) return 'errors:avatarType';
  if (f.size === 0) return 'errors:fileEmpty';
  if (f.size > AVATAR_MAX_INPUT_BYTES) return 'errors:avatarInputTooLarge';
  return null;
}

/** zoom >= 1 (1 = image just covers the square); x/y = pan in output pixels from the centred position. */
export interface View { zoom: number; x: number; y: number }

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));
const coverScale = (w: number, h: number, zoom: number) => Math.max(AVATAR_SIZE / w, AVATAR_SIZE / h) * zoom;

/** Keeps the image covering the whole square, so the crop never shows an empty edge. */
export function clampView(w: number, h: number, v: View): View {
  const zoom = clamp(v.zoom, 1, 4);
  const s = coverScale(w, h, zoom);
  const mx = Math.max(0, (w * s - AVATAR_SIZE) / 2);
  const my = Math.max(0, (h * s - AVATAR_SIZE) / 2);
  return { zoom, x: clamp(v.x, -mx, mx), y: clamp(v.y, -my, my) };
}

export function drawAvatar(ctx: CanvasRenderingContext2D, img: CanvasImageSource, w: number, h: number, v: View) {
  const s = coverScale(w, h, v.zoom);
  ctx.fillStyle = '#fff'; // JPEG has no alpha
  ctx.fillRect(0, 0, AVATAR_SIZE, AVATAR_SIZE);
  ctx.drawImage(img, (AVATAR_SIZE - w * s) / 2 + v.x, (AVATAR_SIZE - h * s) / 2 + v.y, w * s, h * s);
}

const toBlob = (c: HTMLCanvasElement, type: string, q: number) => new Promise<Blob | null>((res) => c.toBlob(res, type, q));

/** WebP first (every current browser encodes it); JPEG where it does not. Lowers quality until it fits 512 KB. */
export async function encodeAvatar(canvas: HTMLCanvasElement): Promise<{ blob: Blob; ext: 'webp' | 'jpg' }> {
  for (const [type, ext] of [['image/webp', 'webp'], ['image/jpeg', 'jpg']] as const) {
    for (let q = 0.85; q >= 0.4; q -= 0.15) {
      const blob = await toBlob(canvas, type, q);
      if (!blob || blob.type !== type) break; // the browser fell back to PNG: this format is unsupported
      if (blob.size <= AVATAR_MAX_BYTES) return { blob, ext };
    }
  }
  throw new AppError('validation', 'The photo could not be prepared.', undefined, 'errors:avatarEncode');
}
