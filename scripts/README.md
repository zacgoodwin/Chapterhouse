# Workflow scripts

Deterministic halves of two local workflows (specs live in `workflows/*.md`,
which is intentionally gitignored — these scripts contain no secrets and are
generic `gh`/`flyctl` plumbing).

- `lib/` — shared: gh wrapper, Project-3 board ops, run-log heartbeat, toast.
- `triage/` — daily issue triage: queue, apply-decision, brief writer, headless
  session prompt + Task Scheduler entry (`run-triage.ps1`), label-rubric eval.
- `ship/` — ticket drain (see `.claude/skills/ticket-ship/`): queue snapshot,
  board transitions, Fly deploy + health gate, brief writer, ordering eval.

Gate tests: `spec/javascript/triage-scripts.test.js`, `ship-scripts.test.js`
(run with `yarn test` — pure functions, no network, <2s).

Paid evals (one claude call each, run before editing prompts):
`node scripts/triage/eval.mjs`, `node scripts/ship/eval-ordering.mjs`.
