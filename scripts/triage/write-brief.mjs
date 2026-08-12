// Render + write the daily triage brief, then toast. Brief file exists iff
// the queue was non-empty; toast fires iff the brief was written
// (workflows/issue-triage.md acceptance #3).
// Usage: node scripts/triage/write-brief.mjs '<run-json>'   (or stdin)
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { notify } from '../lib/notify.mjs';
import { REPO } from '../lib/gh.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
export const BRIEFS_DIR = join(ROOT, 'workflows', 'briefs');

// run.date comes from latent-session JSON — untrusted. Anything but a bare
// date would let a crafted value escape BRIEFS_DIR ("../../CLAUDE.md").
export function assertBriefDate(date) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`bad brief date: ${date}`);
  return date;
}

// LOCAL date, not UTC: run-triage.ps1 searches for today's brief with the
// host's local date — a UTC default would miss near midnight.
export function localDate(d = new Date()) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

// A second run on the same date must never overwrite an earlier brief (it may
// hold a pending approval record). Pure core for tests; the writer below uses
// atomic 'wx' creation so concurrent runs cannot race exists->write.
export function nextName(file, exists) {
  if (!exists(file)) return file;
  for (let i = 2; ; i++) {
    const candidate = file.replace(/\.md$/, `-${i}.md`);
    if (!exists(candidate)) return candidate;
  }
}

// Atomic create-new: walks -N suffixes on EEXIST, never overwrites.
export function writeBriefFile(file, content) {
  for (let i = 1; ; i++) {
    const candidate = i === 1 ? file : file.replace(/\.md$/, `-${i}.md`);
    try {
      writeFileSync(candidate, content, { flag: 'wx' });
      return candidate;
    } catch (e) {
      if (e.code !== 'EEXIST') throw e;
    }
  }
}

// POSIX single-quote escaping for paste-ready commands: model-controlled text
// must never break out of the quoted argument ($(), backticks, quotes).
export function shellSingleQuote(s) {
  return `'${String(s).replace(/[\r\n]+/g, ' ').replace(/'/g, `'\\''`)}'`;
}

// run = { date?, triaged: [{number,title,label,status,model,effort,blockedBy,why}],
//         wontfix: [{number,title,reason,closeComment}],
//         needsInfoOpen: [{number,title}] }
export function renderTriageBrief(run) {
  const lines = [`# Triage brief — ${run.date}`, ''];
  if (run.triaged.length) {
    lines.push('## Triaged (applied)', '');
    for (const t of run.triaged) {
      const edges = t.blockedBy?.length ? ` · blocked by ${t.blockedBy.map((n) => `#${n}`).join(', ')}` : '';
      lines.push(`- **#${t.number}** ${t.title}`,
        `  ${t.label} · ${t.status} · ${t.model}/${t.effort}${edges} — ${t.why}`);
    }
    lines.push('');
  }
  if (run.wontfix?.length) {
    lines.push('## Wontfix proposals (NOT applied — approve to close)', '');
    for (const w of run.wontfix) {
      // w.number is latent output: must be a bare integer or it could smuggle
      // shell syntax into the paste-ready command. Command is POSIX-quoted —
      // paste into Git Bash (or hand it to a session), not PowerShell.
      if (!Number.isInteger(w.number) || w.number <= 0) throw new Error(`bad wontfix number: ${w.number}`);
      lines.push(`- **#${w.number}** ${w.title} — ${w.reason}`, '', '  ```', `  # Git Bash:`, `  gh issue close ${w.number} -R ${REPO} --comment ${shellSingleQuote(w.closeComment)}`, '  ```', '');
    }
  }
  if (run.needsInfoOpen?.length) {
    lines.push('## Still waiting on info', '');
    for (const n of run.needsInfoOpen) lines.push(`- #${n.number} ${n.title}`);
    lines.push('');
  }
  return lines.join('\n');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const run = JSON.parse(process.argv[2] ?? readFileSync(0, 'utf8'));
  run.date ??= localDate();
  assertBriefDate(run.date);
  mkdirSync(BRIEFS_DIR, { recursive: true });
  const file = writeBriefFile(join(BRIEFS_DIR, `triage-${run.date}.md`), renderTriageBrief(run));
  notify('Triage brief ready',
    `${run.triaged.length} triaged, ${run.wontfix?.length ?? 0} wontfix proposals`);
  console.log(file);
}
