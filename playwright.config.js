import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import { defineConfig } from '@playwright/test';

// Eval lane, not a gate (README, E2E tests): this suite drives the deployed dev
// instance over the network with a real Supabase login, so it runs before ship
// and on a schedule, never in a pre-commit hook.
//
// Credentials come from .env.qa.local, which is gitignored and stays that way:
// this repo is public. node's own loader, no dotenv dependency.
const CREDENTIALS_FILE = fileURLToPath(new URL('.env.qa.local', import.meta.url));

if (existsSync(CREDENTIALS_FILE)) process.loadEnvFile(CREDENTIALS_FILE);

export default defineConfig({
  testDir: 'spec/playwright',
  // Web::DashboardsController rate-limits /dashboard to 10 requests a minute per
  // IP. One worker keeps a full run well under that; parallel workers would trip
  // it and report the throttle as a product failure.
  workers: 1,
  retries: 1,
  reporter: 'list',
  use: {
    baseURL: process.env.QA_BASE_URL ?? 'https://dev.chapterhouse.tools',
    // Below 768px the app renders one column at a time (CharKeeperAppContent.jsx),
    // which is the layout both specs walk: opening a character replaces the list
    // with the sheet instead of drawing them side by side.
    viewport: { width: 390, height: 844 },
    trace: 'retain-on-failure',
    // The dev instance is a Fly machine that auto-stops to zero, so the first
    // request of a run pays a cold start.
    actionTimeout: 15_000,
    navigationTimeout: 60_000
  },
  timeout: 90_000,
  expect: { timeout: 30_000 }
});
