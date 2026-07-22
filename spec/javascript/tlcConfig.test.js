import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import dnd2024Config from '../../app/javascript/applications/CharKeeperApp/data/dnd2024.json' with { type: 'json' };
import tlcDelta from '../../app/javascript/applications/CharKeeperApp/data/tlc.json' with { type: 'json' };
import { tlcConfig, dndConfigFor, speciesFor } from '../../app/javascript/applications/CharKeeperApp/data/tlcConfig.js';

const CHARKEEPER = path.join(
  fileURLToPath(new URL('../../', import.meta.url)),
  'app/javascript/applications/CharKeeperApp'
);

test('tlcConfig inherits keys that only dnd2024.json declares', () => {
  assert.ok(tlcDelta.species.halfling === undefined);
  assert.deepEqual(tlcConfig.species.halfling, dnd2024Config.species.halfling);
  assert.deepEqual(tlcConfig.skills, dnd2024Config.skills);
  // Nested combine: the 2024 subclasses survive alongside the TLC archetype.
  assert.ok('thief' in tlcConfig.classes.rogue.subclasses);
  assert.equal(tlcConfig.classes.rogue.subclasses.gambler.name.en, 'Gambler');
});

test('tlcConfig lets tlc.json override, arrays wholesale', () => {
  assert.deepEqual(dnd2024Config.species.dwarf.sizes, ['small']);
  assert.deepEqual(tlcConfig.species.dwarf.sizes, ['medium']);
  assert.equal(tlcConfig.species.dwarf.unlock, 'reputation');
  // Untouched sibling keys of an overridden node still come from the base.
  assert.deepEqual(tlcConfig.species.dwarf.legacies, dnd2024Config.species.dwarf.legacies);
});

test('tlcConfig drops the base pointer and matches the server contract', () => {
  assert.equal(tlcDelta.base, 'dnd2024');
  assert.equal(tlcConfig.base, undefined);
});

test('tlc.json carries the 17 TLC species and 12 subclass slugs', () => {
  assert.equal(Object.keys(tlcDelta.species).length, 17);
  const subclasses = Object.values(tlcDelta.classes).flatMap((klass) => Object.keys(klass.subclasses));
  assert.equal(subclasses.length, 12);
  const unlocks = [
    ...Object.values(tlcDelta.species).map((s) => s.unlock),
    ...Object.values(tlcDelta.classes).flatMap((k) => Object.values(k.subclasses).map((s) => s.unlock))
  ];
  // Vocabulary is Tlc::Homebrews::Feat#unlock (app/platforms/tlc/homebrews/feat.rb:18).
  assert.ok(unlocks.every((u) => /^(none|reputation|special|little_leyfarers|chapter_\d+)$/.test(u)), unlocks.join(','));
});

test('dndConfigFor routes tlc to the merged config and leaves dnd2024 alone', () => {
  assert.equal(dndConfigFor('tlc'), tlcConfig);
  assert.equal(dndConfigFor('dnd2024'), dnd2024Config);
  assert.equal(dndConfigFor('dnd5'), dnd2024Config);
});

// The list row renders species through speciesFor; feeding it dnd2024's base
// species as if they were homebrew clobbers every slug tlc redefines.
test('speciesFor keeps the tlc overrides and lets homebrew win', () => {
  const tlcSpecies = speciesFor('tlc');

  assert.deepEqual(tlcSpecies.dwarf.sizes, ['medium']);
  assert.equal(tlcSpecies.dwarf.unlock, 'reputation');
  assert.deepEqual(speciesFor('dnd2024').dwarf, dnd2024Config.species.dwarf);

  const homebrew = { customspecies: { name: { en: 'Custom' }, legacies: {} } };
  assert.deepEqual(speciesFor('tlc', homebrew).customspecies, homebrew.customspecies);
  assert.equal(speciesFor('tlc', homebrew).dwarf.unlock, 'reputation');
  // Homebrew overriding a shared slug still wins over the merged config.
  assert.equal(speciesFor('tlc', { dwarf: { name: { en: 'Hb' } } }).dwarf.name.en, 'Hb');
});

const sourceFiles = (dir) =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return sourceFiles(full);
    return /\.jsx?$/.test(entry.name) ? [full] : [];
  });

const isComment = (line) => /^(\/\/|\*|\/\*|\{\/\*)/.test(line.trim());

// Pre-merge grep sweep (plan eng finding 9): an exact dnd2024 comparison that
// survives has to say why tlc is excluded, otherwise it is a silent misroute.
test("every surviving === 'dnd2024' carries a why-kept comment", () => {
  const unexplained = [];

  for (const file of sourceFiles(CHARKEEPER)) {
    const lines = readFileSync(file, 'utf8').split(/\r?\n/);
    lines.forEach((line, index) => {
      if (!line.includes("=== 'dnd2024'") || isComment(line)) return;

      const previous = lines.slice(0, index).reverse().find((candidate) => candidate.trim() !== '');
      if (!previous || !isComment(previous)) {
        unexplained.push(`${path.relative(CHARKEEPER, file)}:${index + 1}`);
      }
    });
  }

  assert.deepEqual(unexplained, []);
});
