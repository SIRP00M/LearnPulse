import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AVATAR_SIZE, clampView, drawAvatar, encodeAvatar, type View } from '../lib/avatar';
import { AppError, toAppError } from '../lib/errors';
import { Button, FormError, Modal } from './kit';

const STEP = 8;

/** Square crop: drag (or arrow keys) to position, slider to zoom. What is on the canvas is exactly what is uploaded. */
export function AvatarEditor({ file, onClose, onSave }: {
  file: File | null;
  onClose: () => void;
  onSave: (blob: Blob, ext: 'webp' | 'jpg') => Promise<void>;
}) {
  const { t } = useTranslation(['profile', 'common']);
  const canvas = useRef<HTMLCanvasElement>(null);
  const drag = useRef<{ x: number; y: number; vx: number; vy: number } | null>(null);
  const [bmp, setBmp] = useState<ImageBitmap | null>(null);
  const [view, setView] = useState<View>({ zoom: 1, x: 0, y: 0 });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);

  useEffect(() => {
    let live = true;
    setBmp(null); setError(null); setView({ zoom: 1, x: 0, y: 0 });
    if (!file) return;
    createImageBitmap(file, { imageOrientation: 'from-image' }).then(
      (b) => { if (live) setBmp(b); else b.close(); },
      () => { if (live) setError(new AppError('validation', 'The photo could not be read.', undefined, 'errors:avatarDecode')); },
    );
    return () => { live = false; };
  }, [file]);

  useEffect(() => {
    const ctx = canvas.current?.getContext('2d');
    if (ctx && bmp) drawAvatar(ctx, bmp, bmp.width, bmp.height, view);
  }, [bmp, view]);

  const move = useCallback((v: View) => { if (bmp) setView(clampView(bmp.width, bmp.height, v)); }, [bmp]);

  async function save() {
    if (!canvas.current || busy) return;
    setBusy(true); setError(null);
    try {
      const { blob, ext } = await encodeAvatar(canvas.current);
      await onSave(blob, ext);
    } catch (e) { setError(toAppError(e)); } finally { setBusy(false); }
  }

  return (
    <Modal open={!!file} onClose={() => { if (!busy) onClose(); }} title={t('profile:photoCropTitle')} description={t('profile:photoCropHint')}>
      <div className="avatar-crop">
        <canvas
          ref={canvas} width={AVATAR_SIZE} height={AVATAR_SIZE} tabIndex={0} role="img" aria-label={t('profile:photoCropCanvas')}
          onPointerDown={(e) => { e.currentTarget.setPointerCapture(e.pointerId); drag.current = { x: e.clientX, y: e.clientY, vx: view.x, vy: view.y }; }}
          onPointerMove={(e) => {
            const d = drag.current; if (!d) return;
            const k = AVATAR_SIZE / e.currentTarget.getBoundingClientRect().width; // CSS px -> canvas px
            move({ ...view, x: d.vx + (e.clientX - d.x) * k, y: d.vy + (e.clientY - d.y) * k });
          }}
          onPointerUp={() => { drag.current = null; }}
          onKeyDown={(e) => {
            const d = { ArrowLeft: [-STEP, 0], ArrowRight: [STEP, 0], ArrowUp: [0, -STEP], ArrowDown: [0, STEP] }[e.key];
            if (d) { e.preventDefault(); move({ ...view, x: view.x + d[0]!, y: view.y + d[1]! }); }
          }}
        />
      </div>
      <label className="field"><span>{t('profile:photoZoom')}</span>
        <input type="range" min={1} max={4} step={0.05} value={view.zoom} disabled={!bmp} onChange={(e) => move({ ...view, zoom: Number(e.target.value) })} />
      </label>
      <FormError error={error} />
      <div className="row">
        <Button onClick={() => void save()} busy={busy} disabled={!bmp}>{t('profile:photoSave')}</Button>
        <Button variant="outline" onClick={onClose} disabled={busy}>{t('common:cancel')}</Button>
      </div>
    </Modal>
  );
}
