# Rule warnings

Chapterhouse never blocks a choice. If a build breaks a rule, the sheet still
saves it and raises a **warning** instead: a short note saying which rule broke
and where the rule comes from. You decide whether it matters at your table.

Only two things are ever rejected outright, and neither is a rule judgement:

- Data that does not exist (a species trait whose content row is not in the
  database, an unknown species).
- Values outside a hard bound (an ability score above 30, more than 10 selected
  traits, a level outside 1-20).

Everything else — an under-prereq multiclass, a fourth species trait, a level
above the chapter cap — saves and warns.

## Where warnings come from

Every warning names its **source** so you know whose rule you are bending:

| Source | Meaning                                                            |
| ------ | ------------------------------------------------------------------ |
| `PHB`  | A D&D 2024 Player's Handbook rule that TLC did not change.          |
| `TLC`  | A rule specific to The Leyfarer's Chronicle.                        |

## The warnings

| Slug                    | Source | Fires when                                                                                        |
| ----------------------- | ------ | ------------------------------------------------------------------------------------------------- |
| `multiclass_prereq`     | PHB    | You hold two or more classes and one of them has an unmet ability prerequisite (13 in the listed abilities). |
| `trait_count`           | TLC    | More species traits are selected than your species allows: 3 normally, 4 with Mixed Ancestry.       |
| `prepared_overrun`      | PHB    | A class has more spells prepared than its prepared-spells allowance. Cantrips do not count.         |
| `level_vs_chapter_cap`  | TLC    | Your level is above the maximum for your campaign's chapter (chapter 8 caps at level 12, up to chapter 16 at level 20). |
| `banned_spell_exempted` | TLC    | A feat, an item, or a spell on your sheet grants one of the eight spells TLC bans. The grant is kept as an explicit exemption and flagged. |
| `trait_unavailable`     | TLC    | A species trait you selected no longer exists as content, so it was skipped when your features were rebuilt. |

### Human Greenhorn

Humans have the **Greenhorn** trait: they ignore multiclassing ability
prerequisites. A Human — including a Mixed Ancestry character with Human as
either half — never raises `multiclass_prereq`.

### Chapter caps

The level cap comes from the **chapter** set on the campaign the character
belongs to. A campaign with no chapter set raises no cap warning, and neither do
chapters below 8, which have no published cap. A character in more than one
campaign is held to the earliest chapter.

## Dismissing and restoring

Every warning is dismissible. Dismissing one hides it from the sheet and adds
its slug to the character's dismissed list; the warning stays hidden until you
restore it from character settings, even if you later change the build in a way
that breaks the same rule again. That is deliberate: a dismissal means "I know,
this is intentional", and re-raising it on every edit would be noise.

Dismissals are per character, not per campaign or per account.

## For developers

The slug list is one constant, `Tlc::Warnings::SLUGS` in
`app/lib/tlc/warnings.rb`. It is the single source for:

- the warning's source (`PHB` / `TLC`),
- its i18n key, derived as `warnings.<slugInCamelCase>` and resolved against
  `app/javascript/applications/CharKeeperApp/i18n/*.json`,
- the values `data.dismissed_warnings` accepts. The update contract binds only
  the delta: a slug being newly added must be in the registry, and one already
  stored is grandfathered — a retired slug keeps saving and restoring instead of
  freezing every later mutation behind a 422.

Adding a warning means adding a registry row, a private method on
`Tlc::Warnings` named after the slug, and one message per frontend locale.
`spec/lib/tlc/warnings_spec.rb` fails if any of the three is missing.

Each entry serializes as:

```json
{
  "slug": "multiclass_prereq",
  "source": "PHB",
  "message_key": "warnings.multiclassPrereq",
  "dismissible": true,
  "context": { "classes": ["paladin"], "required": { "paladin": [["str"], ["cha"]] }, "minimum": 13 }
}
```

`context` carries whatever the message needs to interpolate and differs per
slug. At most one entry per slug is ever produced, because dismissals are keyed
by slug alone — a check with several offenders aggregates them into `context`.

The character serializer exposes `warnings` (active only) alongside
`dismissed_warnings` (the raw hidden list, for the settings restore surface).
