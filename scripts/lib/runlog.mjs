// Run-log heartbeat shared by issue-triage and ticket-ship: exactly one line
// per run, success or failure, so a dead scheduler is distinguishable from an
// empty queue. CLI: node scripts/lib/runlog.mjs <workflow> <outcome...>
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const RUN_LOG = join(ROOT, 'workflows', 'briefs', 'run-log.txt');

export function formatLine(workflow, outcome, date = new Date()) {
  return `${date.toISOString()} ${workflow} ${outcome}\n`;
}

export function appendRunLog(workflow, outcome) {
  mkdirSync(dirname(RUN_LOG), { recursive: true });
  appendFileSync(RUN_LOG, formatLine(workflow, outcome));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [workflow, ...rest] = process.argv.slice(2);
  if (!workflow || rest.length === 0) {
    console.error('usage: node scripts/lib/runlog.mjs <workflow> <outcome...>');
    process.exit(2);
  }
  appendRunLog(workflow, rest.join(' '));
}
