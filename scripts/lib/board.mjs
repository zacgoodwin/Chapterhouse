// Project board ops for GitHub Project 3 "Chapterhouse".
// Pure mappings exported for gate tests; gh IO kept in the exported ops.
import { gh, ghJson, REPO, PROJECT_NUMBER, PROJECT_OWNER } from './gh.mjs';

// Triage label -> board Status (workflows/issue-triage.md).
export const STATUS_BY_LABEL = {
  'ready-for-agent': 'Ready',
  'ready-for-human': 'Backlog',
  'needs-info': 'Questions',
  'wontfix': 'Skipped',
};

export const TRIAGE_LABELS = ['needs-triage', 'needs-info', 'ready-for-agent', 'ready-for-human', 'wontfix'];
export const MODELS = ['haiku', 'sonnet', 'opus', 'fable'];
export const EFFORTS = ['low', 'medium', 'high', 'xhigh'];

let fieldsCache;
// Resolve project + single-select field/option ids by name, once per process.
function fields() {
  if (fieldsCache) return fieldsCache;
  const raw = ghJson(['project', 'field-list', PROJECT_NUMBER, '--owner', PROJECT_OWNER, '--format', 'json']);
  const projectId = ghJson(['project', 'view', PROJECT_NUMBER, '--owner', PROJECT_OWNER, '--format', 'json']).id;
  const byName = {};
  for (const f of raw.fields) byName[f.name] = f;
  fieldsCache = { projectId, byName };
  return fieldsCache;
}

export function optionId(fieldName, optionName) {
  const f = fields().byName[fieldName];
  const opt = (f.options ?? []).find((o) => o.name === optionName);
  if (!opt) throw new Error(`no option "${optionName}" on field "${fieldName}"`);
  return { fieldId: f.id, optionId: opt.id };
}

// ponytail: gh project item-list has no pagination flag; 1000 covers this
// board ~20x over. Raise if the board ever approaches it — a duplicate
// item-add is the failure mode when an item falls past the limit.
const ITEM_LIMIT = '1000';

export function listItems() {
  return ghJson(['project', 'item-list', PROJECT_NUMBER, '--owner', PROJECT_OWNER,
    '--format', 'json', '--limit', ITEM_LIMIT]).items;
}

export function findItem(issueNumber) {
  return listItems().find((i) => i.content?.number === issueNumber && i.content?.repository?.endsWith(REPO));
}

// Ensure the issue is on the board; returns the project item id.
export function ensureItem(issueNumber) {
  const hit = findItem(issueNumber);
  if (hit) return hit.id;
  const url = `https://github.com/${REPO}/issues/${issueNumber}`;
  return ghJson(['project', 'item-add', PROJECT_NUMBER, '--owner', PROJECT_OWNER,
    '--url', url, '--format', 'json']).id;
}

export function setSingleSelect(itemId, fieldName, optionName) {
  const { projectId } = fields();
  const { fieldId, optionId: oid } = optionId(fieldName, optionName);
  gh(['project', 'item-edit', '--id', itemId, '--project-id', projectId,
    '--field-id', fieldId, '--single-select-option-id', oid]);
}

// One call the triage/ship scripts use: put the issue on the board with the
// given single-select values ({Status, Model, "Model Effort"}).
export function setBoardFields(issueNumber, values) {
  const itemId = ensureItem(issueNumber);
  for (const [field, value] of Object.entries(values)) {
    if (value) setSingleSelect(itemId, field, value);
  }
  return itemId;
}
