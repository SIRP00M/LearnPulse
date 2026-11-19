import { localeTag } from '../i18n';

/** Date helpers. Occurrences are dates in the schedule's timezone; deadlines are UTC instants shown in local time. */

const pad = (n: number) => String(n).padStart(2, '0');

/** Local calendar date as YYYY-MM-DD (never via toISOString, which shifts to UTC). */
export function ymd(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
export function parseYmd(s: string): Date {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y!, (m ?? 1) - 1, d ?? 1);
}
export const addDays = (d: Date, n: number) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
export const startOfDay = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
/** ISO week start (Monday). */
export function weekStart(d: Date): Date {
  const dow = (d.getDay() + 6) % 7;
  return addDays(startOfDay(d), -dow);
}
export function monthGrid(d: Date): { start: Date; end: Date } {
  const first = new Date(d.getFullYear(), d.getMonth(), 1);
  const start = weekStart(first);
  return { start, end: addDays(start, 42) };
}
/** A request window for a local-date range [from, toExclusive): instants + the viewer's local date window (the server treats p_to_date as exclusive). */
export function windowFor(from: Date, toExclusive: Date) {
  return { from, to: toExclusive, fromDate: ymd(from), toDate: ymd(toExclusive) };
}

// Display formatting follows the interface language (Intl, no hand-made month names). Underlying values, time zones and
// deadlines are never touched by the language: only the way an instant/date is WRITTEN changes.
// Thai: th-TH uses the Buddhist calendar (year = Gregorian + 543); the era "พ.ศ." is always printed next to a year so it
// cannot be mistaken for a Gregorian year. Day/month-only formats print no year.
const cache = new Map<string, Intl.DateTimeFormat>();
function dtf(opts: Intl.DateTimeFormatOptions): Intl.DateTimeFormat {
  const tag = localeTag();
  const key = tag + JSON.stringify(opts);
  let f = cache.get(key);
  if (!f) { f = new Intl.DateTimeFormat(tag, opts); cache.set(key, f); }
  return f;
}
const yearOpts = (): Intl.DateTimeFormatOptions => (localeTag() === 'th-TH' ? { year: 'numeric', era: 'short' } : { year: 'numeric' });
export const formatDay = (ymdStr: string) => dtf({ weekday: 'short', day: 'numeric', month: 'short' }).format(parseYmd(ymdStr));
export const formatDayLong = (ymdStr: string) => dtf({ weekday: 'long', day: 'numeric', month: 'long', ...yearOpts() }).format(parseYmd(ymdStr));
export const formatTime = (iso?: string | null) => (iso ? dtf({ hour: '2-digit', minute: '2-digit' }).format(new Date(iso)) : '—');
export const formatInstant = (iso?: string | null) => (iso ? dtf({ day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso)) : '—');
export const formatMonth = (d: Date) => dtf({ month: 'long', ...yearOpts() }).format(d);
export const weekdayShort = (d: Date) => dtf({ weekday: 'short' }).format(d);
/** Short weekday name for an ISO weekday number (1 = Monday). */
export const isoWeekdayShort = (n: number) => weekdayShort(new Date(2024, 0, n)); // 2024-01-01 was a Monday
export const fmtNumber = (n: number, opts?: Intl.NumberFormatOptions) => new Intl.NumberFormat(localeTag(), opts).format(n);
export const percent = (v?: number | null) => (v == null ? '—' : fmtNumber(Math.round(v) / 100, { style: 'percent', maximumFractionDigits: 0 }));
/** "Today" / "Tomorrow" / "Yesterday" in the interface language, or null for any other day (Intl.RelativeTimeFormat, numeric:'auto'). */
export function relativeDay(ymdStr: string, now: Date = new Date()): string | null {
  const diff = Math.round((parseYmd(ymdStr).getTime() - startOfDay(now).getTime()) / 864e5);
  if (diff < -1 || diff > 1) return null;
  const r = new Intl.RelativeTimeFormat(localeTag(), { numeric: 'auto' }).format(diff, 'day');
  return r.charAt(0).toLocaleUpperCase(localeTag()) + r.slice(1);
}

export function toIsoFromLocalInput(v: string): string | null {
  if (!v) return null;
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}
export function toLocalInput(iso?: string | null): string {
  if (!iso) return '';
  const d = new Date(iso);
  return `${ymd(d)}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
export const WEEKDAY_NUMBERS = [1, 2, 3, 4, 5, 6, 7] as const;

/** The calendar date "now" in an IANA zone (the server decides "today" per schedule timezone). */
export function todayIn(tz: string): string {
  try {
    return new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
  } catch {
    return ymd(new Date());
  }
}
/** Earliest valid "effective from" for a schedule change: tomorrow in both the schedule zone and the viewer's zone. */
export function earliestChange(tz: string, previous?: string | null): string {
  const a = addDays(parseYmd(todayIn(tz)), 1);
  const b = startOfDay(addDays(new Date(), 1));
  const c = previous ? addDays(parseYmd(previous), 1) : b; // and strictly after the previous schedule change
  return ymd([a, b, c].reduce((x, y) => (y > x ? y : x)));
}
export const timeZones = (): string[] => {
  try {
    return (Intl as unknown as { supportedValuesOf(k: string): string[] }).supportedValuesOf('timeZone');
  } catch {
    return ['Asia/Bangkok', 'UTC'];
  }
};
