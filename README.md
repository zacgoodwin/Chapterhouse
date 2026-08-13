# README

### Supabase setup

The app runs on Supabase: hosted Postgres, Auth (email/password + Google/Discord OAuth), Storage (avatars/files), and Realtime (campaign dice rolls). Test env stays on localhost Postgres and never touches Supabase. Two projects exist: prod (the `production` credentials section, used by the `chapterhouse` Fly app) and dev (the `development` section, used by local dev and the `chapterhouse-dev` Fly app).

One-time project setup (dashboard):

1. Create a project; note the project ref, region, and database password.
2. Disable the Data API (Project Settings -> Data API). App tables live in `public` with RLS off; a live PostgREST endpoint would expose them.
3. Auth: enable the Email provider (confirmations off for the personal app), add Google + Discord OAuth apps (callback `https://<ref>.supabase.co/auth/v1/callback`), set Site URL and fill the redirect allow-list per project — prod: `https://chapterhouse.tools/dashboard` + `https://www.chapterhouse.tools/dashboard` (+ `https://chapterhouse.fly.dev/dashboard` fallback); dev: `https://dev.chapterhouse.tools/dashboard` + `http://localhost:3000/dashboard`. A host missing from its project's allow-list fails OAuth round-trips with redirect_uri-not-allowed.
4. Storage: create a private bucket `charkeeper`; create S3 access keys (Project Settings -> Storage).
5. The SPA reads the project URL and anon key at runtime from meta tags the Rails layout renders out of the encrypted credentials — nothing to bake into the JS for the web app. `supabaseConfig.js` is only a fallback for hosts without the Rails layout: before building a Tauri webview bundle, fill it with the target project's URL and anon key (and never commit the filled values).
6. Add credentials via `bin/rails credentials:edit`:

```yaml
development:
  supabase:
    url: https://<ref>.supabase.co
    anon_key: <anon key>
    service_role_key: <service role key>
    db:
      host: aws-<n>-<region>.pooler.supabase.com
      port: 5432
      database: postgres
      username: chapter.<ref> # dedicated role, not postgres — see below
      password: "<db password>"
    storage:
      endpoint: https://<ref>.storage.supabase.co/storage/v1/s3
      region: <region>
      access_key_id: <s3 key id>
      secret_access_key: <s3 secret>
      bucket: charkeeper
production: # same shape, pointing at the prod project
```

The app connects as a dedicated `chapter` role, not `postgres`. On a fresh project, create it in the SQL editor before the first schema load (it then owns every table the load creates). Keep it least-privilege: no CREATEDB/CREATEROLE (a CREATEROLE role is a privilege-escalation primitive) and no BYPASSRLS (app tables have RLS off anyway):

```sql
CREATE ROLE chapter LOGIN PASSWORD '<db password>';
GRANT USAGE, CREATE ON SCHEMA public TO chapter;
GRANT USAGE ON SCHEMA extensions TO chapter;
```

Database rules:

- Always connect through the **session pooler** (port 5432, user `chapter.<ref>`). Never the transaction pooler (6543): GoodJob needs LISTEN/NOTIFY and `with_advisory_lock` needs session advisory locks. The direct `db.<ref>.supabase.co` host is IPv6-only.
- First load is `bin/rails db:schema:load` then `bin/rails db:seed` — never `db:migrate` from zero (159 migrations include data backfills), and never `db:create`/`db:drop`/`db:reset` against Supabase.
- The dev Fly app's release step migrates the dev DB under RAILS_ENV=production, which stamps `ar_internal_metadata.environment = production`. A later local `db:schema:load` against the dev project then raises ProtectedEnvironmentError; clear it first with `bin/rails db:environment:set RAILS_ENV=development`.
- After running migrations in development, review the `db/schema.rb` diff: a dump from the Supabase catalog can pick up `extensions.*`/`pg_graphql`/`supabase_vault` lines that break localhost test schema loads. The gate spec `spec/config/supabase_migration_gates_spec.rb` catches this.

Known gaps: the Cypress e2e login step used the removed password form and was never rewritten against Supabase. Browser coverage now lives in the Playwright eval lane instead (see E2E tests); `spec/e2e` is dormant upstream code.

### Game systems

This fork supports D&D only: dnd5 (2014 rules) and dnd2024. The other
upstream CharKeeper systems (pathfinder2, daggerheart, dc20, fate,
fallout, cosmere, cthulhu7) were removed; the
`RemoveNonDndSystemsData` migration deletes their rows on databases
that predate the removal.

### Reference docs

Player and DM guides for the TLC provider live in `docs/user-guide/`
(creating a TLC character, rule warnings, homebrew, admin content).
The Leyfarers/TLC implementation plan lives at
`docs/leyfarers-implementation-plan.md` with digests in `docs/` and source
references in `docs/reference/`. The architecture map is
`docs/codebase-map.md`; deferred work is tracked in `docs/TODOS.md`.
Reference PDFs are NOT in git (GitHub blocks LFS uploads on public forks);
download the Players Guide from the
[reference-docs release](https://github.com/zacgoodwin/Chapterhouse/releases/tag/reference-docs)
into `docs/` (gitignored there).

### TLC provider

The Leyfarer's Chronicle (TLC) is a new provider type (`Tlc::Character`, `Tlc::Feat`, `Tlc::Spell`, `Tlc::Item`) extending dnd2024 as a subclass of the existing decorator (`TlcDecorator < Dnd2024Decorator`). Content queries follow two patterns: STRICT scope (`.tlc()` returns only `Tlc::` rows; used for TLC-only filters) and UNION scope (`.tlc_content()` returns both `Dnd2024::` and `Tlc::` rows, minus the 8-spell banned list; used for character spell/feat/item options). TLC mechanics are code; TLC content lives in `db/data/tlc/*.json` and is seeded by the idempotent `rake tlc:seed`.

#### Content pipeline

Adding TLC content (species, subclasses, feats, spells, items) follows a three-step workflow:

1. **Extract and author:** Run `bin/extract-tlc-content` (lands with ticket #14 B3) to generate author-friendly JSON from the Players Guide, review the diff, and edit `db/data/tlc/{species_traits,feats,spells,items}.json` by hand.

2. **Review and merge:** Before committing JSON edits, run `rake tlc:seed` in the shell to verify the content parses and no malformed modifiers or banned-spell auto-grants are present. The tool prints counts per file type and a count of unverified rows (rows carrying `verified: false` for later content-gate review). An `upsert_all` with a partial unique index ensures re-running the seed is safe; rows never duplicate.

3. **Verify and mark:** Content arrives from extraction marked `verified: false`. Seed it, then mark each unverified row after checking the underlying Players Guide rules and interactions match the modifiers. To mark a row verified: visit the adminbook (HTTP Basic, see CLAUDE.md), click the row's slug in the Feats/Spells/Items index, scroll to the Info textarea, edit the JSON to set `"verified": true`, and submit. Alternatively, query the console to find unverified rows: `Tlc::Feat.where("info->>'verified' = ?", 'false')` (or `Tlc::Spell`/`Tlc::Item` for other types). Once all rows in a file are marked `verified: true`, the extraction phase for that file is done.

#### Formula failure runbook

Modifier syntax errors (malformed Dentaku formulas, missing variables) surface at runtime when a character sheet evaluates the modifiers, not during `rake tlc:seed`. To triage:

1. Reproduce the error on a character sheet using the affected trait/feat/spell/item.
2. Note the exact error message and identify the row's `slug` field from the context (or narrow it down by reproduction).
3. Open `db/data/tlc/{type}.json`, find the row by slug, and inspect the `modifiers` or `eval_variables` JSONB fields for syntax errors or typos.
4. Fix the JSON and re-run `rake tlc:seed` to reload the corrected content into the database (re-runs are safe due to the partial unique index).
5. Commit the fix.

**Cache caveat:** `app/lib/platform_config.rb` caches the TLC config (`app/javascript/applications/CharKeeperApp/data/tlc.json`) under a cache key derived from the config files' own contents (`PlatformConfig::CONFIG_VERSION`, a SHA of every `data/*.json`) for 3 days. Editing `tlc.json` changes the key, so a deploy picks the new config up even though production's redis cache survives deploys. The digest is computed at boot: in development, restart the server (or `Rails.cache.clear`) after editing `tlc.json`.

### Frontend tests (gate lane)

```bash
$ npm test
```

`node --test` over `spec/javascript/*.test.js`. Deterministic, local, free, no network, ~2s on a warm checkout: this is the lane that has to stay green on every commit. `yarn install` is the only setup; nothing is installed by hand at run time.

Both harnesses register the same module hooks (`spec/javascript/support/jsxHooks.js`), which compile the SPA's `.jsx` with the babel preset `esbuild.config.js` uses and redirect the `pages`/`components`/`context`/`helpers` barrels to `support/stubs.js` — the real barrels drag in the whole app, including the gitignored `supabaseConfig.js`. A test file imports exactly one harness:

- **SSR** (`support/jsxLoader.js`) — compiles in SSR mode and renders through `renderToString`. `stubs.js`'s field components record the props they are handed instead of drawing, which is enough to render a creation form and drive it the way a player does (`tlcForm.test.js`: species list, size default, the payload Save submits, the post-save reset, and no blank label against the real `fetchDictionary`, which is English-only and serves the `en` dictionary even to a browser still holding a stale persisted locale). `warningsBanner.test.js` mounts the real `WarningsBanner` this way — direct render/dismiss cases plus a gate that the 2024 character sheet actually mounts it.
- **jsdom** (`support/domHarness.js`) — jsdom supplies the document and the hooks resolve `solid-js` to its client build (the `browser` export condition, the same one esbuild picks), so components mount as real nodes and `createEffect` runs. That is the difference that matters: state arriving from a `fetch` inside an effect is invisible to the SSR harness, because SSR makes effects a no-op. The lane still never touches the network — the request layer resolves to `stubs.js`, and `domHarness.js` makes a real `fetch` throw.

`tlcRouting.test.js` uses the jsdom harness to gate the two TLC surfaces that had no automated check at all:

- `pages/Navigation/CharactersTab.jsx` — the platform picker routing `tlc` to `TlcCharacterForm`. Only evaluates after the characters fetch resolves.
- `pages/Content/CharacterTab.jsx` — the `provider === 'tlc'` `<Match>` opening the interim Dnd5 sheet. `character()` is empty until its fetch resolves.

Delete either branch and `npm test` fails naming that file. Companion cases keep the dnd5/dnd2024 destinations distinct, so a branch that matched everything would not pass either.

The loader needs `module.registerHooks` and jsdom 30 requires `^22.22.2 || ^24.15.0 || >=26`, hence `.node-version` 22.22.2.

**What this lane still cannot reach.** Layout and CSS (jsdom computes no geometry, so anything keyed off a measured size is a guess), Supabase auth, the Rails side of any request, and the built bundle as a browser actually runs it. Those belong to the eval lane below.

### E2E tests (eval lane)

```bash
$ npx playwright install chromium   # one-time, ~115MB, not needed for `npm test`
$ npm run eval:e2e
```

Playwright against the deployed dev instance (https://dev.chapterhouse.tools; override with `QA_BASE_URL`). `spec/playwright/tlcSurfaces.spec.js` signs in and walks the same two TLC surfaces the gate lane covers, but through the shipped bundle, the real API and real CSS: the platform picker opening the TLC creation form, and a TLC character opening its sheet. The second spec creates a throwaway character, opens it, and deletes it again in a `finally`, so the eval needs no seeded fixture. A leftover `Eval Leyfarer <timestamp>` row on the QA account means a cleanup failed.

**This is an eval, not a gate.** The house rule is two lanes with different budgets: gate tests are deterministic, local, free, under two seconds, and run on every commit; periodic evals are networked and slow, and run before ship and on a schedule. This suite needs a live deployment, a real Supabase login and a browser download, and the dev machine auto-stops to zero, so a cold run pays a start-up. Putting it in a pre-commit hook would make every commit depend on Fly's uptime. Run it before shipping anything that touches character creation or the sheet, and after any deploy to dev.

It also asserts on what is **deployed**, which lags `main`. A red eval can mean "dev has not been redeployed yet" rather than "the code broke"; check the deployed version before chasing a failure.

**Credentials.** `QA_EMAIL` and `QA_PASSWORD` come from `.env.qa.local` at the repo root, loaded by `playwright.config.js` through node's own `process.loadEnvFile` (no dotenv dependency). That file is gitignored and stays that way: this repo is public. A run with either missing fails immediately with a message naming the file. Failure traces land in `test-results/` and capture the logged-in session, credentials typed into the login form included, so that directory is gitignored too. Never attach one to an issue.

**Cypress (`spec/e2e`)** is upstream's and is wired to nothing here: it appears in no `package.json`, its documented flow was a manual install-run-uninstall, and its one spec targets a Rails test server on port 5002 that this fork never starts. Kept in place only to keep subrepo merges with kortirso clean. It is not coverage.

### CI

There is none: no `.github/` directory, so every check above runs when a human runs it. Recommendation, deliberately not implemented in #69 because workflow files are deploy-adjacent infrastructure:

- Add one GitHub Actions workflow running `npm test` on push and pull request. It needs no secrets, no services and no browser, and it now covers the TLC routing branches. It is the cheapest real gate available.
- Add `bundle exec rspec` to the same workflow behind a Postgres service container and a `RAILS_MASTER_KEY` secret.
- Leave the Playwright eval out of pull-request CI. It needs the QA login and a live deployment; a nightly or manually dispatched job is the right home for it.
