export type ThemePref = 'system' | 'light' | 'dark';
const KEY = 'lp-theme';

export function getThemePref(): ThemePref {
  try {
    const v = localStorage.getItem(KEY);
    if (v === 'light' || v === 'dark') return v;
  } catch { /* storage blocked: fall back to system */ }
  return 'system';
}
export function applyTheme(pref: ThemePref) {
  const dark = pref === 'dark' || (pref === 'system' && window.matchMedia?.('(prefers-color-scheme: dark)').matches);
  document.documentElement.dataset.theme = dark ? 'dark' : 'light';
}
export function setThemePref(pref: ThemePref) {
  try {
    if (pref === 'system') localStorage.removeItem(KEY); else localStorage.setItem(KEY, pref);
  } catch { /* ignore */ }
  applyTheme(pref);
}
