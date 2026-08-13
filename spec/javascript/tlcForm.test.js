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
const { Dnd2024CharacterForm } = await import(
  '../../app/javascript/applications/CharKeeperApp/pages/Navigation/Characters/Forms/Dnd2024.jsx'
);
const { fetchDictionary } = await import('../../app/javascript/applications/CharKeeperApp/context/appLocale.jsx');
const { default: tlcDelta } = await import('../../app/javascript/applications/CharKeeperApp/data/tlc.json');
const { tlcConfig } = await import('../../app/javascript/applications/CharKeeperApp/data/tlcConfig.js');

const DICTIONARIES = { en: await fetchDictionary() };

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

// The point-buy row: one minus/plus pair per ability, in config order.
const ABILITY_ORDER = Object.keys(tlcConfig.abilities);
const stepper = (fields, slug) => {
  const pair = fields.filter((item) => item.kind === 'button').slice(ABILITY_ORDER.indexOf(slug) * 2);

  // `live` re-reads the prop through the component's getters, so a button that
  // went disabled after the last click reports it.
  return { minus: pair[0], plus: pair[1] };
};
const raise = (fields, slug, times) => { for (let step = 0; step < times; step += 1) stepper(fields, slug).plus.onClick(); };

test('a fresh mount renders the interim TLC fields and nothing else', () => {
  // Dirty a form first, on purpose: the field shape has to hold for any mount, not
  // only for the mount that happens to run before every other test in the file.
  // A form that leaked its species into the next mount renders an extra size
  // Select here (Tlc.jsx `<Show when={species !== undefined}>`).
  speciesSelect(renderForm().fields).onSelect('birdfolk');

  const { fields } = renderForm();

  // No level input (TlcCharacter::BaseBuilder fixes it at 3), no D&D Beyond file
  // import, and one point-buy stepper pair per ability under its label.
  assert.deepEqual(
    fields.map((item) => item.kind),
    ['input', 'select', 'select', 'select', 'select', 'label', ...Array(12).fill('button'), 'checkbox']
  );
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
  // Level belongs to TlcCharacter::BaseBuilder; abilities are the player's to buy.
  assert.deepEqual(
    Object.keys(submitted).sort(),
    ['abilities', 'alignment', 'background', 'legacy', 'main_class', 'name', 'size', 'skip_guide', 'species']
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

test('switching species after picking a legacy clears the stale legacy from the payload', async () => {
  // The legacy Select only mounts once a species with legacies is already picked
  // (Tlc.jsx `<Show when={Object.keys(legacies()).length > 0}>`), so a single SSR
  // pass -- this harness only ever does one -- never renders it starting from the
  // undefined default and there is no field handle to drive a "pick a legacy" click.
  // Solid's server-build store hands `onCreateCharacter` the live, unproxied form
  // object though (solid-js/store/dist/server.js createStore returns the state
  // object itself), so writing `legacy` directly on the payload a prior save
  // captured reproduces exactly what a real legacy pick would have left in the
  // store -- then the species switch below has to clear it same as a real one would.
  const submitted = [];
  const { fields, save } = renderForm('en', async (payload) => { submitted.push(payload); return 'kept'; });

  // elf keeps its dnd2024 legacies (tlc.json's elf entry has no `legacies` key, so
  // the merge leaves the base ones in place).
  speciesSelect(fields).onSelect('elf');
  await save();
  submitted[0].legacy = 'high_elf';

  // birdfolk has no legacies at all -- a legacy left over from elf would otherwise
  // ride along in the payload.
  speciesSelect(fields).onSelect('birdfolk');
  await save();

  assert.equal(submitted[1].species, 'birdfolk');
  assert.equal(submitted[1].legacy, undefined);
});

test('the form renders with real labels and the tlc intro paragraph', () => {
  const enStart = DICTIONARIES.en['newCharacterPage.tlc.start'];
  // Everything up to the first character renderToString would escape.
  const rendered = enStart.slice(0, enStart.search(/[&<>'"]/));

  assert.ok(enStart.includes('level 3') && enStart.includes('point-buy'));
  assert.ok(rendered.length > 40);

  const { html, fields } = renderForm('en');

  // The stepper buttons carry an icon, not a label; every labelled field needs one.
  for (const item of fields.filter((field) => field.kind !== 'button')) {
    assert.ok(
      typeof item.labelText === 'string' && item.labelText.length > 0,
      `blank label on the ${item.kind} field`
    );
  }
  // `start` is the paragraph at the top of the form.
  assert.ok(html.includes(rendered), 'the tlc intro paragraph is dropped');
});

// Point buy (issue #80): the intro paragraph promises it, so the form has to
// deliver it. The server re-prices the spread (Tlc::PointBuy) either way.
test('the allocator opens at the 8 floor with all 27 points unspent', () => {
  const { html, fields } = renderForm();

  assert.ok(html.includes('Points remaining: 27'), 'the remaining-points counter is missing');
  assert.deepEqual(ABILITY_ORDER, ['str', 'dex', 'con', 'int', 'wis', 'cha']);
  for (const slug of ABILITY_ORDER) {
    // Nothing to give back at the floor; everything is affordable from it.
    assert.equal(stepper(fields, slug).minus.disabled, true, `${slug} can be lowered below 8`);
    assert.equal(stepper(fields, slug).plus.disabled, false, `${slug} cannot be raised from 8`);
  }
});

test('the counter charges the PH p.38 table, 2 points for the 13->14 and 14->15 steps', async () => {
  let submitted = null;
  const { fields, save } = renderForm('en', async (payload) => {
    submitted = { ...payload, abilities: { ...payload.abilities } };
    return null;
  });

  // Five abilities to 13: 5 points each by the table, 25 spent, 2 left.
  for (const slug of ['str', 'dex', 'con', 'int', 'wis']) raise(fields, slug, 5);

  // 2 points left buys exactly one 13->14 step and nothing more.
  assert.equal(stepper(fields, 'str').plus.live.disabled, false);
  assert.equal(stepper(fields, 'cha').plus.live.disabled, false, 'an 8->9 step costs 1 and is still affordable');

  raise(fields, 'str', 1); // 13 -> 14, the last 2 points
  assert.equal(stepper(fields, 'str').plus.live.disabled, true, '14->15 costs 2 and the budget is spent');
  assert.equal(stepper(fields, 'cha').plus.live.disabled, true, 'nothing is affordable at 0 remaining');
  assert.equal(stepper(fields, 'str').minus.live.disabled, false, 'a bought point can always be given back');

  // Save last: it resets the allocator, so every live assertion has to precede it.
  await save();
  assert.deepEqual(submitted.abilities, { str: 14, dex: 13, con: 13, int: 13, wis: 13, cha: 8 });
});

test('the allocator refuses to overdraw the budget or to pass 15', async () => {
  let submitted = null;
  const { fields, save } = renderForm('en', async (payload) => {
    submitted = { ...payload, abilities: { ...payload.abilities } };
    return null;
  });

  // 20 clicks on each of the six abilities: unclamped that is 8 + 20 everywhere.
  for (const slug of ABILITY_ORDER) raise(fields, slug, 20);
  await save();

  const spread = submitted.abilities;
  assert.ok(Object.values(spread).every((score) => score >= 8 && score <= 15), JSON.stringify(spread));
  const cost = { 8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9 };
  const spent = Object.values(spread).reduce((total, score) => total + cost[score], 0);
  assert.ok(spent <= 27, `spent ${spent} of 27`);
  // Greedy left-to-right spending: str/dex/con reach 15 (9 each), the rest stay at 8.
  assert.deepEqual(spread, { str: 15, dex: 15, con: 15, int: 8, wis: 8, cha: 8 });
});

test('editing another field keeps the points already spent', async () => {
  let submitted = null;
  const { fields, save } = renderForm('en', async (payload) => {
    submitted = { ...payload, abilities: { ...payload.abilities } };
    return null;
  });

  raise(fields, 'str', 7); // 8 -> 15
  // Every other field writes through a whole-store spread, which is where a
  // nested abilities object would get flattened or reset.
  nameInput(fields).onInput('Kaelith');
  speciesSelect(fields).onSelect('birdfolk');
  raise(fields, 'dex', 2); // 8 -> 10, after the spreads
  await save();

  assert.equal(submitted.name, 'Kaelith');
  assert.deepEqual(submitted.abilities, { str: 15, dex: 10, con: 8, int: 8, wis: 8, cha: 8 });
});

test('saving resets the allocator to a fresh floor, never a shared one', async () => {
  const submitted = [];
  const { fields, save } = renderForm('en', async (payload) => {
    submitted.push({ ...payload, abilities: { ...payload.abilities } });
    return null;
  });

  raise(fields, 'int', 7); // 8 -> 15
  await save();
  await save();

  assert.equal(submitted[0].abilities.int, 15);
  assert.deepEqual(submitted[1].abilities, { str: 8, dex: 8, con: 8, int: 8, wis: 8, cha: 8 });
  // A second mount must not inherit the first one's spend (the createStore /
  // shared-nested-object footgun the module-level default form used to carry).
  const fresh = renderForm();
  assert.ok(fresh.html.includes('Points remaining: 27'));
});

// Point buy is TLC-only: dnd2024 creation keeps its class standard array, which
// CharactersContext::Dnd2024::CreateCommand fills in server-side.
test('the dnd2024 form takes no ability input at all', () => {
  stubs.setAppLocale('en', DICTIONARIES.en);

  const html = renderToString(() => Dnd2024CharacterForm({
    onCreateCharacter: async () => null,
    onImportCharacter: () => {},
    setCurrentTab: () => {},
    homebrews: () => undefined,
    dnd2024Races: () => ({})
  }));

  assert.equal(stubs.fields.filter((item) => item.kind === 'button').length, 0);
  assert.equal(stubs.fields.filter((item) => item.kind === 'label').length, 1); // the D&D Beyond file label
  assert.ok(!html.includes('Points remaining'));
});

test('fetchDictionary serves the flattened en dictionary regardless of argument', async () => {
  // The app is English-only: any historical locale value a stale client sends
  // (ru, es, the ru-DHM alias) must still resolve to a working dictionary.
  for (const stale of [undefined, 'en', 'ru', 'ru-DHM', 'es']) {
    const dictionary = await fetchDictionary(stale);

    assert.equal(dictionary['pages.characterNavigation.tlc'], "The Leyfarer's Chronicle");
    assert.ok(dictionary['newCharacterPage.tlc.skipGuide'].length > 0);
  }
});
