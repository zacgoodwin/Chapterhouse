// Ticket-ship drain snapshot (workflows/ticket-ship.md): board-Ready +
// ready-for-agent + unassigned + zero open blockers. The deterministic filter
// underneath the latent ordering call — a blocked or claimed ticket can never
// reach the drain whatever the ordering says.
import { fileURLToPath } from 'node:url';
import { ghJson, ghJsonPaginated, REPO, PROJECT_NUMBER, PROJECT_OWNER } from '../lib/gh.mjs';

// gh project item-list lowercases custom field names in its JSON; be tolerant
// of both spellings for the two we consume.
export function itemFields(item) {
  return {
    number: item.content?.number,
    status: item.status ?? null,
    model: item.model ?? item.Model ?? null,
    effort: item['model Effort'] ?? item.modelEffort ?? item['Model Effort'] ?? null,
  };
}

const CONFLICTING = ['ready-for-human', 'wontfix', 'needs-info', 'needs-triage'];

// Eligibility for unattended work, from a REST issue object. Fail-closed on
// both trust edges: a missing/non-numeric dependency summary (API drift) and
// conflicting triage outcome labels (a stale ready-for-human or wontfix
// alongside ready-for-agent) each exclude the issue. Also the pre-claim
// re-check: a ticket claimed/relabeled/blocked mid-drain must fail this.
export function isClaimable(iss) {
  const labels = (iss.labels ?? []).map((l) => l.name ?? l);
  return (iss.state ?? 'open') === 'open'
    && labels.includes('ready-for-agent')
    && !labels.some((l) => CONFLICTING.includes(l))
    && (iss.assignees ?? []).length === 0
    && iss.issue_dependencies_summary?.blocked_by === 0
    && !iss.pull_request;
}

// items: gh project item-list items; issues: REST issues (labels, assignees,
// issue_dependencies_summary). Returns drain tickets with board fields attached.
export function filterReady(items, issues) {
  const board = new Map(
    items.map(itemFields).filter((f) => f.number && f.status === 'Ready').map((f) => [f.number, f]),
  );
  return issues
    .filter((iss) => board.has(iss.number) && isClaimable(iss))
    .map((iss) => ({
      number: iss.number,
      title: iss.title,
      body: (iss.body ?? '').slice(0, 400),
      model: board.get(iss.number).model,
      effort: board.get(iss.number).effort,
    }));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const items = ghJson(['project', 'item-list', PROJECT_NUMBER, '--owner', PROJECT_OWNER,
    '--format', 'json', '--limit', '500']).items;
  // ponytail: board item-list capped at 500; raise if the board outgrows it.
  const issues = ghJsonPaginated(`repos/${REPO}/issues?state=open&per_page=100`);
  process.stdout.write(JSON.stringify(filterReady(items, issues), null, 2) + '\n');
}
