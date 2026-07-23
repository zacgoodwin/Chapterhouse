# Chapterhouse

Fork of kortirso/charkeeper (Rails 8.1 + SolidJS + esbuild TTRPG character
manager), being adapted for The Leyfarer's Chronicle (TLC) homebrew D&D 2024
campaign. Plan: `docs/leyfarers-implementation-plan.md`.

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec

## Deploy Configuration (configured by /setup-deploy)

- Platform: Fly.io (apps `chapterhouse` = prod + `chapterhouse-dev` = dev, region `iad`; Dockerfile + fly.toml (prod) + fly.dev.toml (dev) in repo root)
- Production URL: https://chapterhouse.tools (custom domain; https://chapterhouse.fly.dev still works as fallback)
- Dev URL: https://dev.chapterhouse.tools (app `chapterhouse-dev`)
- Deploy workflow: `fly deploy --remote-only` (prod) / `fly deploy -c fly.dev.toml --remote-only` (dev). No local Docker; remote builder. No CI deploy workflow — deploys are manual.
- Dev instance shape: same image, RAILS_ENV=production, `CREDENTIALS_ENV=development` selects the development credentials section, which points at the separate dev Supabase project (own DB, Storage bucket `charkeeper`, and S3 keys). Web-only (GoodJob async in-process), no Redis (cache errors degrade to misses; rails_performance disabled without REDIS_URL). Dev credentials carry the full set: url, anon (`sb_publishable`), `service_role_key` (`sb_secret`), db (role `chapter`), and storage S3 keys.
- Deploy status command: `fly status --app chapterhouse`
- Merge method: squash
- Project type: web app (Rails 8.1 + SolidJS; Supabase for DB/Auth/Storage/Realtime). Two Fly process groups: `web` (auto-stops to 0) + `worker` (GoodJob, always-on).
- Post-deploy health check: https://chapterhouse.tools/up
- flyctl: installed at `~/.fly/bin/flyctl.exe` (v0.4.72), authed.
- Note: Procfile and config/deploy.rb are upstream (kortirso) leftovers — never deploy with them.
- FIRST-DEPLOY GATE: SATISFIED — the app is created, secrets are set, and production is live.
  Kept as history; there is no longer a gate to clear before deploying.
  - `config/master.key` is gitignored and lives only on the dev box and in Fly's
    `RAILS_MASTER_KEY` secret. Keep a copy in a password manager: losing it means re-keying.
  - The encrypted credentials hold `secret_key_base` plus `production` and `development`
    `.supabase.{db,url,anon_key,service_role_key,storage}` and
    `.discord_{bot_token,public_key}`. The sections point at DIFFERENT Supabase projects
    (prod vs dev) since the dev instance was set up; they are no longer mirrored.
    Read them with `bin/rails credentials:show`; never
    paste project refs, DB users, hostnames, or keys into tracked files — this repo is public.
  - Fly secrets in use: prod = `RAILS_MASTER_KEY`, `REDIS_URL`; dev = `RAILS_MASTER_KEY`,
    `SECRET_KEY_BASE` (own signing key so dev-minted cookies/signed IDs never verify on
    prod — the shared master key means dev CAN decrypt prod credential sections; splitting
    into per-env credential files is tracked in docs/TODOS.md). All Supabase settings come
    from credentials; the old `SUPABASE_URL` env override was removed.
  - The deploy's `release_command` runs `bin/rails db:migrate` against Supabase on every
    deploy. Locally, never run `db:migrate`/`db:create`/`db:drop` against Supabase — use
    `db:schema:load` + `db:seed` per README "Supabase setup".

### Custom deploy hooks

- Pre-merge: none
- Deploy trigger: `fly deploy --remote-only`
- Deploy status: `fly status --app chapterhouse`
- Health check: https://chapterhouse.tools/up (fly.toml also checks /up every 30s)
