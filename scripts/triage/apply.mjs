// Apply one triage decision (workflows/issue-triage.md): label swap, board
// fields, scoping comment, dependency edges — everything except wontfix,
// which only ever appears in the brief until Zac approves the close.
// Usage: node scripts/triage/apply.mjs '<decision-json>'   (or JSON on stdin)
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { gh, addBlockedBy, REPO } from '../lib/gh.mjs';
import { STATUS_BY_LABEL, MODELS, EFFORTS, TRIAGE_LABELS, setBoardFields } from '../lib/board.mjs';
import { needsTriage } from './queue.mjs';

// Validate a latent decision before any mutation. Returns a list of problems;
// empty list = valid. The latent session is a trust boundary: never apply an
// out-of-vocabulary value.
export function validateDecision(d) {
  const problems = [];
  if (!Number.isInteger(d.number) || d.number <= 0) problems.push(`bad issue number: ${d.number}`);
  if (!['needs-info', 'ready-for-agent', 'ready-for-human'].includes(d.label)) {
    problems.push(`label must be needs-info|ready-for-agent|ready-for-human (wontfix is brief-only), got: ${d.label}`);
  }
  if (!MODELS.includes(d.model)) problems.push(`bad model: ${d.model}`);
  if (!EFFORTS.includes(d.effort)) problems.push(`bad effort: ${d.effort}`);
  if (typeof d.comment !== 'string' || d.comment.trim().length < 40) {
    problems.push('comment missing or too short to be a real scoping comment');
  }
  if (!Array.isArray(d.blockedBy ?? []) || (d.blockedBy ?? []).some((n) => !Number.isInteger(n) || n === d.number)) {
    problems.push(`bad blockedBy list: ${JSON.stringify(d.blockedBy)}`);
  }
  return problems;
}

// The chosen label must be the ONLY triage label left: stale outcome labels
// from earlier triage passes would otherwise let e.g. a ready-for-human issue
// also carry ready-for-agent and enter the unattended ship queue.
export function labelSwapArgs(label) {
  const remove = TRIAGE_LABELS.filter((l) => l !== label);
  return ['--add-label', label, ...remove.flatMap((l) => ['--remove-label', l])];
}

export function applyDecision(d) {
  const problems = validateDecision(d);
  if (problems.length) throw new Error(`invalid decision for #${d.number}: ${problems.join('; ')}`);
  const n = String(d.number);
  // The decision JSON is latent-session output — bind it to the live queue:
  // the target must still be an open issue that needs triage, so a prompt-
  // injected decision can never relabel or comment on an arbitrary issue.
  const live = JSON.parse(gh(['api', `repos/${REPO}/issues/${n}`]));
  if (live.pull_request) throw new Error(`#${n} is a PR — not a triage target`);
  if (live.state !== 'open') throw new Error(`#${n} is not open — not a triage target`);
  if (!needsTriage(live)) throw new Error(`#${n} is already triaged — refusing to re-apply`);
  // Label transition LAST: while needs-triage is still on the issue, a crash
  // in any earlier mutation leaves the issue in tomorrow's queue for a clean
  // retry (board/edge writes are idempotent; a duplicated comment is the
  // acceptable cost of never losing an issue from the queue).
  gh(['issue', 'comment', n, '-R', REPO, '--body-file', '-'], { input: d.comment });
  setBoardFields(d.number, {
    Status: STATUS_BY_LABEL[d.label],
    Model: d.model,
    'Model Effort': d.effort,
  });
  for (const blocker of d.blockedBy ?? []) addBlockedBy(d.number, blocker);
  gh(['issue', 'edit', n, '-R', REPO, ...labelSwapArgs(d.label)]);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const raw = process.argv[2] ?? readFileSync(0, 'utf8');
  applyDecision(JSON.parse(raw));
  console.log(`applied #${JSON.parse(raw).number}`);
}
