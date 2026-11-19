import { defineConfig, devices } from '@playwright/test';

// Localization acceptance: the production-style build (dist-mock/) against the LOCAL mock backend. No remote Supabase request, no fixture.
const only = process.env.PW_BROWSER;
const all = [
  { name: 'chromium', use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 900 } } },
  { name: 'firefox', use: { ...devices['Desktop Firefox'], viewport: { width: 1440, height: 900 } } },
  { name: 'webkit', use: { ...devices['Desktop Safari'], viewport: { width: 1440, height: 900 } } },
];
export default defineConfig({
  testDir: './e2e-mock',
  testMatch: /.*\.spec\.ts/,
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 60_000,
  expect: { timeout: 10_000 },
  reporter: [['list'], ['json', { outputFile: 'test-results/i18n.json' }]],
  outputDir: 'test-results/i18n-artifacts',
  use: { baseURL: 'http://127.0.0.1:4174' },
  projects: only ? all.filter((p) => p.name === only) : [all[0]!],
  webServer: [
    { command: 'node e2e-mock/server.mjs', url: 'http://127.0.0.1:54399/auth/v1/settings', reuseExistingServer: true, timeout: 30_000 },
    { command: 'node scripts/serve-dist.mjs', env: { DIST: 'dist-mock', PORT: '4174' }, url: 'http://127.0.0.1:4174', reuseExistingServer: true, timeout: 30_000 },
  ],
});
