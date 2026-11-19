import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
const shots = join(process.cwd(), '..', '.tools', 'evidence', 'welcome', 'web');
mkdirSync(shots, { recursive: true });
test('guest landing, locale, theme, responsive and accessibility', async ({ page }) => {
  await page.request.get('http://127.0.0.1:54399/__reset');
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'A clearer path for every class' })).toBeVisible();
  await expect(page.getByText('Example content only')).toBeVisible();
  expect(await (await page.request.get('http://127.0.0.1:54399/__calls')).json()).toEqual([]);
  for (const [lang, tag] of [['th','th-TH'],['ms','ms-MY'],['en','en']]) { await page.locator('.langsel select').selectOption(lang); await expect(page.locator('html')).toHaveAttribute('lang', tag); }
  await page.getByLabel('Theme').selectOption('dark'); await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.getByLabel('Theme').selectOption('light');
  for (const width of [1440, 768, 320]) { await page.setViewportSize({ width, height: 900 }); expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBeTruthy(); expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]); await page.screenshot({ path: join(shots, `landing-${width}.png`), fullPage: true }); }
  await page.getByRole('link', { name: 'Get started' }).click(); await expect(page).toHaveURL(/\/login$/);
  await page.getByRole('link', { name: 'Home' }).click(); await expect(page).toHaveURL(/\/$/);
});

for (const lang of ['en', 'th', 'ms']) for (const theme of ['light', 'dark']) {
  test(`landing ${lang} ${theme}: reflow, accessibility, persistence and screenshots`, async ({ page }) => {
    test.setTimeout(120_000);
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.addInitScript(({ lang, theme }) => { localStorage.setItem('lp-lang', lang); localStorage.setItem('lp-theme', theme); }, { lang, theme });
    await page.goto('/');
    await expect(page.locator('html')).toHaveAttribute('lang', lang === 'en' ? 'en' : lang === 'th' ? 'th-TH' : 'ms-MY');
    for (const width of [320, 768, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1)).toBeTruthy();
      expect((await new AxeBuilder({ page }).withTags(['wcag2a','wcag2aa','wcag21aa','wcag22aa']).analyze()).violations).toEqual([]);
      await page.screenshot({ path: join(shots, `landing-${lang}-${theme}-${width}.png`), fullPage: true });
    }
    await page.evaluate(() => { document.body.style.zoom = '2'; });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1)).toBeTruthy();
    await page.reload();
    await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
    await expect(page.locator('.langsel select')).toHaveValue(lang);
    await page.keyboard.press('Tab');
    await expect(page.locator('a.skip')).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page.locator('#main')).toBeInViewport();
  });
}

test('PKCE recovery callback takes precedence over public Landing', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('sb-127-auth-token-code-verifier', JSON.stringify('mock-code-verifier/recovery')));
  await page.goto('/auth/callback?code=mock-recovery');
  await expect(page.getByRole('heading', { name: 'Choose a new password' })).toBeVisible();
  await expect(page.getByText('Example content only')).toHaveCount(0);
  await page.getByLabel('New password', { exact: true }).fill('Mock-New-Pass1x');
  await page.getByLabel('Repeat new password', { exact: true }).fill('Mock-New-Pass1x');
  await page.getByRole('button', { name: 'Save password', exact: true }).click();
  await expect(page).toHaveURL(/\/dashboard$/);
  await expect(page.getByRole('heading', { name: 'Dashboard', exact: true })).toBeVisible();
});
for (const role of ['teacher', 'student']) test(`${role} restores session and protected deep link`, async ({ page }) => {
  await page.goto('/login'); await page.locator('input[type=email]').fill(`${role}@mock.test`); await page.locator('input[type=password]').fill('Mock-Pass1x'); await page.locator('button[type=submit]').click(); await expect(page).toHaveURL(/\/dashboard$/);
  await page.route('**/rest/v1/profiles*', async route => { await new Promise(resolve => setTimeout(resolve, 500)); await route.continue(); });
  await page.goto('/'); await expect(page.getByText('Example content only')).toHaveCount(0); await expect(page).toHaveURL(/\/dashboard$/); await page.goto('/courses'); await expect(page).toHaveURL(/\/courses$/); await expect(page.getByRole('main')).toBeVisible();
});
test('guest deep links and callback', async ({ page }) => { await page.goto('/courses'); await expect(page).toHaveURL(/\/login$/); await page.goto('/auth/callback?error=access_denied'); await expect(page.getByRole('alert')).toBeVisible(); await page.goto('/confirm-email'); await expect(page).toHaveURL(/\/confirm-email/); });
test('registration waits for positive settings', async ({ page }) => {
  await page.route('**/auth/v1/settings', async route => { await new Promise(resolve => setTimeout(resolve, 400)); await route.fulfill({ status: 200, contentType: 'application/json', body: '{"disable_signup":true}' }); });
  await page.goto('/signup'); await expect(page.getByRole('button', { name: 'Create account' })).toHaveCount(0); await expect(page.getByText(/Registration is currently closed/)).toBeVisible(); await page.goto('/login'); await expect(page.getByRole('link', { name: 'Create a student account' })).toHaveCount(0);
  await page.unrouteAll(); await page.route('**/auth/v1/settings', route => route.fulfill({ status: 503, body: '' })); await page.reload(); await page.goto('/signup'); await expect(page.getByText(/Registration availability is unavailable/)).toBeVisible(); await expect(page.getByRole('button', { name: 'Create account' })).toHaveCount(0); await expect(page.getByRole('button', { name: 'Retry' })).toBeVisible();
});
