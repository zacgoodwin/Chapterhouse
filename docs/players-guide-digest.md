# TLC Players Guide v2.10 — Character-App Digest

Source: `docs/TLC Players Guide v2.10.pdf` (82 pages, dated 4/30/2026). Digest scoped to what a character manager must MODEL. Lore omitted except where mechanics reference it.

---

## 1. System baseline

- **D&D 5e, "latest printing wins."** Characters use official D&D 5e content, always the most recent printing (i.e., 2024 PHB versions supersede 2014; TCE optional class features belong to 2014 classes only and cannot mix with 2024 classes).
- The guide freely uses **2024-edition machinery**: d20 Tests, weapon Mastery properties, Focus Points (monk), Brutal Strike (barbarian), Magic action, Emanation areas, Bloodied condition, Origin/General feat categories, background-based ability increases (+2/+1 or +1/+1/+1), point-buy per "PH p. 38."
- **Allowed sources** (non-optional rules, latest printing): PHB, TLC (this guide), Basic Rules, Bigby GotG, Book of Many Things, Eberron: Forge of the Artificer (only: Artificer class; Alchemist/Armorer/Artillerist/Battle Smith/Cartographer archetypes; Changeling/Shifter/Warforged species; Homunculus Servant spell), Fizban's, Forgotten Realms: Heroes of Faerûn (only: College of the Moon, Knowledge Domain, Banneret, Oath of the Noble Genies, Winter Walker, Bladesinger; feats Cold Caster, Fairy Trickster, Genie Magic, Street Justice; spells Backlash, Blade of Disaster, Cacophonic Shield, Conjure Constructs, Death Armor, Dirge, Doomtide, Wardaway), MPMM, TCE, XGE. No UA/playtest, no partnered content (e.g., Blood Hunter banned).
- **Unchanged**: core action economy, combat, initiative, rests, death saves, conditions, exhaustion, spell slots, proficiency bonus, multiclassing (except Human trait below).
- **Changed/removed**: alignment removed entirely; ability generation restricted to point buy; leveling replaced by session-based advancement; fixed HP at level-up mandatory; 8 spells banned; species replaced by TLC species system with pick-3 optional traits; backgrounds are build-your-own; Leyfarer Rank added as parallel progression; content gated by campaign-chapter/reputation unlocks.

**Terms the prompt asked about**: "Leylines" appear only as lore (world geography, wild-magic barriers). There are **no mechanics named "Aptitudes," "Breaks," or "Leypoints" anywhere in this PDF**. If those exist, they're in another document (e.g., `docs/Leyfarers Design Document - v2.md`), not the Players Guide.

---

## 2. Character creation

Steps as printed:

1. **Step 1: Origin**
   - **Background — build your own** (or PHB background): choose abilities to increase (+2/+1 to two scores, or +1/+1/+1 to three), one **Origin feat**, **two skill** proficiencies, **one tool** proficiency, **50 GP of equipment** (incl. unspent gold; no martial weapons or armor — those come from class). Every PC also receives a **Leyfarer's Journal** and **Leyfarer's Emblem** (see §3/§8).
   - **Species**: any official-source species, or a TLC species (§4). TLC species with identical names to official ones are *different species* for prerequisites.
   - **Languages**: all PCs know Common (a pidgin; rarely written). Choose others from TLC language tables (§10).
2. **Step 2: Ability Scores** — **point buy only** (PH p. 38). Eight sample arrays offered: 15/15/14/10/8/8, 15/15/12/12/9/8, 15/14/14/12/8/8, 15/14/14/10/10/8, 15/14/13/12/10/8, 14/14/14/12/9/9, 14/14/12/12/12/9, 13/13/13/12/12/12.
3. **Step 3: Alignment** — none. Spells/abilities that vary by alignment (e.g., Spirit Guardians): the caster picks the version when gained. Other alignment references adjudicated by GM.
4. **Step 4: Leyfarer Rank** — see §3.

**Leveling**: PCs **start at level 3**. Advancement is session-based: level = f(session number) (Table 3, §10), capped by campaign chapter (Table 2, §10; chapter 8 → max 12 ... chapter 16 → max 20). Extra session XP past cap transfers to an alternate/future character. **Fixed HP values** per class at level-up (no rolling).

**Alternate characters**: players may keep several PCs for Side Quests; each has own XP/equipment; chapter locks the active campaign character. Non-campaign PCs are rank-0 Prospects; become Initiates on joining. **Retirement**: permanent; session XP refunds to the player for the next character; non-tradeable boons lost; new PC starts as Initiate.

---

## 3. Homebrew mechanics (what a sheet must track)

1. **Leyfarer Rank** (parallel progression, not tied to class level)
   - Ranks: 0 Prospect, 1 Initiate, 2 Adept, 3 Mentor, 4 Advisor, 5 Director. Auto-promotion at end of PC's first two chapters; ranks above Mentor are limited, temporary, nomination-based.
   - At **Adept**, choose a **Focus**: Explorer / Naturalist / Scholar.
   - Perks by rank+focus (table layout in PDF is garbled; best reading): **Skill Proficiency** perk — Explorer: Survival, Naturalist: Nature, Scholar: History (if already proficient, pick another skill); **Ritual Spell** perk — Explorer: Comprehend Languages, Naturalist: Detect Poison and Disease, Scholar: Identify. Mentor perk unlisted/blank. **Advisor**: cast Message at will (Emblem as focus), Message can mass-target all Emblem wearers in range (no replies), Sending 1/day targeting an Emblem wearer. **Director**: "???" (unrevealed).
   - Sheet fields: `leyfarer_rank` (0–5), `leyfarer_focus` (enum, nullable until Adept), derived rank perks (bonus skill, ritual spell, advisor spells).
2. **Leyfarer's Journal** (wondrous, uncommon; auto-granted) — action to write a question, answer in 10 min. **Uses per long rest = Leyfarer rank.** Sheet: per-LR counter keyed to rank.
3. **Leyfarer's Emblem** (wondrous, common; auto-granted) — required material component/focus for rank-based spells/abilities.
4. **Species optional-trait system** — every TLC species = fixed base traits + **choose 3** from a per-species optional pool; some pools contain a **Lineage** trait that itself has sub-options. Some traits grant **free traits** that don't count against the 3 (Snailfolk: Molluscan Aegis/Quick Withdraw grant Snail's Pace). Several species choose Small/Medium size at selection.
5. **Mixed Ancestry** (Origin feat) — two non-fabricated Ruvinar species; for same-named non-optional traits pick one (always lowest Speed); **4 optional traits total** across both pools. Snail's Pace is negated for Snailfolk+Turtlefolk mixes.
6. **Creature-type interaction tags** — traits that widen targeting: **Wilderfolk** (beast-affecting effects also affect you — birdfolk, catfolk, frogfolk, lizardfolk, otterfolk, ratfolk), **Dreamtouched** (fey — elves), **Biomechanical** (humanoid-affecting effects also affect you — fabricated), **Nephilim** (celestial — feat), **Shedim** (fiend — feat), **Dragonborn** (dragon — feat), Monk Twisting Hand 11 (fiend). Sheet needs boolean tags per character.
7. **Content unlock gating** — every campaign option is stamped: no gate, **Chapter N Unlock**, **Reputation Unlock**, **Special Unlock**, **Little Leyfarers Unlock**. App needs an `unlock_source` field per content row and ideally a campaign-progress switch.
8. **Session-based leveling + XP banking** — session counter per player, chapter cap, transferable banked XP, retirement refunds.
9. **Subclass resource pools** (all need counters):
   - **Sunshards** (Artificer Sunforge): synthesized items with **charges** (= highest slot level at LR; or = slot level spent); infusion slots (PB, later PB+Int); each sunshard tracked with charges + attached infusion (Overcharge / Solar Shield / Arcane Brilliance / Cutting Edge, improved variants at 9).
   - **Runes** (Cleric Rune Priest): runes per LR = ⌊cleric level / 2⌋ + PB; 6 rune types + Rune of Destruction; carry limits (1 per creature, later PB per creature); at 17 each rune activates twice.
   - **Divine Code points** (Wizard Technomancer): pool = ⌊wizard level / 2⌋ + PB, regen on LR; plus 1/LR free re-cast; Extricate Essence uses = PB + Int mod.
   - **Lucky Number** (Rogue Gambler): d20 rolled each LR, stored value; crit on that number; Hedge Your Bets uses/short rest = PB.
   - **Vial of Sand** (Sorcerer Mirage): −10 speed while carried; two any-class cantrips; d6 rolled per LR → stored ability score that gets +1d4 on saves.
   - Monk Twisting Hand spends **Focus Points** on new options; Bard Calamity has Dumb Luck uses (1 + Cha mod per LR); Ranger Ghostscale has Ghost Shroud uses (1 + Wis mod per day); Paladin Ivory has per-LR aura damage-type choice.
10. **Darkvision rewording** — TLC darkvision: perceive darkness/dim light "one degree brighter," muted colors (functionally standard; text differs). Dwarves get **Tremorsense 30 ft** instead of darkvision.
11. **Banned spells** (cannot be learned or prepared): Demiplane, Dream of the Blue Veil, Earthquake, Fabricate, Plane Shift, Teleport, Tsunami, Wind Walk. **Contradiction flag**: Warlock "Lady of Ivory" grants **Fabricate** as an always-prepared patron spell at warlock level 4 — direct conflict with the ban; needs a ruling/flag in-app.
12. **Human Greenhorn** — humans ignore multiclassing ability prerequisites (validator change).

---

## 4. Species (17 TLC species; base traits + choose 3 optional)

All are Humanoid, 30 ft speed, unless noted. "Lineage" = optional trait with sub-choices. Unlock gates noted.

| Species | Gate | Size | Base traits | Optional traits (pick 3) |
|---|---|---|---|---|
| **Birdfolk** | — | S or M (choose) | Wilderfolk; Flight = walk speed (not in med/heavy armor) | Aerial Acrobat; Mimicry; Nocturnal Hunter; Seizing Talons; Songspeech; Vigilance |
| **Catfolk** | — | S or M | Wilderfolk; Darkvision 60 | Catching Claws; **Lineage** (Grimalkin: 30-ft teleport BA, PB/LR; Maneko: reroll failed d20 Test or downgrade crit vs you, ⌊PB/2⌋/LR); Land on Your Feet; Premonition; Soothing Purr; Stalking Strike |
| **Dwarf** | Reputation | M | **Tremorsense 30 (Whiskers)** — no darkvision | Animist; Runecraft (+1 ability rune, attunement); Spirit Companion; Stonespeech (Mending, Identify @3, Augury @5); Stout Build (Topple mastery swap); Tympanic Reflex |
| **Elf** | — | M | Dreamtouched (fey); Darkvision 60; ~350-yr lifespan (lore) | Dreamless (4-hr LR trance); **Lineage** (Briar / Moon / Shadow / Sun — each grants skills/adv/resistances + a standard language Solis or Noctis); Graceling (+5 speed, +5 self-teleports); Fey Magic (cantrip + L1 spell @3 from Bard/Cleric/Druid); Magic Resistance (adv vs ench/illusion/transmutation) |
| **Fabricated** | Chapter 9 | S or M | **Construct**; Biomechanical; Constructed (poison res/adv, no exhaustion from dehydration/malnutrition/suffocation) | Arcane Power Core (artificer cantrip; Absorb Elements @3 1/LR incl. radiant/force); Integrated Armor; Memory Lattice; Modular Frame (per-LR mode: Optical Processor / Rebound Actuator / Strata Frame / Submersion Core / Terrain Lock / Vector Array); Protocol Imprint (3 languages); Self-Repair (BA spend Hit Die + Con, PB/LR) |
| **Frogfolk** | Reputation | S | Wilderfolk; Dynamic Movement (swim = walk; 30-ft leap) | Connoisseur (Goodberry); **Lineage** (Ranga: poison unarmed/weapon coating; Wark: 15-ft cone thunder bellow 1d8→4d8, PB/LR); Militia Training; Pebbly Skin (AC 13+Dex; Con-for-Dex AC option); Powerful Tongue; Toxic Diet (poison immune) |
| **Gnome** | — | S | Darkvision 60 | Adaptable Trait (steal 1 non-lineage trait from another Ruvinar species, not fabricated); Expert Researcher (expertise); Improvised Spell (any wizard cantrip, PB/LR); Overcharge (add charge to item, PB/LR); Temporary Focus; Tinker (Fast Crafting) |
| **Human** | — | S or M | Greenhorn (ignore multiclass prereqs) | Beginner's Luck (die > char level → +⌊PB/2⌋); Hearthkeeper; Intrepid; Irrepressible (save proficiency of choice); Juke (force attack reroll, PB/LR); Well Traveled (skill+tool+language; repeatable) |
| **Hyenafolk** | Chapter 6 | M | Darkvision 60 | Apex Predator; Bone Crusher; Demoralizing Cackle (−PB from enemy success, 1/SR); Firearms Expert (bullet martial weapons, ignore loading/reload); Pack Hunter (Help→melee attack, PB/LR); Spirit Speaker (elemental cantrip; Tasha's Hideous Laughter @3, Healing Spirit @5) |
| **Kobold** | Chapter 4 | S (Vagrant may be M) | Darkvision 60 | Echolocate (BA blindsight 30); Improvised Ingenuity (toolless crafting); **Lineage** (Vagrant: +⌊PB/2⌋ to-hit vs adjacent; Sovereign: patron damage resistance + 30-ft line breath 1d10→4d10, PB/LR, per Draconic Patrons table §10); Trapper; Tunnel Fighter (Dex thrown); Underfoot |
| **Lizardfolk** | — | S or M | Wilderfolk; Regeneration (short-rest HD heal +Con extra; LR spend all HD to regrow limb) | Camouflage; **Lineage** (Busaya: swim, AC 13+Dex; Drakasi: climb + glide; Voranos: burrow 20, heat-exhaustion adv, AC 13+Dex); Neck Frill (fear cone, PB/LR); Powerful Tongue; Tail Drop (negate hit, tail regrows 1d4 LRs); Venomous Bite (+ Poison Spray, Con casting) |
| **Nereid** | Chapter 10 | S or M | Aquatic (amphibious; swim = walk+10) | Abyssal Warden (cold or force res); Bioluminescent (DV 120 + Dancing Lights); Bottom Feeder (corpse-eating = healing potion, greater @5); Ink Shame (fog cloud underwater / blinding jet, 1/SR); Needle Down (inflate, poison burst, 1/SR); Predatory Pulse (BA blindsight 30, PB/LR); Reef Emissary; Sucker Punch (reach +5 BA; grapple DC 10+Str/Dex+PB); Taunting Lure (Compelled Duel 1/LR) |
| **Orc** | — | M | Solar Synthesis (bright light: adv Str checks; carry as one size larger) | Bushcraft; Foraging Companion (CR ≤1/4 beast, non-combat); Martial Training (2 weapon profs + per-LR mastery); Prowess Weapon (Str for heavy ranged); Tenacious (+HP = char level; min temp HP = PB); Wanderer's Endurance (adv vs exhaustion; treat level as −1; LR removes 2 levels) |
| **Otterfolk** | Chapter 10 | S or M | Wilderfolk; Long Body (squeeze one size smaller) | Belly Up; Comrade In Arms (hand-holding anti-shove/prone); Dauntless Defender (fear immune); Favored Tool ("favorite rock" = +1 tool/+1 weapon 1d6 Sap); Lutrine Agility (BA Dash; 1/SR no-OA dash); River Rider (swim walk+10, 10-min breath, 2 hidden tiny-object pouches) |
| **Ratfolk** | — | S or M | Wilderfolk; Darkvision 60 | Bushy Tail; Cheek Pouches (2×PB tiny objects; hands-free potions); Gnawing Teeth (+ burrow 10); Keen Smell (blindsight 15, smell-based); Nimble Fingers; Swarm (share/move through spaces) |
| **Snailfolk** | Chapter 2 | M | Boneless (bludgeoning resistance; adv vs grapple) | Molluscan Aegis (permanent handless shield; grants Snail's Pace free); Quick Withdraw (reaction reduce B/P/S damage by PB+Con; grants Snail's Pace free); Shelter in Place; Slime Trail; **Lineage** (Chipachi: 1/LR drop-to-1-HP; Hollow: artisan tools + skill; Welkin: swim walk+10, water breathing, 1d6 mouth strikes w/ poison option); Wall Crawler. **Snail's Pace** (non-selectable): −10 walk speed (waived for Snailfolk+Turtlefolk Mixed Ancestry) |
| **Turtlefolk** | Chapter 10 | M | **Speed 20**; Armored Carapace (**cannot wear armor**; base AC 13+Con) | Ancestral Carvings (**+1 attunement slot**, History/Religion, Liranu); Mobile Defense (½ or ¾ cover stances); Patient Hunter (swim, 10-min breath, 1d6 jaws, crit-grapple); Shell Garden (herbalism/poisoner kit always carried); Spirit Walker (Starry Wisp; Sanctuary @3; Enhance Ability @5); Stalwart Heart (never Bloodied for enemy effects; +⌊PB/2⌋ death saves; 1/LR stabilize→1 HP) |

Species prerequisites in official content do NOT match same-named TLC species.

---

## 5. Classes / subclasses

No new base classes. Standard classes (incl. Artificer via EFotA). **12 homebrew archetypes, one per class**:

1. **Artificer — Sunforge** (Ch3 unlock). 3: jeweler's tools; Sunforge Spells (Guiding Bolt, Hellish Rebuke / Continual Flame, Flame Blade / Blinding Smite, Daylight / Fire Shield, Sickening Radiance / Destructive Wave, Wall of Light at 3/5/9/13/17); Synthesize Sunshard (charges = highest slot at LR; action + slot for more; expire next LR); Sunshard Infusion (attach to items, PB slots; Overcharge/Solar Shield/Arcane Brilliance/Cutting Edge). 5: Efficient Caster (d10+Int ≥10 on 2nd+ spell → free 1-charge shard). 9: Improved Infusions (+ effects if shard ≥2 charges; slots = PB+Int). 15: Sunforge Mastery (Reclaim Magic: shard→spell slot; Quick Charge: charges upcast spells; Dependable Power on radiant dice).
2. **Barbarian — Path of the Primordial** (Ch10). 3: Primordial Rage — pick Fire/Acid/Cold/Lightning/Thunder on raging; Str attacks +1d8 (2d8 @10); 15-ft aura Emanation 1d8 (2d8 @10) to enemies + chosen-type resistance to allies; BA + Rage use to switch type. 6: Manifest Fury (10-ft burst 3d6 on rage/type-change, Dex save 8+Str+PB). 10: Brutal Manifestation — Brutal Strike replacement riders (Scorching/Frigid/Corrosive/Thundering/Charged, 3d6 + effect). 14: Primordial Resilience (Relentless Rage success → 30-ft 8d6 burst, −2d6 per subsequent use until LR).
3. **Bard — College of Calamity** (Ch2). 3: Bardic Sinsperation (reroll nat-1 inspiration dice, must be rude); Savage Mockery (Intimidation prof, Vicious Mockery, **Tavern Brawler feat**; failed-save chains to 2nd target within 15 ft). 6: Dumb Luck (reaction reduce damage 1d6+Cha; 1+Cha/LR; last use → next d20 at disadvantage). 14: Feast of Fortune (max-roll inspiration die refunds a die).
4. **Cleric — Rune Priest** (Ch4). 3: Domain spells (Alarm, Catapult / Arcane Lock, Shining Smite / Erupting Earth, Glyph of Warding / Stoneskin, Deathward / Wall of Stone, Circle of Power @1/3/5/7/9); Runecraft (stonemason's tools; runes per LR = ⌊cleric/2⌋+PB; 10-min ritual; 1 rune-item per creature; Escape/Accuracy/Resilience/Absorption/Warding/Impact); Rune of Destruction (action, 60 ft, 10-ft cube, Con save, 3d6 force + stun). 6: Connecting Runes (+1 AC to carriers; remote-activate as heal 2d6+Wis; +5 temp HP on activation; carry limit = PB). 17: Runemaster (runes activate ×2; Stoneskin Wis-mod/day free; slot ≥3 → bonus rune).
5. **Fighter — Frog Knight** (Reputation). Save DC 8+PB+Str/Dex. 3: bonus skill (History/Insight/Performance/Religion, or expertise); Leaping Strike (BA 10-ft leap, OAs at disadvantage; two-handed melee after leap → Athletics check table: 11–15 +1d6, 15+ +1d8 + Topple-save disadvantage; damage → 2d6/2d8 @7, 3d6/3d8 @15). 7: Froggly Honor (adv vs fear/charm; no stealth disadvantage from med/heavy armor). 10: Defensive Leap (+3 AC after leaping strike). 15: Leap of Faith (redirect attack to self, 2/SR; leap range 15 ft). 18: Relentless Tongue (BA tongue: 1d8 strike / push 10 / pull 10 / disarm).
6. **Monk — Way of the Twisting Hand** (Ch7). 3: Fiendish Mutation (1 Focus Point after unarmed hit: Fire and Brimstone DoT / Hellborn Tethers restrain / Infernal Claw necrotic+slow / Venomous Barb poison; DC 8+Wis+PB). 6: Armor of Fiends (2 FP: temp HP 10+Wis+PB; while up: fire/poison resistance, +1d6 necrotic on unarmed). 11: Infernal Evolution (counts as fiend; Shield for 1 FP; BA 1 FP fly speed 1 min). 17: Aspect of the Lower Planes (Hellions Strike 1 FP: +Wis-mod d4s fire; crit heals char level; fire/poison resistance, immunity while Armor active).
7. **Paladin — Oath of the Ivory Knight** (Ch1). 3: Oath spells (Magic Missile, Tasha's Hideous Laughter / Gentle Repose, Magic Mouth / Hunger of Hadar, Mass Healing Word / Aura of Purity, Sickening Radiance / Wall of Stone, Holy Weapon @3/5/9/13/17); Channel Divinity: Ward of Fangs (1d6 piercing aura, temp HP on kill), Blinding Smile (30-ft blind burst). 7: Pearly Aura (choose B/P/S per LR; you+allies 10 ft resistance; 30 ft @18). 15: Jaws of Life (reaction move + Lay on Hands on downed ally 1/LR). 20: Perfect Smile (1 min: temp HP per turn, 30-ft blind aura, ranged Lay on Hands, healing-pool refund on kills).
8. **Ranger — Ghostscale Reaver** (Ch2). 3: spells (Divine Favor / Spiritual Weapon / Vampiric Touch / Guardian of Faith / Holy Weapon @3/5/9/13/17); Fallen Spirits (kill → temp HP = Wis; necrotic resistance while up); Spirit Strike (BA imbue +1d8 necrotic, 8 heals 4 HP; 2d8 @11). 7: Ghost Shroud (reaction +Wis AC, or save reroll; 1+Wis/day). 11: Death's Chosen (0-HP aura: 2d8 necrotic to enemies / 1d6+Wis heal to allies; adv on death saves). 15: Retributive Spirit (reaction 3d8 necrotic + no healing for attacker).
9. **Rogue — Gambler** (Ch4). 3: High Roller (dice + card set profs; usable as thieves' tools); Lucky Number (d20 per LR; rolling it on weapon attacks = crit; 20 → triple damage dice). 9: Hedge Your Bets (PB uses/SR: Side Bet even/odd → advantage; Split Bet doubles into two attacks, split sneak dice; Sure Bet single die + 2×PB, still counts as advantage). 13: Poker Face (Deception prof/expertise; adv vs lie/thought detection; post-attack no OAs). 17: All In (roll 1d6 for all sneak dice; 1–2 → next attack advantage).
10. **Sorcerer — Mirage** (Ch6). 3: spells (Comprehend Languages, Earth Tremor / Mirror Image, Spiritual Weapon / Bestow Curse, Wall of Sand / Hallucinatory Terrain, Phantasmal Killer / Commune with Nature, Scrying @1/3/5/7/9); Vial of Sand (carried: −10 speed; 2 any-class cantrips; LR roll d6 → that ability's saves get +1d4). 6: Withered Might (below half HP: BA 2 HD → 1 sorcery point, uses scale 1→5; BA gain exhaustion level → 2 SP, blocked at 3+ exhaustion); Foreseen Fate (1 SP → +1d4 on attack/save after roll). 14: Veil of Sand (2 SP halve attack damage; 2 SP auto-succeed death save; 4 SP downgrade crit 1/LR). 18: Borders of Death (BA regain 1 SP, Cha+1/LR; below half HP +1 spell attack/DC, below quarter +2).
11. **Warlock — The Lady of Ivory** (Ch1). 3: patron spells (Tasha's Hideous Laughter, Ice Knife / Cloud of Daggers, Magic Mouth / Revivify, Speak with Dead / **Fabricate**, Blight / Raise Dead, Antilife Shell @1–5); bonus cantrips Word of Radiance + Friends; Arcane Fangs (fire/cold/thunder/lightning/acid → piercing); Tooth Taker (tooth of CR 1+ creature replaces components ≤500 GP). 6: Many Mouths (understand languages via held tooth). 10: Deep Roots (immune to prone/push; movement = teleport). 14: Enamel Grafting (piercing + radiant resistance).
12. **Wizard — Technomancer** (Ch9). 3: Medicine + tinker's tools; Secrets in the Code (free spellbook adds: 1st/2nd-level wizard Necromancy + cleric Abjuration + Cure Wounds; one more each new slot level); Manipulate the Code — **Divine Code points** = ⌊wizard/2⌋+PB per LR: Diagnostic Recalibration / Override Safeguards / Entropy Optimization / Threat Interdiction (1 pt each); 1/LR re-cast an already-cast action spell for points = its level. 6: Extricate Essence (BA 3d6 radiant siphon, refund point on avg+ damage; PB+Int uses/LR; 4d6 @10). 10: Analyze Anatomy (sense Bloodied creatures 30 ft; 2 pts ignore resistance). 14: Code Savant (spend PB points → +1d8/point heal or necrotic single-target; 1 pt adv on spell attack vs construct/undead).

---

## 6. Feats

**Homebrew Origin feats** (backgrounds grant one Origin feat):
- **Celestial Ancestry** (Ch5 unlock): Nephilim tag + necrotic-or-radiant resistance + one of: Crown of Blades, Halo of Eyes, Harbinger of Death, Number the Stars, Plumage of the Sun, Song of Extinction.
- **Divine Aspect** (Special unlock): cleric cantrip + one Aspect: Belios (no material components unless consumed), Kirvalo (weapon damage → fire), Umaro (strip temp HP, PB/LR), Isopor (regain slot ≤PB on short rest), Soumeros (change appearance after short rest).
- **Draconic Ancestry** (no gate): Dragonborn tag + adv vs frightened + one Gift: Cindergale (pierce fire resistance/immunity), Levintide (reroll lightning/thunder dice), Mindsire (PB charges → improvised spell slots), Mooneater (aquatic telepathy, reroll 1s on cold), Mourningstar (**double concentration** if one spell is Div/Ench), Neverbeast (monstrosity tag + beast-spells include dumb monstrosities), Windrose (BA Search via Performance; Heroism 1/LR).
- **Infernal Ancestry** (Ch5): Shedim tag + fire-or-cold resistance + one of: Fiendish Design (flight + claws), Fire From Dust (speed/Athletics/extra attack paid in Hit Dice self-damage), Honeyed Words, Sanguine Rubies, Spellbound Flesh (Ench/Conj or fire/cold spell scaling 1st/3rd/5th), Written in Blood (LR: spend HD → temp language/skill/weapon/save proficiencies).
- **Mixed Ancestry** (prereq: non-fabricated Ruvinar species): second species; 4 optional traits pooled.

**Homebrew General feats** (all prereq level 4+):
- **Adaptive Mycelia** (Ch2): +1 Con; reaction fungal melee spell attack (Con-based), damage = spent Hit Dice, PB uses.
- **Ancestral Exemplar** (any Ruvinar species): +1 any; gain one more qualifying optional species trait; **repeatable**.
- **Ashen Touch** (Ch8): +1 Str/Wis; fire/radiant hits block healing until end of next turn; fire/radiant crits blind.
- **Lessons of the Past** (Ch7): +1 Wis/Cha; Bless + Sanctuary free 1/LR each; Improved Bless (unbreakable concentration PB rounds); Improved Sanctuary (10 temp HP/turn).
- **Might and Mettle** (Ch5): +1 Str/Dex; Heavy Lancer (one-hand polearms mounted, adv vs Huge+); Monster Hunter (+Str/Dex mod damage vs monstrosities).
- **Roll the Bones** (Ch10; must have died at least once): +1 Con/Cha; death saves become **2d6 table** (2 = two failures; 3–6 = one failure; 7–10 = one success; 11 = stabilize +1 HP conscious; 12 = stabilize + level+PB HP conscious). Description text literally reads "Description" — placeholder left in.
- **Wyd Touched** (Ch1): +1 Con/Wis; Guarded Mind (adv Int/Wis saves vs spells; charm immunity); Hybrid Flora (beast-referencing spells include plants).
- **White as a Swan's Wing** (Ch5): +1 Int/Wis; Plan Ahead (Int/Wis for initiative); Triage (Ready → heal reaction).

Official feats otherwise allowed per source list (incl. the 4 FRHoF feats). Ability score prerequisites per printing.

---

## 7. Spells

- **Banned** (cannot be learned/prepared): Demiplane, Dream of the Blue Veil, Earthquake, Fabricate, Plane Shift, Teleport, Tsunami, Wind Walk. (Theme: no teleporting/plane-hopping/terraforming.) **Conflict**: Lady of Ivory patron list includes Fabricate.
- **Homebrew spells** (Appendix S; unlock gates in parens):
  1. **Bronwyn's Words of Affirmation** — 2nd Ench (Little Leyfarers), BA, 30 ft, V/S/M (a personal compliment); target gains adv on next d20 Test, attackers disadvantaged, healing maximized until end of its next turn. Artificer/Bard/Cleric/Druid.
  2. **Fiendish Brand** — 4th Conj (Ch5), 60 ft, conc 1 min; learn resistances/immunities; per-turn Con save 6d6 fire + attack disadvantage. Sorcerer/Warlock.
  3. **Final Breath** — 3rd Necro (Ch2), touch spell attack; 5d6 necrotic, 5d8 if below full HP, 5d10 if below half; kill → target rises as commanded zombie ≤1 min. Cleric/Sorcerer/Wizard.
  4. **Helping Hands** — 3rd Conj (Ch8), self 20-ft Emanation, conc 1 min; menu of BA/reaction effects (restrain, feed potion, Help, adv on ally Dex saves, disadvantage on enemy attack). +5 ft per level above 3. Cleric/Bard/Warlock/Wizard.
  5. **Summon Divine Machine** — 6th Conj (Ch9), 500+ GP sunshard component, conc 1 hr; Large Construct with full stat block (AC 12+level, HP 50+10/level, its own **Divine Code point** pool 6+2/level, upgradeable attacks/reaction). Artificer/Cleric/Wizard.
  6. **Squeeb's Shellward** — 2nd Abj (Ch2), reaction; adv on save vs a spell ≤ level 2 (scaling +1 level per slot), nat 20 negates. Sorcerer/Wizard.
  7. **Squeeb's Tenacious Tendrils** — 3rd Conj (Ch2), 60 ft, conc; 10-ft slime pool, 2d6 bludgeoning + grapple, difficult terrain; +1d6/slot. Sorcerer/Wizard.
  8. **Wrath of the Tempest** — 5th Conj (Ch10), 60 ft, conc 1 min; storm-cloud spirit, BA command, bolt strikes 4d10 lightning (count = ⌊cast level/2⌋), 10-ft 2d8 thunder push aura. Druid/Sorcerer/Wizard.
- Alignment-variant spells: choose version at acquisition.
- Also allowed: Homunculus Servant (EFotA) and the 8 FRHoF spells.

---

## 8. Items / equipment / crafting

- **Currency**: standard GP (no homebrew currency). Background equipment budget 50 GP; martial weapons/armor come from class selection.
- **Auto-granted items**: Leyfarer's Journal (uncommon; queries/LR = rank), Leyfarer's Emblem (common; focus/component for rank abilities).
- **Sunshards**: setting magitech power crystals; charge-bearing consumables created by Sunforge Artificers; also a 500+ GP spell component. Model as item with `charges`, `expires_on_long_rest`, `infusion`.
- **Favorite rock** (Otterfolk Favored Tool): per-LR designated object = +1 artisan tool + +1 simple melee weapon (1d6 bludgeoning, Sap mastery).
- **Rune-inscribed items** (dwarf trait: +1 ability score, forces attunement; Rune Priest: consumable activated runes with carry limits).
- **Crafting**: relies on the 2024 PHB "Fast Crafting" table (referenced by Gnome Tinker, Kobold Improvised Ingenuity, Turtlefolk Shell Garden — which adds Healer's Kit or Basic Poison to that table for the character). No standalone TLC crafting system in this guide.
- **Attunement**: standard 3 slots; Turtlefolk Ancestral Carvings grants a 4th.

---

## 9. Combat / rest rules — deltas from standard

- **Initiative, rests, death saves, conditions, exhaustion: unchanged at the rules level.** All deltas come from character options: Roll the Bones feat replaces the d20 death save with a 2d6 table; Turtlefolk Stalwart Heart adds a death-save bonus; Ghostscale Reaver 11 gives adv on death saves; Vigilance/Premonition/Plan Ahead/White as a Swan's Wing modify initiative; Orc Wanderer's Endurance makes a long rest remove 2 exhaustion levels (implying the standard 1); Mirage sorcerer voluntarily gains exhaustion as a resource.
- **Hit points**: fixed per-level values mandatory (no rolls).
- **Bloodied** (2024, below half HP) is load-bearing for several features (Turtlefolk, Technomancer, Final Breath tiers).
- **Hit Dice as currency** is a recurring homebrew pattern (Fabricated Self-Repair, Fire From Dust, Written in Blood, Adaptive Mycelia, Withered Might, Lizardfolk limb regrowth) — the sheet's HD tracker gets nonstandard drains.
- No changes printed for surprise, flanking, cover, or travel.

---

## 10. Structured tables worth seeding

1. **Allowed-sources whitelist** (with per-book partial allowances) — for content filtering.
2. **Banned spells** (8 rows).
3. **Species / base traits / optional traits / lineages** (~17 species, ~110 traits) — the biggest seed.
4. **Table 1: Draconic Patrons** (7 rows): Alor'Arkan the Mindsire / Spellscale / Tanzanite / Force / Dex; Bakunua the Mooneater / Tidescale / Coral / Cold / Dex; Durantera the Neverbeast / Beastscale / Opal / Thunder / Dex; Eravoros the Mourningstar / Dreamscale / Hematite / Psychic / Wis; Karthranix the Levintide / Stormscale / Citrine / Lightning / Dex; Nox'Pyrrha the Cindergale / Cinderscale / Obsidian / Fire / Dex; Uravkaia the Windrose / Prismscale / Bismuth / Radiant / Dex.
5. **Languages**: Ethnolects (Arosi, Common, Common sign, Duergo, Eotnar, Gobalo, Gorok, Hae'Khulo, Honoko, Karukari, Ku'nuan, Kuikui, Lho'Khahri, Miau, Nomic, Orokan, Sneklik, Wildersign); Regional (Avendari, Bastil, D'randeli, Erebosi, Ilorean, Karsanic, Namorian, Orazi, Pyran, Valkai); Rare (Caelinth, Enyori, Nyth, Liranu, Malraeth, Noctis, Solis, T'Ahsai). NOTE: the regional and rare tables' language↔speaker column alignment is skewed in the PDF text extraction; verify pairings against the rendered PDF before seeding.
6. **Sample point-buy arrays** (8 rows).
7. **Table 2: Max level by chapter** (ch 8→12 through ch 16→20).
8. **Table 3: Level by session number** (sessions 1–66 → levels 3–20; ~3 sessions per level band).
9. **Leyfarer rank table** (rank/title/perk × focus).
10. **Sunshard Infusions + Improved Infusions** (4+4 rows).
11. **Rune Priest rune list** (7 runes), **Modular Frame modes** (6), **Brutal Manifestation strikes** (5), **Hedge Your Bets options** (3), **Roll the Bones 2d6 table** (5 bands), **Mirage d6 ability table** (6), **Frog Knight Leaping Strike table** (3 bands), **Divine Machine stat block**.

---

## Ambiguities / contradictions to flag

1. **Fabricate is banned but granted** by Lady of Ivory warlock (level-4 patron spell). Needs errata flag.
2. **Leyfarer rank perk table is layout-garbled** in the PDF: whether Initiate or Adept receives the skill proficiency, and what (if anything) Mentor grants, is unclear. Focus is explicitly chosen at Adept, yet the skill row is aligned to Initiate. Director perks are literally "???".
3. **Roll the Bones** feat body contains the placeholder word "Description" — unfinished text.
4. **Frog Knight Leaping Strike table** bands "11-15" and "15+" overlap at 15; the "0-10" row has no effect text.
5. **Darkvision reworded** ("one degree brighter") — mechanically it reads as standard darkvision but the app should store TLC's wording.
6. **Ivory Knight paladin** gets non-paladin spells (Magic Missile, Tasha's Hideous Laughter, Hunger of Hadar) as oath spells — intended flavor, but breaks any "spell must be on class list" validation.
7. **Rune Priest** lists "Deathward" (sic) and gets both a species-style Runecraft (dwarf trait) namesake — dwarf Runecraft and cleric Runecraft are different mechanics sharing a name.
8. **Mixed 2014/2024 surface**: "latest printing wins" plus TCE-as-2014-only creates per-option edition tagging needs; e.g., Focus Points/Brutal Strike/Mastery assume 2024 classes, while EFotA Artificer is its own printing.
9. **Elf Fey Magic / trait spell grants** frequently let Int/Wis/Cha be chosen as casting ability — sheet must store per-trait casting ability choices.
10. Several traits reference **"Fast Crafting"** (2024 PHB) — external dependency the app must know about.
11. **Regional/Rare language tables** likely mis-aligned in extraction (see §10.5) — verify visually.

---

## Data modeling impact (entities/fields the app must add or change)

**New entities**
1. `tlc_species` + `tlc_species_trait` (base vs optional, `is_lineage`, lineage sub-options, `grants_free_trait`, per-trait choice slots: size, damage type, skill, cantrip, casting ability, patron).
2. `character_species_trait` join (character → chosen optional traits, 3 default / 4 with Mixed Ancestry; second species FK nullable for Mixed Ancestry).
3. `draconic_patron` lookup (7 rows: name, clan, scale color, damage type, save).
4. `tlc_language` lookup (category: ethnolect/regional/rare) replacing the stock language list.
5. `tlc_subclass` (12) + `subclass_feature` rows with level, resource definitions.
6. `tlc_feat` (5 origin + 8 general; `repeatable`, `prerequisite`, unlock gate, embedded choices).
7. `tlc_spell` (8) + `banned_spell` list (enforced in spell pickers).
8. `unlock_gate` on every TLC content row: none / chapter N / reputation / special / little-leyfarers; plus a campaign-progress setting to filter availability.
9. `resource_tracker` instances: Divine Code points, runes/LR, sunshard infusion slots, Focus-Point spend options, Dumb Luck, Ghost Shroud, Hedge Your Bets, per-trait PB-per-LR/SR counters (very common pattern: "PB times per Long Rest").
10. Item records: Leyfarer's Journal (uses = rank), Leyfarer's Emblem, Sunshard (charges, infusion, expiry), Favorite Rock, Vial of Sand (carried flag → −10 speed), rune-inscribed items (forces attunement).
11. `session_xp` ledger per player (not per character): session count, banked XP, transfers, retirement refunds.

**Character fields to add/change**
- `leyfarer_rank` (0–5), `leyfarer_focus` (explorer/naturalist/scholar), derived rank perks (bonus skill, ritual spell, Advisor spells).
- Remove/hide `alignment`.
- `creature_type` may be Construct (Fabricated); interaction tags: `wilderfolk`, `dreamtouched`, `biomechanical`, `nephilim`, `shedim`, `dragonborn_tag`, `fiend_tag` (Monk 11), `monstrosity_tag` (Neverbeast).
- Size becomes a per-character choice for many species (S/M).
- Senses: support **Tremorsense** (dwarf) and conditional Blindsight (BA-activated) alongside darkvision.
- AC formulas: 13+Dex (Pebbly Skin, Busaya, Voranos), 13+Con + no-armor-allowed (Turtlefolk), Con-instead-of-Dex armor bonus (Pebbly Skin), permanent handless shield (Molluscan Aegis), integrated armor flag (Fabricated).
- Attunement slot count variable (Turtlefolk +1).
- Speed modifiers: Snail's Pace −10, Vial of Sand −10, Graceling +5, Turtlefolk base 20; swim = walk+10 pattern.
- HP: fixed-value level-up only; Tenacious (+char level max HP).
- Death saves: pluggable mechanism (d20 default, 2d6 table with Roll the Bones, flat bonuses, auto-success spends).
- Hit Dice: spendable outside rests by many features — needs a general HD-spend action, not just short-rest UI.
- Multiclass validator: bypass prereqs if Human.
- Spell system: per-trait/feat innate spells with chosen casting ability (Int/Wis/Cha), 1/LR free castings, "always prepared" flags from subclass tables; banned-spell filter; source whitelist filter; alignment-variant choice storage.
- Level/progression: level derived from session count + chapter cap tables rather than XP; support alternate characters per player.

**Validation rules**
- Point-buy-only ability generation (plus 8 preset arrays).
- Background builder: +2/+1 or +1/+1/+1, 1 Origin feat, 2 skills, 1 tool, ≤50 GP gear (no martial weapons/armor).
- Exactly 3 optional species traits (4 for Mixed Ancestry; +1 per Ancestral Exemplar take; free traits excluded from count).
- Content availability = source whitelist ∧ unlock gate ∧ "latest printing" rule (block 2014 versions when a 2024 reprint exists; block TCE optional features on 2024 classes).
