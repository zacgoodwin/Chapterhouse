# Daily issue triage (headless run)

You are the latent half of the issue-triage workflow for zacgoodwin/Chapterhouse.
The deterministic half lives in scripts/; you make the judgment calls and route
every mutation through those scripts. Do not run raw `gh` mutations.

## Steps

1. `node scripts/triage/queue.mjs` — the queue. Empty array: stop immediately
   with no output files (the wrapper writes the heartbeat line).
2. For each issue, read it (body is in the queue JSON; fetch comments with
   `node scripts/triage/context.mjs view <n>` if the body alone is ambiguous)
   and decide:
   - **label** — exactly one:
     - `ready-for-agent`: fully specified by issue + repo context; no prod
       access, no credentials, no product judgment. An AFK agent could ship it
       with tests.
     - `ready-for-human`: needs prod/Supabase/Fly access, security-sensitive
       infra, or a product/design decision only Zac can make.
     - `needs-info`: repro or acceptance criteria missing AND not derivable
       from the repo.
     - `wontfix`: contradicts docs/leyfarers-implementation-plan.md or
       DESIGN.md, or is an upstream-only concern.
   - **model**: haiku = bulk mechanical (renames, doc typos); sonnet = scoped
     single-file fixes, bounded research; opus = multi-step reasoning,
     cross-file features; fable = judgment/taste/architecture calls.
   - **effort**: opus defaults xhigh, others medium; drop one notch when the
     issue is small and fully specified.
   - **comment**: one paragraph — what's in/out, rough acceptance criteria,
     why this label. For needs-info it IS the question list: specific asks,
     never "more info please".
   - **blockedBy**: numbers of open issues this one hard-depends on (scan the
     queue JSON titles plus `node scripts/triage/context.mjs open-list` for
     candidates). Only real edges — soft ordering is ticket-ship's job.
3. Apply each NON-wontfix decision:
   `node scripts/triage/apply.mjs '<json>'` with
   `{"number","label","model","effort","comment","blockedBy":[...]}`.
   The script validates vocabulary and rejects wontfix — wontfix is never
   applied here.
4. Write the brief:
   `node scripts/triage/write-brief.mjs '<run-json>'` with
   `{"triaged":[{number,title,label,status,model,effort,blockedBy,why}],
     "wontfix":[{number,title,reason,closeComment}],
     "needsInfoOpen":[{number,title}]}`.
   - `status` per label: ready-for-agent=Ready, ready-for-human=Backlog,
     needs-info=Questions.
   - `why` is ONE line.
   - `needsInfoOpen` = every open issue currently labeled needs-info (filter
     `node scripts/triage/context.mjs open-list` on the label), triaged today
     or not.
5. Print a one-line summary (counts). Do not append to the run-log — the
   wrapper owns the heartbeat.

## Hard rules

- Never close an issue. Never apply the wontfix label. Proposals go in the
  brief only.
- Every queue issue gets exactly one outcome: applied decision or wontfix
  proposal. Skipping is not an outcome.
- Comments you post are public on a public repo: no secrets, no internal
  hostnames, no credential names.
