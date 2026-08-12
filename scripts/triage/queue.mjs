// Triage queue (workflows/issue-triage.md): open issues that carry
// `needs-triage` OR none of the five triage labels. Paginated REST (no
// silent cap); PRs surface in this endpoint so they are filtered explicitly.
// Prints a JSON array.
import { fileURLToPath } from 'node:url';
import { ghJsonPaginated, REPO } from '../lib/gh.mjs';
import { TRIAGE_LABELS } from '../lib/board.mjs';

export function needsTriage(issue) {
  if (issue.pull_request) return false;
  const labels = issue.labels.map((l) => (typeof l === 'string' ? l : l.name));
  if (labels.includes('needs-triage')) return true;
  return !labels.some((l) => TRIAGE_LABELS.includes(l));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const issues = ghJsonPaginated(`repos/${REPO}/issues?state=open&per_page=100`);
  const queue = issues.filter(needsTriage).map(({ number, title, body, labels, assignees, html_url }) => ({
    number, title, body, labels, assignees, url: html_url,
  }));
  process.stdout.write(JSON.stringify(queue, null, 2) + '\n');
}
