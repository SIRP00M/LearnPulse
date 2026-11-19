import { describe, expect, it, vi } from 'vitest';
import { AVATAR_MAX_BYTES, AVATAR_SIZE, checkAvatarFile, clampView, drawAvatar, encodeAvatar } from './avatar';

describe('checkAvatarFile', () => {
  it('accepts only JPEG/WebP within the decode cap', () => {
    expect(checkAvatarFile({ type: 'image/jpeg', size: 1000 })).toBeNull();
    expect(checkAvatarFile({ type: 'image/webp', size: 1000 })).toBeNull();
    expect(checkAvatarFile({ type: 'image/png', size: 1000 })).toBe('errors:avatarType');
    expect(checkAvatarFile({ type: 'image/svg+xml', size: 1000 })).toBe('errors:avatarType');
    expect(checkAvatarFile({ type: 'image/jpeg', size: 0 })).toBe('errors:fileEmpty');
    expect(checkAvatarFile({ type: 'image/jpeg', size: 11 * 1024 * 1024 })).toBe('errors:avatarInputTooLarge');
  });
});

describe('crop geometry', () => {
  it('clamps pan so the image always covers the square', () => {
    // 512x256 landscape at zoom 1: scaled to 512x256 -> 256 px of horizontal slack, none vertical.
    const v = clampView(512, 256, { zoom: 1, x: 999, y: 999 });
    expect(v).toEqual({ zoom: 1, x: 128, y: 0 });
    expect(clampView(512, 256, { zoom: 1, x: -999, y: 0 }).x).toBe(-128);
  });
  it('limits zoom to 1..4 and widens the pan range with zoom', () => {
    expect(clampView(256, 256, { zoom: 0.2, x: 0, y: 0 }).zoom).toBe(1);
    expect(clampView(256, 256, { zoom: 9, x: 0, y: 0 }).zoom).toBe(4);
    expect(clampView(256, 256, { zoom: 2, x: 999, y: 0 }).x).toBe(128);
  });
  it('draws the image covering the 256 square from its centre', () => {
    const drawImage = vi.fn();
    const ctx = { fillRect: vi.fn(), drawImage, fillStyle: '' } as unknown as CanvasRenderingContext2D;
    drawAvatar(ctx, {} as CanvasImageSource, 512, 256, { zoom: 1, x: 0, y: 0 });
    expect(drawImage).toHaveBeenCalledWith(expect.anything(), -128, 0, 512, 256);
    expect(AVATAR_SIZE).toBe(256);
  });
});

function fakeCanvas(sizes: Record<string, number[]>) {
  const calls: Array<[string, number]> = [];
  const next: Record<string, number> = {};
  const canvas = {
    toBlob(cb: (b: Blob | null) => void, type: string, q: number) {
      calls.push([type, q]);
      const list = sizes[type];
      if (!list) { cb(new Blob(['x'], { type: 'image/png' })); return; } // unsupported: the browser answers PNG
      const i = (next[type] = (next[type] ?? -1) + 1);
      cb(new Blob([new Uint8Array(list[Math.min(i, list.length - 1)]!)], { type }));
    },
  } as unknown as HTMLCanvasElement;
  return { canvas, calls };
}

describe('encodeAvatar', () => {
  it('uses WebP when it fits', async () => {
    const { canvas } = fakeCanvas({ 'image/webp': [20_000] });
    const r = await encodeAvatar(canvas);
    expect(r.ext).toBe('webp');
    expect(r.blob.size).toBeLessThanOrEqual(AVATAR_MAX_BYTES);
  });
  it('lowers quality until the result fits 512 KB', async () => {
    const { canvas, calls } = fakeCanvas({ 'image/webp': [AVATAR_MAX_BYTES + 1, AVATAR_MAX_BYTES + 1, 1000] });
    const r = await encodeAvatar(canvas);
    expect(r.ext).toBe('webp');
    expect(calls.map((c) => c[1])).toEqual([0.85, expect.closeTo(0.7), expect.closeTo(0.55)]);
  });
  it('falls back to JPEG where WebP cannot be encoded', async () => {
    const { canvas } = fakeCanvas({ 'image/jpeg': [30_000] });
    expect((await encodeAvatar(canvas)).ext).toBe('jpg');
  });
  it('fails clearly when nothing fits', async () => {
    const { canvas } = fakeCanvas({ 'image/webp': [AVATAR_MAX_BYTES + 1], 'image/jpeg': [AVATAR_MAX_BYTES + 1] });
    await expect(encodeAvatar(canvas)).rejects.toMatchObject({ key: 'errors:avatarEncode' });
  });
});
