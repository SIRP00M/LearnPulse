import { useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../auth/AuthProvider';
import { Button, Chip, Frame, FormError, PageHead, TextField, useToast } from '../ui/kit';
import { Avatar } from '../ui/Avatar';
import { AvatarEditor } from '../ui/AvatarEditor';
import { checkAvatarFile } from '../lib/avatar';
import { LOCALES, currentLanguage, isLocale, setLanguage } from '../i18n';
import { toAppError, type AppError } from '../lib/errors';
import { validateName } from '../lib/validators';
import { getThemePref, setThemePref, type ThemePref } from '../lib/theme';
import { APP_VERSION, config } from '../config';

export function ProfilePage() {
  const { t } = useTranslation(['profile', 'common', 'nav', 'errors']);
  const { profile, email, userId, updateName, setAvatar, removeAvatar, signOut } = useAuth();
  const toast = useToast();
  const [name, setName] = useState(profile?.fullName ?? '');
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<AppError | null>(null);
  const [theme, setTheme] = useState<ThemePref>(getThemePref);
  const [pick, setPick] = useState<File | null>(null);
  const [photoErr, setPhotoErr] = useState<string | null>(null);
  const [photoError, setPhotoError] = useState<AppError | null>(null);
  const [photoBusy, setPhotoBusy] = useState(false);
  const fileInput = useRef<HTMLInputElement>(null);
  async function savePhoto(blob: Blob, ext: 'webp' | 'jpg') {
    await setAvatar(blob, ext);
    setPick(null);
    toast(t('profile:photoSaved'));
  }
  async function removePhoto() {
    setPhotoBusy(true); setPhotoError(null);
    try { await removeAvatar(); toast(t('profile:photoRemoved')); } catch (e) { setPhotoError(toAppError(e)); } finally { setPhotoBusy(false); }
  }
  async function save() {
    const v = validateName(name);
    setErr(v);
    if (v || busy) return;
    setBusy(true); setError(null);
    try { await updateName(name); toast(t('profile:nameSaved')); } catch (e) { setError(toAppError(e)); } finally { setBusy(false); }
  }
  return (
    <>
      <PageHead title={t('profile:title')} />
      <div className="cols">
        <div className="c6 stack"><Frame title={t('profile:photo')}>
          <div className="row">
            <Avatar userId={userId} name={profile?.fullName ?? ''} size={96} />
            <div className="stack">
              <span className="hint">{t('profile:photoHint')}</span>
              <div className="row">
                <input ref={fileInput} type="file" accept="image/jpeg,image/webp" hidden data-testid="avatar-input"
                  onChange={(e) => {
                    const f = e.target.files?.[0]; e.target.value = '';
                    if (!f) return;
                    const k = checkAvatarFile(f);
                    setPhotoErr(k); setPhotoError(null);
                    if (!k) setPick(f);
                  }} />
                <Button variant="outline" icon="photo_camera" onClick={() => fileInput.current?.click()}>{profile?.avatarPath ? t('profile:photoChange') : t('profile:photoAdd')}</Button>
                {profile?.avatarPath && <Button variant="text" icon="delete" busy={photoBusy} onClick={() => void removePhoto()}>{t('profile:photoRemove')}</Button>}
              </div>
              {photoErr && <span className="err-text" role="alert">{t(photoErr as 'errors:avatarType')}</span>}
              <FormError error={photoError} />
            </div>
          </div>
        </Frame>
        <Frame title={t('profile:account')}>
          <form className="stack" noValidate onSubmit={(e) => { e.preventDefault(); void save(); }}>
            <dl className="kv"><dt>{t('profile:email')}</dt><dd>{email}</dd><dt>{t('profile:role')}</dt><dd><Chip icon={profile?.role === 'teacher' ? 'school' : 'person'}>{profile?.role === 'teacher' ? t('common:teacher') : t('common:student')}</Chip></dd></dl>
            <TextField label={t('profile:displayName')} value={name} onChange={(e) => setName(e.target.value)} error={err} maxLength={120} autoComplete="name" />
            <FormError error={error} />
            <div className="row"><Button type="submit" busy={busy} disabled={name.trim() === (profile?.fullName ?? '')}>{t('profile:saveName')}</Button></div>
          </form>
        </Frame></div>
        <div className="c6 stack">
          <Frame title={t('profile:appearance')}>
            <div className="stack">
              <fieldset style={{ border: 0, padding: 0, margin: 0 }}><legend className="sr-only">{t('profile:theme')}</legend>
                <div className="checks">{(['system', 'light', 'dark'] as ThemePref[]).map((th) => (
                  <label key={th} className="check"><input type="radio" name="theme" checked={theme === th} onChange={() => { setTheme(th); setThemePref(th); }} />{th === 'system' ? t('profile:themeSystem') : th === 'light' ? t('profile:themeLight') : t('profile:themeDark')}</label>))}</div>
              </fieldset>
              <fieldset style={{ border: 0, padding: 0, margin: 0 }}><legend style={{ fontWeight: 500, marginBottom: 6 }}>{t('profile:language')}</legend>
                <div className="checks" role="radiogroup" aria-label={t('profile:language')}>{LOCALES.map((l) => (
                  <label key={l.code} className="check"><input type="radio" name="language" checked={currentLanguage() === l.code} onChange={() => { if (isLocale(l.code)) void setLanguage(l.code); }} /><span lang={l.tag}>{l.label}</span></label>))}</div>
                <span className="hint">{t('profile:languageHint')}</span>
              </fieldset>
            </div>
          </Frame>
          <Frame title={t('profile:session')}>
            <div className="stack"><p className="muted">{t('profile:sessionText')}</p>
              <div><Button variant="outline" icon="logout" onClick={() => void signOut()}>{t('nav:signOut')}</Button></div></div>
          </Frame>
          <Frame title={t('profile:about')}><p className="muted small">{t('profile:aboutText', { version: APP_VERSION, env: config.env })}</p></Frame>
        </div>
      </div>
      <AvatarEditor file={pick} onClose={() => setPick(null)} onSave={savePhoto} />
    </>
  );
}
