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
- flyctl: installed at `~/.fly/bin/flyctl.exe` (v0.4.72). Not yet authed — run `flyctl auth login` (browser).
- Note: Procfile and config/deploy.rb are upstream (kortirso) leftovers — never deploy with them.
- FIRST-DEPLOY GATE: do not deploy until all four hold —
  (1) DONE — `config/master.key` present + valid on this box (gitignored). Re-keyed 2026-07-20 (old upstream kortirso enc was undecryptable): fresh master.key + Chapterhouse-owned enc holding `secret_key_base`, `production` + `development` (mirrored) `.supabase.{db,url,anon_key,service_role_key,storage}` + `.discord_{bot_token,public_key}`. DB creds LIVE-VERIFIED: session pooler `aws-1-us-west-2.pooler.supabase.com:5432`, user `chapter.surtaqeyusnowwltwgka` (custom least-priv role, tenant-suffixed), SELECT + LISTEN/UNLISTEN confirmed against PG 17.6.
  (2) the Supabase project exists (ref `surtaqeyusnowwltwgka`) and its schema is loaded (README "Supabase setup": `db:schema:load` + `db:seed` run locally);
  (3) `fly apps create chapterhouse` has been run by a human;
  (4) `fly secrets set RAILS_MASTER_KEY=<config/master.key contents> --app chapterhouse` is done (SUPABASE_URL is already in credentials, so no separate secret needed).
  Until all four hold, stop after merge.

### Custom deploy hooks

- Pre-merge: none
- Deploy trigger: `fly deploy --remote-only`
- Deploy status: `fly status --app chapterhouse`
- Health check: https://chapterhouse.fly.dev/up (fly.toml also checks /up every 30s)
