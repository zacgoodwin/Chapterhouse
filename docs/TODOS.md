# TODOS

Deferred scope from docs/leyfarers-implementation-plan.md (/autoplan, 2026-07-19).
Each item was considered and explicitly deferred — the rationale is recorded so
picking one up later starts from the reasoning, not from scratch.

## Deferred from the Leyfarers (TLC) plan

- [ ] **Full Effects/automation engine** (L) — P2. The design doc's Effects
  sections are empty headers; there is no spec to build. Phase D ships minimal
  conditions (modifier-expressible ones via character_bonus, informational
  badges otherwise). Start by designing the effect model (trigger, duration,
  per-roll riders, advantage propagation), then replace the ponytail ceiling in
  Phase D. Blocked by: a real design for effect anatomy.
- [ ] **PDF export (official-style + app-style layouts)** (L) — P3. Design-doc
  feature; orthogonal to the TLC system. Needs a renderer decision
  (Puppeteer/PDFKit equivalent in Rails: Grover/Prawn). Start: serializer
  already exposes the full sheet.
- [ ] **Live read-only share links with content filters** (M) — P3. Design-doc
  feature; needs a public-token route + filtered serializer. Security review
  required (unauthenticated read path).
- [ ] **Offline-first / autosave queue / divergence warning** (XL) — P3.
  Design-doc technical wish; the SolidJS SPA is currently online-only. This is
  an architecture project, not a feature.
- [ ] **XP banks / transfers / retirement refunds** (M) — P3. Session-based
  leveling bookkeeping across players; needs campaign-level design (per-player
  ledger on campaigns). The chapter-cap soft warning (Phase C) covers table
  needs meanwhile.
- [ ] **Spreadsheet-style admin + 5e.tools import for TLC** (L) — P3. Adminbook
  CRUD (Phase E) covers operating need; bulk grid UX and importer later.
- [ ] **Companion templates + embedded owner-sheet blocks** (M) — P3.
  `character_companions` exists; TLC companion templates (design doc) are
  additive. Start: template model + embed blocks on Combat/Character tabs.
- [ ] **Change-log/audit of every character mutation** (M) — P3. Design-doc
  requirement (batched per-character log + admin log); needs storage design.
  Not load-bearing for playability.
- ~~**ru/es translations of TLC content**~~ — dropped in v0.5.0.0: the app is
  English-only and the locale infrastructure (ru/es dictionaries, per-user
  provider sublocales) was removed; translating again means restoring i18n first.
- [ ] **Owlbear integration for TLC** (M) — P3. `owlbear` namespace exists for
  other providers; wire tlc after MVP.
- [ ] **Rank-up ceremony UI** (S) — P3. Delight moment on rank promotion;
  after MVP. Rank badge stepper (Phase C/D) is the functional path.
- [ ] **Session-log / auto level suggestions** (M) — P3. Needs campaign session
  tracking (session number → suggested level per the Players Guide table).
  Depends on: XP banks design above.
- [ ] **Publish TLC content via homebrew publications** (M) — P3. Share the TLC
  corpus with other tables through the existing homebrew_publications flow once
  content is verified (all `verified: false` rows cleared).
- [ ] **DESIGN.md via /design-consultation** (S) — P2. No design system file
  exists; Phase 2 review capped Design System alignment at 6/10 without it.
  Run before or alongside Phase D.
- [ ] **Motion spec for tab transitions/toggles** (S) — P3. Litmus check
  "motion improves hierarchy" was NOT SPEC'D; decide during Phase D wireframes.
- [ ] **Encumbrance** (M) — P3. Design doc's own Future list (toggle in options,
  backpack/stored weight rules, Powerful Build interaction). Notes preserved in
  the design doc.
- [ ] **Dice roller** (M) — P3. Design doc's own Future list; explicitly assumed
  physical dice for now.

Effort scale: S/M/L/XL (human team) → with CC+gstack roughly S→S, M→S, L→M, XL→L.

## Deferred from the dev-instance ship (2026-07-23)

- [ ] **Per-env credential files (split RAILS_MASTER_KEY)** (M) — P2. Both Fly
  apps decrypt the ONE credentials.yml.enc, so a compromise of the experimental
  dev app yields the prod DB password, service_role key, and storage keys.
  CREDENTIALS_ENV is a runtime convention, not a security boundary. Fix: Rails
  multi-env credentials (config/credentials/production.yml.enc + its own key),
  each Fly app holding only its own key. Requires re-keying prod secrets.
- [ ] **Replace hardcoded charkeeper.org domain** (S) — P1. Upstream leftover:
  web/base_controller.rb#current_domain and application_helper.rb#root_host
  return 'charkeeper.org' in production, so the cookie-banner cookie is
  rejected on chapterhouse.tools / dev.chapterhouse.tools (Domain mismatch)
  and root_host lies. Fix: host-only cookie (nil domain) + derive root_host
  from request.host. Found by /ship red-team 2026-07-23. Scope is wider than
  the two helpers: charkeeper.org is also hardcoded in the og:url meta
  (layouts/application.html.erb), the SPA API fallback host (helpers/
  apiRequest.jsx, appState.jsx, LoginPage.jsx region), avatar host
  (lib/cache/avatars.rb), and Homebrews links (Equipment.jsx, Feats.jsx,
  HomebrewTab.jsx).
- [ ] **Revoke CREATEDB/CREATEROLE/BYPASSRLS on the PROD chapter role** (S) —
  P2. Dev's role is already least-privilege (revoked 2026-07-23); prod's still
  carries all three. One SQL statement in the prod project, but it is a prod
  action: `ALTER ROLE chapter NOCREATEDB NOCREATEROLE NOBYPASSRLS;`.
