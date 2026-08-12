// Repo-pinned read access for the headless triage session. Raw `gh issue
// list/view` would accept -R <any-repo> and read private repos with the
// host's credentials; this wrapper hardcodes the repository and validates
// inputs, and is the ONLY gh read surface on the session's allowlist.
//   node scripts/triage/context.mjs open-list        -> [{number,title,labels}]
//   node scripts/triage/context.mjs view <number>    -> issue + comments
import { fileURLToPath } from 'node:url';
import { ghJson, ghJsonPaginated, REPO } from '../lib/gh.mjs';

export function parseIssueNumber(raw) {
  if (!/^[1-9]\d{0,5}$/.test(String(raw))) throw new Error(`bad issue number: ${raw}`);
  return Number(raw);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [verb, arg] = process.argv.slice(2);
  if (verb === 'open-list') {
    const issues = ghJsonPaginated(`repos/${REPO}/issues?state=open&per_page=100`)
      .filter((i) => !i.pull_request)
      .map((i) => ({ number: i.number, title: i.title, labels: i.labels.map((l) => l.name) }));
    process.stdout.write(JSON.stringify(issues, null, 2) + '\n');
  } else if (verb === 'view') {
    const n = parseIssueNumber(arg);
    const issue = ghJson(['api', `repos/${REPO}/issues/${n}`]);
    if (issue.pull_request) throw new Error(`#${n} is a PR`);
    const comments = ghJsonPaginated(`repos/${REPO}/issues/${n}/comments?per_page=100`)
      .map((c) => ({ author: c.user?.login, body: c.body }));
    const { number, title, body, state, labels } = issue;
    process.stdout.write(JSON.stringify(
      { number, title, body, state, labels: labels.map((l) => l.name), comments }, null, 2,
    ) + '\n');
  } else {
    console.error('usage: context.mjs open-list | view <number>');
    process.exit(2);
  }
}
