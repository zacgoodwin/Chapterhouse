# README

### Supabase setup

The app runs on Supabase: hosted Postgres, Auth (email/password + Google/Discord OAuth), Storage (avatars/files), and Realtime (campaign dice rolls). Test env stays on localhost Postgres and never touches Supabase.

One-time project setup (dashboard):

1. Create a project; note the project ref, region, and database password.
2. Disable the Data API (Project Settings -> Data API). App tables live in `public` with RLS off; a live PostgREST endpoint would expose them.
3. Auth: enable the Email provider (confirmations off for the personal app), add Google + Discord OAuth apps (callback `https://<ref>.supabase.co/auth/v1/callback`), set Site URL and add `http://localhost:3000/dashboard` to the redirect allow-list.
4. Storage: create a private bucket `charkeeper`; create S3 access keys (Project Settings -> Storage).
5. Fill `app/javascript/applications/CharKeeperApp/supabaseConfig.js` with the project URL and anon key, then `yarn build`.
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
      username: postgres.<ref>
      password: "<db password>"
    storage:
      endpoint: https://<ref>.storage.supabase.co/storage/v1/s3
      region: <region>
      access_key_id: <s3 key id>
      secret_access_key: <s3 secret>
      bucket: charkeeper
production: # same shape when cutting over
```

Database rules:

- Always connect through the **session pooler** (port 5432, user `postgres.<ref>`). Never the transaction pooler (6543): GoodJob needs LISTEN/NOTIFY and `with_advisory_lock` needs session advisory locks. The direct `db.<ref>.supabase.co` host is IPv6-only.
- First load is `bin/rails db:schema:load` then `bin/rails db:seed` — never `db:migrate` from zero (149 migrations include data backfills), and never `db:create`/`db:drop`/`db:reset` against Supabase.
- After running migrations in development, review the `db/schema.rb` diff: a dump from the Supabase catalog can pick up `extensions.*`/`pg_graphql`/`supabase_vault` lines that break localhost test schema loads. The gate spec `spec/config/supabase_migration_gates_spec.rb` catches this.

Known gaps: the Cypress e2e login step used the removed password form and needs a rewrite against Supabase before it can run again.

### Game systems

This fork supports D&D only: dnd5 (2014 rules) and dnd2024. The other
upstream CharKeeper systems (pathfinder2, daggerheart, dc20, fate,
fallout, cosmere, cthulhu7) were removed; the
`RemoveNonDndSystemsData` migration deletes their rows on databases
that predate the removal.

### Reference docs

The Leyfarers/TLC implementation plan lives at
`docs/leyfarers-implementation-plan.md` with digests in `docs/reference/`.
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

3. **Verify and mark:** Content arrives from extraction marked `verified: false`. Seed it, then visit the adminbook (HTTP Basic, see CLAUDE.md) → Feats / Spells / Items filter, and manually mark each unverified row after checking the underlying Players Guide rules and interactions match the modifiers. Once all rows in a file are marked `verified: true`, the extraction phase for that file is done.

#### Formula failure runbook

Modifier syntax errors (malformed Dentaku formulas, missing variables) surface at runtime when a character sheet evaluates the modifiers, not during `rake tlc:seed`. To triage:

1. Reproduce the error on a character sheet using the affected trait/feat/spell/item.
2. Note the exact error message and identify the row's `slug` field from the context (or narrow it down by reproduction).
3. Open `db/data/tlc/{type}.json`, find the row by slug, and inspect the `modifiers` or `eval_variables` JSONB fields for syntax errors or typos.
4. Fix the JSON and re-run `rake tlc:seed` to reload the corrected content into the database (re-runs are safe due to the partial unique index).
5. Commit the fix.

**Cache caveat:** `app/lib/platform_config.rb` caches the TLC config (`app/javascript/applications/CharKeeperApp/data/tlc.json`) per version (default `0.4.12`) for 3 days. After editing `tlc.json` in development, either bump the version in `platform_config.rb:6` or clear the cache via `Rails.cache.clear` in the console to pick up changes immediately. Production deploys use the same cache window; plan accordingly.

### E2E tests

With browser
```bash
$ yarn add cypress@14.5.4 --dev
$ rails server -e test -p 5002
$ yarn cypress open --project ./spec/e2e
$ yarn remove cypress
```

Headless
```bash
$ yarn add cypress@14.5.4 --dev
$ rails server -e test -p 5002
$ yarn run cypress run --project ./spec/e2e
$ yarn remove cypress
```
