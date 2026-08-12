---
name: ticket-ship
description: >-
  Drain ready-for-agent tickets end to end: implement per board Model/Effort
  on a stax branch, /stack-ship (roborev gate + adversarial review),
  auto-merge on green, dev deploy + blocking QA, one brief, one prod approval.
  Use when the user says "run" (drain all Ready tickets), "run #<n>" (one
  ticket), "ticket-ship", or "drain the backlog".
---

# ticket-ship

Spec of record: `workflows/ticket-ship.md` (local-only, gitignored). This
skill is the runbook; every deterministic step routes through `scripts/ship/`
and `scripts/lib/` — never raw `gh` mutations for board/label state.

## Verbs

- **run** — drain every ticket in the snapshot, serially.
- **run #N** — the same pipeline, snapshot of one.

## 0. Preflight

- `bash ~/.claude/skills/stack-ship/check-pipeline.sh` — all green or BLOCKED.
- Clean tree on `main`, up to date with origin.
- `node scripts/ship/queue.mjs` — the snapshot (board-Ready + ready-for-agent
  + unassigned + zero open blockers). Tickets entering Ready mid-drain wait
  for the next drain. Empty snapshot: append run-log line
  (`node scripts/lib/runlog.mjs ship "ok queue-empty"`) and stop.

## 1. Order (drain mode only)

ONE ordering call using `orderPrompt()` from `scripts/ship/order.mjs` (import
it in a node one-liner or replicate its exact text): security first, cluster
related files, small unblockers early. Validate the reply with
`validateOrder()` — any violation: fall back to snapshot order and note it in
the brief. Never re-order after this point.

## 2. Per ticket, serially (next starts only after this one merges or blocks)

1. **Claim**: `node scripts/ship/transitions.mjs <n> Building --claim`.
   Tickets predating issue-triage may have null Model/Model Effort in the
   snapshot: estimate them yourself at claim time with the triage rubric
   (scripts/triage/prompt.md) and set the fields via a node one-liner around
   `setBoardFields` (scripts/lib/board.mjs) before spawning the implementer.
2. **Branch**: fresh stax branch off current main (`st branch create
   ticket-<n>`), named for the ticket.
3. **Implement**: spawn the **ticket-implementer** agent
   (`subagent_type: ticket-implementer`, defined in `.claude/agents/` —
   never general-purpose), `model` = the ticket's board Model field, effort =
   Model Effort field (both in the queue snapshot JSON). Brief it with: issue
   body + triage scoping comment (`gh issue view <n> --comments`), the
   acceptance criteria, house rules (tests + docs in the same diff), and the
   instruction to commit incrementally with real messages — roborev reviews
   each commit. Wall-clock cap 60 min, then Blocked.
   TOOL BOUNDARY (hook-level, honestly scoped): the agent definition fences
   Bash via a PreToolUse guard (`.claude/agents/implementer-bash-guard.mjs`)
   that blocks DIRECT invocation shapes — `gh`, `flyctl`, network clients,
   workflow scripts in any spelling, inline eval, git network verbs — because
   ticket bodies are public, untrusted input. It is NOT a sandbox: an
   implementer that writes a helper file and runs it through an allowed
   interpreter gets past it (#100 owns that ceiling — until it lands, the
   diff-level gates (roborev + adversarial review before merge) are the
   protection for what an implementer produces, and its session should be
   watched, not unattended). Deploys and GitHub state changes happen only in
   this parent session, after the gates.
4. **/stack-ship** (invoke the skill): roborev gate with bounded auto-fix →
   squash submit → PR → /z-adversarial-review. PR body carries `Part of #<n>`,
   never `Closes #<n>` — the issue must survive a post-merge QA failure, so it
   closes only at Done (section 4). Then
   `node scripts/ship/transitions.mjs <n> Review`.
5. **Merge gate**: adversarial verdict green → `gh pr merge <pr> --squash
   --delete-branch`. Red or low-confidence → Blocked (step F).
   IMMEDIATELY after any merge, append to the drain's **merge ledger**:
   `{number, mergeSha, migrations}` (migrations via `git diff --name-only
   <mergeSha>^ <mergeSha> -- db/migrate`). This happens before dev deploy/QA
   so a later QA failure can never leave merged code missing from the deploy
   plan. The ledger is passed to write-brief as `run.merges`, and the brief
   renderer REFUSES to render unless every ledger entry appears in the plan
   and the plan's migrations equal the ledger's union — merged-but-blocked
   tickets ship with the deploy whether the plan admits it or not, so the
   renderer makes not admitting it impossible.
6. **Dev deploy**: `node scripts/ship/deploy.mjs dev` (deploy + /up poll).
   Then `node scripts/ship/transitions.mjs <n> QA`.
7. **Dev QA (blocking)**: /qa-only against https://dev.chapterhouse.tools,
   scoped to the ticket's changed surface + the scoping comment's acceptance
   criteria. Fail → Blocked (step F) — its merge stays in main; flag
   prominently in the brief so the prod decision accounts for it. Pass →
   record evidence path for the brief.
8. Record for the brief: PR number, verdict summary, diff stats, QA evidence,
   `git diff --name-only <merge>^ <merge> | grep ^db/migrate` for the
   migration flag.

**F — failure path (any stage AFTER a successful claim)**: `node
scripts/ship/transitions.mjs <n> Blocked`, comment on the issue naming the
stage + detail, keep branch/PR, continue the drain. A claim REJECTION is not
a failure: someone else took, relabeled, closed, or moved the ticket — skip
it with zero mutations and a one-line note in the brief. Environmental
failure (Fly down, gh auth broken, roborev daemon dead): halt the drain,
brief explains.

## 3. Checkpoint (one per drain)

The release commit comes BEFORE the brief, so the approved SHA is exactly the
deployed SHA — never invalidated by a post-approval commit:

1. VERSION bump (default third segment) + any CHANGELOG touch-up as one
   commit on main, pushed (`git push origin main`). This is the **release
   SHA**. Its diff against the last merge must touch ONLY VERSION and
   CHANGELOG.md — anything else voids the drain.
2. `node scripts/ship/write-brief.mjs '<run-json>' --start-sha <drain-start
   SHA>` (shape in the script header) — writes
   `workflows/briefs/ship-YYYY-MM-DD.md` + toast. deployPlan.sha = the
   release SHA. The writer independently derives the commits in
   `startSha..releaseSha` from git and refuses to render if the ledger does
   not account for every one of them. Record the drain-start SHA
   (`git rev-parse origin/main` at preflight) in the run-log start line so it
   cannot be lost. Then append the heartbeat:
   `node scripts/lib/runlog.mjs ship "ok shipped=<n> blocked=<m>"`.

Present the brief and STOP. Prod moves only on explicit approval. Zac wanting
a different version segment = new VERSION commit → regenerate the brief with
the new release SHA.

## 4. On approval (and only then)

1. Verify the approved SHA: `git fetch origin`, then require ALL THREE equal —
   local `HEAD`, `origin/main`, and the brief's deployPlan.sha — on a clean
   tree (`git status --porcelain` empty, untracked included: fly deploy
   packages the working directory, so an untracked file would ship unreviewed).
   Any mismatch → regenerate the brief and re-ask; never deploy unapproved
   commits.
2. Nothing else lands between brief and deploy — the release SHA was already
   pushed in section 3.
3. `node scripts/ship/deploy.mjs prod`.
4. /canary against https://chapterhouse.tools.
5. Green: per shipped ticket, `gh issue close <n> --comment "Live on prod
   <version>"` and `node scripts/ship/transitions.mjs <n> Done`; append prod
   confirmation to the brief.
6. Red: toast immediately (`node scripts/lib/notify.mjs "CANARY RED" ...`),
   tickets stay un-Done, append the canary report + a paste-ready revert plan
   (`git revert` of the squash commits → new PR → redeploy) to the brief.
   NO auto-revert, NO flyctl rollback — db:migrate already ran on prod; a
   human reads the migration before choosing the revert strategy.

## Hard rules

- Nothing touches prod without the recorded approval — that includes retries.
- Never skip the roborev gate, the adversarial review, or the QA gate.
- Every drain appends exactly one run-log line, success or halt.
- Public repo: briefs and specs stay under `workflows/` (gitignored); never
  paste credential names or infra hostnames into issues or PRs.
