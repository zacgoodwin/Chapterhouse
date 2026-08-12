// Periodic eval (PAID — one claude call) for the triage label rubric
// (workflows/issue-triage.md acceptance #6). Not a gate test: run before
// changing prompt.md and nightly if the loop misbehaves.
// Usage: node scripts/triage/eval.mjs
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = dirname(fileURLToPath(import.meta.url));
const fixtures = JSON.parse(readFileSync(join(DIR, 'eval-fixtures.json'), 'utf8'));
const THRESHOLD = 0.8;

// The rubric under test is the one the daily prompt carries — extract the
// label rules verbatim from prompt.md so the eval can never drift from it.
const prompt = readFileSync(join(DIR, 'prompt.md'), 'utf8');
const rubric = prompt.slice(prompt.indexOf('- **label**'), prompt.indexOf('- **model**'));

const ask = `You are triaging GitHub issues for zacgoodwin/Chapterhouse (Rails+SolidJS
TTRPG character manager for an in-person homebrew campaign; docs/leyfarers-implementation-plan.md
is the plan). Apply this rubric and choose exactly one label per issue:

${rubric}

Issues:
${JSON.stringify(fixtures.map(({ number, title, body }) => ({ number, title, body })), null, 2)}

Reply with ONLY a JSON array: [{"number": <n>, "label": "<label>"}]. No prose, no fences.`;

const raw = execFileSync('claude', ['-p', ask, '--model', 'claude-opus-5'],
  { encoding: 'utf8', timeout: 300000 });
const answers = JSON.parse(raw.replace(/^```(json)?|```$/gm, '').trim());

let pass = 0;
for (const f of fixtures) {
  const got = answers.find((a) => a.number === f.number)?.label ?? '(missing)';
  const ok = got === f.expected;
  if (ok) pass += 1;
  console.log(`${ok ? 'PASS' : 'FAIL'} #${f.number} expected=${f.expected} got=${got}`);
}
const score = pass / fixtures.length;
console.log(`score ${pass}/${fixtures.length} (${Math.round(score * 100)}%), threshold ${THRESHOLD * 100}%`);
process.exit(score >= THRESHOLD ? 0 : 1);
