// Periodic eval (PAID — one claude call) for the drain-ordering prompt
// (workflows/ticket-ship.md acceptance #6): every hard edge must be respected
// (100%); the judgment order itself is not scored.
// Usage: node scripts/ship/eval-ordering.mjs
import { execFileSync } from 'node:child_process';
import { orderPrompt, validateOrder } from './order.mjs';

const tickets = [
  { number: 101, title: 'Security: close feats attach user_id scoping hole', body: 'Another user\'s homebrew feat can attach to your character.' },
  { number: 102, title: 'Add TLC species to seed data', body: 'Seed the 12 TLC-only species.' },
  { number: 103, title: 'Species dropdown reads merged config', body: 'Depends on species seed data existing.' },
  { number: 104, title: 'Doc typo sweep in user guide', body: 'Mechanical copy fixes.' },
  { number: 105, title: 'Character sheet renders species traits', body: 'Depends on dropdown wiring.' },
];
// [blocked, blockedBy]
const edges = [[103, 102], [105, 103]];

const raw = execFileSync('claude', ['-p', orderPrompt(tickets, edges), '--model', 'claude-opus-5'],
  { encoding: 'utf8', timeout: 300000 });
const order = JSON.parse(raw.replace(/^```(json)?|```$/gm, '').trim());
const problems = validateOrder(order, tickets, edges);

console.log(`order: ${JSON.stringify(order)}`);
for (const p of problems) console.log(`FAIL ${p}`);
console.log(problems.length ? 'RESULT: FAIL' : 'RESULT: PASS (all edges respected)');
process.exit(problems.length ? 1 : 0);
