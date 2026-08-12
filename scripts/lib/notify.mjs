// Toast wrapper: fire-and-forget desktop notification on Windows, no-op
// elsewhere. CLI: node scripts/lib/notify.mjs <title> [body]
import { execFileSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const TOAST = join(dirname(fileURLToPath(import.meta.url)), 'toast.ps1');

export function notify(title, body = '') {
  if (process.platform !== 'win32') return;
  try {
    execFileSync('powershell.exe', [
      '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', TOAST,
      '-Title', title, '-Body', body,
    ], { stdio: 'ignore', timeout: 15000 });
  } catch {
    // A failed toast must never fail the run; the brief file is the record.
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [title, body] = process.argv.slice(2);
  if (!title) { console.error('usage: node scripts/lib/notify.mjs <title> [body]'); process.exit(2); }
  notify(title, body ?? '');
}
