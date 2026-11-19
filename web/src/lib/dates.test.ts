import { describe, expect, it } from 'vitest';
import { addDays, earliestChange, monthGrid, parseYmd, weekStart, windowFor, ymd, todayIn, toIsoFromLocalInput, toLocalInput } from './dates';

describe('dates', () => {
  it('formats local dates without shifting through UTC', () => {
    expect(ymd(new Date(2026, 10, 16, 23, 59))).toBe('2026-11-16');
    expect(ymd(parseYmd('2026-03-01'))).toBe('2026-03-01');
  });
  it('weeks start on Monday (ISO)', () => {
    expect(ymd(weekStart(new Date(2026, 10, 16)))).toBe('2026-11-16'); // a Monday
    expect(ymd(weekStart(new Date(2026, 10, 22)))).toBe('2026-11-16'); // Sunday belongs to the week that began on Monday
    expect(ymd(weekStart(new Date(2026, 10, 15)))).toBe('2026-11-09');
  });
  it('a month grid is six whole weeks starting on a Monday', () => {
    const g = monthGrid(new Date(2026, 1, 10));
    expect(Math.round((g.end.getTime() - g.start.getTime()) / 864e5)).toBe(42);
    expect(g.start.getDay()).toBe(1);
  });
  it('request windows pass an EXCLUSIVE end date, and a day is 1 day (server rule: 1-62 days)', () => {
    const w = windowFor(new Date(2026, 10, 16), new Date(2026, 10, 17));
    expect(w.fromDate).toBe('2026-11-16');
    expect(w.toDate).toBe('2026-11-17');
    const g = monthGrid(new Date(2026, 10, 1));
    const month = windowFor(g.start, g.end);
    const days = Math.round((parseYmd(month.toDate).getTime() - parseYmd(month.fromDate).getTime()) / 864e5);
    expect(days).toBeGreaterThanOrEqual(1);
    expect(days).toBeLessThanOrEqual(62);
  });
  it('schedule changes start tomorrow or later and strictly after the previous change', () => {
    expect(earliestChange('UTC') >= ymd(addDays(new Date(), 1))).toBe(true);
    const far = ymd(addDays(new Date(), 10));
    expect(earliestChange('UTC', far)).toBe(ymd(addDays(parseYmd(far), 1)));
  });
  it('knows today in another zone and survives a bad zone', () => {
    expect(todayIn('Pacific/Kiritimati')).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(todayIn('Not/AZone')).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
  it('round-trips datetime-local values', () => {
    const iso = toIsoFromLocalInput('2026-11-20T09:30')!;
    expect(toLocalInput(iso)).toBe('2026-11-20T09:30');
    expect(toIsoFromLocalInput('')).toBeNull();
    expect(toIsoFromLocalInput('garbage')).toBeNull();
  });
});
