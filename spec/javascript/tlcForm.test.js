import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import en from '../../app/javascript/applications/CharKeeperApp/i18n/en.json' with { type: 'json' };
import ru from '../../app/javascript/applications/CharKeeperApp/i18n/ru.json' with { type: 'json' };
import es from '../../app/javascript/applications/CharKeeperApp/i18n/es.json' with { type: 'json' };

const CHARKEEPER = path.join(
  fileURLToPath(new URL('../../', import.meta.url)),
  'app/javascript/applications/CharKeeperApp'
);

const read = (relative) => readFileSync(path.join(CHARKEEPER, relative), 'utf8');

// The A5b creation form and the surfaces that route to it. Rendering SolidJS
// needs a DOM the repo has no harness for, so the option data itself is covered
// by pure assertions (tlcConfig.test.js) and the wiring is asserted on source.
test('the tlc creation form reads species from tlcConfig, never a provider json', () => {
  const source = read('pages/Navigation/Characters/Forms/Tlc.jsx');

  assert.match(source, /import \{[^}]*tlcCreationSpecies[^}]*\} from '\.\.\/\.\.\/\.\.\/\.\.\/data\/tlcConfig'/);
  assert.match(source, /items=\{translate\(tlcCreationSpecies, locale\(\)\)\}/);
  assert.doesNotMatch(source, /data\/dnd2024\.json/);
  assert.doesNotMatch(source, /data\/tlc\.json/);
});

// There is no ImportContext::Tlc and the tlc `import` route is deliberately
// unrouted, so a Beyond-import affordance on this form would 404 on click.
test('the tlc creation form offers no D&D Beyond import', () => {
  const source = read('pages/Navigation/Characters/Forms/Tlc.jsx');

  assert.doesNotMatch(source, /onImportCharacter/);
  assert.doesNotMatch(source, /type="file"/);
});

test('CharactersTab routes the tlc platform to the tlc form and lists it', () => {
  const source = read('pages/Navigation/CharactersTab.jsx');

  assert.match(source, /platform\(\) === 'tlc'/);
  assert.match(source, /<TlcCharacterForm/);
  assert.match(source, /\['dnd5', 'dnd2024', 'tlc'\]/);
  assert.match(source, /'tlc': t\('pages\.characterNavigation\.tlc'\)/);
  // No homebrew props: /frontend/homebrews only serves a dnd2024 bucket.
  assert.doesNotMatch(source, /<TlcCharacterForm[^>]*homebrews=/);
});

test('CharacterTab renders a tlc character on the interim Dnd5 sheet', () => {
  const source = read('pages/Content/CharacterTab.jsx');

  assert.match(source, /<Match when=\{character\(\)\.provider === 'tlc'\}>/);
  // Its own Match, so D2 swaps one component instead of untangling a shared branch.
  assert.equal((source.match(/<Match /g) || []).length, 3);
});

// The PDF export sheet is the official 2024 form; tlc has none to fill.
test('tlc gets no PDF affordance in the characters list', () => {
  const source = read('pages/Navigation/Characters/ListItem.jsx');

  assert.match(source, /const AVAILABLE_PDF = \['dnd5', 'dnd2024'\];/);
});

test('en carries the tlc strings the form and the provider label need', () => {
  assert.equal(en.pages.characterNavigation.tlc, "The Leyfarer's Chronicle");
  assert.match(en.newCharacterPage.tlc.start, /level 3/);
  assert.match(en.newCharacterPage.tlc.start, /point-buy/);
  assert.ok(en.newCharacterPage.tlc.skipGuide);
});

// The form's field labels are reused from dnd2024 rather than duplicated under
// a tlc namespace: every locale already translates them, so a ru/es player gets
// a real translation instead of an en fallback.
test('every field label the tlc form reuses is translated in ru and es', () => {
  const labels = ['species', 'legacy', 'size', 'background', 'mainClass', 'alignment'];

  for (const [name, dictionary] of [['ru', ru], ['es', es]]) {
    assert.ok(dictionary.newCharacterPage.name, `${name} is missing newCharacterPage.name`);
    for (const label of labels) {
      assert.ok(dictionary.newCharacterPage.dnd2024[label], `${name} is missing newCharacterPage.dnd2024.${label}`);
    }
    for (const size of ['small', 'medium', 'large']) {
      assert.ok(dictionary.newCharacterPage.dnd2024.sizes[size], `${name} is missing size ${size}`);
    }
  }
});

// Mirrors i18n.flatten from @solid-primitives/i18n: every nested leaf also gets
// a dotted top-level key, which is what translator() looks up.
const flatten = (dictionary, prefix = '') =>
  Object.entries(dictionary).reduce((acc, [key, value]) => {
    const flatKey = prefix ? `${prefix}.${key}` : key;
    acc[flatKey] = value;
    if (value && typeof value === 'object' && !Array.isArray(value)) Object.assign(acc, flatten(value, flatKey));
    return acc;
  }, {});

const TLC_KEYS = ['pages.characterNavigation.tlc', 'newCharacterPage.tlc.start', 'newCharacterPage.tlc.skipGuide'];

// ru/es lag en deliberately (plan L134). translator() returns undefined for a
// missing key, so without the en layer in fetchDictionary these render blank.
test('the tlc labels are non-blank in every locale once layered over en', () => {
  for (const [name, dictionary] of [['en', en], ['ru', ru], ['es', es]]) {
    const merged = { ...flatten(en), ...flatten(dictionary) };

    for (const key of TLC_KEYS) assert.ok(merged[key], `${name} renders ${key} blank`);
  }
});

// newCharacterPage.tlc is the partially-translated case: ru/es carry skipGuide
// (the string already existed for the dnd2024 form) and lag `start`. A locale
// node that lags one sibling key must not shadow the en string for it.
test('a partially translated tlc node keeps its own strings and falls back on the rest', () => {
  for (const [name, dictionary] of [['ru', ru], ['es', es]]) {
    const merged = { ...flatten(en), ...flatten(dictionary) };

    assert.ok(dictionary.newCharacterPage.tlc.skipGuide, `${name} should translate skipGuide`);
    assert.equal(merged['newCharacterPage.tlc.skipGuide'], dictionary.newCharacterPage.tlc.skipGuide);
    assert.equal(merged['newCharacterPage.tlc.start'], en.newCharacterPage.tlc.start);
  }
});

test('layering keeps the en string for a lagging key and the locale string elsewhere', () => {
  const lagging = { ...flatten(en), ...flatten({ pages: { characterNavigation: { dnd5: 'ДиД 5' } } }) };

  assert.equal(lagging['pages.characterNavigation.tlc'], "The Leyfarer's Chronicle");
  assert.equal(lagging['pages.characterNavigation.dnd5'], 'ДиД 5');
});

test('fetchDictionary layers en under every non-en locale', () => {
  const source = read('context/appLocale.jsx');

  assert.match(source, /i18n\.flatten\(await import\('\.\.\/i18n\/en\.json'\)\), \.\.\.i18n\.flatten\(dictionary\)/);
});
