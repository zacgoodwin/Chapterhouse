# TLC content admin

The adminbook (`/adminbook`) has a **TLC** section in the left nav with CRUD for
the three TLC content types: **Feats**, **Spells**, and **Items**. Each row is an
STI record (`Tlc::Feat`, `Tlc::Spell`, `Tlc::Item`) sharing the feats / spells /
items tables with the D&D content.

Access is HTTP Basic, inherited from every adminbook page (gated to
production / ru_production; open locally). Credentials live in encrypted
credentials under `admin.username` / `admin.password`.

## Routes

| Type   | Index                     | New                          |
| ------ | ------------------------- | ---------------------------- |
| Feats  | `/adminbook/tlc/feats`    | `/adminbook/tlc/feats/new`   |
| Spells | `/adminbook/tlc/spells`   | `/adminbook/tlc/spells/new`  |
| Items  | `/adminbook/tlc/items`    | `/adminbook/tlc/items/new`   |

## Visibility states

Every TLC row carries a `visibility` value (stored in the row's jsonb meta
column: `info` for feats/items, `data` for spells). It governs only what the
options / search path OFFERS. It never touches a character who already holds the
row.

| State        | In the browse (add) list | In search                       | Existing holders |
| ------------ | ------------------------ | ------------------------------- | ---------------- |
| `public`     | yes (default)            | yes (partial + exact)           | keep it          |
| `locked`     | no                       | no                              | keep it          |
| `deprecated` | no                       | no                              | keep it (\*)     |
| `hidden`     | no                       | only on an exact name/slug match| keep it          |

(\*) `deprecated` is a label at this stage. Removing a deprecated row from the
characters that hold it, with a replacement prompt, is a deferred flow (see
`docs/TODOS.md`).

These semantics are enforced at the query layer by `Tlc::ContentFlags`:

- `Tlc::Feat.addable` — the browse list (public only).
- `Tlc::Feat.searchable(term)` — public rows on a partial match, plus hidden
  rows only on an exact name/slug match; locked and deprecated never surface.

The later options and list features (plan tickets C5 / D2) consume these scopes.

## Verification queue

Content imported from garbled source tables is seeded `verified: false` (plan
Phase B; see `Tlc::Seeder`). Each TLC index has a **Filter** toggle:

- **All** — every row.
- **Unverified queue** (`?verified=false`) — only rows explicitly flagged
  `verified: false`, the human-check queue. `verified` defaults to true, so a
  clean row never appears here.

Open the queue, review each row against the source, fix it, and check the
**Verified** box on the edit form to clear it from the queue.

## Security: eval fields are seed-only

The base D&D feats admin permits three Ruby-eval'd fields
(`eval_variables`, `description_eval_variables`, `bonus_eval_variables`). Those
strings are evaluated by Dentaku at runtime, so an admin form that writes them is
a remote-code-execution surface (T18 / eng finding 6).

**The TLC admin forms omit all three, from both the form and the strong
parameters.** Posting them in the payload persists nothing. TLC feats that need
computed variables are authored in the seed files (`db/data/tlc/*.json`) and
loaded by `rake tlc:seed`, where the content is reviewed before it lands.
