# Creating a TLC character

The Leyfarer's Chronicle is a provider next to D&D 5 and D&D 2024, not a mode on
top of one. A TLC character is created from its own form, gets its own
`/frontend/tlc/characters` endpoint, and shows up in the characters list under
its own filter tab.

## Walkthrough

1. On the characters list, tap the round **+** button.
2. In **Platform**, pick **The Leyfarer's Chronicle**. The form below swaps to
   the TLC one; the note at the top confirms you are creating a Leyfarer.
3. **Name** — up to 50 characters.
4. **Species** — the 17 TLC species (Birdfolk, Catfolk, Dwarf, Elf, Fabricated,
   Frogfolk, Gnome, Human, Hyenafolk, Kobold, Lizardfolk, Nereid, Orc,
   Otterfolk, Ratfolk, Snailfolk, Turtlefolk). The five 2024 species TLC does not
   use — Halfling, Dragonborn, Tiefling, Aasimar, Goliath — are deliberately
   absent, even though a character that already has one still renders.
5. **Legacy** — only appears for a species that has legacies (the ones TLC
   redefines from a 2024 species, such as Elf). TLC-only species have none.
6. **Size** — the sizes that species allows; it defaults to the first one.
7. **Background** — the 2024 background list, which TLC shares.
8. **Main class** — the 2024 class list, which TLC shares. TLC's own subclasses
   are picked later, on the sheet, not here.
9. **Alignment** — defaults to neutral.
10. **Skip new character guide** — leave it off to walk the guided setup on the
    sheet, turn it on to land on the finished sheet directly.
11. **Save**.

## What the server fills in

You do not choose a level or roll ability scores in this form:

- **Level 3.** Leyfarers start at level 3 (players-guide-digest §2), set by
  `TlcCharacter::BaseBuilder`. The class also starts at 3, so hit dice and
  class-feature grants line up.
- **Point-buy ability scores.** TLC uses point buy only; there is no roll or
  standard-array option to pick.

## What is not in this form yet

- **Optional species traits.** Every TLC species has a pool of optional traits
  (3 picks by default). The form does not offer the picker yet — traits are
  selectable through the API until the trait picker ships. A character created
  here has its base traits and an empty optional selection.
- **Mixed Ancestry.** The two-species origin feat is accepted by the API but has
  no control on this form.
- **D&D Beyond import.** Import exists for D&D 5 and D&D 2024 only; there is no
  Beyond equivalent for TLC content, so the TLC form has no file field.
- **Homebrew species and backgrounds.** The characters screen only receives a
  D&D 2024 homebrew bucket today, so the TLC form offers seeded content only.

## After saving

The new character appears at the top of the list, showing `Level 3` and its
species. A **The Leyfarer's Chronicle** tab appears in the list filter once you
have at least one TLC character.

Opening it renders the D&D 2024 sheet as interim scaffolding while the dedicated
TLC sheet is built. Most tabs work as they do for a 2024 character; **Craft** is
the exception — it has no TLC endpoint yet and shows an error until crafting
lands. The PDF export in the row menu is deliberately absent: the export sheet is
the official 2024 character sheet and there is no TLC one to fill.

## Language support

The TLC-specific prose — the provider name and the form's intro note — is
English-only for now. Russian and Spanish fall back to English for those two and
keep their own translations everywhere else, because every field label on this
form is shared with the D&D 2024 form. Nothing renders blank in any locale: each
dictionary is layered over English in `context/appLocale.jsx`, so a key a locale
has not translated yet resolves to the English string.
