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

- Platform: Fly.io (app `chapterhouse`; Dockerfile + fly.toml in repo root)
- Production URL: https://chapterhouse.fly.dev
- Deploy workflow: `fly deploy --remote-only` (no local Docker needed)
- Deploy status command: `fly status --app chapterhouse`
- Merge method: squash
- Project type: web app (Rails 8.1 + SolidJS; Supabase for DB/Auth/Storage/Realtime)
- Post-deploy health check: https://chapterhouse.fly.dev/up
- Note: Procfile and config/deploy.rb are upstream (kortirso) leftovers — never deploy with them.
- FIRST-DEPLOY GATE: do not deploy until (1) the Supabase project exists and its schema is loaded (README "Supabase setup": db:schema:load + db:seed run locally), (2) `fly apps create chapterhouse` has been run by a human, and (3) `fly secrets set RAILS_MASTER_KEY=...` is done. Until then, stop after merge.

### Custom deploy hooks

- Pre-merge: none
- Deploy trigger: `fly deploy --remote-only`
- Deploy status: `fly status --app chapterhouse`
- Health check: https://chapterhouse.fly.dev/up (fly.toml also checks /up every 30s)
