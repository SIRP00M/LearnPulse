import { useId } from 'react';
import { useTranslation } from 'react-i18next';
import { LOCALES, currentLanguage, isLocale, setLanguage } from '../i18n';
import { Icon } from './kit';

/**
 * Switches the interface language in place: no reload, no route change, the session and any typed form data are untouched.
 * Options always show each language in its own script (English / ไทย / Bahasa Melayu) so a user can find theirs in any language.
 */
export function LanguageSelector({ compact }: { compact?: boolean }) {
  const { t } = useTranslation('common');
  const id = useId();
  return (
    <div className={`langsel${compact ? ' compact' : ''}`}>
      <label htmlFor={id} className={compact ? 'sr-only' : 'langsel-label'}><Icon name="translate" /> {t('language')}</label>
      <select id={id} className="input" value={currentLanguage()} onChange={(e) => { if (isLocale(e.target.value)) void setLanguage(e.target.value); }}>
        {LOCALES.map((l) => <option key={l.code} value={l.code} lang={l.tag}>{l.label}</option>)}
      </select>
    </div>
  );
}
