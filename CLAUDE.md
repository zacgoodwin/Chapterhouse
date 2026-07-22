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

- Platform: Fly.io (app `chapterhouse`, region `iad`; Dockerfile + fly.toml in repo root)
- Production URL: https://chapterhouse.fly.dev
- Deploy workflow: `fly deploy --remote-only` (no local Docker; remote builder). No CI deploy workflow — deploys are manual.
- Deploy status command: `fly status --app chapterhouse`
- Merge method: squash
- Project type: web app (Rails 8.1 + SolidJS; Supabase for DB/Auth/Storage/Realtime). Two Fly process groups: `web` (auto-stops to 0) + `worker` (GoodJob, always-on).
- Post-deploy health check: https://chapterhouse.fly.dev/up
- flyctl: installed at `~/.fly/bin/flyctl.exe` (v0.4.72), authed.
- Note: Procfile and config/deploy.rb are upstream (kortirso) leftovers — never deploy with them.
- FIRST-DEPLOY GATE: SATISFIED — the app is created, secrets are set, and production is live.
  Kept as history; there is no longer a gate to clear before deploying.
  - `config/master.key` is gitignored and lives only on the dev box and in Fly's
    `RAILS_MASTER_KEY` secret. Keep a copy in a password manager: losing it means re-keying.
  - The encrypted credentials hold `secret_key_base` plus `production` and `development`
    (mirrored) `.supabase.{db,url,anon_key,service_role_key,storage}` and
    `.discord_{bot_token,public_key}`. Read them with `bin/rails credentials:show`; never
    paste project refs, DB users, hostnames, or keys into tracked files — this repo is public.
  - Fly secrets in use: `RAILS_MASTER_KEY`, `REDIS_URL`. `SUPABASE_URL` comes from
    credentials, so it needs no separate secret.
  - The deploy's `release_command` runs `bin/rails db:migrate` against Supabase on every
    deploy. Locally, never run `db:migrate`/`db:create`/`db:drop` against Supabase — use
    `db:schema:load` + `db:seed` per README "Supabase setup".

### Custom deploy hooks

- Pre-merge: none
- Deploy trigger: `fly deploy --remote-only`
- Deploy status: `fly status --app chapterhouse`
- Health check: https://chapterhouse.fly.dev/up (fly.toml also checks /up every 30s)
