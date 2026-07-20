# Leyfarers Design Document v2 — Requirements Digest

Source: `docs/Leyfarers Design Document - v2.md` (1306 lines; lines 1291-1306 are embedded base64 mockup images image1-image9: limited-use action UI, Character, Combat, Spells, Inventory, Aptitudes, Breaks, Settings, Components).

---

## 1. Purpose & Design Principles

- Mobile + desktop app to manage D&D 2024 characters for the Leyfarers/TLC homebrew campaign. Reduces manual tracking/calculation during play; does not replace roleplay. Neutral facilitator: removes overhead but every value can be manually overridden.
- Player rolls physical dice; a dice roller is a possible future addition.
- Inspiration/reference: charkeeper.org (existing codebase, implementation target), mothershipcompanion.com (UI/UX), charsheet.derikbadman.com, DnD-5e-Character-Sheet (lckynmbrsvn), adventurerscodex.com, crobi dnd5e-quickref (for combat-tab actions, pre-2024).

### Universal behaviors
- **Minimal screen switching**: everything for RP + skill challenges on Character screen; everything for combat on Combat screen; minimal clutter (OK to split to another tab if it hurts usability, e.g. Spells). Custom-content add flows are inline and context-aware.
- **Non-blocking warnings** for invalid/rule-breaking choices, e.g. "You do not meet the ability prerequisites to multiclass into Paladin (13 STR, 13 CHA required)." Warnings include a brief explanation and source (**PHB or TLC**), are dismissible/collapsible, and NEVER prevent continuing.
- Easy to **undo or revise** any decision; a **summary of all rule warnings** on the character overview page for quick diagnostics.
- **Helpful, unrestrictive**: smart suggestions from rule logic ("You gain proficiency in two skills from this list…"); user can override/skip/manually assign any value; gentle highlighting of missing/incomplete areas ("you haven't selected your Fighting Style yet"); any field re-editable; never blocks progress for incomplete/"incorrect" setups.
- **Traceability**: the system remembers what was done via wizard vs manual override; keeps a **log of all actions** for both admin and each character.

---

## 2. Screens & Features

App is tab-based, except login and the no-characters state.

### Login
- Login goes to character screen; shows last selected character; launches Create-a-Character wizard if user has no characters.

### Topbar
- **Heroic Inspiration**: toggle on/off.
- **Level #**: tap/click shows breakdown of all classes ("Fighter 3 / Wizard 2") with class-level summary view + option to Level Up.
- **Character Name**: truncate if too long.
- (Component tree also includes Avatar and Settings button.)

### Character tab
- **Ability Scores** — editable.
- **Proficiency Bonus**, **Size**, **Passive Perception**.
- **Saving Throws** — editable to add modifiers.
- **Skills**:
  - Show skill, score, and current advantage/disadvantage state.
  - Click a skill to see: ability modifier, proficiency modifier, any active effect modifier, what is giving adv/disadv; edit to give a custom modifier.
  - Manually add a proficiency.
  - Must account for effects/feats: expertise, jack-of-all-trades.
  - Must account for magic item bonuses ("Quartz Helm of Clarity").
- **Other modifiers**: Species, Feat, and Intrinsic notes that are not combat related.
- (Component tree: also Aptitudes summary, Species info + non-combat traits, Class non-combat features, non-combat Feats, CompanionStatBlock.)

### Combat tab
- **Armor Class, Initiative, Speed**: speed as multiple small fields or one large one for walk/fly/swim/burrow breakdown; editable for custom modifiers.
- **Spell DC**: if some spell types have higher/lower DC than the base, show a star; clicking shows DC per spell type with add/remove modifiers.
- **Health / Max Health / Temp HP / Hit Dice**:
  - Easy toggle buttons to add/remove HP; **must be able to heal above max health**.
  - Tap/click points to update max HP and temp HP numbers.
- **Death Saving Throw** successes + failures.
- **Exhaustion Points**.
- **Concentration**: **automatically toggles on when you cast a Concentration spell**.
- **Status Toggles**: show all acquirable status effects.
- **Damage Resistances**: quickly see all currently active vulnerabilities, resistances, immunities; tap section to toggle each on/off.
- **Spell Slots**: empty boxes touched to fill.
- **Actions**:
  - Aggregates every available action from: spells, rules (e.g. Study action), equipped items, class abilities, consumable items, feats — each source a collapsible subsection.
  - Spells shown by level within their section.
  - Feats granting 1 free spell use show the spell in the Feats section (for the use) AND as a prepared spell in the Spells section.
  - Tap a skill/spell name pops a description.
  - Show attack bonus or DC (excluding spells' DC display here), damage modifier, and damage type(s).
  - Limited-use actions: toggle to use a charge + count of uses before short/long rest (see image1 mockup).
  - Casting a spell: shows list of castable levels; picking one toggles a spell slot. Spells show damage dice, DC, and type where applicable.
    - **Defaults to consuming an ability/feat free cast first** if available ("can cast X once without expending a spell slot"), with an override toggle (use spell slot instead of ability).
    - If the spell is available via an item (e.g. Wand of Magic Missiles), toggle to use item charges instead of a spell slot.
  - Items with charges indicated the same way as limited actions.
  - Consumable items noted; using one decrements inventory by that amount.
- **Bonus Actions** / **Reactions**: behave the same as Actions but for their action type.
- (Component tree adds: CompanionCombatBlock with its own ActionList/BonusActions/Reactions.)

### Items / Inventory tab
- **Base categories**:
  - **Equipped** — affects stats (AC, movement, resistances, spell DCs, etc.).
  - **Backpack** — does NOT affect stats; has a "Used" subsection for consumables at 0 qty.
  - **Stored** (bank, cart, home) — does not affect stats; pushed to bottom.
- **Gold total**: single gold number; silver = 0.1 gold, copper = 0.01 gold.
- **Add an Item**: add a mundane item, search for an item, or create a custom item with the Item Wizard. Custom items can define: bonus types (flat, conditional), what they apply to (AC, skills, spells, etc.), attunement requirement, any additional effect + which tab it displays in (Combat, Non-Combat, Both).
- **Consumables**: QTY with +/- toggle; at 0 QTY move to Backpack "Used" section; 0-QTY items appear only under Items tab, not elsewhere.
- **Equipped items**: system auto-applies mechanical effects — AC, saving throws, ability checks, resistances, immunities, movement speed changes, spell save DC/attack bonuses (e.g. Rod of the Pact Keeper), weapon/armor mastery effects, spellcasting bonuses. Unequipping to backpack/storage removes bonuses. Backpack = inactive regardless of attunement.
- **Attunement**:
  - Default limit 3 attuned items per character; certain skills/abilities can change this number.
  - Equipping an attunement item puts it in the Attunement section rather than Equipped; all attuned items count as Equipped.
  - At max attunement, equipping another prompts: "You have max attuned items. Please choose an item to unattune"; allow override to ignore the limit (with warning); allow equipping without attunement — Equipped-but-not-attuned = inactive (gray icon/label).
- **Stored Items**; **Spell Components** (open question inline: should this section interact with Spells?).
- Pre-populated item database + custom item creation.
  - Non-magical weapons/armor can be edited to add basic "+X" enhancements; anything beyond requires DB search or custom item.
  - Each item includes: type, rarity, attunement requirement, charges, effects, weight, gold value; affects: attack bonus, damage, saves, skills, speed, tools, languages, stats.
  - Magic item rarity colors: Common=Grey, Uncommon=Green, Rare=Blue, Legendary=Purple, Unique=Gold; asterisk if attunement required. (No color given for Very Rare — see contradictions.)
- Consumable/basic items: quantity input with quick +/-; weapons/armor/magic items: Equip/Unequip toggle with immediate stat recalculation.
- **Charged magic items**: show current/max charges (3/7), allow manual adjustment anytime, display recharge rule ("regains 1d6+1 charges at dawn").

### Spells tab
- Sections broken out **by class**; class sections collapsible; each conforms to that class's rules (Wizards see known spells + add-to-spellbook option).
- Sections: **Prepared Spells** (filters; "always prepared" section at bottom), **Learned Spells**, **Ability or Item Spells**. This tab is for preparing/learning/managing spells, not casting.
- Filter by: level, components, cost, range, school, description, casting time, duration, component (V/S/M), concentration, ritual.
- Toggle default display of: level (if not grouped by), components, cost, range, school (if not grouped by), description, casting time, duration component, concentration, ritual.
- Group by: level, school.
- Show cantrip max and total prepared count; can prepare more than allowed.
- Add a spell from another class within each class section with an override option (learned-spell classes: button on the learn-spell toggle; prepared-spell classes: button next to the class name).
- System calculates allowed prepared count per class ("You can prepare 5 Cleric spells"); players may exceed it; soft warning: "You have prepared 8 spells, but your limit is 5. (Cleric Level 3 + WIS modifier 2)".
- Prepared spells manually toggled per class; **no automatic daily reset** — players control prep; quick "Clear All" toggle. Spells from feats/items/multiclassing grouped separately with prep toggles if needed.
- Known-spell classes: system calculates/displays allowed known count; players can exceed; soft warning "You know 10 Bard spells, but are only allowed 8 at level 6." Easy add/remove; "Remove All" toggle.
- (Behaviors section: item-granted innate casting appears under an "External Sources" spell section, filterable by source (Class, Feat, Item…), respects per-day/per-rest limits with automatic usage tracking and recharge logic (1/day, regains d6/day).)

### Aptitudes tab
- **Feats**: summary title (e.g. "Wyrmkin Adept") expanding to all granted elements ("Tool Proficiency: Tinker's Tools, Language: Draconic"). Grouped by: Origin, General, Fighting Style, Epic Boon, **Val'Ruvina**.
- **Languages**.
- **Weapons + Armor**:
  - Proficiencies — if a subset, option to pick specific weapon/armor types.
  - **Mastery** — show count of weapon types with mastery; select mastery (may select more than allowed, with warning); qualifying weapons in inventory get mastery tags auto-applied; weapon attacks on Combat tab auto-update for mastery effects.
- **Tools and Instruments**.
- **Intrinsics**: semi-permanent or miscellaneous effects — Supernatural Gifts, curses, abilities, modifications granted over the Leyfarers campaign; plus traits from Lineage selection.

### Rest (a.k.a. Breaks tab in component tree)
- Toggles a popup with Short Rest, Long Rest, Session Rest. (Component tree makes it a `BreaksTab` with ShortRest / LongRest / SessionRest / **LevelChange** children — see contradictions.)
- **Short Rest**: refresh short-rest abilities; select hit dice used + HP recovered; display list of refreshed features; spell slot restoration; optional conditions; custom recharge items/charges; option to swap abilities that permit it; option to restore per-session abilities (unchecked by default).
- **Long Rest**: fully restore HP; remove 1 exhaustion point (toggle to remove more); spell slot restoration; custom recharge items/charges; restore all short/long-rest abilities; option to swap abilities that permit it (e.g. Weapon Masteries); optional conditions; option to restore per-session abilities (unchecked by default).
- **Session Action**: restores per-session abilities; prompts a dialog to take a long/short rest (launches rest screen).
- **Rest screen**: summarizes what will refresh; user confirms before applying; per-item toggles, e.g. Restore Rage Uses (2/2), Recharge Wand of the Warmage (0/3), Regain 1 Exhaustion Level, Restore Spell Slots, Refresh "Flame Step" (custom Intrinsic). "Apply Rest" executes chosen steps only, leaves others untouched.

### Settings
- **Character settings**: change character or create new; upload avatar (shown on Select Character menu); delete character (confirm by typing "delete me"); Reset All User Modifications/Overrides; Show Avatar on Character Screen toggle.
- **Change Log**: all changes logged to a per-character change log. Entries batched (e.g. "-10 hit points, condition of fear"): batch covers all changes from last entry until X seconds of inactivity. Rest logs like "Last Rest: Long, 08/04/25, +1 HD used, 2 spells restored."
- **Exporting**:
  - Formats: Official-Style Sheet (mimics 2024 D&D sheet layout) or App-Style Sheet (mirrors app tabs).
  - Section selection: Core Stats, Combat Stats, Spells, Items & Equipment, Aptitudes, Companion Sheet; buttons for Select All or Summary (Summary = Core + Combat stats).
  - Option to include overrides + annotations ("AC is 18 due to Bracers of Defense + manual override").
  - Single-click PDF download; filename `CharacterName_Level_Class_MM-DD-YYYY.pdf`. (Sentence trails off: "If you don't want to export…".)
- **Share via live link**: real-time sync of changes on shared link; only 1 active link at a time; copy/revoke; content filters: stats only / actions+spells only / inventory only / everything (default).
- **Account settings**: reset password, update email, feedback, links (policy etc.), logout. (Component tree also has DeleteAccount.)

### Companion
- Covers warlock familiars, summoned companions, pets, bonded creatures. A special character type tied to the admin companion-template list, tied to an existing character on the account; creates a special "Companion" section in the owner's Combat and Character pages.
- Creation requires selecting the owning character; can reassign to a different character on the account from the companion sheet; a character can have multiple companions.
- Companions do **not** level up, gain XP, or auto-unlock features. HP, AC, actions, stats manually editable at any time; can create and assign new traits.
- **Creation** via limited character-sheet UI: name, type (selectable list defined in admin), ability scores, HP/AC/movement, actions/spells/traits.
- **Inventory**: own mini-inventory (Equipped/Backpack only), supports consumables and attunement; items (potions, infused collars, spell batteries) usable from the companion sheet or the owner's Combat tab.
- **Combat tab**: compact card in the owner's Combat tab with HP, conditions, initiative bonus, action buttons (bite, help, magic attack); modifiable like a main character.
- **Character tab**: "Switch to Companion" swaps to full editable companion sheet; "Return to Owner" comes back.
- **Rest & recharge**: same rest mechanics — hit dice (if relevant), short/long rest usage tracking, custom features supported.

---

## 3. App Behaviors

- Display both system-calculated and user-overridden values where relevant; small indicators (asterisk, pencil icon) denote overrides.
- Dedicated sections collapsible on each tab.
- All gameplay fields (HP, AC, spell slots, etc.) inline-editable; undo/revert to calculated state where applicable.
- **Per-use features** tracked under Combat > Actions: Rage, Wild Shape, Channel Divinity, Action Surge/Second Wind, Lay on Hands, and similar TLC-subclass abilities. Each gets a usage counter (0/2) that auto-increments (restores) on short/long rest and has a manual-adjust toggle.
- During Long/Session Rest: rechargeable items included in the Rest Summary panel ("Wand of Magic Missiles: roll recharge?") with +/- buttons to manually set charges gained.
- **Items**:
  - Magic item effects fully described in tooltip/quick-expand (same pattern as spells).
  - Actions tab shows for weapons/consumables/limited-use items: attack roll bonus (magic factored in), damage type/dice, save DC if applicable, usage counters ("1 of 3 charges used").
  - Item-granted innate spellcasting: "External Sources" spell section, filterable by source, auto usage tracking, recharge logic.
  - **Passive effects** from gear (adv/disadv, movement, skill bonuses, resistances, conditions): auto-apply in background mechanics (e.g. auto-calculated stealth bonus); noted with a passive-effect tag in character summary and conditions panel; toggle off when unequipped/unattuned.
  - Consumables: appear in a Consumables subsection of Actions/Combat; auto-decrement on use; move to "Used" bin or gray out in backpack when depleted.

---

## 4. Admin

Purpose is twofold: (1) avoid the "Hasbro lawyer problem" (no bundled WotC content; data entered/imported), (2) manage and add future Leyfarers-universe unlocks. Also enables self-hosting with own homebrew. Interface should be **spreadsheet-like**, one section per content type, integrating with wizards for advanced needs.

- **Anatomy of an effect** (section header present but EMPTY): feats, spells, magic items, intrinsics can affect a character in a number of ways — not elaborated.
- **Content visibility states**:
  - Public — visible/searchable by all.
  - Locked — cannot be added to new characters, hidden from search, existing characters keep it.
  - Depreciated [sic] — cannot be added; entity is removed from existing characters, prompting replacement; user warned on first character open about what was removed.
  - Hidden — can be on characters but only appears in selection/search if exact name typed.
- **Content types managed**: Feats, Skills, Proficiencies, Classes + Subclasses, Spells (admin defines spellcasting capability by class and allowable spells), Items (magic + mundane; weapon/armor types; tools/instruments), Species and Lineages, Intrinsics (incl. companion-specific traits like "Owl Flyby"; Supernatural Gifts/Abilities/Modifications), Languages, Companion Templates.
  - Companion Templates have: name, species, size, AC, HP, speed; traits/features/actions; optional inventory; tags (Familiar, Mount, Pet, Automaton, etc.); companion traits defined like intrinsics but flagged "Companion-only" (Flyby, Bound Soul, Loyalty Bond).
- **User Generated Content**: view all user-created content; "promote" an item into the full database for all users; mark as reviewed (hides from list).
- **Manage users**: view all users + metadata (email, join date, character count, last login); search/filter; disable/ban; manual password resets; restore backups/imports; view all custom content by a user; reassign ownership of characters/companions.
- **Import data**: import from other sources (e.g. 5e.tools) to populate.
- **Admin roles**: Superadmin (all powers, creates admins), Content Admin (feats/items/spells/species…), Moderator (users, password resets), Content Reviewer (view/approve user submissions only).
- Admin can pre-build campaign-specific powers (Flame Step), faction unlockables, world-specific boons/curses (Val'Ruvina-specific magic, Leyfarer ranks); players receive via selectable lists or (future) auto-assignment via companion features.

---

## 5. Wizards / Workflows

### General customization (custom action/spell/passive trait/reaction)
- Define: name, description, usage limits (per rest / per day / per session), recharge type (short rest, long rest, X/day, "session only"), save DC or attack roll, damage dice + type (optional), tags (Bonus Action, Reaction, Spell, Skill, Intrinsic, Custom Origin, etc.), skill modifiers.
- Appears fully integrated in: Actions tab (sections like Class Features / Magic Items / Custom), Combat UI summary if relevant, Spells tab if spell-type. Auto-tracked with rest logic (counters reset per spec); manual override always available.

### Character creation wizard
- Can flag character as companion/familiar (unlocks admin-defined companion options).
- Species selection (with species-appropriate attribute traits), Background, Origin, stat allocation + hit points, class selection (core classes) + subclass selection; pulls languages, proficiencies, feats from the admin list.

### Leveling
- "Level Up" modal selects which class gets the next level; add feat at specified levels; unlock class-level abilities; choose Epic Boon at level 19; can level multiple levels at once (e.g. 4).
- Multiclass: select a second class any time after level 1; class breakdown summary; independent subclass choices per class; multiclass prerequisites (min 13 in key abilities) enforced as prompts + soft warnings only.
- Spellcasting/scaling features (Extra Attack, feats, proficiency bonus) calculated per **5e + Leyfarer multiclass rules**, explained via tooltips/toggles (especially combined spellcasting).
- Features from different classes grouped in collapsible per-class sections; all class spell sections maintained and toggleable.

### Custom Item / Custom Intrinsics / Custom Feat
- Section headers exist but are EMPTY — flows undefined.

### Wizard behaviors (repeat of universal principles)
- Smart suggestions; override/skip/manual assign; gentle highlighting of incomplete areas; every field re-editable; never blocks; wizard-vs-override provenance remembered.

---

## 6. UI / UX

- Clean, minimal, for in-game use; responsive desktop/mobile/tablet; **mobile-first** (used at the table).
- **Screens**: 1 Login & Account; 2 Character Select (avatar grid/list); 3 Character Sheet (tabs: Character, Combat, Spells, Inventory, Aptitudes); 4 Level Up Wizard; 5 Rest Modal; 6 Export & Share; 7 Admin Panel.
- **Routing**:
  - `/` → login (or redirect to /characters)
  - `/characters` → character select
  - `/characters/[id]` → character tab root
  - `/characters/[id]/[tab]` → tabs (character, combat, …)
  - `/characters/[id]/level` → level-up wizard
  - `/admin` → admin panel
  - `/export/[id]` → printable/export view
  - `/share/[linkId]` → read-only sync viewer
- **Component tree**: `LayoutShell` > Sidebar (desktop nav), TopBar (name, avatar, level, heroic inspiration, settings button), TabBar (Character | Combat | Spells | Inventory | Aptitudes | **Breaks**), TabContent switching among CharacterTab / CombatTab / SpellsTab / InventoryTab / AptitudesTab / BreaksTab.
  - CharacterTab: AbilityScores, ProficiencyBonus (Base, PassivePerception, SavingThrows), Skills, Aptitudes, Species (info + non-combat traits), Class (non-combat features), Feat (non-combat), CompanionStatBlock.
  - CombatTab: Primary (AC, initiative bonus, walk speed), HealthBlock (+DeathSavingThrows, HealthBlock [duplicated in doc], ExhaustionPoints), Effects (Concentration, DamageResistances, StatusEffects), ActionList (incl. combat intrinsics; Weapons, SpellAttack, SpellsDC, Spells), BonusActions (Spells), Reactions (Spells), CompanionCombatBlock (ActionList, BonusActions, Reactions).
  - SpellTab: per-Class (Allowed qty to prepare/learn/cantrips/known; Update button to prepare/learn showing available spells), Levels, NonClassSpells (AddSpell showing all spells for all classes by level), Aptitudes (feat/lineage/trait/item spell grants). Note: "a lot of the complexity is the actions to add/remove spells."
  - InventoryTab: Header (Gold, AddItem, Filters — Is Consumable? Is Magic?), Attuned, Equipped, Backpack, Stored.
  - AptitudesTab: Feats, Languages, Weapons, Armor, ToolsAndInstruments, Intrinsics.
  - BreaksTab: ShortRest, LongRest, SessionRest, **LevelChange**.
  - SettingsButton: SwitchCharacter; Character (UploadAvatar, CharSettings, Changelog, Export, Share, DeleteChar); AccountSettings (Reset Password, Update Email, Feedback, Links, Logout, DeleteAccount).
- **State handling**: local UI = useState/useReducer; character data = Redux slice `characterData`; server content = Redux slice `content` (or React Query); auth = `auth`; live share = `sync`; settings/preferences = `ui` persisted via localStorage.
- **Reusable components**: StatBox (editable value with calc + override), ToggleIcon (adv/disadv switch, On/Off), QTYToggle, X (remove line/close modal), InfoModal, RestSummaryModal, SpellCard, ValueCalcModal, ItemRow, Tabs (collection of Sections), StaticSection, ExpandableSection (Open/Closed), EditableField (inline override support).
- Screens section contains mockup images for Character, Combat, Spells, Inventory, Aptitudes, Breaks, Settings, Components (base64, not machine-readable here).

---

## 7. Technical Design

### Stack (every choice marked "(?)" — undecided)
| Layer | Tech (proposed) |
|---|---|
| Frontend | React + Next.js (?) |
| Backend | Node.js + Express or NestJS (?) — modular API service |
| Database | PostgreSQL (?) |
| Realtime | Socket.IO or Supabase Realtime (?) — live link sharing/sync |
| Auth | Supabase Auth or Firebase Auth (?) — Google OAuth + email/password |
| Storage | S3-compatible or Supabase storage (?) — avatars, PDFs, exports |
| PDF | Puppeteer or PDFKit (?) |
| Admin panel | React + Next.js (?) |

### General
- **Offline is key**: state tracking required. Domain slices separate persistent synced data (characters, spells), UI state, live overrides/local edits.
- **LocalStorage/cache**: persisted slices auth, ui, content (optional), last loaded character; unsaved edits via overrides or draft buffer; offline-first rendering with autosave queue; **warn if offline and online versions diverge**.
- **Auth**: Google OAuth; manual registration (username/password/email, email-validation hold screen, activate on validation); forgot password/username.

### Calculations
- App handles all calculations automatically; manual override for house rules/DM exceptions; effect toggles update sheet in real time; temporary + override modifiers show a small asterisk.

### Definitions (common fields for all content entities)
| Field | Required | Notes |
|---|---|---|
| Name | yes | unique, user-facing |
| Description/Lore | yes | Markdown |
| Tags | opt | filtering, source flags (TLC, SRD, PHB2024) |
| Source | yes | "PHB", "TLC", "Homebrew" |
| Prerequisites | opt | level, species, class, feat, lineage, etc. |
| Effects | yes | AC bonus, spell slots, languages, damage mod, etc. |
| Charge/Regen Logic | opt | d6/day, once/session, long rest, manual |
| Overrides Allowed | yes | yes/no flag |
| Visibility/Availability | yes | Public, Locked (DM only), Faction Unlocked, Hidden |

### Enum types
- Language (Common, Deep Speech, **Val'Ruvian**); Tool (full PHB tool list); Instrument (Bagpipes…Violin); Weapon (Simple, Martial); Armor (Light, Medium, Heavy, Shields); Damage/Resistance (13 standard types); Item (Weapon, Armor, Consumable, Wondrous, Tool, Instrument, Component, Misc); Attributes/Saves (STR/CON/DEX/INT/WIS/CHA); Skills (18 standard); Spell Schools (8); Weapon Mastery (Cleave, Graze, Nick, Push, Sap, Slow, Topple, Vex); Creature Type (14 standard); **Bonus** (Proficiency Bonus, Ability Check Bonus, Attack Roll Bonus, Damage Roll Bonus, Saving Throw Bonus, Spell Attack Bonus, Spell Save DC Bonus, Ability Score Bonus); **Activations** (Action, Bonus Action, Reaction, X time, Free Action); **Reset Conditions** (Short Rest, Long Rest, **Session Rest**, Custom); Feats (Origin, General, Fighting Style, Epic Boon).

### Effects
- Two "Effects" section headers exist (one under Technical Design, one after the Character/User tables) — **both are EMPTY**. The effects system, the doc's most load-bearing subsystem, is not specified.

### Database design

**Spells**: Name (text, unique), Level (int 0-9, 0=cantrip), School (enum), Casting Time (dropdown/text), Range (structured text), Duration (text, special handling for Concentration/Until Dispelled), Components (V/S/M checkboxes + material note), Concentration (bool), Ritual (bool), Description (Markdown), Higher Levels Text (Markdown, upcast override), Source (PHB/TCE/TLC/Custom), Visibility (Public/Locked/Hidden), Tags (chips, e.g. Healing/Damage/Control/TLC-only), Custom/Official (bool), Damage Dice (text "2d6"), Damage Type (enum), Save Type (enum), Attack Roll (bool), Affects (multi-select: creatures/objects/area), Conditions Applied (tags e.g. Restrained), Applies Status Effect (enum/text e.g. "Decrease Con"), Combat/Non (bool: display on Combat vs Character tab).

**Items** (base): Name, Type (Weapon/Armor/Consumable/Wondrous/Tool/Instrument/Component/Misc), Is Magical (bool), Is Consumable (bool), Description (Markdown), Source (PHB/TLC/Custom), Visibility, Tags, Custom/Official, Weight (float lbs), Gold Value (float, supports 0.1/0.01), Stackable (bool, default true unless unique/magical/equippable).
- Magic-specific: Rarity (Common, Uncommon, Rare, **Very Rare**, Legendary, Unique — with tooltip coloring), Is Cursed, Attunement Required, Total Charges, Charge Reset (Short/Long/Session/Custom).
- Weapon-specific: Damage Dice, Damage Type, Range ("Melee", "30/120"), Properties (multi: Finesse/Reach/Thrown…), Weapon Mastery (enum), Bonus to Hit/Damage (int), Requires Ammo Type (optional).
- Armor-specific: Base AC, Dex Cap, Strength Requirement, Stealth Disadvantage, Armor Type (Light/Medium/Heavy/Shield).

**Aptitudes**:
- Proficiency: Name, Type (Language / Tool and Instrument / Weapon / Armor), Description (opt Markdown), Tags (TLC-only, Exotic, Legacy), Source, Visibility, Custom/Official.
- Feats: Name, Description, Source (PHB/TCE/TLC/Custom), Visibility, Level Requirement (opt int), Prerequisites ("freeform or structured fields?" — open), Tags, Custom/Official, Combat/Non (bool).
- Intrinsics, Skills, CharacterStats: headers only, EMPTY.
- Species/Lineages/Traits: Name, Subtypes/Lineages (list), Description, Source, Visibility, Tags (Fey, Wilderfolk, Custom, Tiny-only), Creature Type (enum), Size Options (multi-select; some choose at creation), Speed (int), Darkvision (bool + range), Innate Traits (always granted), Selectable Traits (choose N, configurable), Languages Known (starting + Common). Lineage and Traits sub-schemas EMPTY.
- Proficiency extras table: Associated Skill (enum, tools/instruments, e.g. Sleight of Hand for Forgery Kit), Mastery Required (bool, weapon/armor), Rarity (enum, languages: Common/Rare).

**Classes**: Class Name (e.g. Fighter, **Fateweaver**), Source, Hit Die (d6/d8/d10/d12), Primary Ability (multi, for multiclass prereqs), Proficiencies Gained (structured: armor/weapons/tools/saving throws), Skills Available (list + choose-N), Spellcasting (object: level acquired, progression table, prep/known mechanic), Subclass Level (int), Visibility, Tags ("Full Caster", "Half Caster", "Melee", "TLC"), Level Features (1-20 table — schema nearly EMPTY, only Combat/Non bool defined), Weapon Mastery (enum + count, 2024 rules e.g. "2 at level 1").
- **Level Gated Choice**: Choice Label ("Choose your Divine Order"), Options (list of objects: name/description/effects), Grants (structured, same as feat fields — spells, proficiencies, actions, modifiers), UI Behavior (Dropdown/Cards/Radio), Optional? (bool). The chosen value lives on the Character table. Examples: Cleric Divine Order at 1 (Protector/Thaumaturge/Scholar), Fighter Combat Style at 1, Druid (TLC) Dreamwild Bond, Warlock (TLC) Pact Mutation.

**Character**: `id` UUID PK, `owner_id` UUID FK users, `name` text, `avatar_url` string opt, `metadata` JSONB (custom UI prefs, tags), `is_companion` bool (toggles limited view), `companion_of` UUID nullable (links to main character). — No columns for stats/classes/HP/inventory/spell state: the actual character-state model is unspecified.

**User tables**: `users` (players/admins), `user_settings` (encumbrance toggle, default avatar, etc.), `user_characters` (ownership relationships), `user_roles` (admin/mod/content status).

**Join Tables**: header only, EMPTY.

---

## 8. TLC-Specific / Homebrew Concepts

- **TLC** = the campaign/homebrew source; warnings cite "PHB or TLC"; content tagged Source=TLC.
- **Aptitudes**: umbrella tab/term (not standard D&D) covering Feats, Languages, Weapon+Armor proficiencies & masteries, Tools/Instruments, and Intrinsics.
- **Intrinsics**: semi-permanent/miscellaneous effects — Supernatural Gifts, curses, abilities, modifications granted over the Leyfarers campaign; also Lineage traits. Companion-only variants exist (Flyby, Bound Soul, Loyalty Bond). Example custom intrinsic: "Flame Step" (from a sidequest).
- **Breaks**: the tab name for the rest system, including LevelChange in the component tree.
- **Session Rest / per-session abilities**: a third rest type; "Session Rest" is a Reset Condition enum value; abilities can recharge "once/session" or "session only"; Session action restores per-session abilities and prompts short/long rest.
- **Val'Ruvina**: a feat grouping category (alongside Origin/General/Fighting Style/Epic Boon) and a world source ("Val'Ruvina-specific magic"); **Val'Ruvian** is a language.
- **Leyfarer ranks**: world-specific unlockables admins can build.
- **Leyfarer multiclass rules**: scaling features calculated per "5e + Leyfarer multiclass rules" (not defined in doc).
- **TLC classes/subclasses**: example class "Fateweaver"; Druid (TLC) "Dreamwild Bond" choice; Warlock (TLC) "Pact Mutation" choice; "TLC subclasses" with per-use features.
- **Unique rarity tier** (gold color) above Legendary — not in standard 2024 rules.
- **Language rarity** (Common/Rare) as a data field.
- **Heal above max health**: explicitly allowed (non-RAW).
- **Per-spell-type Spell DCs**: some "spell types" can have higher/lower DC than the base with a star indicator (non-standard).
- **Lineages** with innate + selectable traits (choose N, configurable) — TLC species model; example species "Frogfolk"; tags like "Wilderfolk".
- **Companion Templates** as first-class admin content with companion-only traits.
- Example TLC-flavored items/content: "Quartz Helm of Clarity", "Wand of the Warmage", "Wyrmkin Adept" feat, spell batteries, infused collars.

---

## 9. Questions (from the doc, condensed but complete)

- **Structured tables vs JSON blobs**: "At what point should everything be structured vs thrown into a JSON file to be parsed in the DB?" E.g. level-1 Cleric Divine Order choice: (a) a `choices` table referencing the level-gated-choice table which is referenced by the level-features table, OR (b) a JSON blob on the level-gated-choices table shaped like:
  - `{ "name": "Protector", "description": "...Martial weapons and Heavy armor...", "grants": { "proficiency": [PROF123, PROF124] } }`
  - `{ "name": "Thaumaturge", "description": "...extra cantrip... Arcana/Religion bonus = WIS mod (min +1)", "grants": { "proficiency": [PROF122, PROF111], "bonus": +wis, "spells": { "cantrip": +1 } } }`
- Inline open questions elsewhere: Should the Spell Components inventory section interact with the Spells tab? Feat prerequisites: freeform text or structured fields? All tech-stack rows marked "(?)".

---

## 10. Future / Out of Scope

- **Encumbrance** (explicitly out of scope; notes preserved): enable/disable in options; Backpack contributes to weight (with "Used" subsection for 0-qty consumables); Stored excluded from weight; weight total shown only when enabled; magic items/skills can affect carry capacity (e.g. Powerful Build = count as one size larger for push/lift/carry); when enabled, Equipped + Backpack count toward weight, Stored excluded.
- Other features to be added: option to add a custom Intrinsic/Feat [note: contradicts wizard sections that already list these]; option to create custom Companion types.
- Also flagged as future earlier in doc: dice roller (Purpose); auto-assignment of admin powers via companion features ("in a future release").

---

## Contradictions & Ambiguities

### Contradictions
1. **Rest: modal vs tab.** App Screens says Rest "toggles a pop up" and the UI screens table lists "Rest Modal" as its own screen; the component tree makes Breaks a full tab (`BreaksTab` in `TabBar`). The screens table's tab list (Character, Combat, Spells, Inventory, Aptitudes) omits Breaks; the TabBar includes it.
2. **Leveling location.** Level Up is reachable from Topbar Level tap, has its own route `/characters/[id]/level` and "Level Up Wizard" screen, AND appears as `LevelChange` inside BreaksTab. Three entry points, no stated reconciliation.
3. **Tab name: Items vs Inventory.** The screen spec section is titled "Items"; the component tree, screens table, and routing use "Inventory".
4. **Visibility states disagree.** Content Management: Public / Locked / Depreciated / Hidden (4 states incl. removal-with-prompt semantics). Definitions table: Public / Locked (DM only) / **Faction Unlocked** / Hidden. All DB tables: Public / Locked / Hidden only. Three different enums for the same field.
5. **Rarity tiers vs colors.** Item screen colors list Common/Uncommon/Rare/Legendary/Unique (no Very Rare); DB rarity enum is Common/Uncommon/Rare/Very Rare/Legendary/Unique. Very Rare has no color.
6. **Feat categories.** Aptitudes tab groups feats into Origin/General/Fighting Style/Epic Boon/**Val'Ruvina**; the Feats enum row lists only Origin/General/Fighting Style/Epic Boon.
7. **Depleted consumables.** Items section: at 0 QTY the item moves to the "Used" subsection; Behaviors section: "Move to 'Used' bin **or gray out** when depleted" — two different behaviors offered.
8. **Custom Intrinsic/Feat scope.** Wizard section has (empty) "Custom Intrinsics" and "Custom Feat" headings implying in-scope; Future section lists "Option to add a custom Intrinsic / Feat" as a feature to be added.
9. **Companions don't level but rest with hit dice.** "Companions do not level up… do not unlock new features" vs Companion Rest "Hit dice (if relevant)" — companions have no defined hit-dice source.
10. **Component tree typo/duplication**: `HealthBlock` appears nested inside itself in CombatTab; TopBar shown twice in LayoutShell area (Sidebar + TopBar + duplicate SettingsButton nesting). Mockup-level, but the tree can't be implemented verbatim.

### Implementation-blocking ambiguities
1. **The Effects system is unspecified.** "Anatomy of an effect" (Admin) and both "Effects" technical sections are empty, and "Join Tables" is empty — yet effects are the core engine (items, feats, intrinsics, spells, conditions all funnel through it). Biggest gap in the doc.
2. **Character state schema missing.** The Character table has only identity fields (id/owner/name/avatar/metadata/companion flags). Where HP, ability scores, classes/levels, prepared spells, inventory instances, overrides, and choice selections live is undefined (only "Choice lives on the Character Table" is stated).
3. **Class Level Features schema is empty** (only a Combat/Non boolean); Intrinsics, Skills, CharacterStats, Lineage, Traits DB schemas are empty headers.
4. **Entire tech stack undecided** — every layer has "(?)"; state layer says "Redux slice … (or React Query)".
5. **Structured vs JSON storage** (the doc's own open question) determines the whole content-data model.
6. **"Leyfarer multiclass rules"** referenced but never defined.
7. **Per-spell-type DC**: "spell types" is undefined (school? class? damage type?).
8. **Override/audit model**: overrides must be indicated, revertible, reset-all-able, and logged, but no data model for override provenance is given.
9. **Change-log batching**: "after X seconds of inactivity" — X unspecified.
10. **Admin "Depreciated" removal flow**: how replacement prompting works, and what happens to dependent state, is unspecified. Export section has a trailing incomplete sentence ("If you don't want to export…").
11. **Spell Components ↔ Spells interaction**: explicitly left open.
12. **Session Rest semantics**: which abilities are "per session" is data-driven, but nothing defines how a feature is flagged per-session beyond the Reset Conditions enum.

---

## Top 10 Implementation-Defining Requirements

1. **Never-block, soft-warn philosophy**: every rule violation is a dismissible warning with source (PHB/TLC); every value overridable, revertible, and re-editable; a warnings summary on the character overview. This shapes every validation path in the app.
2. **A unified Effects engine**: equipped/attuned items, feats, intrinsics, species/lineage traits, class features, and conditions all apply mechanical effects (AC, saves, skills, speed, resistances, spell DC/attack, adv/disadv) that auto-apply on equip/toggle and auto-remove on unequip, with real-time recalculation. (Unspecified in the doc — must be designed.)
3. **Calculated + override dual-value model**: every stat shows the system-calculated value and any user override with an asterisk/pencil indicator, undo/revert to calculated, "Reset All User Modifications", and wizard-vs-manual provenance tracking.
4. **Combat-tab action aggregation**: Actions/Bonus Actions/Reactions compiled from spells, base rules, equipped items, class abilities, consumables, and feats into collapsible source sections, with usage counters, charge tracking, consumable decrement, free-cast-first defaulting, item-charge vs spell-slot toggles, and upcast level selection.
5. **All game content is admin-managed data** (no hardcoded rules content — the "Hasbro lawyer" constraint): spreadsheet-like admin CRUD for classes, spells, items, species/lineages, feats, proficiencies, intrinsics, languages, companion templates; 4-state visibility lifecycle; 5e.tools import; user-content promotion; 4 admin roles.
6. **Three-tier rest system** (Short/Long/Session) with a confirm-summary screen of individually toggleable refresh actions, ability-swap options, per-session ability restoration, and item recharge logic.
7. **Per-character batched change log** (inactivity-window batching) plus admin action log — implies an event/action layer under all mutations.
8. **Offline-first state** with persisted slices, autosave queue, and offline/online divergence warning; plus real-time read-only share links (single active link, revocable, content-filtered).
9. **Companion subsystem**: template-driven limited character sheets tied to an owner character, embedded stat/combat blocks in the owner's tabs, sheet switching, own mini-inventory, shared rest mechanics.
10. **Creation + leveling wizards with multiclass and level-gated choices**: data-driven choice prompts (Divine Order etc.) whose selections persist on the character, multi-level level-ups, soft-enforced multiclass prereqs, and per-class collapsible feature/spell sections.
