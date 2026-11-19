import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import en from './locales/en';
import th from './locales/th';
import ms from './locales/ms';

/** Supported interface languages. `label` is always shown in its own language (never translated) so a user can find theirs. */
export const LOCALES = [
  { code: 'en', label: 'English', tag: 'en' },
  { code: 'th', label: 'ไทย', tag: 'th-TH' },
  { code: 'ms', label: 'Bahasa Melayu', tag: 'ms-MY' },
] as const;
export type LocaleCode = (typeof LOCALES)[number]['code'];
export const FALLBACK: LocaleCode = 'en';
const KEY = 'lp-lang';

export const isLocale = (v: unknown): v is LocaleCode => LOCALES.some((l) => l.code === v);

/**
 * First-visit detection: the first supported browser language wins. Malaysian Malay (`ms`, `ms-MY`, `ms-BN`) maps to Bahasa Melayu;
 * Indonesian (`id`) is deliberately NOT mapped to it (different vocabulary) and falls back to English.
 */
export function detectLanguage(langs: readonly string[] = typeof navigator === 'undefined' ? [] : navigator.languages ?? [navigator.language]): LocaleCode {
  for (const raw of langs) {
    const base = raw.toLowerCase().split('-')[0];
    if (isLocale(base)) return base;
  }
  return FALLBACK;
}

export function storedLanguage(): LocaleCode | null {
  try {
    const v = localStorage.getItem(KEY);
    return isLocale(v) ? v : null;
  } catch {
    return null; // storage blocked: detection still works, the choice just is not remembered
  }
}

export const resources = { en, th, ms } as const;
export type Namespace = keyof typeof en;

void i18n.use(initReactI18next).init({
  resources,
  lng: storedLanguage() ?? detectLanguage(),
  fallbackLng: FALLBACK,
  ns: Object.keys(en),
  defaultNS: 'common',
  interpolation: { escapeValue: false }, // React escapes
  returnNull: false,
  react: { useSuspense: false },
});

/** BCP-47 tag used for Intl formatting and for <html lang>. */
export const localeTag = (): string => LOCALES.find((l) => l.code === i18n.language)?.tag ?? 'en';
export const currentLanguage = (): LocaleCode => (isLocale(i18n.language) ? i18n.language : FALLBACK);

function apply(code: string) {
  if (typeof document !== 'undefined') document.documentElement.lang = LOCALES.find((l) => l.code === code)?.tag ?? 'en';
}
apply(i18n.language);
i18n.on('languageChanged', apply);

/** Changes the language immediately (no reload, no route or session change) and remembers the choice on this device only. */
export async function setLanguage(code: LocaleCode): Promise<void> {
  await i18n.changeLanguage(code);
  try {
    localStorage.setItem(KEY, code);
  } catch { /* not remembered */ }
}

/**
 * Translates a validation/error KEY stored in component state ("validation:emailInvalid"), or returns plain text unchanged.
 * Keeping the key (not the text) in state means a message re-renders in the new language the moment the language changes.
 */
export function tr(keyOrText: string | null | undefined, options?: Record<string, unknown>): string {
  if (!keyOrText) return '';
  if (/^[a-z]+:[A-Za-z0-9_.]+$/.test(keyOrText) && i18n.exists(keyOrText)) return (i18n.t as unknown as (k: string, o?: unknown) => string)(keyOrText, options);
  return keyOrText;
}

export default i18n;

declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: 'common';
    resources: typeof en;
  }
}
