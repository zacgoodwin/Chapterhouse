# Design System - Leyfarer's Chapterhouse

Source of truth for every visual decision in this repo. Codified 2026-08-11 by
/design-consultation from the design system locked on 2026-07-19 through five
feedback rounds (see Decisions Log). When this file and a locked comp disagree,
the comp wins; flag the mismatch here.

## Product Context

- **What this is:** Leyfarers, a D&D 2024 character manager for The Leyfarer's
  Chronicle (TLC) homebrew campaign. Fork of kortirso/charkeeper.
- **Who it's for:** One table: the campaign's players and DM, live at the table.
- **Project type:** Web app (Rails 8.1 + SolidJS + Tailwind). Phones first
  (390px viewport, 44px touch targets), desktop second.
- **Memorable thing:** "It feels like our campaign's own chronicle." Every
  design decision serves that.

## Aesthetic Direction

- **Direction:** Editorial hybrid. Brutalist print structure (Anton numerals,
  hairline tables, thick section rules) fused with card-era mobile ergonomics
  (44px tap targets, thumb-zone actions).
- **Decoration level:** Minimal. Typography and rules carry the identity. No
  gradients, no texture images, no fantasy chrome, no rarity-color rainbows.
- **Mood:** A campaign chronicle in print: warm paper, dense ink, exact numbers.
  Warm from three feet away, exact from three inches.
- **Reference comps (the locked authority):**
  - Screens (all six tabs, light + dark each):
    `~/.gstack/projects/zacgoodwin-Chapterhouse/designs/character-sheet-20260719/screen-*.html` + `.png`
  - TLC sheet layer: `~/.gstack/projects/zacgoodwin-Chapterhouse/designs/tlc-sheet-layer-20260719/tlc-layer-locked.html`
  - Create-character (Stacked Accordion): `~/.gstack/projects/zacgoodwin-Chapterhouse/designs/create-character-20260722/`
  - Login (Skyfall Immersive, dark-only): `~/.gstack/projects/zacgoodwin-Chapterhouse/designs/login-screen-20260720/`
  - Figma base: 'Leyfarer App' (key `NTjuwh9Gq0E79jx8RUW4Wg`), frames in `../figma-base/`
  - Wireframes + design-doc mockups: `docs/reference/leyfarers-refs/` (each
    Phase D PR links its wireframe; no component built without one)

## Typography

- **Display/Numerals:** Anton. Character names, tab-panel headings, and every
  big game number (HP, AC, ability mods, initiative). Observed display scale:
  46 / 40 / 34 / 22px.
- **Body/UI/Labels:** Archivo, weights 400/600/800. All labels, body copy,
  buttons, table text. Dense label scale: 8.5-14px with letter-spacing 0.2-3px
  (wider tracking on smaller uppercase labels).
- **Tabs:** 9.5px / weight 800 / 0.4px tracking. All six tabs visible at 390px,
  44px tap height. Never collapse tabs into a hamburger or overflow menu.
- **Data/Tables:** Anton for numerals, Archivo for cells. Right-align numeric
  columns.
- **Code:** Not a product surface. Keep Cascadia Mono only if a dev-facing
  screen ever needs it.
- **Loading:** Self-host woff2 in `app/assets/fonts/` (same pattern as the
  existing files). The vendored NotoSans/CascadiaMono files are upstream
  charkeeper legacy; replace with Anton + Archivo during the retheme, do not
  mix the two systems on one screen.

## Color

- **Approach:** Restrained. Neutrals do the work; green is identity, bronze is
  data, two reserved colors carry game meaning. Nothing else. Pale yellow
  (#e8e372) and plum (#5B2842) were tried and dropped: "too many colors."

| Token | Light | Dark | Usage |
|---|---|---|---|
| `--paper` | `#f8f7f1` | `#171a15` | Page background |
| `--ink` | `#171a17` | `#f2f1e8` | Primary text, big numerals |
| `--panel` | `#e7e5da` | `#2c3028` | Section/panel fill |
| `--hairline` | `#C0BBAE` | `#45463c` | Table rules, borders |
| `--label` | `#3B3B32` | `#a5a698` | Field labels |
| `--muted` | `#6f746a` | `#9a9d94` | Secondary text |
| `--green` | `#34813f` | `#52b25f` | Identity accent: active states, primary buttons, accordion open-bar |
| `--bronze` | `#594110` | `#c89a63` | Data accent: values, collapsed accordion summaries |

- **Reserved (semantic, never decorative):**
  - Damage `#FF5143`: Damage button and death-save failure boxes only.
  - Arcane `#00C0F5`: spell slot pips only.
- **Semantic mapping:** success = green tokens, error/danger = `#FF5143`,
  info = muted neutrals. No separate warning hue; use bronze + copy.
- **Dark mode:** Full token swap per the table (both variants locked per
  screen). Dark is warm green-black, never neutral gray. Login is the one
  dark-only surface.

## Spacing

- **Base unit:** 4px.
- **Density:** Compact data rows, breathing section headers. Sheet surfaces are
  dense on purpose; whitespace belongs between sections, not inside tables.
- **Touch targets:** 44px minimum everywhere (buttons, tabs, dropdown rows,
  increment controls). Equal-width button pairs (e.g. Damage / Heal).

## Layout

- **Approach:** Grid-disciplined single column, mobile-first (390px is the
  design viewport, per acceptance test 12). Desktop widens panels; it does not
  become a card-grid dashboard.
- **Structure:** Header (name, level, inspiration, settings) over six always-
  visible tabs over stacked ruled sections. One job per tab.
- **Border radius:** 0. Sharp print corners across the system. (Locked comps
  contain no border-radius declarations; keep it that way.)
- **Create-character:** Stacked Accordion. One section open at a time with a
  green left bar; completed sections collapse to a header row with the value in
  bronze; last section is always Review. The whole form stays on one page.
- **Login exception:** Skyfall Immersive. Full-bleed `docs/Mountains.png`,
  sigil seal, dark-only, TPK corner credit on desktop. Framing values are
  locked in its approved.json; do not re-crop.

## Motion

- **Approach:** Minimal-functional. The locked comps ship zero transitions;
  motion is allowed only where it aids comprehension (accordion open/close,
  modal enter/exit).
- **Easing:** enter ease-out, exit ease-in, move ease-in-out.
- **Duration:** micro 50-100ms, short 150-250ms. Nothing longer. No floating,
  glowing, bouncing, or page-turn theatrics.

## Anti-patterns (hard rules)

- No purple/violet gradients, no gradients at all.
- No card mosaics or 3-column icon grids (explicit rule: none on Aptitudes).
- No new colors. Any additional hue is a design decision for this file first.
- No fantasy display fonts, no faux-medieval ornament, no torn-paper edges.
- No hamburger tabs, no truncated tab row.
- Icons support labels; they never replace them.

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-07-19 | Editorial hybrid direction locked (R1-R5): Anton + Archivo, paper/ink neutrals, green + bronze accents, all six screens light + dark | Five-round feedback loop; grimoire and HUD directions rejected; extended palette tried and cut to "green + bronze + neutrals" |
| 2026-07-19 | Reserved colors: damage `#FF5143`, arcane `#00C0F5` | Game meaning must stay unambiguous; never reuse decoratively |
| 2026-07-20 | Login = Skyfall Immersive, dark-only, wordmark "The Leyfarer's Chapterhouse" | Approved variant A1; framing locked |
| 2026-07-22 | Create-character = Stacked Accordion (variant E) | Wizard clarity without wizard tunnel vision; smallest build cost on existing CharacterForm store |
| 2026-08-11 | DESIGN.md codified from locked artifacts; memorable thing confirmed: "our campaign's own chronicle" | /design-consultation; comps remain visual authority, this file is the token authority |
