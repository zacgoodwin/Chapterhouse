# CharKeeper (Chapterhouse fork) — Architecture Map

Rails 8.1 + PostgreSQL (uuid PKs, heavy JSONB) backend API, SolidJS SPA bundled by esbuild, plus Telegram/Discord bots and an adminbook. 9 systems: Dnd5, Dnd2024, Pathfinder2, Daggerheart, Dc20, Fate, Fallout, Cosmere, Cthulhu7.

## 1. System architecture
One `characters` table, STI via `type` column (e.g. `Dnd2024::Character`) + a JSONB `data` blob holding all system-specific attributes (db/schema.rb L197-206). Base `app/models/character.rb` has per-system scopes; `decorator` is abstract. System subclasses live in `app/platforms/<sys>/character.rb` (not models/lib). Each defines `<Sys>::CharacterData` (include StoreModel::Model, typed JSONB attribute schema) and `<Sys>::Character < Character` which attaches `attribute :data, <Sys>::CharacterData.to_type`, exposes `config` from `PlatformConfig.data('<sys>')`, and returns its calc engine via `def decorator`. Same folder holds `feat.rb` (STI `<Sys>::Feat < Feat`, with `enum :origin/:kind/:limit_refresh`), `item.rb`, `spell.rb`, `homebrews/`.

## 2. Rules data
(a) Master lookup tables = `app/javascript/applications/CharKeeperApp/data/<provider>.json` — species/legacies/classes/subclasses/skills/backgrounds; read server-side by `app/lib/platform_config.rb` AND bundled into the SPA.
(b) Secondary server tables `config/settings/<sys>/*.json` via `app/lib/config.rb`.
(c) Feats/features/spells/items are DB rows seeded by `db/seeds.rb` from `db/data/<sys>/*.{json,csv}` (upsert_all with `type` set). Feat record: `{slug, title{en,ru}, description, origin, origin_value, kind, modifiers, eval_variables}`. The `feats` table (schema L235) is the richest content store.

## 3. Mechanics engine
The decorator derives all stats from `data` + feats + items + bonuses. Two generations: v1 chained wrappers `app/decorators/<sys>_character/*` (Dnd5, Daggerheart, Dc20, Fallout, Fate — see app/platforms/dnd5/character.rb L128); v2 single `app/decorators_v2/<sys>_decorator.rb < ApplicationDecoratorV2` (Dnd2024, Pathfinder2, Cosmere, Cthulhu7). Ref app/decorators_v2/dnd2024_decorator.rb#call L13-48: modifiers `(v/2)-5`; AC L486; skills `mod + level*proficiency` L520; spell DC `8+prof+mod`. `all_modifiers` (L545) aggregates `character_bonus.value` + equipped item modifiers + active feat modifiers, each `{key:{type:'add'|'set'|'concat', value:<formula>}}`. Formulas evaluated by Dentaku (`app/lib/formula.rb`); feats may also carry Ruby `eval_variables`.

## 4. Homebrew
Two subsystems: `homebrews` table (STI `type`, self-ref `homebrew_id`, `info/title/description` jsonb, `public`, `user_id`, Discard soft-delete) with per-system classes `app/platforms/<sys>/homebrews/*.rb` (Daggerheart domain/ancestry/subclass/…; Dnd2024 race/background/subclass), each `< ::Homebrew` with a StoreModel `info` + `to_homebrew_json`. Plus older `homebrew_subclasses`. Grouping via `homebrew_books`/`homebrew_book_items`/`user_books`; precomputed `user_homebrews`; `upvotes`. Scoped by `user_id` unioned with owned-book items. Custom slugs resolved through `app/lib/cache/dnd_names.rb`. API `namespace :homebrews_v2` (routes L259), controllers `app/controllers/homebrews_v2/`, import commands `app/commands/homebrews_v2_context/import/<sys>/`, separate HomebrewsApp SPA.

## 5. Frontend
SolidJS 1.8 + esbuild (esbuild.config.js); no React/Stimulus. `CharKeeperApp/{components,pages,context,hooks,requests,data,i18n,assets}`. Per-system dispatch: `pages/Content/CharacterTab.jsx` L49-77 `<Switch>` on `character().provider` → `<Dnd5|Pathfinder2|Daggerheart|Dc20|Fate|Fallout|Cosmere|Cthulhu7>` (dnd2024 reuses `<Dnd5>`). Sheets: `pages/Content/Character/<Sys>.jsx` + `<Sys>/` tabs; creation forms `pages/Navigation/Characters/Forms/<Sys>.jsx`. i18n: `i18n/{en,ru,es}.json` + server `config/locales/*.yml`, with per-user per-provider sublocales.

## 6. API/transport
Route namespaces `frontend/` (SPA JSON API), `homebrews_v2/`, `webhooks/`, `owlbear/`, `adminbook/`, `web/`. Business logic = commands + dry-validation contracts: `BaseCommand` (app/commands/base_command.rb) runs `use_contract` (`BaseContract < Dry::Validation::Contract`) then `do_prepare`/`do_persist`; wired via dry-container/dry-auto_inject in `config/initializers/container.rb` (`Deps[...]`). Serializers = Panko (`app/serializers/<sys>/character_serializer.rb`) delegating to the decorator and exposing `def provider` (the literal provider string); controller picks via `"#{type}Serializer".constantize`. Auth = token-based Authkeeper (ApplicationController include Authkeeper::Controllers::Authentication); `user_sessions`, OAuth `user_identities`; authorization via action_policy.

## 7. Admin
`namespace :adminbook` (routes L11), controllers `app/controllers/adminbook/`, HTTP-Basic auth in prod, skips token auth. Mounts GoodJob, PgHero, SolidErrors engines.

## 8. Tests
RSpec + FactoryBot mirroring app dirs; per-system rules in `spec/platforms/<sys>/character_spec.rb` and `spec/decorators_v2/*_decorator_spec.rb`. Cypress E2E in `spec/e2e/` (cypress/e2e/*.cy.js), run against `rails server -e test -p 5002`.

## 9. Database
Character: `characters` (STI+data), `character_feats` (state: tokens/used_count/limit_refresh/value), `character_items` (modifiers/states/charges), `character_spells`, `character_bonus` (polymorphic, value jsonb), `character_resources` + `custom_resources`, `character_companions`, `daggerheart_projects`. Content: `feats`, `spells`, `items` (+`item_recipes`). Homebrew: `homebrews`, `homebrew_subclasses`, `homebrew_books`, `homebrew_book_items`, `homebrew_publications`, `user_books`, `user_homebrews`, `upvotes`. Social: `campaigns` (provider), `campaign_*`, `channels`; users + notifications; GoodJob/ActiveStorage.

## Extension checklist — add a new system (e.g. customized D&D 2024 variant)
STI+JSONB means no migration needed — a new `type` string + config + decorator + plumbing. Clone the dnd2024/Dnd2024 slug:

1. `app/platforms/<sys>/character.rb` — CharacterData StoreModel schema + `<Sys>::Character < Character` (config from `PlatformConfig.data('<sys>')`, `decorator`). Add feat.rb/item.rb/spell.rb.
2. Add `scope :<sys>` in `app/models/character.rb` (+ feat.rb/item.rb/spell.rb).
3. `app/javascript/.../CharKeeperApp/data/<sys>.json` — required master config (species/classes/skills).
4. `config/settings/<sys>/*.json` — only if extra lookup tables needed.
5. `app/decorators_v2/<sys>_decorator.rb` (or reuse Dnd2024Decorator) + sub-decorators under `app/decorators_v2/<sys>/`.
6. `app/builders/<sys>_character/` creation builders; `app/services/characters_context/<sys>/refresh_feats.rb`.
7. `app/commands/characters_context/<sys>/{create,update,…}_command.rb` with use_contract; register keys in `config/initializers/container.rb`.
8. `app/controllers/frontend/<sys>/` + `namespace :<sys>` in `config/routes.rb` (copy L136-151); add to campaign provider enum in `app/commands/campaigns_context/add_campaign_command.rb` L8.
9. `app/serializers/<sys>/character_serializer.rb` (`def provider => '<sys>'`); add cases in `app/controllers/frontend/characters_controller.rb` L52-72.
10. `db/data/<sys>/` content + loader block in `db/seeds.rb`/`seeds_prod.rb`.
11. Frontend: `pages/Content/Character/<Sys>.jsx` (+ tabs), add `<Match when={provider==='<sys>'}>` in CharacterTab.jsx, `Navigation/Characters/Forms/<Sys>.jsx`, provider name maps (CampaignsTab.jsx L183, ListItem.jsx), i18n strings.
12. `app/controllers/adminbook/<sys>/` + adminbook routes/views.
13. Tests: `spec/platforms/<sys>/character_spec.rb`, `spec/decorators_v2/<sys>_decorator_spec.rb`, factories, optional Cypress spec.
14. Optional homebrew: `app/platforms/<sys>/homebrews/*`, `homebrews_v2/<sys>/` controllers + import commands, `app/lib/cache/<sys>_names.rb`.

Connective tissue: the `provider` string (serializer output ⇄ CharacterTab.jsx match ⇄ data/<sys>.json) links backend `type` → frontend component → config. For a minimal D&D 2024 variant you can reuse Dnd2024Decorator, the `<Dnd5>` UI, and the dnd2024 command/contract set, changing only the `data/<variant>.json` tables and the new type/serializer/routes.
