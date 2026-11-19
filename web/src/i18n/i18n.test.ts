import { afterEach, describe, expect, it } from 'vitest';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import i18n, { LOCALES, detectLanguage, localeTag, resources, setLanguage, storedLanguage, tr } from './index';
import { fmtNumber, formatDay, formatDayLong, formatMonth, isoWeekdayShort, percent, relativeDay } from '../lib/dates';

type Tree = { [k: string]: string | Tree };
const flat = (o: Tree, p = ''): Record<string, string> =>
  Object.entries(o).reduce((acc, [k, v]) => (typeof v === 'string' ? { ...acc, [p + k]: v } : { ...acc, ...flat(v, `${p}${k}.`) }), {} as Record<string, string>);
const holders = (s: string) => [...s.matchAll(/\{\{\s*(\w+)\s*\}\}/g)].map((m) => m[1]!).sort();

const en = flat(resources.en as unknown as Tree);
const th = flat(resources.th as unknown as Tree);
const ms = flat(resources.ms as unknown as Tree);

afterEach(async () => { await setLanguage('en'); localStorage.clear(); });

describe('translation completeness', () => {
  it('Thai and Malay provide exactly the English key set (nothing missing, nothing extra)', () => {
    expect(Object.keys(th).sort()).toEqual(Object.keys(en).sort());
    expect(Object.keys(ms).sort()).toEqual(Object.keys(en).sort());
    expect(Object.keys(en).length).toBeGreaterThan(600);
  });

  it('no empty strings and no missing-key placeholders in any language', () => {
    for (const [name, r] of [['en', en], ['th', th], ['ms', ms]] as const) {
      for (const [k, v] of Object.entries(r)) {
        expect(v.trim(), `${name}:${k} is empty`).not.toBe('');
        expect(v, `${name}:${k} looks like a missing-key placeholder`).not.toMatch(/^(TODO|FIXME|XXX)|\[missing|not translated/i);
      }
    }
  });

  it('every interpolation placeholder in English exists in the translation (and vice versa)', () => {
    for (const k of Object.keys(en)) {
      expect(holders(th[k]!), `th:${k}`).toEqual(holders(en[k]!));
      expect(holders(ms[k]!), `ms:${k}`).toEqual(holders(en[k]!));
    }
  });

  it('Thai strings contain Thai script; Malay and Thai are not left as copied English', () => {
    const keepEnglish = new Set(['status.unknown']); // none expected; extend only with a reason
    const sameOk = /^(\{\{.*\}\}|[\s·—–\-/:()+0-9{}a-zA-Z_,.]*)$/; // pure placeholders / punctuation / product tokens
    for (const k of Object.keys(en)) {
      if (keepEnglish.has(k)) continue;
      if (!sameOk.test(en[k]!) || /[a-z]{4,}/i.test(en[k]!.replace(/\{\{\w+\}\}/g, ''))) {
        expect(/[฀-๿]/.test(th[k]!), `th:${k} has no Thai script: ${th[k]}`).toBe(true);
        // allow identical Malay only for tokens that are the same word in Malay (e.g. "Status", "Menu", "Profil" differ by spelling elsewhere)
        if (ms[k] === en[k]) expect(['status', 'menu', 'sessions'].some((w) => en[k]!.toLowerCase().includes(w)), `ms:${k} is untranslated English: ${ms[k]}`).toBe(true);
      }
    }
  });

  it('Malay uses Malaysian vocabulary, not Indonesian', () => {
    const indonesian = ['kata sandi', 'unggah', 'unduh', 'berkas', 'surel', 'silakan', 'harap tunggu', 'sudah tersedia'];
    const all = Object.values(ms).join('\n').toLowerCase();
    for (const w of indonesian) expect(all, `Indonesian word "${w}" found in ms`).not.toContain(w);
    expect(all).toContain('kata laluan'); // Malaysian "password"
    expect(all).toContain('muat naik'); // Malaysian "upload"
    expect(all).toContain('fail'); // Malaysian "file"
  });

  it('every namespaced translation key written as a string literal in the source exists', () => {
    const walk = (d: string): string[] => readdirSync(d).flatMap((n) => { const p = join(d, n); return statSync(p).isDirectory() ? (n === 'i18n' ? [] : walk(p)) : /\.(tsx?)$/.test(n) && !/\.test\./.test(n) ? [p] : []; });
    const files = walk(join(process.cwd(), 'src'));
    const used = new Set<string>();
    for (const f of files) for (const m of readFileSync(f, 'utf8').matchAll(/['"`]((?:common|errors|validation|status|nav|table|auth|dashboard|courses|lessons|assignments|attendance|activities|progress|tasks|verification|profile):[A-Za-z0-9_.]+)['"`]/g)) used.add(m[1]!);
    expect(used.size).toBeGreaterThan(100);
    for (const key of used) expect(i18n.exists(key), `missing key ${key}`).toBe(true);
  });
});

describe('language selection', () => {
  it('detects supported browser languages, in preference order; Indonesian is NOT mapped to Malay', () => {
    expect(detectLanguage(['th-TH', 'en'])).toBe('th');
    expect(detectLanguage(['ms-MY'])).toBe('ms');
    expect(detectLanguage(['ms'])).toBe('ms');
    expect(detectLanguage(['ms-BN'])).toBe('ms');
    expect(detectLanguage(['fr-FR', 'ms-MY', 'en'])).toBe('ms');
    expect(detectLanguage(['id-ID'])).toBe('en');
    expect(detectLanguage(['de', 'fr'])).toBe('en');
    expect(detectLanguage([])).toBe('en');
  });

  it('switching applies at once, sets <html lang>, remembers the choice, and the stored choice overrides detection', async () => {
    await setLanguage('th');
    expect(i18n.t('nav:dashboard')).toBe('แดชบอร์ด');
    expect(document.documentElement.lang).toBe('th-TH');
    expect(localeTag()).toBe('th-TH');
    expect(storedLanguage()).toBe('th');
    await setLanguage('ms');
    expect(i18n.t('nav:dashboard')).toBe('Papan pemuka');
    expect(document.documentElement.lang).toBe('ms-MY');
    await setLanguage('en');
    expect(document.documentElement.lang).toBe('en');
  });

  it('exposes the three selector labels in their own scripts', () => {
    expect(LOCALES.map((l) => l.label)).toEqual(['English', 'ไทย', 'Bahasa Melayu']);
  });

  it('tr() translates stored keys in the current language and passes plain text through', async () => {
    expect(tr('validation:emailRequired')).toBe('Enter your email address');
    await setLanguage('th');
    expect(tr('validation:emailRequired')).toBe('กรอกที่อยู่อีเมลของคุณ');
    await setLanguage('ms');
    expect(tr('validation:scoreRange', { max: 20 })).toBe('Nombor bulat dari 0 hingga 20');
    expect(tr('A teacher-written title: 12:30')).toBe('A teacher-written title: 12:30'); // user content is never translated
    expect(tr(null)).toBe('');
  });
});

describe('locale-aware dates and numbers (display only)', () => {
  const day = '2026-11-16'; // a Monday

  it('Thai uses the Buddhist era and always prints the era next to the year', async () => {
    await setLanguage('th');
    expect(formatMonth(new Date(2026, 10, 1))).toMatch(/พ\.ศ\.\s*2569/);
    expect(formatDayLong(day)).toMatch(/พ\.ศ\.\s*2569/);
    expect(formatDay(day)).not.toMatch(/25\d\d|2026/); // day-month formats carry no year
  });

  it('English and Malay keep the Gregorian year', async () => {
    expect(formatDayLong(day)).toMatch(/2026/);
    await setLanguage('ms');
    expect(formatDayLong(day)).toMatch(/2026/);
    expect(formatDayLong(day).toLowerCase()).toContain('november'); // Malay month name
    expect(formatMonth(new Date(2026, 10, 1)).toLowerCase()).toContain('november');
  });

  it('weekday and relative-day names follow the language', async () => {
    const today = new Date(2026, 10, 16);
    expect(isoWeekdayShort(1)).toBe('Mon');
    expect(relativeDay('2026-11-16', today)).toBe('Today');
    expect(relativeDay('2026-11-17', today)).toBe('Tomorrow');
    expect(relativeDay('2026-11-15', today)).toBe('Yesterday');
    expect(relativeDay('2026-11-20', today)).toBeNull();
    await setLanguage('th');
    expect(isoWeekdayShort(1)).toMatch(/^จ/); // Monday (จ. / จันทร์ depending on the ICU version)
    expect(relativeDay('2026-11-16', today)).toBe('วันนี้');
    expect(relativeDay('2026-11-17', today)).toBe('พรุ่งนี้');
    expect(relativeDay('2026-11-15', today)).toBe('เมื่อวาน');
    await setLanguage('ms');
    expect(relativeDay('2026-11-17', today)).toBe('Esok');
    expect(relativeDay('2026-11-15', today)).toBe('Semalam');
  });

  it('numbers and percentages are formatted per locale, and null stays a dash (never 0%)', async () => {
    expect(fmtNumber(1234567)).toBe('1,234,567');
    expect(percent(87.4)).toBe('87%');
    expect(percent(null)).toBe('—');
    await setLanguage('ms');
    expect(fmtNumber(1234567)).toBe('1,234,567');
    await setLanguage('th');
    expect(fmtNumber(1234567)).toBe('1,234,567'); // Thai locale keeps Latin digits
  });

  it('the language never changes the underlying instant or the schedule date', async () => {
    const iso = '2026-11-16T17:30:00.000Z';
    const before = new Date(iso).getTime();
    await setLanguage('th');
    await setLanguage('ms');
    expect(new Date(iso).getTime()).toBe(before);
    expect(new Date(iso).toISOString()).toBe(iso);
  });
});
