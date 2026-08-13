import { test } from 'node:test';
import assert from 'node:assert/strict';

// Registers the hooks that let node import .jsx; everything below it has to be a
// dynamic import, or the module graph loads before the hooks exist.
import './support/jsxLoader.js';

const stubs = await import('./support/stubs.js');
const { renderToString } = await import('solid-js/web');
const { Dnd5Info } = await import(
  '../../app/javascript/applications/CharKeeperApp/pages/Content/Character/Dnd5/Info.jsx'
);
const { fetchDictionary } = await import('../../app/javascript/applications/CharKeeperApp/context/appLocale.jsx');
const { tlcConfig } = await import('../../app/javascript/applications/CharKeeperApp/data/tlcConfig.js');

const DICTIONARIES = { en: await fetchDictionary() };

const character = (overrides = {}) => ({
  id: 'c1', provider: 'tlc', name: 'Test', alignment: 'neutral', species: 'elf', legacy: undefined,
  names: { species_name: 'Elf' },
  ...overrides
});

// Text is stubbed to record its props (support/stubs.js), not draw HTML -- read
// what Info.jsx actually computed for `renderValue`, the same way tlcForm.test.js
// reads a stubbed Select's `items`.
const legacyField = (fields) => fields.find((item) => item.labelText === 'Legacy');

// Issue #64 acceptance criterion: a tlc-only value under `species` has to reach a
// converted component through dndConfigFor, not the dnd2024 base it replaced --
// and a dnd2024 character must be completely unaffected by that same override.
// SAME species (elf) and SAME legacy key (high_elf) for both providers, the
// mutation held active across BOTH renders: a version that renders the base
// dnd2024 name while the tlc override is live is the only proof this isn't
// coincidentally passing because the mutation had already been restored, or
// because the two renders used keys neither config actually shares.
// elf is redefined by tlc.json (sizes/unlock) but its `legacies` key is
// untouched there, so tlcConfig.species.elf.legacies starts out === (deep)
// dnd2024Config.species.elf.legacies -- and elf IS in tlc.json's delta, so
// tlcConfig.species.elf is already a distinct object from
// dnd2024Config.species.elf (deepMerge), meaning this reassignment never
// reaches dnd2024Config.species.elf.legacies at all.
test('Dnd5Info reads a tlc-only species value through the merged config; a dnd2024 character never sees it', () => {
  stubs.setAppLocale('en', DICTIONARIES.en);

  const original = tlcConfig.species.elf.legacies;
  tlcConfig.species.elf.legacies = { ...original, high_elf: { name: { en: 'TLC-Only High Elf' } } };

  try {
    renderToString(() => Dnd5Info({ character: character({ legacy: 'high_elf' }) }));
    const tlcText = legacyField(stubs.fields)?.text;

    // setAppLocale is also stubs.js's field-recorder reset (fields.length = 0)
    // -- without it, the second renderToString call's fields append onto the
    // first's, and legacyField finds the tlc render's stale entry instead.
    stubs.setAppLocale('en', DICTIONARIES.en);
    renderToString(() =>
      Dnd5Info({ character: character({ provider: 'dnd2024', legacy: 'high_elf', names: { species_name: 'Elf' } }) })
    );
    const dnd2024Text = legacyField(stubs.fields)?.text;

    assert.equal(tlcText, 'TLC-Only High Elf');
    assert.equal(dnd2024Text, 'High elf');
    assert.notEqual(tlcText, dnd2024Text);
  } finally {
    tlcConfig.species.elf.legacies = original;
  }
});
