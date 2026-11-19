import { useMemo } from 'react';
import qrcode from 'qrcode-generator';

/** Renders `value` as a QR image (inline SVG data URL: allowed by the CSP `img-src data:`). Black on white for reliable scanning. */
export function QrCode({ value, label, size = 280 }: { value: string; label: string; size?: number }) {
  const src = useMemo(() => {
    const qr = qrcode(0, 'M');
    qr.addData(value);
    qr.make();
    return `data:image/svg+xml;utf8,${encodeURIComponent(qr.createSvgTag({ cellSize: 6, margin: 4, scalable: true }))}`;
  }, [value]);
  return <img className="qr" src={src} alt={label} width={size} height={size} style={{ background: '#fff', imageRendering: 'pixelated' }} />;
}
