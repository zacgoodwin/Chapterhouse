// Gate tests for the ticket-ship workflow scripts (workflows/ticket-ship.md
// acceptance #1, #4, #6). Pure functions only — no gh, no flyctl, no network.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { filterReady, itemFields, isClaimable } from '../../scripts/ship/queue.mjs';
import { VALID_STATUSES } from '../../scripts/ship/transitions.mjs';
import { TARGETS } from '../../scripts/ship/deploy.mjs';
import { renderShipBrief, validateLedgerAgainstCommits, validateReleaseFiles } from '../../scripts/ship/write-brief.mjs';
import { validateOrder } from '../../scripts/ship/order.mjs';

const item = (number, status, extra = {}) => ({ content: { number }, status, ...extra });
const iss = (number, overrides = {}) => ({
  number,
  title: `t${number}`,
  labels: [{ name: 'ready-for-agent' }],
  assignees: [],
  issue_dependencies_summary: { blocked_by: 0 },
  ...overrides,
});

test('queue: only board-Ready + ready-for-agent + unassigned + unblocked survive', () => {
  const items = [item(1, 'Ready'), item(2, 'Backlog'), item(3, 'Ready'), item(4, 'Ready'), item(5, 'Ready'), item(6, 'Ready')];
  const issues = [
    iss(1),
    iss(2), // board Backlog
    iss(3, { labels: [{ name: 'ready-for-human' }] }),
    iss(4, { assignees: [{ login: 'zacgoodwin' }] }),
    iss(5, { issue_dependencies_summary: { blocked_by: 2 } }),
    iss(6, { pull_request: { url: 'x' } }),
    iss(7), // not on board at all
  ];
  assert.deepEqual(filterReady(items, issues).map((t) => t.number), [1]);
});

test('queue: fail-closed — missing dep summary and conflicting labels are excluded', () => {
  const items = [item(1, 'Ready'), item(2, 'Ready'), item(3, 'Ready')];
  const issues = [
    iss(1, { issue_dependencies_summary: undefined }), // API drift: no summary
    iss(2, { issue_dependencies_summary: {} }),        // summary without blocked_by
    iss(3, { labels: [{ name: 'ready-for-agent' }, { name: 'wontfix' }] }), // stale conflict
  ];
  assert.deepEqual(filterReady(items, issues), []);
});

test('queue: board Model/Model Effort fields ride along, tolerant of gh key casing', () => {
  const items = [item(1, 'Ready', { model: 'sonnet', 'model Effort': 'medium' })];
  const [t] = filterReady(items, [iss(1)]);
  assert.equal(t.model, 'sonnet');
  assert.equal(t.effort, 'medium');
  assert.equal(itemFields(item(2, 'Ready', { Model: 'opus', 'Model Effort': 'xhigh' })).model, 'opus');
});

test('claim re-check: closed, relabeled, assigned, or blocked tickets fail isClaimable', () => {
  assert.equal(isClaimable(iss(1)), true);
  assert.equal(isClaimable(iss(1, { state: 'closed' })), false);
  assert.equal(isClaimable(iss(1, { assignees: [{ login: 'x' }] })), false);
  assert.equal(isClaimable(iss(1, { labels: [{ name: 'ready-for-agent' }, { name: 'needs-info' }] })), false);
  assert.equal(isClaimable(iss(1, { issue_dependencies_summary: { blocked_by: 1 } })), false);
});

test('brief: all-blocked drain still renders the deploy plan with warnings', () => {
  const md = renderShipBrief({
    date: '2026-08-11',
    merges: [{ number: 70, mergeSha: 'def5678', migrations: [] }],
    shipped: [],
    blocked: [{ number: 70, title: 'ban', stage: 'dev QA', detail: 'x' }],
    deployPlan: { tickets: [], migrations: [], sha: 'abc1234', mergedBlocked: [{ number: 70, mergeSha: 'def5678' }] },
  });
  assert.match(md, /Approved SHA: abc1234/);
  assert.match(md, /WARNING.*#70 merged \(def5678\)/);
  assert.ok(!md.includes('Nothing merged'));
});

test('transitions: status vocabulary matches the board', () => {
  assert.deepEqual(VALID_STATUSES,
    ['Backlog', 'Ready', 'Questions', 'Building', 'QA', 'Review', 'Blocked', 'Skipped', 'Done']);
});

test('deploy: target config maps to the right fly app + health URL', () => {
  assert.deepEqual(TARGETS.dev.args, ['deploy', '-c', 'fly.dev.toml', '--remote-only']);
  assert.deepEqual(TARGETS.prod.args, ['deploy', '--remote-only']);
  assert.equal(TARGETS.dev.health, 'https://dev.chapterhouse.tools/up');
  assert.equal(TARGETS.prod.health, 'https://chapterhouse.tools/up');
});

test('brief: deploy plan lists tickets and flags migrations', () => {
  const md = renderShipBrief({
    date: '2026-08-11',
    merges: [
      { number: 93, mergeSha: 'abc0001', migrations: ['db/migrate/20260811_x.rb'] },
      { number: 70, mergeSha: 'def5678', migrations: [] },
    ],
    shipped: [{ number: 93, title: 'bump solid-js', pr: 95, verdict: 'green', diffStats: '+2 -2', qaEvidence: 'dev QA pass', hasMigrations: true }],
    blocked: [{ number: 70, title: 'campaign ban', stage: 'dev QA', detail: 'banned spell still grantable' }],
    deployPlan: {
      tickets: [93], migrations: ['db/migrate/20260811_x.rb'], sha: 'abc1234',
      mergedBlocked: [{ number: 70, mergeSha: 'def5678' }],
    },
  });
  assert.match(md, /#93.*bump solid-js.*PR #95/s);
  assert.match(md, /\*\*MIGRATIONS\*\*/);
  assert.match(md, /failed at dev QA: banned spell/);
  assert.match(md, /Approved SHA: abc1234/);
  assert.match(md, /Tickets: #93/);
  assert.match(md, /WARNING.*#70 merged \(def5678\) but failed dev QA/);
  assert.match(md, /db\/migrate\/20260811_x\.rb/);
  assert.match(md, /scripts\/ship\/deploy\.mjs prod/);
});

test('order: edge violations and non-permutations are caught', () => {
  const tickets = [{ number: 1 }, { number: 2 }, { number: 3 }];
  const edges = [[3, 1]]; // #3 blocked by #1
  assert.deepEqual(validateOrder([1, 2, 3], tickets, edges), []);
  assert.ok(validateOrder([3, 1, 2], tickets, edges).length > 0, 'blocked before blocker');
  assert.ok(validateOrder([1, 2], tickets, edges).length > 0, 'missing ticket');
  assert.ok(validateOrder([1, 2, 2], tickets, edges).length > 0, 'duplicate');
});

test('order: malformed latent replies return violations, never throw', () => {
  const tickets = [{ number: 1 }];
  for (const bad of [null, {}, 'x', [1.5], ['1'], undefined]) {
    const problems = validateOrder(bad, tickets, []);
    assert.ok(Array.isArray(problems) && problems.length > 0, JSON.stringify(bad));
  }
});

test('brief: ledger consistency — omitted merges, phantom tickets, bad migration records all refuse', () => {
  const shipped = [{ number: 93, title: 't', pr: 1, verdict: 'green', diffStats: '+1', qaEvidence: 'ok', hasMigrations: false }];
  const base = { date: '2026-08-12', shipped, blocked: [] };
  // no ledger at all
  assert.throws(() => renderShipBrief({ ...base, deployPlan: { tickets: [93], migrations: [], sha: 'a' } }),
    /ledger is required/);
  // ledger entry missing from the plan (the dev-QA-blocked omission)
  assert.throws(() => renderShipBrief({
    ...base, merges: [{ number: 93, mergeSha: 'a', migrations: [] }, { number: 70, mergeSha: 'b', migrations: [] }],
    deployPlan: { tickets: [93], migrations: [], sha: 'a' },
  }), /mergedBlocked must equal ledger minus shipped/);
  // plan lists a ticket that never shipped
  assert.throws(() => renderShipBrief({
    ...base, merges: [{ number: 93, mergeSha: 'a', migrations: [] }],
    deployPlan: { tickets: [93, 99], migrations: [], sha: 'a' },
  }), /must equal shipped/);
  // a QA-failed merge smuggled into tickets instead of mergedBlocked
  assert.throws(() => renderShipBrief({
    date: '2026-08-12', blocked: [],
    shipped: [],
    merges: [{ number: 70, mergeSha: 'b', migrations: [] }],
    deployPlan: { tickets: [70], migrations: [], sha: 'a' },
  }), /must equal shipped/);
  // mergedBlocked mergeSha must match the ledger's
  assert.throws(() => renderShipBrief({
    date: '2026-08-12', blocked: [], shipped: [],
    merges: [{ number: 70, mergeSha: 'b', migrations: [] }],
    deployPlan: { tickets: [], migrations: [], sha: 'a', mergedBlocked: [{ number: 70, mergeSha: 'WRONG' }] },
  }), /mergeSha mismatch/);
  // null migration record
  assert.throws(() => renderShipBrief({
    ...base, merges: [{ number: 93, mergeSha: 'a', migrations: null }],
    deployPlan: { tickets: [93], migrations: [], sha: 'a' },
  }), /missing migration record/);
  // plan migrations diverge from ledger union
  assert.throws(() => renderShipBrief({
    ...base, merges: [{ number: 93, mergeSha: 'a', migrations: ['db/migrate/1_x.rb'] }],
    deployPlan: { tickets: [93], migrations: [], sha: 'a' },
  }), /!= ledger union/);
});

test('ledger vs git: exact bijection — unclaimed, duplicate, and out-of-range entries all refuse', () => {
  const commits = [{ sha: 'aaa', subject: 'fix x (#93)' }, { sha: 'bbb', subject: 'sneaky' }, { sha: 'rrr', subject: 'v0.5.2' }];
  const ledger = [{ number: 93, mergeSha: 'aaa', migrations: [] }];
  assert.throws(() => validateLedgerAgainstCommits(commits, ledger, 'rrr'), /not in the merge ledger: bbb/);
  assert.doesNotThrow(() => validateLedgerAgainstCommits(
    [{ sha: 'aaa', subject: 'x' }, { sha: 'rrr', subject: 'v' }], ledger, 'rrr'));
  // one commit presented as two tickets
  assert.throws(() => validateLedgerAgainstCommits(
    [{ sha: 'aaa', subject: 'x' }],
    [{ number: 93, mergeSha: 'aaa', migrations: [] }, { number: 94, mergeSha: 'aaa', migrations: [] }],
  ), /duplicate merge SHAs/);
  // same ticket twice
  assert.throws(() => validateLedgerAgainstCommits(
    [{ sha: 'aaa', subject: 'x' }, { sha: 'ccc', subject: 'y' }],
    [{ number: 93, mergeSha: 'aaa', migrations: [] }, { number: 93, mergeSha: 'ccc', migrations: [] }],
  ), /duplicate ticket numbers/);
  // ledger points outside the git range
  assert.throws(() => validateLedgerAgainstCommits(
    [{ sha: 'aaa', subject: 'x' }],
    [{ number: 93, mergeSha: 'aaa', migrations: [] }, { number: 94, mergeSha: 'zzz', migrations: [] }],
  ), /not in startSha\.\.releaseSha: zzz/);
});

test('release commit may touch only VERSION and CHANGELOG.md, and must touch VERSION', () => {
  assert.doesNotThrow(() => validateReleaseFiles(['VERSION', 'CHANGELOG.md']));
  assert.doesNotThrow(() => validateReleaseFiles(['VERSION']));
  assert.throws(() => validateReleaseFiles(['VERSION', 'app/models/user.rb']), /non-release files: app\/models\/user\.rb/);
  assert.throws(() => validateReleaseFiles(['CHANGELOG.md']), /must modify VERSION/);
  assert.throws(() => validateReleaseFiles([]), /must modify VERSION/);
});

test('brief: empty drain says no prod deploy', () => {
  const md = renderShipBrief({ date: '2026-08-11', merges: [], shipped: [], blocked: [], deployPlan: { tickets: [], migrations: [] } });
  assert.match(md, /Nothing merged — no prod deploy/);
});
