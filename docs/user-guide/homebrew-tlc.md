# Homebrew TLC species, subclasses, and feats

TLC homebrew mirrors the D&D 2024 homebrew pattern: an authoring **container**
record (a `Homebrew` STI subclass) groups the content rows it produces. Importing
a container writes `Tlc::Feat` content rows into the shared `feats` table (STI
type `Tlc::Feat`), so they join the same `tlc_content` union the seeded content
uses and become selectable on a TLC character.

Three authoring types exist, under `Tlc::Homebrews::`:

| Type       | Container class              | Produces                                       |
| ---------- | ---------------------------- | ---------------------------------------------- |
| Species    | `Tlc::Homebrews::Species`    | species-trait rows (`origin: 'species'`)       |
| Subclass   | `Tlc::Homebrews::Subclass`   | feature rows (`origin: 'subclass'`) + resources |
| Feat       | `Tlc::Homebrews::Feat`       | one selectable feat row (`origin: 'feat'`)     |

## Security: eval fields are never accepted

`eval_variables`, `description_eval_variables`, and `bonus_eval_variables` are
raw-Ruby-`eval`'d by the decorator, so they are **seed-only**. No homebrew import
contract (TLC or dnd2024) declares them, so a payload that smuggles one has it
stripped before the row is written. A per-use `limit` on a TLC homebrew feat is
stored in `info` instead of `description_eval_variables`, so every imported TLC
row leaves all three eval columns empty. Mechanics are expressed with `modifiers`
(sandboxed Dentaku formulas), which are safe and fully supported.

## Species (fixed base traits + choose-N optional pool)

A TLC species is a set of always-on **base** traits plus a **pool** of optional
traits the player chooses from (3 by default; players-guide-digest.md §4). The
import payload carries species-level facts and a single `traits` array; each
trait declares its `trait_kind`:

```jsonc
{
  "title": { "en": "Snailfolk" },
  "description": { "en": "..." },
  "creature_type": "humanoid",          // or "construct" (Fabricated)
  "interaction_tags": ["wilderfolk"],   // widen targeting (dreamtouched, biomechanical, ...)
  "size": ["small", "medium"],          // choose-at-selection sizes
  "vision": { "darkvision": 60 },       // or { "tremorsense": 30 } (Dwarf)
  "speed": 30,
  "speeds": { "swim": 30 },
  "optional_pool_size": 3,              // how many optional traits the picker offers
  "traits": [
    { "trait_kind": "base",     "title": { "en": "Boneless" },        "description": { "en": "..." }, "kind": "static",
      "modifiers": { "resistance": { "type": "concat", "value": "bludge" } } },
    { "trait_kind": "optional", "title": { "en": "Wall Crawler" },    "description": { "en": "..." }, "kind": "static",
      "is_lineage": true, "lineage_options": [ { "slug": "chipachi" }, { "slug": "welkin" } ] },
    { "trait_kind": "optional", "title": { "en": "Molluscan Aegis" }, "description": { "en": "..." }, "kind": "static",
      "grants_free_trait": "snails_pace" }
  ]
}
```

- `trait_kind` (`base` | `optional`) is folded into each trait row's `info`. The
  picker offers the `optional` subset; `base` traits attach unconditionally.
- `is_lineage` + `lineage_options` mark an optional trait that itself branches
  into sub-choices (Catfolk Grimalkin/Maneko, Elf Briar/Moon/Shadow/Sun).
- `grants_free_trait` names a trait that does not count against the pool
  (Snailfolk's Snail's Pace).

## Subclass (features + resource pools)

A subclass import carries `class_id`, a `features` array (each with a `level` so
it attaches at the right subclass level), and a `resources` array of C8-shaped
pool definitions. Attaching the subclass to a character instantiates the pools
through the same `CharactersContext::Tlc::RefreshResources` machinery the 12
seeded subclasses use — `max_formula` is a Dentaku string evaluated against
`proficiency_bonus`, ability modifiers, and `<class>_level`.

```jsonc
{
  "title": { "en": "Gambler" }, "description": { "en": "..." },
  "class_id": "rogue",
  "resources": [
    { "slug": "gambler_lucky_number", "name": "Lucky Number", "description": "...",
      "min_class_level": 3, "max_value": 20, "reset_direction": 0, "resets": { "long": -1 } }
  ],
  "features": [
    { "title": { "en": "High Roller" }, "description": { "en": "..." }, "kind": "static", "level": 3 }
  ]
}
```

## Feat (standalone)

A standalone homebrew feat produces one selectable `Tlc::Feat` row plus a
container that records feat-level authoring metadata (`repeatable`,
`prerequisite`, `unlock` gate). The `kind` flag on the backing row covers
intrinsics — no separate intrinsic form.

## Browse / visibility

Homebrew browse uses standard scoping: a user sees their own rows plus any
publicly shared ones (`user_id` OR `public`, with the book union). The species
and subclass list is served by the shared `homebrews_v2/homebrews#index` keyed by
`type` (e.g. `?type=Tlc::Homebrews::Species`); feats have their own
`homebrews_v2/tlc/feats#index`. This is orthogonal to the seeded-content
`visibility` states documented in `admin-content.md` (which govern the character
options path, not homebrew browse).

## Routes

| Type     | Show / destroy                           | Index                          |
| -------- | ---------------------------------------- | ------------------------------ |
| Species  | `/homebrews_v2/tlc/species/:id`          | via `/homebrews_v2/homebrews`  |
| Subclass | `/homebrews_v2/tlc/subclasses/:id`       | via `/homebrews_v2/homebrews`  |
| Feat     | `/homebrews_v2/tlc/feats/:id`            | `/homebrews_v2/tlc/feats`      |

## Out of scope

Homebrew publications (book sharing) for TLC, a homebrew-authoring SPA redesign,
and full trait-edit diffing on re-import are not part of this slice.
