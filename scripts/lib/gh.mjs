// Thin gh CLI wrapper. All deterministic GitHub plumbing for the workflow
// scripts routes through here; pure logic lives in the callers so gate tests
// never spawn a process. See workflows/*.md (local-only) for the specs.
import { execFileSync } from 'node:child_process';

export const REPO = 'zacgoodwin/Chapterhouse';
export const PROJECT_NUMBER = '3';
export const PROJECT_OWNER = 'zacgoodwin';

export function gh(args, { input } = {}) {
  return execFileSync('gh', args, { encoding: 'utf8', input, maxBuffer: 16 * 1024 * 1024 });
}

export function ghJson(args) {
  return JSON.parse(gh(args));
}

// Paginated REST list: --slurp yields an array of pages; flatten to one list
// so callers never silently truncate at the first 100 rows.
export function ghJsonPaginated(path) {
  return JSON.parse(gh(['api', '--paginate', '--slurp', path])).flat();
}

// Numeric database id (NOT the #number, NOT node_id) — required by the
// issue-dependencies endpoint.
export function issueDbId(number) {
  return ghJson(['api', `repos/${REPO}/issues/${number}`]).id;
}

// Native "blocked by" edge: child #child is blocked by #blocker. Idempotent:
// a failure is swallowed ONLY after verifying the edge actually exists (retry
// after a partial triage apply); every other error — circular dependency,
// invalid target, limits — rethrows so the issue stays in the queue.
export function addBlockedBy(child, blocker) {
  const blockerId = issueDbId(blocker);
  try {
    gh([
      'api', '--method', 'POST',
      `repos/${REPO}/issues/${child}/dependencies/blocked_by`,
      '-F', `issue_id=${blockerId}`,
    ]);
  } catch (e) {
    const existing = ghJsonPaginated(`repos/${REPO}/issues/${child}/dependencies/blocked_by`);
    if (!existing.some((b) => b.id === blockerId)) throw e;
  }
}
