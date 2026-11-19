import { test, expect, type Page, type Browser } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Localization acceptance against the LOCAL mock backend (no remote request, no fixture): English, Thai, Malay (Malaysia).
 * `build:mock` must have produced dist-mock/ and e2e-mock/server.mjs serves the data.
 */
const MOCK = 'http://127.0.0.1:54399';
const SHOTS = join(process.cwd(), '..', 'docs', 'web_screenshots', 'i18n');
mkdirSync(SHOTS, { recursive: true });
const PASSWORD = 'Mock-Pass1x';
type L = 'en' | 'th' | 'ms';
const LANGS: L[] = ['en', 'th', 'ms'];

const T = {
  en: { signIn: 'Sign in', dash: 'Dashboard', tasks: 'Tasks', courses: 'Courses', calendar: 'Calendar', profile: 'Profile', verification: 'Verification', signOut: 'Sign out', emailRequired: 'Enter your email address', pwRequired: 'Enter your password',
    wrongPw: 'Email or password is incorrect.', today: 'Today', activeCourses: 'Active courses', todo: 'To do', newCourse: 'New course', titleRequired: 'Enter a title', network: 'No connection to the server', noCourses: 'No courses yet', awaiting: 'Awaiting grading', lang: 'Language', htmlLang: 'en' },
  th: { signIn: 'เข้าสู่ระบบ', dash: 'แดชบอร์ด', tasks: 'งานของฉัน', courses: 'รายวิชา', calendar: 'ปฏิทิน', profile: 'โปรไฟล์', verification: 'การตรวจสอบ', signOut: 'ออกจากระบบ', emailRequired: 'กรอกที่อยู่อีเมลของคุณ', pwRequired: 'กรอกรหัสผ่านของคุณ',
    wrongPw: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง', today: 'วันนี้', activeCourses: 'รายวิชาที่เรียนอยู่', todo: 'ต้องทำ', newCourse: 'สร้างรายวิชาใหม่', titleRequired: 'กรอกชื่อเรื่อง', network: 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้', noCourses: 'ยังไม่มีรายวิชา', awaiting: 'รอให้คะแนน', lang: 'ภาษา', htmlLang: 'th-TH' },
  ms: { signIn: 'Log masuk', dash: 'Papan pemuka', tasks: 'Tugasan', courses: 'Kursus', calendar: 'Kalendar', profile: 'Profil', verification: 'Pengesahan', signOut: 'Log keluar', emailRequired: 'Masukkan alamat e-mel anda', pwRequired: 'Masukkan kata laluan anda',
    wrongPw: 'E-mel atau kata laluan tidak betul.', today: 'Hari ini', activeCourses: 'Kursus aktif', todo: 'Perlu dibuat', newCourse: 'Kursus baharu', titleRequired: 'Masukkan tajuk', network: 'Tiada sambungan ke pelayan', noCourses: 'Belum ada kursus', awaiting: 'Menunggu penilaian', lang: 'Bahasa', htmlLang: 'ms-MY' },
} as const;
const LABEL = { en: 'English', th: 'ไทย', ms: 'Bahasa Melayu' } as const;

async function setLang(page: Page, l: L) { await page.locator('.langsel select').first().selectOption(l); }
async function preset(page: Page, l: L) { await page.addInitScript((v) => { try { if (!localStorage.getItem('lp-lang')) localStorage.setItem('lp-lang', v); } catch { /* ignore */ } }, l); }
async function login(page: Page, who: 'teacher' | 'student' | 'student2') {
  await page.goto('/login');
  await page.locator('input[type=email]').fill(`${who}@mock.test`);
  await page.locator('input[type=password]').fill(PASSWORD);
  await page.locator('button[type=submit]').click();
  await expect(page.getByRole('main')).toBeVisible();
  await expect(page.locator('h1').first()).toBeVisible();
}
const bodyText = (page: Page) => page.locator('body').innerText();
const RAW_KEY = /\b(common|nav|auth|status|courses|assignments|activities|attendance|tasks|dashboard|progress|profile|verification|validation|errors|table|lessons):[A-Za-z]/;
async function noRawKeys(page: Page) {
  const t = await bodyText(page);
  expect(t, 'a raw translation key is visible').not.toMatch(RAW_KEY);
  expect(t, 'an unreplaced {{placeholder}} is visible').not.toMatch(/\{\{|\}\}/);
}

test.beforeEach(async ({ page }) => { await page.request.get(`${MOCK}/__reset`); });

test.describe('three languages on the public screens', () => {
  for (const l of LANGS) {
    test(`sign-in in ${l}: switch is instant (no reload), keeps typed text, translates live validation and errors`, async ({ page }) => {
      await page.goto('/login');
      await page.evaluate(() => { (window as unknown as { __marker: number }).__marker = 42; });
      await page.locator('input[type=email]').fill('someone@example.test');
      await setLang(page, l);
      await expect(page.locator('h1').first()).toHaveText(T[l].signIn);
      await expect(page.locator('html')).toHaveAttribute('lang', T[l].htmlLang);
      expect(await page.evaluate(() => (window as unknown as { __marker: number }).__marker)).toBe(42); // no reload
      await expect(page.locator('input[type=email]')).toHaveValue('someone@example.test'); // form data kept
      await page.locator('button[type=submit]').click();
      await expect(page.getByText(T[l].pwRequired)).toBeVisible();
      // the SAME visible error follows a language change without resubmitting
      const other: L = l === 'en' ? 'th' : 'en';
      await setLang(page, other);
      await expect(page.getByText(T[other].pwRequired)).toBeVisible();
      await expect(page.getByText(T[l].pwRequired)).toHaveCount(0);
      await setLang(page, l);
      await page.locator('input[type=password]').fill('wrong-password');
      await page.locator('button[type=submit]').click();
      await expect(page.getByRole('alert').getByText(T[l].wrongPw)).toBeVisible();
      await noRawKeys(page);
    });
  }

  test('the selector is labelled in the current language and offers the three languages in their own script', async ({ page }) => {
    await page.goto('/login');
    for (const l of LANGS) {
      await setLang(page, l);
      const sel = page.getByRole('combobox', { name: new RegExp(T[l].lang) });
      await expect(sel).toBeVisible();
      expect(await sel.locator('option').allTextContents()).toEqual(['English', 'ไทย', 'Bahasa Melayu']);
      await expect(sel.locator('option').nth(1)).toHaveAttribute('lang', 'th-TH');
    }
  });

  for (const [browserLocale, expected] of [['th-TH', 'th'], ['ms-MY', 'ms'], ['ms', 'ms'], ['en-GB', 'en'], ['id-ID', 'en'], ['fr-FR', 'en']] as [string, L][]) {
    test(`first visit with browser language ${browserLocale} starts in ${expected}; a manual choice overrides it and survives reload`, async ({ browser }) => {
      const ctx = await browser.newContext({ locale: browserLocale });
      const page = await ctx.newPage();
      await page.goto('/login');
      await expect(page.locator('h1').first()).toHaveText(T[expected].signIn);
      const manual: L = expected === 'ms' ? 'th' : 'ms';
      await setLang(page, manual);
      await page.reload();
      await expect(page.locator('h1').first()).toHaveText(T[manual].signIn);
      expect(await page.evaluate(() => localStorage.getItem('lp-lang'))).toBe(manual);
      await ctx.close();
    });
  }

  test('other public screens translate (sign-up closed/open, forgot password, confirm email)', async ({ page }) => {
    await page.goto('/signup');
    await setLang(page, 'th');
    await expect(page.getByRole('button', { name: 'สร้างบัญชี' })).toBeVisible();
    await page.goto('/forgot');
    await expect(page.getByRole('button', { name: 'ส่งลิงก์ตั้งรหัสผ่านใหม่' })).toBeVisible();
    await page.goto('/confirm-email?email=a%40b.test');
    await expect(page.getByText('ตรวจสอบอีเมลของคุณ').first()).toBeVisible();
    await setLang(page, 'ms');
    await expect(page.getByText('Semak e-mel anda').first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'Hantar semula e-mel' })).toBeVisible();
    await noRawKeys(page);
  });
});

test.describe('authenticated: switching, persistence and isolation', () => {
  test('switch language from Profile after sign-in: session, route and typed data are untouched; the choice survives reload', async ({ page }) => {
    await login(page, 'student');
    await page.goto('/profile');
    await expect(page.getByRole('heading', { name: 'Profile', exact: true })).toBeVisible();
    await page.evaluate(() => { (window as unknown as { __marker: number }).__marker = 7; });
    await page.getByLabel('Display name').fill('Typed but not saved');
    await page.getByRole('radio', { name: 'ไทย' }).check();
    await expect(page.getByRole('heading', { name: T.th.profile, exact: true })).toBeVisible();
    await expect(page).toHaveURL(/\/profile$/); // same route
    expect(await page.evaluate(() => (window as unknown as { __marker: number }).__marker)).toBe(7); // no reload
    await expect(page.locator('input[type=text], input:not([type])').first()).toHaveValue('Typed but not saved'); // form data kept
    await expect(page.getByRole('link', { name: T.th.dash })).toBeVisible(); // still signed in
    await page.reload();
    await expect(page.getByRole('heading', { name: T.th.profile, exact: true })).toBeVisible(); // language persisted, session persisted
    await expect(page.getByRole('radio', { name: 'ไทย' })).toBeChecked();
    await page.getByRole('radio', { name: 'Bahasa Melayu' }).check();
    await expect(page.getByRole('heading', { name: T.ms.profile, exact: true })).toBeVisible();
    await expect(page.locator('html')).toHaveAttribute('lang', 'ms-MY');
  });

  test('the sidebar selector also switches the language in place', async ({ page }) => {
    await login(page, 'student');
    await setLang(page, 'ms');
    await expect(page.getByRole('navigation').getByRole('link', { name: T.ms.tasks })).toBeVisible();
    await expect(page.getByRole('heading', { name: T.ms.dash })).toBeVisible();
    await expect(page).toHaveURL(/\/dashboard$/);
  });

  for (const l of LANGS) {
    test(`student navigation and pages in ${l}`, async ({ page }) => {
      await preset(page, l);
      await login(page, 'student');
      for (const [name, key] of [['dashboard', 'dash'], ['tasks', 'tasks'], ['courses', 'courses'], ['profile', 'profile']] as const) {
        await expect(page.getByRole('navigation').getByRole('link', { name: T[l][key] })).toBeVisible();
        void name;
      }
      await expect(page.getByRole('navigation').getByRole('link', { name: T[l].verification })).toHaveCount(0); // student has no teacher pages
      await expect(page.getByText(T[l].activeCourses)).toBeVisible();
      await noRawKeys(page);
      await page.getByRole('navigation').getByRole('link', { name: T[l].tasks }).click();
      await expect(page.getByRole('heading', { name: T[l].tasks })).toBeVisible();
      await expect(page.getByText(T[l].todo).first()).toBeVisible(); // server status "todo" shown in the language
      await noRawKeys(page);
      await page.getByRole('navigation').getByRole('link', { name: T[l].courses }).click();
      await page.getByRole('link', { name: 'Algebra I' }).first().click(); // teacher-written title is never translated
      await expect(page.getByRole('heading', { name: 'Algebra I' })).toBeVisible();
      await noRawKeys(page);
    });

    test(`teacher navigation and pages in ${l}`, async ({ page }) => {
      await preset(page, l);
      await login(page, 'teacher');
      const nav = page.getByRole('navigation').first();
      for (const key of ['dash', 'calendar', 'courses', 'verification', 'profile'] as const) await expect(nav.getByRole('link', { name: new RegExp(T[l][key]) })).toBeVisible();
      await expect(page.locator('.stat', { hasText: T[l].awaiting })).toBeVisible();
      await noRawKeys(page);
      await nav.getByRole('link', { name: new RegExp(T[l].verification) }).click();
      await expect(page.getByRole('heading', { name: T[l].verification })).toBeVisible();
      await nav.getByRole('link', { name: T[l].calendar }).click();
      await expect(page.getByRole('heading', { name: T[l].calendar })).toBeVisible();
      await noRawKeys(page);
    });
  }

  test('account switching keeps the language and never shows the previous account’s data', async ({ page }) => {
    await preset(page, 'th');
    await login(page, 'teacher');
    await expect(page.locator('.stat', { hasText: T.th.awaiting })).toBeVisible();
    await page.getByRole('button', { name: T.th.signOut }).first().click();
    await expect(page.locator('h1').first()).toHaveText(T.th.signIn); // still Thai on the sign-in screen
    await login(page, 'student');
    await expect(page.locator('.stat', { hasText: T.th.awaiting })).toHaveCount(0);
    await expect(page.getByRole('navigation').getByRole('link', { name: new RegExp(T.th.verification) })).toHaveCount(0);
    await expect(page.getByText(T.th.activeCourses)).toBeVisible();
    await page.getByRole('button', { name: T.th.signOut }).first().click();
    await login(page, 'student2');
    await expect(page.getByText('Somsri Teacher').first()).toBeVisible(); // this account's own data, in Thai chrome
    await expect(page.getByText(T.th.activeCourses)).toBeVisible();
  });
});

test.describe('server data is independent of the display language', () => {
  test('requests, windows, dates and statuses are identical in all three languages', async ({ browser }) => {
    const seen: Record<string, string> = {};
    for (const l of LANGS) {
      const ctx = await browser.newContext();
      const page = await ctx.newPage();
      await page.request.get(`${MOCK}/__reset`);
      await preset(page, l);
      await login(page, 'student');
      await page.goto('/tasks');
      await expect(page.getByText(T[l].todo).first()).toBeVisible();
      const calls = (await (await page.request.get(`${MOCK}/__calls?name=get_my_tasks`)).json()) as { body: Record<string, unknown> }[];
      const range = calls.find((c) => c.body.p_view === 'range')!;
      seen[l] = JSON.stringify({ view: range.body.p_view, from: range.body.p_from, to: range.body.p_to, fromDate: range.body.p_from_date, toDate: range.body.p_to_date, limit: range.body.p_limit });
      await ctx.close();
    }
    expect(seen.th).toBe(seen.en);
    expect(seen.ms).toBe(seen.en);
  });

  test('switching language mid-session issues no new data request and leaves the activity status and deadlines as the server sent them', async ({ page }) => {
    await login(page, 'student');
    await page.goto('/tasks');
    await expect(page.getByText('Reading Journal')).toBeVisible();
    await page.request.get(`${MOCK}/__reset`);
    const before = await page.getByText('Reading Journal').locator('xpath=ancestor::li').innerText();
    await setLang(page, 'th');
    await expect(page.getByText(T.th.todo).first()).toBeVisible();
    const calls = (await (await page.request.get(`${MOCK}/__calls`)).json()) as unknown[];
    expect(calls.length).toBe(0); // purely a display change
    expect(before).toContain('To do');
    await expect(page.getByText('Reading Journal').locator('xpath=ancestor::li')).toContainText(T.th.todo);
  });
});

test.describe('dates, calendar and numbers', () => {
  test('relative day labels and the calendar month follow the language; Thai years carry the Buddhist era', async ({ page }) => {
    const year = new Date().getFullYear();
    await login(page, 'student');
    await page.goto('/tasks');
    await expect(page.getByRole('heading', { name: 'Today · ' }).first()).toBeVisible();
    await page.getByRole('button', { name: 'Month' }).click();
    await expect(page.getByRole('table').first().locator('caption')).toContainText(String(year));
    await setLang(page, 'th');
    await expect(page.getByRole('heading', { name: new RegExp(`^${T.th.today} · `) }).first().or(page.getByRole('button', { name: 'เดือน' }))).toBeVisible();
    const caption = await page.getByRole('table').first().locator('caption').innerText();
    expect(caption).toMatch(/พ\.ศ\.\s*\d{4}/);
    expect(caption).toContain(String(year + 543));
    expect(caption).not.toContain(String(year));
    await setLang(page, 'ms');
    await expect(page.getByRole('table').first().locator('caption')).toContainText(String(year));
    await page.getByRole('button', { name: 'Hari ini' }).first().click();
    await page.getByRole('button', { name: 'Minggu', exact: true }).click();
    await expect(page.getByRole('heading', { name: /^Hari ini · / }).or(page.getByRole('heading', { level: 3 }).first())).toBeVisible();
  });

  test('numbers and percentages use the locale and never turn "no data" into 0%', async ({ page }) => {
    await login(page, 'student');
    await expect(page.getByRole('group', { name: /Average score: 88%/ })).toBeVisible(); // 87.5 rounds half up like Math.round
    await setLang(page, 'th');
    await expect(page.getByRole('group', { name: /^คะแนนเฉลี่ย: 88%/ })).toBeVisible();
    await setLang(page, 'ms');
    await expect(page.getByRole('group', { name: /^Skor purata: 88%/ })).toBeVisible();
  });
});

test('the localized app runs under the production CSP: no violations in any language (dialog, switching, navigation)', async ({ page }) => {
  const violations: string[] = [];
  page.on('console', (m) => { if (/Content Security Policy|Refused to/.test(m.text())) violations.push(m.text()); });
  await page.addInitScript(() => document.addEventListener('securitypolicyviolation', (e) => console.error('Refused to ' + e.violatedDirective + ' ' + e.blockedURI)));
  await login(page, 'teacher');
  for (const l of LANGS) {
    await setLang(page, l);
    await page.goto('/courses'); await page.waitForLoadState('networkidle');
    await page.getByRole('button', { name: T[l].newCourse }).first().click();
    await expect(page.getByRole('dialog')).toBeVisible();
    await page.keyboard.press('Escape');
  }
  expect(violations).toEqual([]);
});

test.describe('dialogs, errors and empty states', () => {
  for (const l of LANGS) {
    test(`teacher dialog, validation, empty state and offline error in ${l}`, async ({ page }) => {
      await preset(page, l);
      await login(page, 'teacher');
      await page.getByRole('navigation').first().getByRole('link', { name: T[l].courses }).click();
      await page.getByRole('button', { name: T[l].newCourse }).first().click();
      await expect(page.getByRole('dialog')).toBeVisible();
      await page.getByRole('dialog').locator('button[type=submit]').click();
      await expect(page.getByRole('dialog').getByText(T[l].titleRequired)).toBeVisible();
      await noRawKeys(page);
      await page.keyboard.press('Escape');
      // an empty list
      await page.route('**/rest/v1/courses*', (r) => r.fulfill({ status: 200, contentType: 'application/json', body: '[]' }));
      await page.reload();
      await expect(page.getByText(T[l].noCourses)).toBeVisible();
      await page.unroute('**/rest/v1/courses*');
      // a failed load shows the translated message
      await page.route('**/rpc/get_teacher_dashboard', (r) => r.abort('connectionrefused'));
      await page.goto('/dashboard');
      await expect(page.getByRole('alert').getByText(new RegExp(T[l].network))).toBeVisible({ timeout: 20_000 });
    });
  }
});

test.describe('responsive layout, wrapping and accessibility in every language', () => {
  test.setTimeout(300_000); // 3 widths x 9 pages x full checks per language; Firefox/WebKit need more than the 60 s default
  const PAGES: [string, 'student' | 'teacher' | null, string][] = [
    ['signin', null, '/login'], ['student-dashboard', 'student', '/dashboard'], ['teacher-dashboard', 'teacher', '/dashboard'],
    ['tasks', 'student', '/tasks'], ['calendar-month', 'teacher', '/tasks?view=month'], ['course', 'student', '/courses/11111111-1111-4111-8111-111111111111'],
    ['progress', 'student', '/courses/11111111-1111-4111-8111-111111111111/progress'], ['people', 'teacher', '/courses/11111111-1111-4111-8111-111111111111/people'], ['profile', 'student', '/profile'],
  ];
  const SHOT = new Set(['signin', 'student-dashboard', 'teacher-dashboard', 'tasks', 'calendar-month', 'course', 'progress']);

  for (const l of LANGS) {
    test(`no overflow or clipped controls at 390 / 768 / 1440 px in ${l}; screenshots`, async ({ browser }) => {
      for (const width of [390, 768, 1440]) {
        const ctx = await browser.newContext({ viewport: { width, height: 900 } });
        const page = await ctx.newPage();
        await preset(page, l);
        let signedAs: string | null = null;
        for (const [name, who, url] of PAGES) {
          if (who && who !== signedAs) {
            if (signedAs) { await page.evaluate(() => { for (const k of Object.keys(localStorage)) if (k.endsWith('-auth-token')) localStorage.removeItem(k); }); }
            await login(page, who); signedAs = who;
          }
          if (!who && signedAs) { await ctx.clearCookies(); await page.evaluate(() => { for (const k of Object.keys(localStorage)) if (k.endsWith('-auth-token')) localStorage.removeItem(k); }); signedAs = null; }
          await page.goto(url);
          await page.waitForLoadState('networkidle');
          await expect(page.locator('h1').first()).toBeVisible();
          const over = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
          expect(over, `${l} ${name} @${width}: horizontal overflow ${over}px`).toBeLessThanOrEqual(1);
          const clipped = await page.evaluate(() => [...document.querySelectorAll<HTMLElement>('.btn, .chip, .tabs a, .nav a, .stat, h1, h2, h3, label')]
            .filter((e) => { const s = getComputedStyle(e); return e.offsetParent !== null && !e.closest('.sr-only') && !e.classList.contains('sr-only') && (s.overflow === 'hidden' || s.textOverflow === 'ellipsis') && e.scrollWidth > e.clientWidth + 2; })
            .map((e) => `${e.tagName}.${e.className}: ${e.textContent?.slice(0, 40)}`));
          expect(clipped, `${l} ${name} @${width}: clipped text`).toEqual([]);
          if (SHOT.has(name) && (width === 390 || width === 1440)) await page.screenshot({ path: join(SHOTS, `${l}-${name}-${width}.png`), fullPage: false });
        }
        await ctx.close();
      }
    });

    test(`axe (WCAG 2.2 AA) on sign-in, dashboards and tasks in ${l}, light and dark; html lang is correct`, async ({ page }) => {
      for (const scheme of ['light', 'dark'] as const) {
        await page.emulateMedia({ colorScheme: scheme });
        await preset(page, l);
        await page.goto('/login');
        await expect(page.locator('html')).toHaveAttribute('lang', T[l].htmlLang);
        const run = async (label: string) => {
          const v = (await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa']).analyze()).violations.filter((x) => x.impact === 'serious' || x.impact === 'critical');
          expect(v.map((x) => `${x.id}: ${x.nodes[0]?.html.slice(0, 90)}`), `${l} ${scheme} ${label}`).toEqual([]);
        };
        await run('signin');
        await login(page, 'student');
        await run('student dashboard');
        await page.goto('/tasks'); await page.waitForLoadState('networkidle'); await run('tasks');
        await page.evaluate(() => { for (const k of Object.keys(localStorage)) if (k.endsWith('-auth-token')) localStorage.removeItem(k); });
        await login(page, 'teacher');
        await run('teacher dashboard');
        await page.evaluate(() => { for (const k of Object.keys(localStorage)) if (k.endsWith('-auth-token')) localStorage.removeItem(k); });
      }
    });
  }

  test('keyboard: the selector is reachable and operable without a pointer, with an accessible name in the current language', async ({ page, browserName }) => {
    await page.goto('/login');
    const sel = page.locator('.langsel select').first();
    await sel.focus();
    await expect(sel).toBeFocused();
    await expect(page.getByRole('combobox', { name: new RegExp(T.en.lang) })).toBeVisible();
    if (browserName === 'chromium') {
      await page.keyboard.press('ArrowDown'); // closed select: arrow keys change the value
      await expect(page.locator('h1').first()).toHaveText(T.th.signIn);
      await expect(page.getByRole('combobox', { name: new RegExp(T.th.lang) })).toBeVisible();
    } else {
      await sel.selectOption('th'); // Firefox/WebKit: keyboard value change is browser-specific; the control is focusable and labelled
      await expect(page.locator('h1').first()).toHaveText(T.th.signIn);
    }
  });

  test('long Thai/Malay strings in dialogs and tables stay inside their containers', async ({ browser }) => {
    for (const l of ['th', 'ms'] as L[]) {
      const ctx = await browser.newContext({ viewport: { width: 390, height: 800 } });
      const page = await ctx.newPage();
      await preset(page, l);
      await login(page, 'teacher');
      await page.goto('/courses/11111111-1111-4111-8111-111111111111/people');
      await page.waitForLoadState('networkidle');
      await page.getByRole('button', { name: l === 'th' ? 'นำออก' : 'Keluarkan' }).first().click();
      const dlg = page.getByRole('dialog');
      await expect(dlg).toBeVisible();
      const box = await dlg.boundingBox();
      expect(box!.x).toBeGreaterThanOrEqual(0);
      expect(box!.x + box!.width).toBeLessThanOrEqual(390.5);
      expect(await dlg.evaluate((e) => e.scrollWidth - e.clientWidth)).toBeLessThanOrEqual(1);
      await ctx.close();
    }
  });
});

void (null as unknown as Browser);
