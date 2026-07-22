import { test } from 'node:test';
import assert from 'node:assert/strict';

// Registers the hooks that let node import .jsx; everything below it has to be a
// dynamic import, or the module graph loads before the hooks exist.
import './support/jsxLoader.js';

const stubs = await import('./support/stubs.js');
const { renderToString } = await import('solid-js/web');
const { TlcCharacterForm } = await import(
  '../../app/javascript/applications/CharKeeperApp/pages/Navigation/Characters/Forms/Tlc.jsx'
);
const { fetchDictionary } = await import('../../app/javascript/applications/CharKeeperApp/context/appLocale.jsx');
const { default: tlcDelta } = await import('../../app/javascript/applications/CharKeeperApp/data/tlc.json');

const DICTIONARIES = Object.fromEntries(
  await Promise.all(['en', 'ru', 'es'].map(async (locale) => [locale, await fetchDictionary(locale)]))
);

// Renders the real form with the barrels stubbed (support/stubs.js): the field
// components record their props instead of drawing, and CharacterForm hands back
// its save callback, so a test drives the form the way a player does.
const renderForm = (locale = 'en', onCreateCharacter = async () => null) => {
  stubs.setAppLocale(locale, DICTIONARIES[locale]);

  const html = renderToString(() => TlcCharacterForm({ onCreateCharacter, setCurrentTab: () => {} }));

  return { html, fields: [...stubs.fields], save: stubs.onSaveCharacter };
};

const speciesSelect = (fields) => fields.find((item) => item.kind === 'select');
const nameInput = (fields) => fields.find((item) => item.kind === 'input');

test('a fresh mount renders the interim TLC fields and nothing else', () => {
  // Dirty a form first, on purpose: the field shape has to hold for any mount, not
  // only for the mount that happens to run before every other test in the file.
  // A form that leaked its species into the next mount renders an extra size
  // Select here (Tlc.jsx `<Show when={species !== undefined}>`).
  speciesSelect(renderForm().fields).onSelect('birdfolk');

  const { fields } = renderForm();

  // No level or ability inputs (the server fixes both), no D&D Beyond file import.
  assert.deepEqual(fields.map((item) => item.kind), ['input', 'select', 'select', 'select', 'select', 'checkbox']);
  assert.equal(fields[0].labelText, 'Name');
  assert.equal(nameInput(fields).value, '');
  assert.equal(speciesSelect(fields).selectedValue, undefined);
  assert.equal(fields.at(-1).checked, false);
});

test('saving clears the form, so the next Save cannot repost the character just created', async () => {
  const submitted = [];
  const { fields, save } = renderForm('en', async (payload) => { submitted.push({ ...payload }); return null; });

  nameInput(fields).onInput('Kaelith');
  speciesSelect(fields).onSelect('birdfolk');
  await save();
  // The player taps Save again without touching a field: the reset at Tlc.jsx must
  // have emptied the store, or this posts a duplicate of the character just made.
  await save();

  assert.equal(submitted.length, 2);
  assert.equal(submitted[0].name, 'Kaelith');
  assert.equal(submitted[0].species, 'birdfolk');
  assert.equal(submitted[1].name, '');
  assert.equal(submitted[1].species, undefined);
  assert.equal(submitted[1].size, undefined);
  assert.equal(submitted[1].background, undefined);
  assert.equal(submitted[1].alignment, 'neutral');
  // skip_guide is the one field a save keeps on: the guide is a first-character
  // walkthrough, so the dnd2024 form leaves it set too (Dnd2024.jsx saveCharacter).
  assert.equal(submitted[1].skip_guide, true);
});

test('the species select offers exactly the TLC species, never the dnd2024 base', () => {
  const species = speciesSelect(renderForm().fields);

  assert.deepEqual(Object.keys(species.items).sort(), Object.keys(tlcDelta.species).sort());
  assert.equal(Object.keys(species.items).length, 17);
  for (const slug of ['halfling', 'dragonborn', 'tiefling', 'aasimar', 'goliath']) {
    assert.equal(species.items[slug], undefined, `${slug} is a dnd2024-only species and must not be offered`);
  }
  // Names, not slugs: the option list is what the player reads.
  assert.equal(species.items.birdfolk, 'Birdfolk');
  assert.ok(Object.values(species.items).every((name) => typeof name === 'string' && name.length > 0));
});

test('picking a TLC-only species defaults its size and leaves the legacy unset', async () => {
  let submitted = null;
  const { fields, save } = renderForm('en', async (payload) => { submitted = { ...payload }; return null; });

  // birdfolk has no `legacies` key at all -- the branch a dnd2024 species never takes.
  speciesSelect(fields).onSelect('birdfolk');
  await save();

  assert.equal(submitted.species, 'birdfolk');
  assert.equal(submitted.size, 'small');
  assert.equal(submitted.legacy, undefined);
  assert.equal(submitted.alignment, 'neutral');
  assert.equal(submitted.skip_guide, false);
  // Level and abilities belong to TlcCharacter::BaseBuilder, not to the form.
  assert.deepEqual(
    Object.keys(submitted).sort(),
    ['alignment', 'background', 'legacy', 'main_class', 'name', 'size', 'skip_guide', 'species']
  );
});

test('a redefined dnd2024 species takes the TLC size, not the 2024 one', async () => {
  let submitted = null;
  const { fields, save } = renderForm('en', async (payload) => { submitted = { ...payload }; return null; });

  speciesSelect(fields).onSelect('dwarf');
  await save();

  // dnd2024 gives dwarf ['small']; tlc.json overrides it to ['medium'].
  assert.equal(submitted.size, 'medium');
});

test('every locale renders the form with real labels, en filling in for what it lags', () => {
  const enStart = DICTIONARIES.en['newCharacterPage.tlc.start'];
  // Everything up to the first character renderToString would escape.
  const rendered = enStart.slice(0, enStart.search(/[&<>'"]/));

  assert.ok(enStart.includes('level 3') && enStart.includes('point-buy'));
  assert.ok(rendered.length > 40);

  for (const locale of ['en', 'ru', 'es']) {
    const { html, fields } = renderForm(locale);

    for (const item of fields) {
      assert.ok(
        typeof item.labelText === 'string' && item.labelText.length > 0,
        `${locale} renders a blank label on the ${item.kind} field`
      );
    }
    // `start` is en-only (plan L134); it is the paragraph at the top of the form.
    assert.ok(html.includes(rendered), `${locale} drops the tlc intro paragraph`);
  }
});

test('a locale keeps its own translation where it has one', () => {
  const skipGuide = (locale) => renderForm(locale).fields.at(-1).labelText;

  assert.equal(skipGuide('ru'), DICTIONARIES.ru['newCharacterPage.tlc.skipGuide']);
  assert.notEqual(skipGuide('ru'), skipGuide('en'));
  assert.notEqual(skipGuide('es'), skipGuide('en'));
});

test('fetchDictionary layers en under every lagging locale and under the ru alias', async () => {
  const en = DICTIONARIES.en;

  for (const locale of ['ru', 'es']) {
    const dictionary = DICTIONARIES[locale];

    assert.equal(dictionary['pages.characterNavigation.tlc'], "The Leyfarer's Chronicle");
    assert.equal(dictionary['newCharacterPage.tlc.start'], en['newCharacterPage.tlc.start']);
    // The locale still wins wherever it translates a key.
    assert.notEqual(dictionary['newCharacterPage.dnd2024.species'], en['newCharacterPage.dnd2024.species']);
    assert.notEqual(dictionary['newCharacterPage.tlc.skipGuide'], en['newCharacterPage.tlc.skipGuide']);
  }

  assert.deepEqual(await fetchDictionary('ru-DHM'), DICTIONARIES.ru);
});
