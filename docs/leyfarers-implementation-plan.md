<!-- /autoplan restore point: ~/.gstack/projects/zacgoodwin-Chapterhouse/master-autoplan-restore-20260719-071638.md -->
# Leyfarers (TLC) Implementation Plan

**Status: APPROVED** (2026-07-19, /autoplan final gate — approve as-is;
default landing tab = Combat; session date deliberately TBD).

Turn Chapterhouse (a fork of kortirso/charkeeper) into the Leyfarers app: a D&D 2024
character manager for The Leyfarer's Chronicle (TLC) homebrew campaign, per
`docs/Leyfarers Design Document - v2.md` and `docs/TLC Players Guide v2.10.pdf`.

Digests used to build this plan (committed alongside it):
- `docs/reference/codebase-map.md` — CharKeeper architecture + extension checklist
- `docs/reference/design-doc-digest.md` — full requirements digest of the design doc
- `docs/reference/players-guide-digest.md` — full rules digest of the Players Guide
  (the Phase B seeding reference: homebrew mechanics + data-modeling impact)

## Premises

P1. **Build on the existing stack.** Rails 8.1 + SolidJS + esbuild, in this repo.
    The design doc's Technical Design table (React/Next.js, Node, Supabase — every
    row marked "(?)") is superseded by the codebase the doc itself names as
    "Existing Codebase and inspiration". No rewrite.

P2. **TLC is a new provider, not an edit of dnd2024.** Add STI type
    `Tlc::Character` with provider slug `tlc`, following the established
    extension pattern (`app/platforms/<sys>/`, `app/decorators_v2/`). Rationale:
    keeps stock dnd2024 usable and keeps TLC additive for upstream merges.
    Caveat (CEO voice): this fork is currently at ZERO divergence from upstream —
    "clean merges" is a prediction, not evidence. If upstream tracking doesn't
    matter for a private campaign tool, editing dnd2024 in place is viable and
    smaller. Premise gate decides the posture.

P3. **`TlcDecorator < Dnd2024Decorator`.** TLC is D&D 2024 "latest printing
    wins" with deltas. Subclass the existing v2 decorator and override only the
    deltas (alternate AC formulas, trait-driven senses, rank perks). Do not fork
    the whole engine. Known coupling: breaks loudly on upstream decorator
    refactors — parity spec detects, does not prevent.

P4. **Content is data, shared not copied.** TLC options queries return the union
    of dnd2024 content + TLC-only rows, minus the 8-spell banned list. Nothing
    from the 2024 corpus is duplicated into `db/data/tlc/` — TLC seed files hold
    only TLC-specific content. Grants use the existing JSONB `modifiers`
    (add|set|concat + Dentaku) pattern; master lookup config in
    `CharKeeperApp/data/tlc.json`. This answers the design doc's structured-vs-
    JSON open question with the codebase's existing answer. No new content-schema
    tables in the MVP.

P5. **MVP = the party plays on it.** The measurable outcome: the campaign's
    actual player characters rebuilt in the app and used at the table. Content
    entry is party-first (the species/subclasses/feats the party actually uses),
    full corpus second. PDF export, live share links, offline-first, spreadsheet
    admin, companions overhaul are phased behind that (see NOT in scope).

## What already exists (leverage map)

| Sub-problem | Existing code |
|---|---|
| Multi-system characters | STI `characters.type` + JSONB `data`; `app/platforms/dnd2024/character.rb` |
| Stat calculation | `app/decorators_v2/dnd2024_decorator.rb` (AC L486, skills L520, `all_modifiers` L545) |
| Modifier grants | `feats.modifiers` JSONB `{key:{type:add|set|concat, value:formula}}` + Dentaku `app/lib/formula.rb` |
| Content seeding | `db/data/<sys>/*.json` + `db/seeds.rb` upsert_all |
| Content entry UI (no code) | dnd2024 homebrew: race/subclass/speciality/background via `app/platforms/dnd2024/homebrews/` + HomebrewsApp SPA |
| Per-use resources | `character_feats` (tokens/used_count/limit_refresh), `character_resources`, `custom_resources` |
| Manual overrides | `character_bonus` polymorphic jsonb values |
| Companions | `character_companions` table |
| Creation/leveling flows | `app/builders/<sys>_character/`, `characters_context` commands + dry-validation contracts |
| Frontend per-system sheets | `CharacterTab.jsx` provider `<Switch>`; `pages/Content/Character/<Sys>.jsx` |
| Admin | `adminbook` namespace (HTTP Basic) |
| Campaigns/parties | `campaigns` (provider-scoped) |
| Tests | RSpec (`spec/platforms/`, `spec/decorators_v2/`), FactoryBot, Cypress e2e |

## Implementation alternatives considered

| | A: New `tlc` provider (chosen) | B: Homebrew-only on stock dnd2024 | C: Edit dnd2024 in place |
|---|---|---|---|
| Summary | Subclass Dnd2024 provider + decorator; TLC mechanics as code, content as data | No code; enter TLC content via existing homebrew UI, track rank/rests by hand | TLC fields + logic gated into dnd2024 itself |
| Effort | L (human ~3-4 wks / CC ~2-3 days) | S (content-entry only) | M |
| Risk | Med | Low build risk, high fidelity gap | Med (merge debt if upstream tracking resumes) |
| Completeness | 9/10 | 4/10 — cannot express Leyfarer rank, session rest, choose-3 trait pools, chapter caps, banned-list filtering, alternate AC | 8/10 |
| Reuses | Everything in leverage map | Homebrew subsystem only | Everything, no new provider plumbing |

Chosen: A, because only it covers the design doc's mechanics; B survives as the
Phase A0 spike (validates content entry + is the fallback), C remains open at the
premise gate pending the upstream-tracking decision.

## Work breakdown

### Phase A0 — Validation spikes (before any provider code)

1. **Homebrew-UI spike:** enter one full TLC species (with traits) and one
   subclass through the existing dnd2024 homebrew UI. Output: a written verdict
   on what content can route through homebrew vs what needs `db/data/tlc/` seeds,
   and a per-entity time cost that prices Phase B honestly.
2. **Modifiers expressiveness exercise:** encode the 10 hairiest Players Guide
   traits/features on paper as `modifiers` JSONB (candidates: choose-one AC
   formulas, Con-for-Dex AC, variable attunement, Snail's Pace, Tremorsense,
   Lucky Number, Vial of Sand, rank-scaling Journal queries, Hit-Dice-as-currency
   features, Mixed Ancestry). Any that don't fit add|set|concat + Dentaku get a
   named extension point (new modifier type or decorator override) BEFORE Phase A
   is built. Output: table of trait → encoding → fits/needs-extension.

### Phase A — Provider skeleton (TLC characters exist)

Backend:
- `app/platforms/tlc/character.rb`: `Tlc::CharacterData` (StoreModel; copy dnd2024
  fields + add `leyfarer_rank` int, `leyfarer_focus` string, `selected_traits`
  array, `mixed_species` string/null, `dismissed_warnings` array) and
  `Tlc::Character < Character`.
- `app/platforms/tlc/{feat,item,spell}.rb` STI subclasses.
- `scope :tlc` in `app/models/{character,feat,item,spell}.rb`. **Scoping rule
  (eng finding 2):** `Character.tlc` is STRICT — `Tlc::Character` only, because
  controllers use the provider scope for authorization lookup
  (rest_controller.rb:15 pattern); a union there would let dnd2024 characters
  resolve on tlc endpoints. The union (P4) applies ONLY to content models:
  `Feat.tlc_content` / `Spell.tlc_content` / `Item.tlc_content` =
  `where(type: ['Dnd2024::Feat', 'Tlc::Feat'])` etc., used by options paths.
- `app/decorators_v2/tlc_decorator.rb < Dnd2024Decorator` (initially empty overrides).
- `app/builders/tlc_character/` cloned from dnd2024 builders; level 3 default,
  point-buy only.
- `app/commands/characters_context/tlc/` create/update commands + contracts;
  register in `config/initializers/container.rb`.
- Routes `namespace :tlc` (copy dnd2024 block, config/routes.rb L136-151);
  `app/controllers/frontend/tlc/`; serializer `app/serializers/tlc/character_serializer.rb`
  (`provider` → `"tlc"`); add case in `app/controllers/frontend/characters_controller.rb` L52-72;
  add `tlc` to campaign provider enum (`app/commands/campaigns_context/add_campaign_command.rb` L8).
- `app/services/characters_context/tlc/refresh_feats.rb`.

Frontend:
- `CharKeeperApp/data/tlc.json` — TLC species list + TLC class/subclass deltas;
  2024 baseline read from dnd2024 config, not copied (P4).
- `<Match when={provider === 'tlc'}>` in `pages/Content/CharacterTab.jsx` reusing
  the `<Dnd5>` sheet initially; creation form `pages/Navigation/Characters/Forms/Tlc.jsx`;
  provider name maps (`CampaignsTab.jsx` L183, `ListItem.jsx`); en i18n strings
  (ru/es can lag; keys fall back to en).
- **Provider-family helper (eng finding 9):** `Dnd5.jsx` branches on exact
  `provider === 'dnd2024'` at L102 (craft tab), L145 (druid beastform), L193
  (item upgrades) — `tlc` would silently fall to the dnd5 side of each. Add a
  `isDnd2024Family(provider)` helper (`['dnd2024','tlc']`) and replace the three
  exact checks; grep for other `=== 'dnd2024'` sites in the SPA before merge.
- **Client-side config merge (eng finding 8):** the SPA imports config JSON
  statically (`import dndConfig from '../../data/dnd2024.json'` — Conditions.jsx:5,
  CharactersTab.jsx:10), so the server-side PlatformConfig merge doesn't reach
  the frontend. Add a `data/tlcConfig.js` module that imports dnd2024.json +
  tlc.json and deep-merges at module level; tlc components import that.

Tests: `spec/platforms/tlc/character_spec.rb`, `spec/decorators_v2/tlc_decorator_spec.rb`,
factory, request spec for create.

### Phase B — TLC content (the Players Guide becomes data)

**B1 — Party-first (gates the MVP):** seed only what the campaign's actual party
uses: their 4-6 species (with full trait pools), their subclasses, their feats,
spells, and starting items. Party roster is an input from Zac. Rebuild every
current PC as acceptance test 0.

**B2 — Full corpus backfill:** remaining species (17 total, ~110 traits),
12 subclasses + per-level features, 13 homebrew feats, 8 homebrew spells,
languages, draconic patron lookup, special items (Leyfarer's Journal, Emblem,
Sunshards, Vial of Sand). Extraction is scripted, not hand-typed: a
`bin/extract-tlc-content` script parses `pdftotext -layout` output of the
Players Guide into `db/data/tlc/*.json` with a review diff; garbled tables
(below) are hand-verified.

Shared machinery:
- **Seeds (eng finding 3 — the existing seed file is NOT idempotent):** feats
  seed via `create!` (db/seeds.rb:100-105) and `upsert_all` without `unique_by`
  (db/seeds.rb:23); no unique index exists on feats.slug or spells.slug
  (schema L265, L476 are plain indexes). TLC therefore ships its own
  `rake tlc:seed` task (not a block inside db/seeds.rb) + a migration adding a
  partial unique index on (type, slug) for feats/spells/items scoped to TLC
  types, and seeds with `upsert_all(unique_by:)` against it. Acceptance test 9
  is scoped to `rake tlc:seed`, not the legacy seed file.
- Banned-spell filter: exclusion list (Demiplane, Dream of the Blue Veil,
  Earthquake, Fabricate, Plane Shift, Teleport, Tsunami, Wind Walk) applied in the
  tlc spell options path AND in the grants pipeline: a seed-time lint fails on any
  content row that auto-grants a banned spell unless the row carries an explicit
  `banned_exemption: true`; at runtime an exempted grant still emits a TLC-sourced
  soft warning (never-block). This is the systematic rule that catches the
  Lady of Ivory → Fabricate class of conflict, not just the known instance.
- Species trait system: traits stored as `Tlc::Feat` rows with `origin: :species_trait`
  and modifiers JSONB; character stores `selected_traits`. **Attach semantics
  (eng finding 5):** the inherited `RefreshFeats` auto-attaches EVERYTHING
  matching `origin_value IN (species, ...)` (dnd2024/refresh_feats.rb:60-64) —
  species-keyed trait feats would attach the whole pool, not the chosen 3. The
  TLC refresh service attaches trait feats explicitly from `selected_traits`
  (slug lookup), and the `species_trait` origin int stays OUT of
  `SELECTABLE_ORIGINS` (refresh_feats.rb:24) so deselection actually detaches.
  `mixed_species` is added to the origin-value list so the second species' base
  traits and pool participate. Choose-3 rule (4 with Mixed Ancestry) enforced as
  a soft warning, never a block.
- Unlock gating: `info.unlock` on content rows (`none | chapter_N | reputation |
  special`); options lists label gated content instead of hiding it (never-block
  principle).
- Content-fidelity gate: garbled Players Guide tables (Leyfarer rank perks,
  Frog Knight bands overlap at 15, Roll the Bones placeholder text, Lady of Ivory
  grants banned Fabricate) seed with `verified: false` and require human
  verification against the PDF before merge.

### Phase C — TLC mechanics

- Leyfarer Rank 0-5: `data.leyfarer_rank` + rank-perk feats (`origin: :rank`)
  auto-granted; Focus choice (Explorer/Naturalist/Scholar) at Adept grants skill +
  ritual spell; Journal/Emblem items auto-added at creation. Rank is manually set
  (chapter-driven promotion is campaign bookkeeping, not sheet logic).
- Campaign chapter setting: a `chapter` field on TLC campaigns; drives the
  level-cap table (ch8→12 … ch16→20) soft warning and unlock-gate labels.
- Session-based leveling: leveling stays manual; decorator emits a soft warning
  when level exceeds the campaign chapter cap. XP banks/transfers deferred.
- Session Rest: add `session` to `limit_refresh` enum on `Tlc::Feat` +
  `character_feats` refresh path; rest endpoint accepts `rest_type=session`.
  **Rest-command override (eng finding 1):** the inherited long-rest command
  blanket-resets ALL feats (`feats.update_all(used_count: 0)`,
  make_long_rest_command.rb:38, inherited verbatim by dnd2024) — which would
  refresh session-limited abilities on every long rest. `Tlc::MakeLongRestCommand`
  (and short) excludes `limit_refresh: session` from the reset; only
  `rest_type=session` (or the GM) refreshes those.
- Subclass resources (Rune Priest runes, Divine Code points, Lucky Number, etc.):
  model via existing `character_resources`/`custom_resources` seeded per subclass.
- Decorator overrides in `TlcDecorator`: alternate AC formulas (13+Dex, 13+Con,
  Con-for-Dex, handless shield) selected by trait modifiers; variable attunement
  slots; speed modifiers; Tremorsense/senses from traits; Human multiclass-prereq
  bypass in the multiclass warning check.
  **Species-decorator override (eng finding 4):** `Dnd2024Decorator#call`
  constantizes `Dnd2024::Species::#{species}Decorator` by slug
  (species_decorator.rb:6) — a TLC "dwarf" would double-apply hardcoded 2024
  dwarf logic on top of TLC trait feats. `TlcDecorator` overrides the species
  step: TLC species contribute ONLY via trait feats, never via constantized 2024
  species decorators. Parity spec includes a colliding-slug case (tlc dwarf vs
  2024 dwarf). Same review applies to the class/subclass constantize path
  (class_decorator.rb:14) — TLC subclasses use namespaced slugs.
  **Static-spell override (eng finding 7):** static-spell rendering hardcodes
  `::Dnd2024::Feat.where(origin: 6)` (dnd2024_decorator.rb:204) — TlcDecorator
  widens it to the tlc content union so TLC homebrew static spells render.
- **Spell options path (eng finding 7):** spells are feats (`origin: 6`), and
  seeds move ~60 PHB spell slugs behind a homebrew book user (db/seeds.rb:529-542)
  with `user_id: nil` default scoping (spells_controller.rb:39,45). The TLC
  options query must include the same book machinery (or TLC characters get a
  silently truncated PHB list), use a provider-distinct 12-hour cache key
  (spells_controller.rb:33), and apply the banned-list exclusion after the union.
- Soft-warning engine: decorator computes `warnings` array
  (`{slug, source: PHB|TLC, message_key, dismissible: true}`) — multiclass prereqs,
  trait count, prepared-spell overrun, level-vs-chapter cap; serializer exposes it;
  frontend renders dismissible banners; dismissals persist in `data.dismissed_warnings`.
- **Minimal TLC surface (design finding 1 — MVP must be visible, not just API):**
  Phase C ships a thin UI layer on the interim sheet: rank + Focus badge in the
  sheet header, active-warnings list, a session-rest button on the existing rest
  UI, and a Focus-choice modal that fires when `leyfarer_rank >= 2` and
  `leyfarer_focus` is null. Test 0 asserts these are visible and actionable.

### Phase D — TLC UX layer (design-doc screens)

- `pages/Content/Character/Tlc.jsx` + tabs: Character, Combat, Spells, Inventory,
  **Aptitudes** (feats, languages, weapon/armor proficiency + mastery, tools,
  Intrinsics), **Breaks** (Short/Long/Session rest with per-item toggleable refresh
  summary + level-up entry).
- Intrinsics: `Tlc::Feat` with `kind: :intrinsic`; seeded + addable via homebrew;
  rendered in Aptitudes.
- Conditions/status effects (minimal): a toggleable conditions list on the Combat
  tab; conditions whose mechanics are expressible as modifiers (e.g. exhaustion
  levels) apply via `character_bonus`; the rest render as informational badges.
  ponytail: full effect automation (advantage propagation, per-roll riders) is a
  known ceiling — deferred with the Effects engine (NOT in scope).
- Override affordances: reuse `character_bonus` for value overrides; show
  calculated-vs-overridden indicator (pencil/asterisk) on overridden fields.
- Warnings summary on character overview (list of active rule warnings).

**Phase D design spec (entry gate — from Phase 2 design review):**

- **Wireframes before build:** extract the design doc's embedded mockup images
  (images 2-9, base64 in `Leyfarers Design Document - v2.md` L1291-1306) to
  `~/.gstack/projects/zacgoodwin-Chapterhouse/designs/leyfarers-refs/` and write
  a one-page wireframe per tab from them. No Phase D component is built without
  its wireframe. (No DESIGN.md exists; the design doc's UI/UX section + existing
  CharKeeperApp component vocabulary are the design authority. An interactive
  mockup round — /design-shotgun or /plan-design-review — is recommended before
  Phase D; see final gate.)
- **Default tab + per-tab hierarchy (ordered, constraint-worship 3-first):**
  land on **Combat** (matches existing sheet default and at-the-table use):
  1 HP block (damage/heal steppers), 2 AC + initiative + speed, 3 aggregated
  actions, then conditions, death saves, concentration. **Character**: 1 ability
  scores, 2 skills (with adv/disadv markers), 3 saves; then proficiency/passive
  values. **Spells**: 1 slots, 2 prepared list, 3 DC(s). **Inventory**: 1 equipped,
  2 attunement (n/3), 3 backpack + gold. **Aptitudes**: 1 feats, 2 proficiencies +
  masteries, 3 languages/tools, then Intrinsics. **Breaks**: 1 rest type selector,
  2 refresh confirm-summary, 3 level-up entry.
- **Interaction state matrix** (each cell specified before build; the design doc's
  session-rest "also take a long/short rest?" prompt at v2 L344-347 included):

```
SURFACE            | LOADING        | EMPTY               | ERROR            | SUCCESS               | PARTIAL
-------------------|----------------|---------------------|------------------|------------------------|------------------
Trait picker       | skeleton list  | "0 of 3 selected"   | 422 field errors | "3 of 3" + traits list | "2 of 3" progress
                   |                | + pool by species   |                  |                        | 4th pick = amber warn
Options lists      | skeleton rows  | "content not seeded"| retry banner     | list w/ gate labels    | gated rows labeled
                   |                | + seed hint         |                  | "Ch.4" / "Reputation"  | not hidden
Rest confirm       | n/a (local)    | "nothing to refresh"| txn error banner | per-item checkmarks +  | full resources shown
                   |                |                     | (nothing applied)| toast; session rest    | pre-checked-disabled
                   |                |                     |                  | offers long/short too  |
Warning banners    | n/a            | no banner           | n/a              | stack, newest first,   | dismissed collapse to
                   |                |                     |                  | max 3 + "N more"       | count chip
Conditions         | n/a            | "no active"         | n/a              | mechanical = filled    | informational = outline
                   |                |                     |                  | toggle + stat delta    | badge, no math claim
```

- **Level-up + rank-up flows (the two highest-emotion moments):** level-up
  reuses the existing classLevels flow with named TLC deltas (chapter-cap
  warning, trait/feat prompts at gaining levels); Focus modal fires when
  `leyfarer_rank >= 2 && leyfarer_focus == null` (also reachable from the
  rank badge). Rank is edited from the rank badge (tap → stepper 0-5 with
  rank names Prospect→Director).
- **Warning dismissal re-enable:** character settings gains a "dismissed
  warnings" list with per-item restore (closes the one-way-door gap).
- **Accessibility + responsive:** 390px is the design target (mobile-first per
  design doc); tap targets ≥ 44px (HP steppers, toggles, rest checkboxes);
  warning banners use role="alert" with an accessible dismiss button; trait
  picker and rest summary fully keyboard-navigable; contrast follows the
  existing theme tokens; app-UI hard rules apply (calm surface hierarchy, no
  card mosaics on Aptitudes, utility copy not mood copy).

### Phase E — Admin + homebrew completeness

- `app/controllers/adminbook/tlc/` CRUD for TLC feats/spells/items with visibility
  enum (`public | locked | deprecated | hidden` — resolving the doc's 3-way enum
  disagreement in favor of the 4-value set) and the `verified` flag from Phase B.
- Homebrew: `app/platforms/tlc/homebrews/` (species, subclass, feat) + `homebrews_v2/tlc/`
  controllers + import commands, mirroring dnd2024 homebrew.

Each phase lands as its own PR with green RSpec + one Cypress happy path.
Sequencing vs the MVP: acceptance test 0 gates on A0+A+B1+C only. Phase D is
required for the full design-doc UX but the party can play on the interim sheet;
Phase E is a post-MVP fast-follow and never gates test 0.

## Acceptance tests

0. **Table test:** every current party PC rebuilt in the app and used at a named
   session, with TLC state visible and actionable on the sheet (rank badge,
   warnings list, session-rest button) — not just present in the API. Date:
   deliberately left TBD at the 2026-07-19 gate — Zac sets it once the campaign
   calendar is known; the kill criterion stays unarmed until then. This is the
   P5 outcome.
1. POST create TLC character → 200, `provider: "tlc"`, level 3, point-buy scores.
2. Selecting 3 species traits attaches 3 trait feats; a Dwarf with Tremorsense
   trait shows the sense in the serializer; selecting a 4th trait without Mixed
   Ancestry yields a warning entry, not an error.
3. TLC spell options = dnd2024 spell-feats + 8 homebrew − 8 banned (union test:
   a stock 2024 spell IS visible to a TLC character; a known homebrew-BOOK-gated
   PHB spell from db/seeds.rb:529-542 IS visible; Teleport is NOT).
4. Setting `leyfarer_rank: 2` grants Adept perks and exposes a Focus choice;
   Journal + Emblem exist in inventory from creation.
5. A Gambler character has a Lucky Number resource trackable via character_resources.
6. `rest_type=session` refreshes only `limit_refresh: session` feats — AND the
   inverse: a long rest does NOT reset a session-limited feat (guards eng
   finding 1 against the inherited blanket `update_all`).
7. Multiclassing into Paladin with STR 12 saves successfully and yields a
   PHB-sourced warning; a Human character yields no warning (bypass).
8. TlcDecorator applies 13+Dex AC when the granting trait is selected; base spec
   parity with Dnd2024Decorator for a delta-free character.
9. `rake tlc:seed` twice → identical row counts (idempotent via the new partial
   unique (type, slug) index; scoped to the TLC loader — the legacy seed file is
   known non-idempotent and out of scope).
10. Cypress: create TLC character via wizard → sheet renders with Aptitudes and
    Breaks tabs visible.
11. Toggling a condition with mechanical effect changes the derived stat;
    toggling it off restores the calculated value.
12. Cypress at 390px viewport: Combat tab shows HP, AC, and conditions above the
    fold; all tap targets ≥ 44px (mobile-first is enforced, not asserted).
13. **Regression guard:** stock dnd2024 character create/sheet/rest behave
    identically before and after the TLC merge (shared-file edits: routes,
    characters_controller, CharacterTab.jsx, campaign enum).
14. Deselecting a species trait detaches its feat (removal semantics — guards
    eng finding 5's SELECTABLE_ORIGINS trap).
15. Colliding-slug parity: a TLC "dwarf" gets NO 2024 species-decorator effects,
    only its selected trait feats (guards eng finding 4).
16. Mixed Ancestry: second species' trait pool selectable, 4 traits attach, and
    both species' base traits participate (guards eng finding 5's
    mixed_species omission).
17. Decorator parity spec runs the dnd2024 50-sample randomized suite
    (dnd2024_decorator_spec.rb:71 pattern) with a PINNED seed against both
    decorators for a delta-free character — unpinned randomization proves
    nothing.

## NOT in scope (deferred, with rationale)

- **Full Effects/automation engine** — the design doc's Effects sections are
  empty headers; there is no spec to build. Minimal conditions (Phase D) covers
  table needs; per-roll automation waits for a real design. TODOS.md.
- **PDF export, live share links, offline-first/autosave-queue** — design-doc
  features orthogonal to the TLC system; each is its own project. TODOS.md.
- **XP banks / transfers / retirement refunds** — campaign bookkeeping across
  players; needs campaign-level design. TODOS.md.
- **Spreadsheet-style admin & 5e.tools import for TLC** — adminbook CRUD (Phase E)
  covers operating need; bulk UX later.
- **Companion templates overhaul** — `character_companions` exists; TLC companion
  templates + embedded blocks are additive later work.
- **Encumbrance, dice roller** — design doc's own Future list.
- **Change-log/audit of every mutation** — design-doc requirement needing its own
  storage design; not load-bearing for playability. TODOS.md.
- **ru/es translations of TLC content** — en-only at seed time; i18n keys in place.
- Expansion candidates deferred to TODOS.md: Owlbear integration for TLC,
  rank-up ceremony UI, session-log/level suggestions, publishing TLC content via
  homebrew publications.

## Resolved design-doc questions

- Structured vs JSON grants → JSONB `modifiers` on content rows (existing pattern), P4.
- Visibility enum 3-way disagreement → `public|locked|deprecated|hidden`.
- Rest: modal vs tab → Breaks tab with confirm-summary (matches component tree).
- "Aptitudes/Breaks" absent from Players Guide → they are app tab names, not rules.
- Effects system unspecified → minimal conditions now, engine deferred (explicit).

## Risks / failure modes / kill criterion

- **Garbled source tables** (rank perks, Frog Knight, Roll the Bones, Lady of
  Ivory/Fabricate) → seeded `verified: false`, human check before merge.
- **Dentaku formula errors** on new TLC modifiers → decorator spec per formula
  family; formula lint spec iterating all seeded modifiers.
- **Upstream merge drift** → TLC kept additive; the only shared-file edits are
  enumerated (routes, characters_controller case, campaign enum, CharacterTab
  switch, provider maps). Posture confirmed at premise gate.
- **`<Dnd5>` sheet reuse hides TLC fields in Phase A** → acceptable scaffolding;
  Phase D replaces it; tracked so it can't silently ship as final.
- **StoreModel schema drift** between Tlc::CharacterData and dnd2024 upstream
  changes → parity spec comparing attribute sets.
- **Content-entry stall (the real schedule risk)** → B1 party-first ordering +
  scripted extraction; homebrew-UI spike prices entry cost before commitment.
- **Kill criterion:** if acceptance test 0 isn't achievable by the session date
  (TBD — set at the final gate), fall back to stock dnd2024 + homebrew content +
  paper tracking for TLC mechanics, and re-plan.

## Phase 1 — CEO Review Outputs (/autoplan, 2026-07-19)

Premise gate: P1/P3/P4/P5 confirmed; P2 confirmed as Approach A (new `tlc`
provider) by Zac. Mode: SELECTIVE EXPANSION. Voices: [subagent-only] — Codex CLI
not installed.

### Architecture (Section 1)

```
SolidJS SPA                                   Rails API
-----------                                   ---------
CharacterTab.jsx --Switch provider--> frontend/tlc/* controllers
  |                                        |            \
  v                                        v             v
Tlc.jsx (Phase D; <Dnd5> interim)   characters_context/tlc   serializers/tlc/
  tabs: Character Combat Spells      commands + contracts    character_serializer
        Inventory Aptitudes Breaks         |                      |
                                           v                      v
data/tlc.json --base-merge--> PlatformConfig    Tlc::Character (STI, JSONB data)
     ^                                                |
     | (dnd2024.json as base)                         v
                                        TlcDecorator < Dnd2024Decorator
                                                      |
                                 all_modifiers <- character_feats (incl. trait
                                 feats origin=species_trait) + character_items
                                 + character_bonus
                                                      |
                        content rows: (Dnd2024::* UNION Tlc::*) feats/spells/items
                                       minus banned-spell list
```

Findings resolved into the plan (auto-decided, logged in audit trail):
- `data/tlc.json` composes with dnd2024 config via a `base: dnd2024` deep-merge
  in `app/lib/platform_config.rb` — one explicit merge point, no copied config.
- Decorator coupling to upstream accepted (premise P3); parity spec is the alarm.
- Warning-dismissal state: `data.dismissed_warnings` holds warning slugs;
  a dismissed slug stays dismissed until the user re-enables it in settings.
  ponytail: no context-hash re-arming (a dismissed multiclass warning stays
  dismissed even if a new multiclass repeats the violation); upgrade path is
  slug+context keys.
- Rest apply (Breaks confirm-summary) is a single transaction: all toggled
  refresh actions commit or none do; hit-dice spends inside rest are guarded
  against double-submit by comparing sent state to current state.
- Rollback posture: additive provider; revert PR restores stock behavior. The
  only migration (campaigns.chapter, nullable) is backward compatible and can
  remain through a rollback.
- Scaling: private-table scale (~6 players); nothing breaks at 10x. Union
  options query must be a single `type IN (...)` query (see Performance).
- No feature flag: solo self-hosted deployment; tlc is invisible until a tlc
  character is created. Dark-ship by construction.

### Error & Rescue Registry (Section 2)

```
METHOD/CODEPATH                    | WHAT CAN GO WRONG                  | EXCEPTION CLASS
-----------------------------------|------------------------------------|------------------
TlcDecorator modifier application  | Seeded/homebrew formula invalid    | Dentaku::ParseError,
                                   |                                    | Dentaku::UnboundVariableError
Seeds loader (db/data/tlc)         | Malformed JSON file                | JSON::ParserError
Seeds loader                       | Duplicate slug on upsert           | ActiveRecord::RecordNotUnique
bin/extract-tlc-content            | pdftotext missing / layout drift   | Errno::ENOENT / parse mismatch
characters_context/tlc create      | Invalid species/trait slug         | Dry::Validation failure
Tlc refresh_feats                  | selected_trait row deleted         | (lookup miss, no raise)
Rest endpoint (rest_type=session)  | Unknown rest_type                  | Dry::Validation failure
Options union query                | dnd2024 content unseeded           | (empty result, no raise)

EXCEPTION CLASS                | RESCUED? | RESCUE ACTION                        | USER SEES
-------------------------------|----------|--------------------------------------|-----------------
Dentaku::ParseError/Unbound    | Y (new)  | Log slug+formula+character, skip     | Stat without that
                               |          | that modifier only                   | modifier + log trail
JSON::ParserError (seeds)      | N (ok)   | Abort seed task loudly               | Dev sees stacktrace
RecordNotUnique (seeds)        | Y        | upsert_all(unique_by:) on the NEW    | Nothing (idempotent)
                               |          | partial (type,slug) index — created  |
                               |          | by this plan's migration (eng F3:    |
                               |          | no such index exists today)          |
ENOENT (extract script)        | Y (new)  | Exit 1 with install hint             | Dev sees message
Dry::Validation (create/rest)  | Y        | 422 with error keys (existing)       | Field-level errors
Trait row deleted              | Y (new)  | Skip + emit TLC-sourced warning      | "Trait unavailable"
                               |          |                                      | warning banner
Empty union (unseeded env)     | Y        | Options list renders empty state     | Empty-state message
```

No CRITICAL GAPS remain: every failure path is rescued-with-log, loud-by-design,
or a validation rejection. The two gaps found (silent Dentaku 500, silent
deleted-trait skip) were closed by auto-decisions 13 and 15.

### Security & Threat Model (Section 3)

| Threat | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `eval_variables` (Ruby eval on feats) reachable from homebrew input | Low | High | Spec asserting homebrew import commands never persist eval_variables (TLC + dnd2024 paths); TLC homebrew contracts omit the field entirely |
| Cross-provider slug injection (tlc character selecting non-TLC feat/trait slugs) | Med | Med | Contract validates slugs against the tlc union scope, not global feats |
| Unbounded selected_traits array in JSONB | Low | Low | Contract caps array length (10) and dedupes |
| IDOR on new tlc endpoints | Low | High | Same action_policy character-ownership policies as dnd2024; request spec proves character of user B returns 404 for user A |

Dentaku formulas are data-driven but sandboxed (no arbitrary code); homebrew-
authored modifiers reuse the upstream-vetted path. No new secrets, no new gems,
no PII classes. Adminbook TLC CRUD inherits HTTP Basic + existing audit posture.

### Data Flow & Interaction Edge Cases (Section 4)

Trait selection flow (the load-bearing new flow):
```
selected_traits[] -> contract validate -> persist data -> refresh_feats -> decorator
   | nil: defaults []   | unknown slug: 422    | txn        | batch upsert   | warnings
   | empty: soft warn   | >cap(10): 422        |            | missing row:   |  recompute
   | dup: deduped       | >3 chosen: SOFT WARN |            |  skip + warn   |
   | wrong type: 422    |   (never block)      |            |                |
```
Distinction encoded: *nonexistent* slug = validation error (reject);
*rule-breaking but real* selection = soft warning (never block).

Interaction edge cases: double-click create (existing builder idempotency reused
— verified in request spec); navigate away mid-wizard (builder draft state,
existing behavior); rest double-apply (idempotent for refreshes — set-to-limit;
hit-dice spends guarded, see Section 1); stale sheet after admin content edit
(SPA refetch on focus — existing behavior, noted, not expanded); options list
zero results (empty state with "content not seeded" hint).

### Code Quality (Section 5)

- Cloned command/controller set follows the codebase's own per-system
  convention — DRY tension accepted deliberately (matching upstream pattern
  beats inventing an abstraction upstream doesn't have).
- AC choose-one formulas: decorator computes all applicable AC formulas and
  takes the max (matches player-optimal 5e reading). ponytail: no manual AC-mode
  picker; upgrade path is `data.ac_mode`.
- Warning slugs come from a single registry constant (`Tlc::Warnings::SLUGS`) so
  frontend i18n keys and dismissal storage can't drift.
- No method may exceed 5 branches in TlcDecorator overrides; AC selection is a
  formula table, not an if-chain.

### Test Review (Section 6)

```
NEW UX FLOWS: tlc creation wizard (trait picker), Aptitudes tab, Breaks tab
  (short/long/session), conditions toggles, warning banners + dismissal,
  rank/focus setting, campaign chapter setting
NEW DATA FLOWS: trait selection -> feats; union options; banned filter;
  session refresh; rank perk grant; chapter-cap warning
NEW CODEPATHS: TlcDecorator overrides (AC formulas, senses, attunement, speed,
  human bypass), Formula rescue path, seeds loader, extraction script
NEW JOBS/INTEGRATIONS: none (pdftotext is dev-time only)
NEW ERROR PATHS: Dentaku rescue, deleted-trait skip, contract rejections
```
Coverage: acceptance tests 0-11 (plan body) + unit specs per decorator override
family. The 2am-Friday test: **formula lint spec** — iterate every seeded TLC
modifier, parse and evaluate against a fixture character; fails on any
unparseable or unbound formula. Hostile-QA test: cross-provider slug injection
(Section 3). Chaos test: delete a selected trait's content row, assert sheet
renders with warning instead of 500. No LLM surface → no eval suites required;
gate tests only. Flakiness: none of the new tests depend on time, randomness,
or external services.

### Performance (Section 7)

- Union options query: single query, `type IN ('Dnd2024::Feat','Tlc::Feat')`;
  verify index covering (type) or (type, slug) exists in schema before Phase A
  lands — add if missing (additive migration).
- refresh_feats: batch upsert of trait feats (one query), not per-trait writes.
- PlatformConfig JSON: confirm existing memoization covers the tlc base-merge
  (compute once per boot, not per request).
- Decorator cost: +3-4 trait feat rows per character through the existing
  all_modifiers path — negligible at table scale.

### Observability (Section 8)

- Modifier-eval failure log line: slug, formula, character id, provider — the
  one log that matters; SolidErrors (already mounted) catches anything raised.
- Seed task prints per-type counts + `verified: false` count on every run.
- Runbook (README section): formula failure triage = grep log for slug → fix
  JSON → re-seed; content re-verification = adminbook filter on verified:false.
- Deliberately no new dashboards/alerts: solo self-hosted, SolidErrors + logs
  suffice. Named as a decision, not an omission.

### Deployment & Rollout (Section 9)

- Two migrations, both additive and zero-downtime: `campaigns.chapter`
  (nullable integer) and the partial unique (type, slug) index on
  feats/spells/items scoped to TLC types (for idempotent `rake tlc:seed`).
  Migrate before deploy. The read-path (type) index already exists
  (schema L266 `index_feats_on_type` — verified, no migration needed).
- No feature flag (see Section 1). Rollout order per phase PR: migrate → deploy
  → seed. Seeds are idempotent so re-running is safe.
- Post-deploy check (first 5 minutes): create a tlc character in production,
  open sheet, run a session rest. Smoke = acceptance test 1 against prod.
- Old/new code window: additive routes and STI types are invisible to old
  frontend bundles; no mixed-version breakage.

### Long-Term Trajectory (Section 10)

Reversibility: 4/5 (additive provider; removal = delete rows by type + delete
dirs + revert enumerated shared-file edits). Debt introduced, all tracked:
interim `<Dnd5>` sheet reuse (Phase D replaces), minimal-conditions ceiling
(ponytail), en-only content, `verified:false` rows pending human check.
Ecosystem fit: uses upstream's own extension pattern — a future upstream
"add a system" refactor maps directly. Docs: README gains a TLC provider +
content pipeline section (Phase B deliverable). 1-year read: plan + digests +
decision log make the why recoverable.

### Design & UX (Section 11 — CEO-level; deep review in Phase 2)

Tab structure and names come from the design doc (Aptitudes, Breaks). State
coverage to verify in Phase 2: warning banner states (active/dismissed/empty),
options-list loading/empty, rest confirm partial-toggle state. AI-slop risk:
the interim `<Dnd5>` sheet is generic by definition — flagged so Phase D can't
silently become final. No DESIGN.md in repo: the design doc's UI/UX section is
the design authority. Mobile-first is a design-doc requirement — Phase 2 checks
the SPA's existing responsive behavior against it.

### Dream state delta

```
CURRENT STATE                THIS PLAN                    12-MONTH IDEAL
Stock CharKeeper fork;       TLC provider + party         Full TLC corpus admin-
TLC campaign on paper/PDF -> content + rank/rests/    ->  managed; companions,
                             warnings/tabs; party         share links, PDF export;
                             plays on the app             generic pieces upstreamed
```
This plan lands the load-bearing half of the ideal (system + mechanics + party
content); the ideal's remainder is enumerated in NOT-in-scope with owners
(TODOS.md), none of it blocked by this plan's architecture.

### CEO Dual Voices — Consensus Table

```
CEO DUAL VOICES — CONSENSUS TABLE:                       [subagent-only]
=================================================================
  Dimension                             Claude subagent  Codex   Consensus
  ------------------------------------- ---------------  ------  ---------
  1. Premises valid?                    Challenged P2/P4  N/A    Resolved at gate
  2. Right problem to solve?            Yes, w/ spike     N/A    CONFIRMED (w/ A0)
  3. Scope calibration correct?         B split needed    N/A    CONFIRMED (amended)
  4. Alternatives sufficiently explored? No -> added       N/A    CONFIRMED (amended)
  5. Competitive/market risks covered?  Kill criterion    N/A    CONFIRMED (amended)
  6. 6-month trajectory sound?          Content-entry     N/A    CONFIRMED (amended)
                                        risk flagged
=================================================================
Codex unavailable (CLI not installed) — single-voice, findings absorbed as plan
amendments before the premise gate; no open disagreements remain.
```

### Implementation Tasks (Phase 1 — CEO review)

- [ ] **T1 (P1, human: ~2d / CC: ~1h)** — content-pipeline — Run Phase A0 spikes (homebrew UI entry + 10-trait modifier encoding) and record verdicts in the plan
  - Surfaced by: CEO voice findings 1 & 3 — zero-build baseline unpriced; modifier expressiveness unproven
  - Files: docs/leyfarers-implementation-plan.md (verdict tables), scratch homebrew records
  - Verify: verdict tables filled; each of 10 traits marked fits/needs-extension
- [ ] **T2 (P1, human: ~1d / CC: ~30min)** — backend — PlatformConfig base-merge so data/tlc.json extends dnd2024 config
  - Surfaced by: Section 1 — config composition point undefined
  - Files: app/lib/platform_config.rb, app/javascript/applications/CharKeeperApp/data/tlc.json
  - Verify: PlatformConfig.data('tlc') returns merged hash; spec covers override + inherit cases
- [ ] **T3 (P1, human: ~1d / CC: ~30min)** — backend — Dentaku rescue-and-log in modifier application + formula lint spec over all seeded TLC modifiers
  - Surfaced by: Section 2 — silent 500 on bad formula was a CRITICAL GAP
  - Files: app/lib/formula.rb (or TlcDecorator wrapper), spec/decorators_v2/tlc_formula_lint_spec.rb
  - Verify: bad formula in fixture → stat renders without modifier, log line emitted, lint spec fails on unparseable seed
- [ ] **T4 (P1, human: ~4h / CC: ~15min)** — security — Contract-level slug scoping + eval_variables exclusion specs
  - Surfaced by: Section 3 — cross-provider slug injection; Ruby-eval field reachable in theory
  - Files: app/commands/characters_context/tlc/*, spec/commands/..., spec/platforms/tlc/homebrews/*
  - Verify: selecting a Daggerheart slug → 422; homebrew-created feat has eval_variables nil
- [ ] **T5 (P2, human: ~4h / CC: ~15min)** — backend — Rest apply as single transaction with double-submit guard on hit-dice spends
  - Surfaced by: Section 4 — rest double-apply partial-state edge
  - Files: app/commands/characters_context/tlc/rest_command.rb (new), request spec
  - Verify: concurrent double POST leaves state as single application
- [ ] **T6 (P2, human: ~2h / CC: ~10min)** — db — Verify/add (type) index for union options query
  - Surfaced by: Section 7 — union query index unverified
  - Files: db/schema.rb check; optional additive migration
  - Verify: EXPLAIN shows index scan on options query
- [ ] **T7 (P3, human: ~2h / CC: ~10min)** — docs — README section: TLC provider, content pipeline, formula-failure runbook
  - Surfaced by: Sections 8/10 — knowledge concentration
  - Files: README.md
  - Verify: section exists and names the triage steps

## Phase 1 Completion Summary

```
+====================================================================+
|            MEGA PLAN REVIEW — COMPLETION SUMMARY (CEO)             |
+====================================================================+
| Mode selected        | SELECTIVE EXPANSION (auto, /autoplan)       |
| System Audit         | 0 divergence from upstream; homebrew churn  |
| Step 0               | Premises confirmed at gate; Approach A      |
| Section 1  (Arch)    | 7 findings, all resolved into plan          |
| Section 2  (Errors)  | 8 error paths mapped, 2 GAPS closed         |
| Section 3  (Security)| 4 findings, 1 High (mitigated via T4)       |
| Section 4  (Data/UX) | 12 edge cases mapped, 0 unhandled remain    |
| Section 5  (Quality) | 4 findings, resolved (2 ponytail ceilings)  |
| Section 6  (Tests)   | Diagram produced, 3 gaps -> tests added     |
| Section 7  (Perf)    | 3 findings -> T6 + batch + memo checks      |
| Section 8  (Observ)  | 3 additions; no-dashboards named decision   |
| Section 9  (Deploy)  | 1 migration, additive; no flag (named)      |
| Section 10 (Future)  | Reversibility: 4/5, debt items: 4 (tracked) |
| Section 11 (Design)  | 4 notes -> Phase 2 deep review              |
+--------------------------------------------------------------------+
| NOT in scope         | written (9 items + 4 expansion deferrals)   |
| What already exists  | written (13-row leverage map)               |
| Dream state delta    | written                                     |
| Error/rescue registry| 8 methods, 0 CRITICAL GAPS remaining        |
| Failure modes        | see Risks section, 0 CRITICAL GAPS          |
| TODOS.md updates     | 13 items queued (auto-write in Phase 3)     |
| Scope proposals      | 9 proposed, 5 accepted, 4 deferred          |
| CEO plan             | written (~/.gstack/.../ceo-plans/)          |
| Outside voice        | subagent-only (Codex not installed)         |
| Lake Score           | 9/9 recommendations chose complete option   |
| Diagrams produced    | 3 (architecture, trait data flow, dream)    |
| Unresolved decisions | 1 (session date for test 0 — final gate)    |
+====================================================================+
```

## Phase 2 — Design Review Outputs (/autoplan, 2026-07-19)

Voices: [subagent-only] — Codex unavailable. Interactive mockup/comparison-board
loop skipped by /autoplan design (mid-pipeline human feedback session);
recommended as a pre-Phase-D step at the final gate. Design authority: design
doc UI/UX section + existing CharKeeperApp component vocabulary (no DESIGN.md —
/design-consultation queued to TODOS.md).

### Step 0 — Design scope assessment

Initial design completeness: **4/10** — the plan specified error paths and tab
names but no per-tab hierarchy, no state matrix, no responsive enforcement, and
its MVP gate could pass with TLC state invisible on the interim sheet. A 10 for
this plan = every new surface has an ordered hierarchy, a five-state spec, a
wireframe traceable to the design doc's own mockups, and mobile-first proven by
a viewport test. Focus areas: all 7 passes (auto-decided, P1).

### Design subagent findings → resolutions

1. MVP gate passable with TLC invisible (critical) → minimal TLC surface moved
   into Phase C; test 0 amended to require visible, actionable TLC state.
2. Mobile-first asserted not enforced (critical) → acceptance test 12 (Cypress
   390px, above-the-fold Combat, 44px targets). Existing sheet is desktop-first
   with a >=1152px breakpoint (Dnd5.jsx L106-107) — named in Phase D spec.
3. No per-tab information hierarchy (critical) → ordered per-tab hierarchy +
   default-tab decision added to Phase D spec (land on Combat — TASTE, gate).
4. Missing states on every new surface (high) → interaction state matrix added
   as Phase D entry gate, incl. the design doc's session-rest prompt (L344-347).
5. Journey breaks at level-up/rank-up (high) → level-up = classLevels flow +
   named TLC deltas; Focus modal on rank>=2 && focus null; rank badge stepper.
6. Warning dismissal one-way (medium) → dismissed-warnings restore list in
   character settings.
7. Phase D generic patterns (medium) → wireframes-from-mockups entry gate
   (design doc images 2-9), no component built without its wireframe.

### Pass ratings (before → after fixes)

| Pass | Before | After | What closed the gap |
|---|---|---|---|
| 1 Info architecture | 3 | 8 | Per-tab ordered hierarchy + default tab + nav flow |
| 2 Interaction states | 4 | 8 | Five-state matrix per surface |
| 3 Journey/emotional arc | 5 | 8 | Level-up/rank-up/Focus flows specified |
| 4 AI slop risk | 6 | 8 | App-UI hard rules + wireframe entry gate |
| 5 Design system | 4 | 6 | Authority named; no DESIGN.md (deferred, TODOS) |
| 6 Responsive/a11y | 2 | 8 | 390px test, 44px targets, role=alert, keyboard nav |
| 7 Unresolved decisions | — | 6 resolved, 1 taste (default tab) | |

Overall: **4/10 → 8/10.** Pass 5 stays 6 until /design-consultation produces a
DESIGN.md (deliberate deferral, not an oversight).

### Design litmus scorecard (app-UI classification)

```
DESIGN OUTSIDE VOICES — LITMUS SCORECARD:                 [subagent-only]
================================================================
  Check                                    Claude   Codex   Consensus
  ---------------------------------------  -------  ------  ---------
  1. Product unmistakable in first screen?  YES      N/A    CONFIRMED (sheet = product)
  2. One strong visual anchor?              YES*     N/A    HP block per Phase D spec
  3. Scannable by headlines only?           YES*     N/A    After hierarchy fix
  4. Each section has one job?              YES      N/A    One-job-per-tab structure
  5. Cards actually necessary?              FLAGGED  N/A    No card mosaics on Aptitudes (rule)
  6. Motion improves hierarchy?             NOT SPEC N/A    Deferred to wireframes
  7. Premium without decorative shadows?    YES      N/A    Inherits existing calm theme
  Hard rejections triggered:                0        N/A    —
================================================================
* = after Phase 2 fixes. Codex column N/A throughout (CLI not installed).
```

### Implementation Tasks (Phase 2 — design review)

- [ ] **T8 (P1, human: ~1d / CC: ~1h)** — frontend — Minimal TLC surface in Phase C (rank/Focus badge, warnings list, session-rest button, Focus modal)
  - Surfaced by: design finding 1 — MVP gate passable with TLC invisible
  - Files: pages/Content/Character/ (interim sheet extensions), serializer fields already planned
  - Verify: amended acceptance test 0
- [ ] **T9 (P1, human: ~4h / CC: ~20min)** — e2e — Cypress 390px mobile test (above-the-fold Combat, 44px targets)
  - Surfaced by: design finding 2 — mobile-first asserted, never enforced
  - Files: spec/e2e/cypress/e2e/tlc_mobile.cy.js
  - Verify: acceptance test 12 green
- [ ] **T10 (P1, human: ~1d / CC: ~30min)** — design — Extract design-doc mockup images 2-9; one-page wireframe per tab before any Phase D build
  - Surfaced by: design finding 7 — Phase D was generic patterns
  - Files: ~/.gstack/projects/zacgoodwin-Chapterhouse/designs/leyfarers-refs/
  - Verify: wireframe exists per tab; each Phase D PR links its wireframe
- [ ] **T11 (P2, human: ~4h / CC: ~15min)** — frontend — Dismissed-warnings restore list in character settings
  - Surfaced by: design finding 6 — dismissal was a one-way door
  - Files: character settings component (Phase D)
  - Verify: dismiss → restore → warning reappears
- [ ] **T12 (P2, human: ~2h / CC: ~10min)** — frontend — State matrix implementation checks (empty/loading/partial per surface)
  - Surfaced by: design finding 4 — states unspecified
  - Files: Phase D components per matrix
  - Verify: each surface demonstrates its five states in Cypress or story-level checks

## Phase 2 Completion Summary

```
+====================================================================+
|         DESIGN PLAN REVIEW — COMPLETION SUMMARY                    |
+====================================================================+
| System Audit         | No DESIGN.md; UI scope = 6 tabs + wizard    |
| Step 0               | 4/10 initial; all 7 passes (auto)           |
| Pass 1  (Info Arch)  | 3/10 → 8/10                                 |
| Pass 2  (States)     | 4/10 → 8/10                                 |
| Pass 3  (Journey)    | 5/10 → 8/10                                 |
| Pass 4  (AI Slop)    | 6/10 → 8/10                                 |
| Pass 5  (Design Sys) | 4/10 → 6/10 (no DESIGN.md — deferred)       |
| Pass 6  (Responsive) | 2/10 → 8/10                                 |
| Pass 7  (Decisions)  | 6 resolved, 1 taste → final gate            |
+--------------------------------------------------------------------+
| NOT in scope         | unchanged (design deferrals added to TODOS) |
| What already exists  | existing sheet vocabulary named as authority|
| TODOS.md updates     | +2 (design-consultation, motion spec)       |
| Approved Mockups     | 0 generated (loop deferred to pre-Phase-D)  |
| Decisions made       | 7 added to plan                             |
| Decisions deferred   | 1 (default landing tab — taste, at gate)    |
| Overall design score | 4/10 → 8/10                                 |
+====================================================================+
```

## Phase 3 — Eng Review Outputs (/autoplan, 2026-07-19)

Voices: [subagent-only] — Codex unavailable. The independent eng subagent
verified claims against actual code (43 tool calls); every finding below
carries file:line evidence.

### Step 0 — Scope challenge

Complexity check triggers by design (new provider ≈ 30+ files) — accepted at
the premise gate (D2 = Approach A), not re-litigated. Minimum MVP set confirmed
as A0+A+B1+C. Search check [Layer 1]: STI, Rails enums, Dentaku, upsert_all,
Rails.cache — all existing built-ins; no new infrastructure, no innovation
tokens spent. Distribution check: no new artifact types (existing Capistrano
deploy). TODOS.md created (17 items, all cross-referenced). Verified directly:
`index_feats_on_type` exists (schema L266); PlatformConfig caches via
`Rails.cache.fetch(provider/version, 3.days)` (platform_config.rb:6) — TLC
config changes need a version bump or cache clear (runbook line added to T7).

### Eng subagent findings → resolutions (all absorbed as plan amendments)

1. **[P1] (9/10) Long rest wipes session feats** (make_long_rest_command.rb:38)
   → Tlc rest-command override excludes `limit_refresh: session`; test 6 gained
   the inverse assertion. The plan's own test 6 had enshrined the bug.
2. **[P1] (9/10) `Character.tlc` union breaks endpoint scoping**
   (rest_controller.rb:15) → scoping rule split: strict for Character, union
   for content models only. The plan's Phase A wording shipped the bug.
3. **[P1] (9/10) Seeds not idempotent; claimed unique index doesn't exist**
   (db/seeds.rb:23,100-105; schema L265) → dedicated `rake tlc:seed` +
   partial unique (type,slug) index migration; test 9 rescoped; error registry
   corrected.
4. **[P1] (9/10) Species-decorator constantize double-applies 2024 logic**
   (species_decorator.rb:6) → TlcDecorator overrides the species step; TLC
   subclass slugs namespaced; test 15 added.
5. **[P1] (9/10) refresh_feats auto-attaches whole trait pool; deselection trap**
   (dnd2024/refresh_feats.rb:60-64; refresh_feats.rb:24) → explicit attach from
   selected_traits; species_trait origin kept out of SELECTABLE_ORIGINS;
   mixed_species added to origin list; tests 14 & 16 added.
6. **[P2] (9/10) Second eval'd field + adminbook raw eval surface**
   (dnd2024_decorator.rb:396-398,445-449; adminbook/feats_controller.rb:50) →
   T4 widened to both eval fields; Phase E admin CRUD excludes eval fields from
   TLC forms (seed-only, RCE-by-design surface documented).
7. **[P2] (9/10) Spells are feats; ~60 PHB spells homebrew-book-gated; cache
   key; static-spell hardcode** (spells_controller.rb:33,39,45; seeds.rb:529-542;
   dnd2024_decorator.rb:204) → spell options path spec'd (book machinery,
   provider-distinct cache key, post-union ban filter); static-spell override;
   test 3 strengthened.
8. **[P2] (9/10) Config merge server-only** (Conditions.jsx:5) → client-side
   `data/tlcConfig.js` deep-merge module added to Phase A.
9. **[P2] (9/10) Dnd5.jsx exact-provider checks misroute tlc** (Dnd5.jsx
   L102,L145,L193) → `isDnd2024Family()` helper + pre-merge grep sweep.
10. **[P2] (8/10) Missing tests** → tests 13-17 added (regression guard,
    deselect-detach, colliding slug, Mixed Ancestry, pinned-seed parity).

### Eng consensus table

```
ENG DUAL VOICES — CONSENSUS TABLE:                       [subagent-only]
=================================================================
  Dimension                        Claude subagent        Codex  Consensus
  -------------------------------- ---------------------  -----  ---------
  1. Architecture sound?           Sound after F2/F4/F5   N/A    CONFIRMED (amended)
  2. Test coverage sufficient?     No -> tests 13-17      N/A    CONFIRMED (amended)
  3. Performance risks addressed?  Index verified; cache  N/A    CONFIRMED
                                   keys flagged (F7)
  4. Security threats covered?     Widened (F6: 2nd eval  N/A    CONFIRMED (amended)
                                   field, adminbook)
  5. Error paths handled?          Registry corrected F3  N/A    CONFIRMED (amended)
  6. Deployment risk manageable?   2 additive migrations  N/A    CONFIRMED
=================================================================
Codex unavailable — single-voice; all findings absorbed, none open.
```

### Test coverage diagram (planned paths → planned tests)

```
CODE PATHS                                       USER FLOWS
[+] Tlc rest commands                            [+] Create TLC character
  ├── session refresh only session feats  T6       ├── wizard e2e            T10(cy)
  ├── long rest EXCLUDES session feats    T6inv    ├── trait picker 3-of-3   T2
  └── atomic apply / double-submit        T5*      └── 4th trait soft warn   T2
[+] TlcDecorator                                 [+] Play a session
  ├── parity (pinned-seed 50-sample)      T17      ├── session rest visible  T0
  ├── colliding species slug              T15      ├── condition toggle      T11
  ├── alt AC formula from trait           T8       └── mobile 390px          T12
  └── Dentaku rescue (bad formula)        T3*     [+] Level/rank
[+] Content pipeline                               ├── rank 2 -> Focus modal T4
  ├── tlc:seed idempotent                 T9       └── chapter-cap warning   (C)
  ├── formula lint (all modifiers)        T3*     [+] Regression
  ├── banned-grant seed lint              (B)      └── stock dnd2024 flows   T13
  ├── book-gated PHB spell visible        T3
  └── deselect detaches trait             T14
[+] Mixed Ancestry (2 species/4 traits)   T16
[+] Cross-provider slug injection 422     T4*
COVERAGE: every planned codepath has a named test before build (T* = task IDs
from earlier phases; Tn = acceptance tests). No REGRESSION-rule violations:
shared-file edits are guarded by test 13.
```

Test plan artifact written:
`~/.gstack/projects/zacgoodwin-Chapterhouse/zacgo-master-eng-review-test-plan-20260719-081500.md`
(consumed by /qa and /qa-only).

### Worktree parallelization strategy

| Step | Modules touched | Depends on |
|---|---|---|
| A0 spikes | homebrew UI (no code), paper exercise | — |
| A backend skeleton | app/platforms/tlc, decorators_v2, commands, routes/serializers | A0 |
| A frontend wiring | CharKeeperApp (CharacterTab, Forms, config merge) | A backend (serializer) |
| B1/B2 content + extraction | bin/, db/data/tlc, rake task, migration | A0 (verdicts); seeds need A models |
| C mechanics | decorators_v2, commands (rest), services | A backend |
| C minimal TLC surface | CharKeeperApp | A frontend + C mechanics |
| D UX layer | CharKeeperApp pages/Content/Character/Tlc | C + T10 wireframes |
| E admin/homebrew | adminbook, homebrews_v2, platforms/tlc/homebrews | B content model |

Lanes: **Lane 1** A0 → A-backend → C-mechanics (sequential, shared decorators/
commands). **Lane 2** content extraction script + JSON authoring (independent
after A0; merges when A lands). **Lane 3** T10 wireframe extraction (fully
independent). Launch 1-3 in parallel worktrees; A-frontend joins Lane 1 after
the serializer exists; D waits on Lanes 1+3; E last. Conflict flag: Lanes 1 and
the A-frontend step both touch CharKeeperApp provider maps — keep frontend
wiring inside Lane 1's worktree.

### Implementation Tasks (Phase 3 — eng review)

- [ ] **T13 (P1, human: ~4h / CC: ~20min)** — backend — Tlc rest-command override excluding session feats from blanket reset + inverse test
  - Surfaced by: eng finding 1 — make_long_rest_command.rb:38
  - Files: app/commands/characters_context/tlc/make_long_rest_command.rb, request spec
  - Verify: acceptance test 6 (both directions)
- [ ] **T14 (P1, human: ~2h / CC: ~10min)** — backend — Strict Character scope / union content scopes split
  - Surfaced by: eng finding 2 — rest_controller.rb:15 authorization pattern
  - Files: app/models/character.rb, feat.rb, spell.rb, item.rb
  - Verify: dnd2024 character 404s on tlc endpoints (request spec)
- [ ] **T15 (P1, human: ~1d / CC: ~40min)** — db+seeds — rake tlc:seed + partial unique (type,slug) index migration
  - Surfaced by: eng finding 3 — db/seeds.rb:23 no unique_by; schema L265 plain index
  - Files: lib/tasks/tlc.rake, db/migrate/*, db/data/tlc/
  - Verify: acceptance test 9 (run twice, identical counts)
- [ ] **T16 (P1, human: ~1d / CC: ~45min)** — backend — TlcDecorator species-step override + namespaced subclass slugs + TLC refresh service (explicit trait attach, mixed_species)
  - Surfaced by: eng findings 4 & 5 — species_decorator.rb:6, refresh_feats.rb:60-64
  - Files: app/decorators_v2/tlc_decorator.rb, app/services/characters_context/tlc/refresh_feats.rb
  - Verify: acceptance tests 14, 15, 16
- [ ] **T17 (P1, human: ~4h / CC: ~20min)** — backend — TLC spell options path (book machinery, provider-distinct cache key, post-union ban filter, static-spell override)
  - Surfaced by: eng finding 7 — spells_controller.rb:33-45, dnd2024_decorator.rb:204
  - Files: app/controllers/frontend/tlc/spells_controller.rb, app/decorators_v2/tlc_decorator.rb
  - Verify: acceptance test 3 (incl. book-gated spell)
- [ ] **T18 (P2, human: ~2h / CC: ~10min)** — security — Widen eval exclusion to description_eval_variables; exclude eval fields from TLC admin forms
  - Surfaced by: eng finding 6 — dnd2024_decorator.rb:396-398, adminbook/feats_controller.rb:50
  - Files: T4 specs, app/controllers/adminbook/tlc/
  - Verify: homebrew + admin paths cannot persist either eval field
- [ ] **T19 (P2, human: ~2h / CC: ~10min)** — frontend — isDnd2024Family helper + grep sweep of exact-provider checks; client config merge module
  - Surfaced by: eng findings 8 & 9 — Dnd5.jsx L102/145/193, Conditions.jsx:5
  - Files: CharKeeperApp helpers, data/tlcConfig.js
  - Verify: craft tab, beastform, item upgrades render for tlc; tlc config values resolve in SPA
- [ ] **T20 (P2, human: ~2h / CC: ~15min)** — e2e — Regression guard: stock dnd2024 flows unchanged
  - Surfaced by: REGRESSION RULE — shared-file edits
  - Files: spec/e2e/cypress/e2e/dnd2024_regression.cy.js, request specs
  - Verify: acceptance test 13

### Failure Modes Registry (cross-phase, final)

```
CODEPATH               | FAILURE MODE                   | RESCUED?  | TEST?  | USER SEES?           | LOGGED?
-----------------------|--------------------------------|-----------|--------|----------------------|--------
TlcDecorator modifiers | bad Dentaku formula in seed    | Y (skip)  | T3     | stat sans modifier   | Y
Long rest              | session feats wiped (inherited)| Y (excl.) | AT6    | correct resets only  | n/a
tlc endpoints          | cross-provider character load  | Y (scope) | T14    | 404                  | Y
rake tlc:seed          | duplicate rows on re-run       | Y (uniq)  | AT9    | n/a (dev)            | seed summary
TLC refresh_feats      | selected trait row deleted     | Y (skip)  | chaos  | "unavailable" warn   | Y
Spell options          | book-gated PHB spells missing  | Y (spec'd)| AT3    | full spell list      | n/a
Rest apply             | partial application            | Y (txn)   | T5     | all-or-nothing       | Y
Homebrew/admin content | eval fields persisted          | Y (spec'd)| T4,T18 | n/a                  | n/a
Banned-spell grants    | banned spell auto-granted      | Y (lint)  | AT3    | soft warning         | seed lint
```
Every row is rescued AND tested AND visible — **0 CRITICAL GAPS** (no row is
silent + untested + unrescued).

### Cross-Phase Themes

**Theme: the interim `<Dnd5>` sheet is the riskiest scaffold** — flagged
independently in Phase 1 (risk: reuse hides TLC fields), Phase 2 (finding 1:
MVP passable with TLC invisible), and Phase 3 (finding 9: exact-provider checks
misroute tlc). High-confidence signal. Mitigations now in plan: minimal TLC
surface in Phase C, isDnd2024Family helper + grep sweep, tracked Phase D
replacement, amended test 0.

**Theme: content-pipeline fidelity is the real schedule and correctness risk** —
flagged in Phase 1 (unpriced entry burden, garbled PDF tables), Phase 2 (gate
labels need content flags), and Phase 3 (non-idempotent seeds, book-gated
spells, eval fields in content rows). Mitigations: A0 spikes, B1/B2 split,
scripted extraction, verified/banned_exemption flags, dedicated tlc:seed +
unique index, seed lints.

## Phase 3 Completion Summary

```
+====================================================================+
|            ENG PLAN REVIEW — COMPLETION SUMMARY                    |
+====================================================================+
| Mode                 | FULL_REVIEW (via /autoplan)                 |
| Step 0 (Scope)       | Complexity accepted at gate; Layer-1 only   |
| Section 1 (Arch)     | 4 issues (F2,F4,F8,F9) — all amended        |
| Section 2 (Quality)  | 2 issues (F5 semantics, registry claim F3)  |
| Section 3 (Tests)    | Diagram produced; 5 gaps -> tests 13-17     |
| Section 4 (Perf)     | 2 issues (cache keys F7, config cache TTL)  |
+--------------------------------------------------------------------+
| Issues found         | 10 (5 P1, 5 P2) — 10 absorbed, 0 open       |
| Critical gaps        | 0 remaining (2 closed: rest wipe, scoping)  |
| Test plan artifact   | written (eng-review-test-plan-...0815.md)   |
| TODOS.md             | created, 17 items                           |
| Worktree lanes       | 3 parallel lanes mapped                     |
| Outside voice        | subagent-only (Codex not installed)         |
| Migrations           | 2 additive (chapter, unique index)          |
+====================================================================+
```

<!-- AUTONOMOUS DECISION LOG -->
## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|----------------|-----------|-----------|----------|
| 1 | 0 | Plan file created at docs/leyfarers-implementation-plan.md from docs/ references | Mechanical | P6 | No prior plan existed; /autoplan args say make one | — |
| 2 | 0 | UI scope YES; DX scope NO (Phase 3.5 skipped) | Mechanical | P3 | API/import matches are internal plumbing; no SDK/CLI/public-API deliverable | Running DX review |
| 3 | 1 | Mode = SELECTIVE EXPANSION | Mechanical | /autoplan override | Iteration on existing system | Other modes |
| 4 | 1 | Approach A (new `tlc` provider) over B (homebrew-only) and C (edit dnd2024 in place) | TASTE → final gate | P1 | Only A covers design-doc mechanics; C viable if upstream tracking dropped | B, C |
| 5 | 1 | Add Phase A0 spikes (homebrew UI + modifiers expressiveness) | Auto | P2, P6 | Prices content entry and de-risks the modifier model before build | Building blind |
| 6 | 1 | Phase B split: B1 party-first, B2 scripted backfill | Auto | P1, P3 | Table-ready sooner; extraction is deterministic-space work | Hand-entering full corpus first |
| 7 | 1 | Content sharing = union query (dnd2024 + tlc − banned), copy nothing | Auto | P4 | Copying forks from upstream errata and doubles entry burden | Duplicating 2024 corpus |
| 8 | 1 | Minimal conditions in Phase D; full Effects engine explicitly NOT in scope | Auto | P1, P5 | Design doc requires status effects; its Effects spec is empty — can't build what isn't designed | Silent scope drop |
| 9 | 1 | Acceptance test 0 = party PCs rebuilt by next session | Auto | P1 | Ties plan to a measurable table outcome | API-only acceptance |
| 10 | 1 | Kill criterion added (fallback to stock dnd2024 + homebrew) | Auto | P6 | Honest failure path protects the campaign date | No fallback |
| 11 | 1 | Expansions IN: extraction script, campaign chapter setting. DEFERRED: Owlbear, rank ceremony UI, session-log suggestions, content publication | Auto | P2, P3 | In blast radius + <1d CC each for IN; others outside radius | — |
| 12 | 1 | Premises P1/P3/P4/P5 confirmed | USER (gate D1) | — | Zac confirmed 2026-07-19 | Challenge |
| 13 | 1 | P2 = Approach A: new `tlc` provider, keep upstream tracking | USER (gate D2) | — | Zac chose A over in-place edit (B) and spike-first (C) | B, C |
| 14 | 1 | data/tlc.json composes via `base: dnd2024` deep-merge in PlatformConfig | Auto | P5 | One explicit merge point beats copied config or dual imports | Copying dnd2024.json |
| 15 | 1 | Dentaku errors rescued per-modifier: log slug+formula+character, skip modifier | Auto | Zero-silent-failures | Bad seed data must not 500 the sheet; loud in logs | Let serializer 500 |
| 16 | 1 | eval_variables excluded from all homebrew paths (spec-enforced); trait slugs validated against tlc union scope | Auto | Security | Ruby-eval field must stay seed-only; cross-provider injection closed | Trust input |
| 17 | 1 | Rest apply = single transaction + double-submit guard on hit-dice spends | Auto | P1 | Partial rest application is a silent corruption path | Best-effort apply |
| 18 | 1 | Choose-one AC formulas resolved as max(applicable); no manual AC-mode picker | Auto (ponytail) | P3, P5 | Player-optimal default; `data.ac_mode` is the upgrade path | AC mode UI now |
| 19 | 1 | Warning dismissal keyed by slug only, persists until re-enabled | Auto (ponytail) | P3 | Simple, predictable; slug+context keys are the upgrade path | Context-hash re-arming |
| 20 | 1 | No feature flag; no new dashboards/alerts (solo self-hosted, SolidErrors + logs) | Auto | P3 | Dark-ship by construction; observability sized to deployment | Flag + dashboards |
| 21 | 1 | Verify/add (type) index for union options query before Phase A lands | Auto | P1 | STI union scan without index is the first thing to degrade | Assume indexed |
| 22 | 1 | README gains TLC provider + content pipeline + runbook section (Phase B deliverable) | Auto | P1 | Knowledge concentration risk named in Section 10 | Tribal knowledge |
| 23 | 1 | Banned-spell rule systematic: seed lint fails on banned auto-grants without `banned_exemption: true`; exempted grants still soft-warn | Auto | Zero-silent-failures | Spec review: filter guarded selection only; Lady of Ivory → Fabricate caught incidentally | Selection-only filter |
| 24 | 1 | Session date for test 0 = open input, collected at final gate | Auto | Honesty | Spec review: docs claimed a date was set; none was collected | Fabricated date |
| 25 | 2 | Skip interactive mockup/comparison-board loop; recommend pre-Phase-D mockup round at gate | Auto | /autoplan design | Board loop is a human feedback session, contrary to one-command pipeline; design doc has its own mockups | Blocking board session |
| 26 | 2 | Minimal TLC surface moved into Phase C; test 0 requires visible TLC state | Auto | P1 | MVP gate could pass with rank/warnings/session-rest invisible | API-only MVP |
| 27 | 2 | Mobile-first enforced via acceptance test 12 (390px Cypress, 44px targets) | Auto | P1 | Design doc requires table-side phone use; existing sheet is desktop-first | Asserted-only mobile |
| 28 | 2 | Per-tab ordered hierarchy + state matrix + wireframe entry gate added to Phase D | Auto | P1, P5 | Implementer was inventing design; doc's own mockups cited as source | Generic patterns |
| 29 | 2 | Default landing tab = Combat (HP first) | TASTE → final gate | P5 | Matches existing sheet + at-table play; doc routing could read Character-first | Character-first landing |
| 30 | 2 | Level-up = classLevels flow + TLC deltas; Focus modal on rank>=2 && focus null; rank badge stepper | Auto | P1 | The two highest-emotion moments were stubs | Unspecified manual flows |
| 31 | 2 | Dismissed-warnings restore list in character settings | Auto | P1 | Re-enable claim had no surface (one-way door) | Drop the claim |
| 32 | 3 | Tlc rest commands exclude session feats from blanket reset | Auto | Zero-silent-failures | Inherited update_all wipes session abilities on every long rest (verified :38) | Inherit as-is |
| 33 | 3 | Character.tlc strict; union only on content models | Auto | Security | Union on Character breaks endpoint authorization scoping (verified :15) | Union everywhere |
| 34 | 3 | rake tlc:seed + partial unique (type,slug) index migration | Auto | P1 | Existing seeds non-idempotent; claimed index doesn't exist (verified L265) | Reuse db/seeds.rb |
| 35 | 3 | TlcDecorator overrides species step; namespaced subclass slugs | Auto | P5 | Slug constantize double-applies 2024 species logic (verified :6) | Shared slugs |
| 36 | 3 | TLC refresh service: explicit trait attach; origin out of SELECTABLE_ORIGINS; mixed_species in origin list | Auto | P1 | Auto-attach would grant whole trait pool; deselection would never detach (verified :60-64, :24) | Inherited refresh |
| 37 | 3 | Eval exclusion widened to description_eval_variables; admin TLC forms exclude eval fields | Auto | Security | Second Ruby-eval'd field exists (verified :396-398); adminbook writes raw eval (verified :50) | eval_variables-only spec |
| 38 | 3 | TLC spell options: book machinery + provider cache key + post-union ban filter + static-spell override | Auto | P1 | ~60 PHB spells book-gated (verified seeds:529-542); hardcoded Dnd2024 query (verified :204) | Naive union |
| 39 | 3 | isDnd2024Family helper + client-side tlcConfig merge module | Auto | P5 | Exact provider checks misroute tlc (verified L102/145/193); SPA imports config statically | Server-only merge |
| 40 | 3 | Tests 13-17 added (regression, detach, colliding slug, Mixed Ancestry, pinned-seed parity) | Auto | P1 + REGRESSION RULE | Eng finding 10; shared-file edits demand a regression guard | Ship without |
| 41 | 3 | TODOS.md auto-written (17 items); test plan artifact written | Mechanical | /autoplan | Phase 3 required outputs | — |
| 42 | 4 | Plan APPROVED as-is | USER (gate D3) | — | Zac approved 2026-07-19; 0 open findings, 0 user challenges | Overrides / revise / reject |
| 43 | 4 | Default landing tab = Combat (taste resolved) | USER (gate D4) | — | Matches existing sheet + at-table speed | Character-first |
| 44 | 4 | Session date stays TBD; kill criterion unarmed until set | USER (gate D5) | — | Set when campaign calendar is known | 2- or 4-week defaults |

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | issues_open (PLAN via /autoplan) | 9 proposals, 5 accepted, 4 deferred; spec loop 8/10 |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | Codex CLI not installed — all voices [subagent-only] |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | clean (PLAN via /autoplan) | 10 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | clean (PLAN via /autoplan) | score: 4/10 → 8/10, 7 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | skipped: no developer-facing scope |

**VERDICT:** CEO + ENG + DESIGN CLEARED — plan APPROVED at the /autoplan final
gate (2026-07-19), ready to implement. Eng review (the shipping gate) is clean.

**UNRESOLVED DECISIONS:**
- Session date for acceptance test 0 — deliberately TBD (gate D5); the kill criterion stays unarmed until Zac sets it from the campaign calendar.
