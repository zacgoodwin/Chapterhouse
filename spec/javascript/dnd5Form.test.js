import { test } from 'node:test';
import assert from 'node:assert/strict';

// Registers the hooks that let node import .jsx; everything below it has to be a
// dynamic import, or the module graph loads before the hooks exist.
import './support/jsxLoader.js';

const stubs = await import('./support/stubs.js');
const { renderToString } = await import('solid-js/web');
const { Dnd5CharacterForm } = await import(
  '../../app/javascript/applications/CharKeeperApp/pages/Navigation/Characters/Forms/Dnd5.jsx'
);
const { fetchDictionary } = await import('../../app/javascript/applications/CharKeeperApp/context/appLocale.jsx');

const DICTIONARIES = { en: await fetchDictionary() };

// Renders the real form with the barrels stubbed (support/stubs.js): the field
// components record their props instead of drawing, and CharacterForm hands back
// its save callback, so a test drives the form the way a player does.
const renderForm = (locale = 'en', onCreateCharacter = async () => null) => {
  stubs.setAppLocale(locale, DICTIONARIES[locale]);

  const html = renderToString(() => Dnd5CharacterForm({
    onCreateCharacter,
    onImportCharacter: () => {},
    setCurrentTab: () => {}
  }));

  return { html, fields: [...stubs.fields], save: stubs.onSaveCharacter };
};

const raceSelect = (fields) => fields.find((item) => item.kind === 'select');
const nameInput = (fields) => fields.find((item) => item.kind === 'input');

test('a dirtied, unsaved form does not leak into the next mount', () => {
  // Dnd5CharacterForm handed DND5_DEFAULT_FORM straight to createStore: every
  // keystroke wrote through into that module constant, so an abandoned (never
  // saved) form pre-filled the next mount with the previous player's edits.
  const { fields: abandoned } = renderForm();
  nameInput(abandoned).onInput('Stale Name');
  raceSelect(abandoned).onSelect('dwarf');
  // Never call save() -- the player navigated away instead.

  const { fields } = renderForm();

  assert.equal(nameInput(fields).value, '');
  assert.equal(raceSelect(fields).selectedValue, undefined);
});
