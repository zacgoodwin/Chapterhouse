// Gate tests for the issue-triage workflow scripts (workflows/issue-triage.md
// acceptance #1, #2, #6). Pure functions only — no gh, no network, <2s.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { needsTriage } from '../../scripts/triage/queue.mjs';
import { validateDecision, labelSwapArgs } from '../../scripts/triage/apply.mjs';
import { renderTriageBrief, assertBriefDate, nextName, shellSingleQuote } from '../../scripts/triage/write-brief.mjs';
import { STATUS_BY_LABEL } from '../../scripts/lib/board.mjs';
import { formatLine } from '../../scripts/lib/runlog.mjs';
import { denyReason } from '../../.claude/agents/implementer-bash-guard.mjs';
import { parseIssueNumber } from '../../scripts/triage/context.mjs';

const issue = (labels) => ({ number: 1, labels: labels.map((name) => ({ name })) });

test('queue: needs-triage label is queued', () => {
  assert.equal(needsTriage(issue(['bug', 'needs-triage'])), true);
});

test('queue: no triage label at all is queued', () => {
  assert.equal(needsTriage(issue(['bug', 'enhancement'])), true);
  assert.equal(needsTriage(issue([])), true);
});

test('queue: already-triaged issues are not queued', () => {
  for (const l of ['needs-info', 'ready-for-agent', 'ready-for-human', 'wontfix']) {
    assert.equal(needsTriage(issue(['bug', l])), false, l);
  }
});

test('queue: needs-triage wins even alongside another triage label', () => {
  // A half-flipped issue (apply crashed mid-way) must re-enter the queue.
  assert.equal(needsTriage(issue(['needs-triage', 'ready-for-agent'])), true);
});

test('queue: PRs never enter the triage queue (REST issues endpoint includes them)', () => {
  assert.equal(needsTriage({ ...issue(['needs-triage']), pull_request: { url: 'x' } }), false);
});

const valid = {
  number: 42,
  label: 'ready-for-agent',
  model: 'sonnet',
  effort: 'medium',
  comment: 'Scope: fix the species_name resolution for TLC species. Acceptance: all 12 render.',
  blockedBy: [7],
};

test('apply: valid decision passes', () => {
  assert.deepEqual(validateDecision(valid), []);
});

test('apply: wontfix is rejected — brief-only by spec', () => {
  assert.ok(validateDecision({ ...valid, label: 'wontfix' }).length > 0);
});

test('apply: out-of-vocabulary values are rejected', () => {
  assert.ok(validateDecision({ ...valid, label: 'needs-triage' }).length > 0);
  assert.ok(validateDecision({ ...valid, model: 'gpt' }).length > 0);
  assert.ok(validateDecision({ ...valid, effort: 'max' }).length > 0);
  assert.ok(validateDecision({ ...valid, comment: 'lgtm' }).length > 0);
  assert.ok(validateDecision({ ...valid, blockedBy: [42] }).length > 0, 'self-edge');
  assert.ok(validateDecision({ ...valid, number: -1 }).length > 0);
});

test('apply: label swap removes every other triage label, not just needs-triage', () => {
  const args = labelSwapArgs('ready-for-agent');
  assert.deepEqual(args.slice(0, 2), ['--add-label', 'ready-for-agent']);
  const removed = args.filter((_, i) => args[i - 1] === '--remove-label');
  assert.deepEqual(removed.sort(),
    ['needs-info', 'needs-triage', 'ready-for-human', 'wontfix']);
  assert.ok(!removed.includes('ready-for-agent'), 'never removes the chosen label');
});

test('status mapping matches the spec table', () => {
  assert.deepEqual(STATUS_BY_LABEL, {
    'ready-for-agent': 'Ready',
    'ready-for-human': 'Backlog',
    'needs-info': 'Questions',
    'wontfix': 'Skipped',
  });
});

test('brief: renders triaged, wontfix with close command, needs-info carryover', () => {
  const md = renderTriageBrief({
    date: '2026-08-11',
    triaged: [{ number: 80, title: 'Anjurer typo', label: 'ready-for-agent', status: 'Ready', model: 'haiku', effort: 'low', blockedBy: [78], why: 'copy fix' }],
    wontfix: [{ number: 94, title: 'ECC Tools', reason: 'upstream-only', closeComment: 'Out of scope for TLC.' }],
    needsInfoOpen: [{ number: 79, title: 'Local main unrunnable' }],
  });
  assert.match(md, /#80.*Anjurer/s);
  assert.match(md, /blocked by #78/);
  assert.match(md, /gh issue close 94 -R zacgoodwin\/Chapterhouse --comment/);
  assert.match(md, /NOT applied/);
  assert.match(md, /#79 Local main unrunnable/);
});

test('brief: empty wontfix/needs-info sections are omitted', () => {
  const md = renderTriageBrief({ date: '2026-08-11', triaged: [], wontfix: [], needsInfoOpen: [] });
  assert.ok(!md.includes('Wontfix'));
  assert.ok(!md.includes('waiting on info'));
});

test('brief: date is validated — traversal-shaped values are rejected', () => {
  assert.equal(assertBriefDate('2026-08-11'), '2026-08-11');
  for (const bad of ['../../CLAUDE', '2026-08-11/../x', '20260811', 'a', '']) {
    assert.throws(() => assertBriefDate(bad), bad || '(empty)');
  }
});

test('brief: same-date rerun gets a -N suffix, never overwrites', () => {
  const taken = new Set(['t-2026-08-11.md', 't-2026-08-11-2.md']);
  const exists = (f) => taken.has(f);
  assert.equal(nextName('t-2026-08-12.md', exists), 't-2026-08-12.md');
  assert.equal(nextName('t-2026-08-11.md', exists), 't-2026-08-11-3.md');
});

test('brief: close command survives hostile comment text', () => {
  const q = shellSingleQuote(`it's $(rm -rf /) \`x\`\n"end"`);
  assert.ok(q.startsWith("'") && q.endsWith("'"));
  assert.ok(!q.includes('\n'), 'newlines flattened');
  // The only unescaped single quotes are the POSIX '\'' escape triplets.
  assert.equal(q.replaceAll(`'\\''`, '').slice(1, -1).includes("'"), false);
});

test('brief: non-integer wontfix numbers are rejected (no injection via #)', () => {
  for (const bad of ['1; rm -rf /', 1.5, -3, null]) {
    assert.throws(() => renderTriageBrief({
      date: '2026-08-11', triaged: [],
      wontfix: [{ number: bad, title: 't', reason: 'r', closeComment: 'c' }],
      needsInfoOpen: [],
    }), String(bad));
  }
});

test('implementer guard: code work allowed, mutations and escapes blocked', () => {
  for (const ok of ['git add -A && git commit -m "x"', 'npm test', 'npm run lint',
    'node --test spec/javascript/x.test.js', 'yarn run build', 'rake test',
    'bundle exec rails test', 'RAILS_ENV=test bundle exec rspec spec/models', 'rtk git status']) {
    assert.equal(denyReason(ok), null, ok);
  }
  for (const bad of ['gh issue edit 5 --add-label wontfix', 'flyctl deploy', 'curl https://evil',
    'node scripts/ship/deploy.mjs prod', 'rtk node scripts/ship/deploy.mjs prod',
    'git status && gh pr merge 7', 'echo $(gh auth token)', 'powershell -c x', '',
    'git push origin main', 'git config alias.x "!gh pr merge"', 'git -c core.editor=x commit',
    'node -e "require(\'child_process\')"', 'ruby -e "system(\'gh\')"',
    'node --eval="require(\'net\')"', 'git -C . push', 'git --git-dir=/other/repo log', 'ruby -pe "x"',
    'bundle exec ruby -e "system(1)"', 'node --print process.env']) {
    assert.notEqual(denyReason(bad), null, bad);
  }
});

test('implementer guard: adversarial-review bypass spellings (PR #101 F1-F4) are blocked', () => {
  for (const bad of [
    'node ./scripts/ship/deploy.mjs prod',                       // F1: ./ prefix
    'cd scripts/ship && node deploy.mjs prod',                   // F1: cd hop
    'node C:/repo/scripts/ship/deploy.mjs prod',                 // F1: absolute path
    'find . -maxdepth 0 -exec gh pr merge 7 --squash ;',         // F2: find -exec
    'cat <(gh auth token)',                                      // F3: process substitution
    'bin/rails runner "system(1)"',                              // F4: rails runner
    'bundle exec rails runner "system(1)"',                      // F4: via bundle
    'npm exec -c "gh pr merge 7"',                               // F4: npm exec
    'npx anything',                                              // F4: npx
    'npm install evil-pkg',                                      // F4: install lifecycle scripts
    'yarn exec gh pr view',                                      // F4: yarn exec
    'yarn add evil-pkg',                                         // F4: yarn add
    'bin/rails console',                                         // console escape
  ]) {
    assert.notEqual(denyReason(bad), null, bad);
  }
});

test('context: issue numbers validated before hitting the API', () => {
  assert.equal(parseIssueNumber('93'), 93);
  for (const bad of ['0', '-1', '1.5', '93; rm', 'x', '']) assert.throws(() => parseIssueNumber(bad), bad || '(empty)');
});

test('run-log line: timestamped single line', () => {
  const line = formatLine('triage', 'ok queue-empty', new Date('2026-08-11T09:00:00Z'));
  assert.equal(line, '2026-08-11T09:00:00.000Z triage ok queue-empty\n');
});
