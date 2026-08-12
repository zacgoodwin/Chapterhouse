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

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `zacgoodwin/Chapterhouse` (origin, not upstream) via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root, created lazily. See `docs/agents/domain.md`.

## Rules

Read before editing, not after:

- `.claude/rules/ruby-security.md` — before touching Gemfile/Gemfile.lock, credentials, auth or session code, raw SQL, or anything reaching `html_safe`/`raw`.
- `.claude/rules/web-security.md` — before changing CSP, response headers, or any code that injects HTML.
- `.claude/rules/web-performance.md` — before adding fonts, images, or client bundle weight.

DESIGN.md outranks these on any visual question.

## Design System

Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.

## Deploy Configuration (configured by /setup-deploy)

- Platform: Fly.io (apps `chapterhouse` = prod + `chapterhouse-dev` = dev, region `iad`; Dockerfile + fly.toml (prod) + fly.dev.toml (dev) in repo root)
- Production URL: https://chapterhouse.tools (custom domain; https://chapterhouse.fly.dev still works as fallback)
- Dev URL: https://dev.chapterhouse.tools (app `chapterhouse-dev`)
- Deploy workflow: `~/.fly/bin/flyctl.exe deploy --remote-only` (prod) / `~/.fly/bin/flyctl.exe deploy -c fly.dev.toml --remote-only` (dev). No local Docker; remote builder. No CI deploy workflow — deploys are manual.
- Dev instance shape: same image, RAILS_ENV=production, `CREDENTIALS_ENV=development` selects the development credentials section, which points at the separate dev Supabase project (own DB, Storage bucket `charkeeper`, and S3 keys). Web-only (GoodJob async in-process), no Redis (cache errors degrade to misses; rails_performance disabled without REDIS_URL). Dev credentials carry the full set: url, anon (`sb_publishable`), `service_role_key` (`sb_secret`), db (role `chapter`), and storage S3 keys.
- Deploy status command: `~/.fly/bin/flyctl.exe status --app chapterhouse` (prod) / `~/.fly/bin/flyctl.exe status --app chapterhouse-dev` (dev)
- Merge method: squash
- Project type: web app (Rails 8.1 + SolidJS; Supabase for DB/Auth/Storage/Realtime). Two Fly process groups: `web` (auto-stops to 0) + `worker` (GoodJob, always-on).
- Post-deploy health check: https://chapterhouse.tools/up (dev: https://dev.chapterhouse.tools/up)
- flyctl: installed at `~/.fly/bin/flyctl.exe` (v0.4.72), authed. NOT on PATH — neither
  `fly` nor `flyctl` resolves in Git Bash or PowerShell, so every deploy/status command
  above spells out the full path. The `~/.fly/bin/flyctl.exe` form works in both shells.
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
- Deploy trigger: `~/.fly/bin/flyctl.exe deploy --remote-only`
- Deploy status: `~/.fly/bin/flyctl.exe status --app chapterhouse`
- Health check: https://chapterhouse.tools/up (fly.toml also checks /up every 30s)
