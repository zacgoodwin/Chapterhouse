// Fly deploy + health gate for ticket-ship. Deterministic: right config per
// target, poll /up until healthy or fail nonzero.
// Usage: node scripts/ship/deploy.mjs dev|prod [--health-only]
import { execFileSync } from 'node:child_process';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const TARGETS = {
  dev: {
    args: ['deploy', '-c', 'fly.dev.toml', '--remote-only'],
    health: 'https://dev.chapterhouse.tools/up',
  },
  prod: {
    args: ['deploy', '--remote-only'],
    health: 'https://chapterhouse.tools/up',
  },
};

const FLYCTL = join(homedir(), '.fly', 'bin', 'flyctl.exe');

export async function checkHealth(url, { attempts = 10, delayMs = 15000 } = {}) {
  for (let i = 0; i < attempts; i++) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(10000) });
      if (res.ok) return true;
    } catch { /* retry */ }
    if (i < attempts - 1) await new Promise((r) => setTimeout(r, delayMs));
  }
  return false;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [target, ...rest] = process.argv.slice(2);
  const t = TARGETS[target];
  // Fail-closed argument parsing: a typo like '--heath-only' must never fall
  // through to a real deployment.
  const healthOnly = rest.length === 1 && rest[0] === '--health-only';
  if (!t || (rest.length > 0 && !healthOnly)) {
    console.error('usage: deploy.mjs dev|prod [--health-only]');
    process.exit(2);
  }
  if (!healthOnly) {
    execFileSync(FLYCTL, t.args, { stdio: 'inherit' }); // throws (nonzero exit) on deploy failure
  }
  const healthy = await checkHealth(t.health);
  console.log(`${target} health ${t.health}: ${healthy ? 'OK' : 'FAILED'}`);
  process.exit(healthy ? 0 : 1);
}
