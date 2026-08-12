// Board status transition for one ticket, optionally claiming it.
// Usage: node scripts/ship/transitions.mjs <issueNumber> <Status> [--claim]
// Statuses are the board's own: Building, Review, QA, Blocked, Done, ...
import { fileURLToPath } from 'node:url';
import { gh, ghJson, REPO } from '../lib/gh.mjs';
import { setBoardFields, findItem } from '../lib/board.mjs';
import { isClaimable } from './queue.mjs';

export const VALID_STATUSES = ['Backlog', 'Ready', 'Questions', 'Building', 'QA', 'Review', 'Blocked', 'Skipped', 'Done'];

export function transition(number, status, { claim = false } = {}) {
  if (!VALID_STATUSES.includes(status)) throw new Error(`bad status: ${status}`);
  if (claim) {
    // The drain snapshot is stale by the time a ticket's turn comes: re-fetch
    // both the issue AND its board item; abort if anyone claimed, relabeled,
    // closed, blocked, or moved it out of Ready meanwhile.
    const live = ghJson(['api', `repos/${REPO}/issues/${number}`]);
    if (!isClaimable(live)) throw new Error(`#${number} no longer claimable — skip it`);
    if (findItem(number)?.status !== 'Ready') throw new Error(`#${number} board status is not Ready — skip it`);
    gh(['issue', 'edit', String(number), '-R', REPO, '--add-assignee', '@me']);
    try {
      setBoardFields(number, { Status: status });
    } catch (e) {
      // Compensate: an assigned-but-still-Ready issue would vanish from every
      // future queue (assignee filter) with no one working it.
      gh(['issue', 'edit', String(number), '-R', REPO, '--remove-assignee', '@me']);
      throw e;
    }
    return;
  }
  setBoardFields(number, { Status: status });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [n, status, flag] = process.argv.slice(2);
  if (!n || !status) { console.error('usage: transitions.mjs <issueNumber> <Status> [--claim]'); process.exit(2); }
  transition(Number(n), status, { claim: flag === '--claim' });
  console.log(`#${n} -> ${status}`);
}
