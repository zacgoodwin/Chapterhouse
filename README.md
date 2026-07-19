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

Known gaps: Daggerheart domain cards have no in-repo seed source; the Cypress e2e login step used the removed password form and needs a rewrite against Supabase before it can run again.

### Reference docs

The Leyfarers/TLC implementation plan lives at
`docs/leyfarers-implementation-plan.md` with digests in `docs/reference/`.
Reference PDFs are NOT in git (GitHub blocks LFS uploads on public forks);
download the Players Guide from the
[reference-docs release](https://github.com/zacgoodwin/Chapterhouse/releases/tag/reference-docs)
into `docs/` (gitignored there).

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

### Info options for PF2 characters

```bash
"info": { "change_character": { "attr": "archetypes", "type": "push", "value": "bard" } }

"info": { "options_list": "skills" }
"info": { "options_list": "classes" }
"info": { "options_list": "subclasses" }
"info": { "options_list": "spellLists" }
"info": { "options_list": "races" }

"info": { "extra_feats": ["ride"] }
"info": { "required": ["tough"] }

"info": { "focus_spells": ["hymn_of_healing"] }
"info": { "static_spells": { "detect_magic": { "limit": null } } }
"info": { "static_spells": { "oaken_resilience": { "limit": 1 }, "entangle": { "limit": 1 } } }

"info": { "weapons": [{ "items_slug": "razortooth", "items_name": { "en": "Jaws", "ru": "Челюсти" }, "items_info": { "group": "brawling", "weapon_skill": "unarmed", "type": "melee", "damage": "1d6", "damage_type": "pierce", "tooltips": ["finesse", "unarmed"] } }] }

"info": { "weapons": [{ "items_slug": "seedpod", "items_name": { "en": "Seedpod", "ru": "Побег" }, "items_info": { "weapon_skill": "unarmed", "type": "range", "damage": "1d4", "damage_type": "bludge", "tooltips": ["unarmed"], "dist": 30 } }] }
```
