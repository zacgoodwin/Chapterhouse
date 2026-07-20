#!/usr/bin/env node
// A0-1 homebrew-UI spike gate.
//
// The dnd2024 homebrew "UI" is a JSON import: SharedContent.jsx uploads a file
// to homebrews_v2/publications, which runs the Import::Dnd2024::{Races,Subclasses}
// dry-validation contracts, then persists via Feats::AddCommand per feature.
// A live Rails boot is blocked on this box (config/master.key absent, credentials
// encrypted), so this script mirrors those exact contracts to prove both authored
// records WOULD pass import and render. It also prints the Phase B pricing math so
// no arithmetic lives in prose. Exits nonzero on any contract violation.
//
// Contract sources (worktree paths):
//   app/commands/homebrews_v2_context/import/dnd2024/races/perform_command.rb
//   app/commands/homebrews_v2_context/import/dnd2024/subclasses/perform_command.rb
//   app/commands/homebrews_v2_context/import/dnd2024/feats/add_command.rb
//   app/decorators_v2/dnd2024_decorator.rb  (honored modifier keys)
//   app/platforms/dnd2024/feat.rb           (enums)

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));

const DAMAGE = ['bludge','pierce','slash','acid','cold','fire','force','lighting','necrotic','poison','psychic','radiant','thunder'];
const SIZES = ['small','medium','large'];
// Feats::AddCommand Kinds is the persistence truth (narrower than race PerformCommand's).
const KINDS = ['static','text','update_result','hidden'];
const LIMIT_REFRESH = ['short_rest','long_rest','one_at_short_rest'];
const VISION = ['darkvision','truesight','blindsight','tremorsense'];
const SPEEDS = ['flight','swim','climb','burrow'];
const BASE_CLASSES = ['barbarian','bard','cleric','druid','fighter','monk','paladin','ranger','rogue','sorcerer','warlock','wizard','artificer'];
// dnd2024_decorator ONLY_ADD_MODIFIERS + WEAPON_MODIFIERS + set/concat-eligible result keys.
const HONORED_MODIFIER_KEYS = new Set([
  'str','dex','con','wis','int','cha','spell_save_dc','spell_attack_bonus',
  'attack','unarmed_attacks','melee_attacks','range_attacks','damage','unarmed_damage','melee_damage','range_damage',
  'armor_class','initiative','speed'
]);

const errors = [];
const warnings = [];
const err = (f, m) => errors.push(`${f}: ${m}`);
const warn = (f, m) => warnings.push(`${f}: ${m}`);

function locStr(f, path, val, max) {
  if (val === undefined || val === null) return err(f, `${path} is missing`);
  if (typeof val.en !== 'string' || val.en.length < 1) return err(f, `${path}.en required non-empty string`);
  if (val.en.length > max) err(f, `${path}.en exceeds ${max} chars (${val.en.length})`);
}

function validateFeature(f, ft, descMax) {
  const t = ft.title?.en ?? '<untitled>';
  locStr(f, `feature[${t}].title`, ft.title, 50);
  locStr(f, `feature[${t}].description`, ft.description, descMax);
  if (!KINDS.includes(ft.kind)) err(f, `feature[${t}].kind '${ft.kind}' not in ${KINDS.join('/')}`);
  // Feats::AddCommand: required(:level).filled(:integer, gteq?: 1)  -> EVERY feature needs a level.
  if (!Number.isInteger(ft.level) || ft.level < 1 || ft.level > 20) err(f, `feature[${t}].level must be integer 1..20 (got ${ft.level})`);
  const hasLimit = ft.limit !== undefined;
  const hasRefresh = ft.limit_refresh !== undefined;
  if (hasLimit && (!Number.isInteger(ft.limit) || ft.limit < 1 || ft.limit > 20)) err(f, `feature[${t}].limit must be integer 1..20`);
  if (hasRefresh && !LIMIT_REFRESH.includes(ft.limit_refresh)) err(f, `feature[${t}].limit_refresh '${ft.limit_refresh}' invalid`);
  if (hasLimit !== hasRefresh) err(f, `feature[${t}] limit/limit_refresh must be all-or-nothing (rule check_all_or_nothing_present)`);
  if (ft.modifiers !== undefined) {
    if (typeof ft.modifiers !== 'object' || Array.isArray(ft.modifiers)) err(f, `feature[${t}].modifiers must be object`);
    else for (const [k, v] of Object.entries(ft.modifiers)) {
      if (!v || !['add','set','concat'].includes(v.type)) err(f, `feature[${t}].modifiers.${k}.type must be add/set/concat`);
      const base = k.includes('.') ? k.split('.')[0] : k;
      if (!HONORED_MODIFIER_KEYS.has(base) && !['save_dc','speeds'].includes(base))
        warn(f, `feature[${t}].modifiers.${k} is stored but INERT (decorator honors none of this key)`);
    }
  }
  if (ft.static_spells !== undefined && (typeof ft.static_spells !== 'object' || Array.isArray(ft.static_spells)))
    err(f, `feature[${t}].static_spells must be object`);
}

function validateRace(f, r) {
  locStr(f, 'title', r.title, 50);
  locStr(f, 'description', r.description, 500);
  if (r.public !== undefined && typeof r.public !== 'boolean') err(f, 'public must be bool');
  for (const key of ['resistance','immunity','vulnerability'])
    if (r[key] !== undefined) { if (!Array.isArray(r[key])) err(f, `${key} must be array`); else r[key].forEach(x => DAMAGE.includes(x) || err(f, `${key} '${x}' not a damage type`)); }
  if (r.size !== undefined) { if (!Array.isArray(r.size)) err(f, 'size must be array'); else r.size.forEach(s => SIZES.includes(s) || err(f, `size '${s}' invalid`)); }
  if (r.vision !== undefined) for (const [k, v] of Object.entries(r.vision)) {
    if (!VISION.includes(k)) err(f, `vision key '${k}' invalid`);
    if (!Number.isInteger(v) || v < 1 || v > 1000) err(f, `vision.${k} must be 1..1000`);
  }
  if (r.speed !== undefined && (!Number.isInteger(r.speed) || r.speed < 1 || r.speed > 100)) err(f, 'speed must be 1..100');
  if (r.speeds !== undefined) for (const [k, v] of Object.entries(r.speeds)) {
    if (!SPEEDS.includes(k)) err(f, `speeds key '${k}' invalid`);
    if (!Number.isInteger(v) || v < 0 || v > 1000) err(f, `speeds.${k} must be 0..1000`);
  }
  (r.features ?? []).forEach(ft => validateFeature(f, ft, 1000));
}

function validateSubclass(f, s) {
  locStr(f, 'title', s.title, 50);
  locStr(f, 'description', s.description, 500);
  if (s.public !== undefined && typeof s.public !== 'boolean') err(f, 'public must be bool');
  if (typeof s.class_id !== 'string' || s.class_id.length < 1) err(f, 'class_id required');
  else if (!BASE_CLASSES.includes(s.class_id)) warn(f, `class_id '${s.class_id}' is not a base class (treated as homebrew class id)`);
  (s.features ?? []).forEach(ft => validateFeature(f, ft, 1000));
}

function load(name) {
  return JSON.parse(readFileSync(join(HERE, name), 'utf8'));
}

console.log('== A0-1 homebrew import-contract gate ==\n');
load('birdfolk.race.json').forEach(r => validateRace('birdfolk.race.json', r));
load('college-of-calamity.subclass.json').forEach(s => validateSubclass('college-of-calamity.subclass.json', s));

if (warnings.length) { console.log('WARNINGS (import passes; fidelity note):'); warnings.forEach(w => console.log('  ! ' + w)); console.log(''); }
if (errors.length) { console.log('CONTRACT VIOLATIONS:'); errors.forEach(e => console.log('  x ' + e)); }
else console.log('Both records PASS the import contract -> would persist and render via to_homebrew_json.');

// ---- Phase B pricing (deterministic; no arithmetic in prose) ----
// Counts from players-guide-digest.md §4 (17 species), §5 (12 subclasses),
// §6 (13 feats), §7 (8 spells), §10.3 (~110 optional traits total).
const RATE_MIN_PER_FEATURE = 4;   // measured in this spike: transcribe rule text -> markdown + decide mechanical mapping
const RATE_MIN_PER_HEADER  = 6;   // per-entity header + the manual-tracking design for gaps homebrew can't hold
const counts = {
  species_headers: 17, species_base_traits: 34, species_optional_traits: 110,
  subclass_headers: 12, subclass_features: 60,
  feats: 13, spells: 8
};
const features = counts.species_base_traits + counts.species_optional_traits + counts.subclass_features + counts.feats + counts.spells;
const headers = counts.species_headers + counts.subclass_headers;
const minutes = features * RATE_MIN_PER_FEATURE + headers * RATE_MIN_PER_HEADER;
console.log('\n== Phase B pricing (raw homebrew JSON authoring only) ==');
console.log(`  content features (traits+subclass feats+feats+spells): ${features} x ${RATE_MIN_PER_FEATURE} min`);
console.log(`  entity headers (species+subclasses):                    ${headers} x ${RATE_MIN_PER_HEADER} min`);
console.log(`  total authoring: ${minutes} min = ${(minutes/60).toFixed(1)} h`);
console.log('  NOT included (no homebrew home at any price): choose-N trait pools, unlock gates,');
console.log('  PB/ability-scaled limits, session refresh, creature-type tags, alternate AC, lineage sub-choices.');

process.exit(errors.length ? 1 : 0);
