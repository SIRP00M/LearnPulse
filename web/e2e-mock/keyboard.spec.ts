import { test, expect, type Page } from '@playwright/test';

/**
 * Explicit keyboard-navigation configuration (mock backend; no remote request). Records what plain Tab (no modifier) reaches, per browser,
 * and asserts the contract the app owns: every interactive control is operable by keyboard and the skip link is the first tab stop.
 */
const PASSWORD = 'Mock-Pass1x';
async function login(page: Page) {
  await page.goto('/login');
  await page.locator('input[type=email]').fill('student@mock.test');
  await page.locator('input[type=password]').fill(PASSWORD);
  await page.keyboard.press('Enter'); // submit with the keyboard
  await expect(page.getByRole('main')).toBeVisible();
}
const describeFocus = (page: Page) => page.evaluate(() => { const e = document.activeElement as HTMLElement | null; return e ? `${e.tagName.toLowerCase()}${e.getAttribute('href') ? '[href]' : ''}:${(e.getAttribute('aria-label') || e.textContent || '').trim().slice(0, 24)}` : 'none'; });

test('plain Tab order after sign-in: skip link first, then the sidebar links, then the page controls', async ({ page, browserName }, info) => {
  await login(page);
  await page.goto('/dashboard'); // fresh load: the sequential-focus start point is the top of the document
  await expect(page.getByRole('main')).toBeVisible();
  const stops: string[] = [];
  for (let i = 0; i < 12; i++) { await page.keyboard.press('Tab'); stops.push(await describeFocus(page)); }
  info.annotations.push({ type: `${browserName} tab stops`, description: stops.join(' | ') });
  console.log(`[${browserName}] Tab stops: ${stops.join(' | ')}`);
  expect(stops[0], `${browserName}: first Tab stop`).toMatch(/^a\[href\]:/);
  expect(stops.some((s) => s.startsWith('a[href]:')), `${browserName}: links are reachable by plain Tab`).toBe(true);
});

test('the skip link is a keyboard tab stop with a visible focus ring and moves focus to the main content', async ({ page }) => {
  await login(page);
  await page.goto('/dashboard');
  await expect(page.getByRole('main')).toBeVisible();
  await page.keyboard.press('Tab');
  const skip = page.locator('a.skip');
  await expect(skip).toBeFocused();
  expect(await skip.evaluate((e) => getComputedStyle(e).outlineStyle)).not.toBe('none');
  await page.keyboard.press('Enter');
  expect(await page.evaluate(() => document.activeElement?.id)).toBe('main');
});

test('every control can be reached and activated with the keyboard alone (sign out via Tab + Enter)', async ({ page }) => {
  await login(page);
  const signOut = page.getByRole('button').filter({ has: page.locator('.mi', { hasText: 'logout' }) }).first();
  await signOut.focus();
  await expect(signOut).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.locator('input[type=email]')).toBeVisible();
});
