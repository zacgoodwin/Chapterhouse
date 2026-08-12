// Render + write the drain brief (workflows/ticket-ship.md checkpoint), then
// toast. The brief is the single thing Zac reads before the one prod approval.
// Usage: node scripts/ship/write-brief.mjs '<run-json>'   (or stdin)
import { readFileSync, mkdirSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { notify } from '../lib/notify.mjs';
import { BRIEFS_DIR, assertBriefDate, writeBriefFile, localDate } from '../triage/write-brief.mjs';

// run = { date?, merges: [{number, mergeSha, migrations:[paths]}],   <- THE LEDGER
//         shipped: [{number,title,pr,verdict,diffStats,qaEvidence,hasMigrations}],
//         blocked: [{number,title,stage,detail}],
//         deployPlan: {tickets:[numbers], migrations:[paths], sha,
//                      mergedBlocked:[{number,mergeSha}]} }
// `merges` is the independent merge ledger, appended by the skill IMMEDIATELY
// after each merge (before QA can fail). deployPlan.sha = the main HEAD the
// approval covers. mergedBlocked = ledger entries whose dev QA failed: their
// code ships with this deploy regardless, so the plan must say so.
// Exact-partition consistency gate, derived from the ledger — not from the
// narrative arrays. shipped == deployPlan.tickets exactly; every remaining
// ledger entry == mergedBlocked exactly (with matching mergeSha); migration
// records are real arrays whose union equals the plan's list. Throws on any
// divergence — a partial or shuffled plan would let Zac approve a SHA
// containing unreported code or an unwarned QA failure.
export function validateLedger(run) {
  const ledger = run.merges;
  if (!Array.isArray(ledger)) throw new Error('run.merges ledger is required');
  const sortNums = (a) => [...a].sort((x, y) => x - y);
  const eq = (a, b) => JSON.stringify(sortNums(a)) === JSON.stringify(sortNums(b));

  const shippedNums = run.shipped.map((s) => s.number);
  if (!eq(shippedNums, run.deployPlan.tickets)) {
    throw new Error(`deployPlan.tickets ${JSON.stringify(run.deployPlan.tickets)} must equal shipped ${JSON.stringify(shippedNums)} exactly`);
  }
  const mergedBlocked = run.deployPlan.mergedBlocked ?? [];
  const restNums = ledger.map((m) => m.number).filter((n) => !shippedNums.includes(n));
  if (!eq(restNums, mergedBlocked.map((m) => m.number))) {
    throw new Error(`mergedBlocked must equal ledger minus shipped: expected ${JSON.stringify(restNums)}, got ${JSON.stringify(mergedBlocked.map((m) => m.number))}`);
  }
  for (const mb of mergedBlocked) {
    const entry = ledger.find((m) => m.number === mb.number);
    if (entry.mergeSha !== mb.mergeSha) throw new Error(`#${mb.number} mergeSha mismatch: plan ${mb.mergeSha} vs ledger ${entry.mergeSha}`);
  }
  const shippedInLedger = shippedNums.filter((n) => !ledger.some((m) => m.number === n));
  if (shippedInLedger.length) throw new Error(`shipped tickets missing from ledger: ${shippedInLedger.join(', ')}`);
  const badRecord = ledger.filter((m) => !Array.isArray(m.migrations));
  if (badRecord.length) throw new Error(`missing migration record for: ${badRecord.map((m) => `#${m.number}`).join(', ')}`);
  const union = [...new Set(ledger.flatMap((m) => m.migrations))].sort();
  const planMigrations = [...run.deployPlan.migrations].sort();
  if (JSON.stringify(union) !== JSON.stringify(planMigrations)) {
    throw new Error(`deploy plan migrations ${JSON.stringify(planMigrations)} != ledger union ${JSON.stringify(union)}`);
  }
}

// The ledger itself is session-supplied JSON — anchor it to git with an
// exact BIJECTION: unique ticket numbers, unique merge SHAs, and the set of
// non-release commits in startSha..releaseSha equal to the set of ledger
// SHAs. One real commit can never be presented as several shipped tickets,
// and no ledger entry can point outside the range. commits = [{sha, subject}].
export function validateLedgerAgainstCommits(commits, ledger, releaseSha = null) {
  const numbers = ledger.map((m) => m.number);
  if (new Set(numbers).size !== numbers.length) throw new Error(`duplicate ticket numbers in ledger: ${numbers.join(', ')}`);
  const shas = ledger.map((m) => m.mergeSha);
  if (new Set(shas).size !== shas.length) throw new Error(`duplicate merge SHAs in ledger: ${shas.join(', ')}`);
  const rangeShas = new Set(commits.filter((c) => c.sha !== releaseSha).map((c) => c.sha));
  const unclaimed = [...rangeShas].filter((s) => !shas.includes(s));
  if (unclaimed.length) {
    const bySha = new Map(commits.map((c) => [c.sha, c.subject]));
    throw new Error(`commits on main not in the merge ledger: ${unclaimed.map((s) => `${s.slice(0, 8)} ${bySha.get(s)}`).join('; ')}`);
  }
  const phantom = shas.filter((s) => !rangeShas.has(s));
  if (phantom.length) throw new Error(`ledger SHAs not in startSha..releaseSha: ${phantom.join(', ')}`);
}

// The release commit may touch ONLY the release files — application code in
// it would deploy unreviewed by any gate — and MUST touch VERSION (the
// runbook requires a version bump before approval).
export function validateReleaseFiles(files) {
  const allowed = new Set(['VERSION', 'CHANGELOG.md']);
  const stray = files.filter((f) => !allowed.has(f));
  if (stray.length) throw new Error(`release commit touches non-release files: ${stray.join(', ')}`);
  if (!files.includes('VERSION')) throw new Error('release commit must modify VERSION');
}

export function renderShipBrief(run) {
  validateLedger(run);
  const lines = [`# Ship brief — ${run.date}`, ''];
  if (run.shipped.length) {
    lines.push('## Merged, dev-deployed, QA green — awaiting prod approval', '');
    for (const s of run.shipped) {
      lines.push(`- **#${s.number}** ${s.title} (PR #${s.pr})`,
        `  verdict: ${s.verdict} · ${s.diffStats} · QA: ${s.qaEvidence}${s.hasMigrations ? ' · **MIGRATIONS**' : ''}`);
    }
    lines.push('');
  }
  if (run.blocked?.length) {
    lines.push('## Blocked (drain continued past these)', '');
    for (const b of run.blocked) lines.push(`- **#${b.number}** ${b.title} — failed at ${b.stage}: ${b.detail}`);
    lines.push('');
  }
  lines.push('## Prod deploy plan', '');
  const mergedBlocked = run.deployPlan.mergedBlocked ?? [];
  // Anything merged is deploy evidence — including tickets that then failed
  // QA. An all-blocked drain must still show its SHA, warnings, migrations.
  if (run.deployPlan.tickets.length || mergedBlocked.length) {
    lines.push(`Approved SHA: ${run.deployPlan.sha ?? 'MISSING — regenerate brief'}`);
    if (run.deployPlan.tickets.length) {
      lines.push(`Tickets: ${run.deployPlan.tickets.map((n) => `#${n}`).join(', ')}`);
    }
    for (const m of mergedBlocked) {
      lines.push(`**WARNING**: #${m.number} merged (${m.mergeSha}) but failed dev QA — its code ships with this deploy.`);
    }
    lines.push(run.deployPlan.migrations.length
      ? `Migrations (db:migrate runs on prod Supabase at deploy): ${run.deployPlan.migrations.join(', ')}`
      : 'No migrations.');
    lines.push('', 'The release SHA above is already committed and pushed. Approve with "go".',
      'Then: verify clean tree + HEAD == origin/main == approved SHA -> `node scripts/ship/deploy.mjs prod` -> /canary.',
      'Different version segment wanted? New VERSION commit -> regenerate this brief.');
  } else {
    lines.push('Nothing merged — no prod deploy this drain.');
  }
  return lines.join('\n') + '\n';
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const startIdx = args.indexOf('--start-sha');
  const startSha = startIdx >= 0 ? args.splice(startIdx, 2)[1] : null;
  const run = JSON.parse(args[0] ?? readFileSync(0, 'utf8'));
  run.date ??= localDate();
  assertBriefDate(run.date);
  // Git is the independent record: the session-supplied ledger must be a
  // bijection with the commits that actually landed, the release commit must
  // touch only release files, and each entry's migration list must match
  // what its commit really changed under db/migrate.
  const changedFiles = (sha) => execFileSync('git',
    ['diff-tree', '--no-commit-id', '--name-only', '-r', sha], { encoding: 'utf8' })
    .trim().split('\n').filter(Boolean);
  if (startSha && run.deployPlan.sha) {
    const log = execFileSync('git', ['log', '--format=%H%x09%s', `${startSha}..${run.deployPlan.sha}`], { encoding: 'utf8' });
    const commits = log.trim().split('\n').filter(Boolean)
      .map((l) => { const [sha, ...s] = l.split('\t'); return { sha, subject: s.join('\t') }; });
    validateLedgerAgainstCommits(commits, run.merges ?? [], run.deployPlan.sha);
    validateReleaseFiles(changedFiles(run.deployPlan.sha));
    for (const m of run.merges ?? []) {
      const real = changedFiles(m.mergeSha).filter((f) => f.startsWith('db/migrate/')).sort();
      if (JSON.stringify(real) !== JSON.stringify([...m.migrations].sort())) {
        throw new Error(`#${m.number} migration record ${JSON.stringify(m.migrations)} != git ${JSON.stringify(real)}`);
      }
    }
  } else if ((run.merges ?? []).length) {
    throw new Error('--start-sha is required when the drain merged anything');
  }
  mkdirSync(BRIEFS_DIR, { recursive: true });
  const file = writeBriefFile(join(BRIEFS_DIR, `ship-${run.date}.md`), renderShipBrief(run));
  notify('Ship brief ready',
    `${run.shipped.length} awaiting prod approval, ${run.blocked?.length ?? 0} blocked`);
  console.log(file);
}
