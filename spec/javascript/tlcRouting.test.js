import { test } from 'node:test';
import assert from 'node:assert/strict';

// The DOM lane (jsdom + solid's client build), not the SSR harness the other
// specs use: both surfaces below only render after a fetch inside a
// createEffect, which SSR never runs. Must be first -- everything after it has
// to be a dynamic import, or the module graph loads before the hooks exist.
import { mount, tick } from './support/domHarness.js';

const stubs = await import('./support/stubs.js');
const { fetchDictionary } = await import('../../app/javascript/applications/CharKeeperApp/context/appLocale.jsx');
const { CharactersTab } = await import(
  '../../app/javascript/applications/CharKeeperApp/pages/Navigation/CharactersTab.jsx'
);
const { CharacterTab } = await import(
  '../../app/javascript/applications/CharKeeperApp/pages/Content/CharacterTab.jsx'
);

const DICTIONARY = await fetchDictionary('en');

// Both tabs fan out to several endpoints from one effect; answer per url so the
// component sees the shapes the serializers actually emit. Nothing here reaches
// the network: the helpers barrel resolves to stubs.js (domHarness.js also
// blocks global fetch outright).
const respondWith = ({ characters = [], character = {} } = {}) => (url) => {
  if (url.startsWith('/frontend/characters.json')) return { characters };
  if (url.startsWith('/frontend/homebrews.json')) return { dnd2024: { races: {} } };
  if (url.startsWith('/frontend/characters/')) return { character };

  throw new Error(`unstubbed request: ${url}`);
};

const arrange = (responses) => {
  stubs.setAppLocale('en', DICTIONARY);
  stubs.resetRequests();
  stubs.setApiResponse(respondWith(responses));
  stubs.setActivePageParams({});
};

const field = (kind, dataTestId) => stubs.fields.find((item) => item.kind === kind && item.dataTestId === dataTestId);

// Walks the platform picker the way a player does: wait out the characters
// fetch, tap the + button, pick a platform in the select. Returns the text the
// creation area rendered, which is the marker name of whichever form opened
// (support/stubs.js).
const pickPlatform = async (platform) => {
  arrange({});

  const { container, dispose } = mount(() => CharactersTab());
  await tick();

  const newCharacter = field('button', 'new-character-button');
  assert.ok(newCharacter, 'CharactersTab.jsx: no new-character button after the characters fetch resolved');
  newCharacter.onClick();

  const picker = field('select', 'new-character-platform-select');
  assert.ok(picker, 'CharactersTab.jsx: no platform select on the new-character tab');
  picker.onSelect(platform);

  const { textContent } = container;
  dispose();

  return textContent;
};

test('CharactersTab routes the tlc platform to the TLC creation form', async () => {
  const rendered = await pickPlatform('tlc');

  // Deleting the `platform() === 'tlc'` branch from CharactersTab.jsx REDs this:
  // tlc falls through to the dnd5 form.
  assert.ok(
    rendered.includes('[TlcCharacterForm]'),
    `CharactersTab.jsx: platform 'tlc' did not open TlcCharacterForm, rendered ${JSON.stringify(rendered)}`
  );
});

test('CharactersTab still routes dnd2024 and dnd5 to their own creation forms', async () => {
  // The tlc branch sits above these two, so a mistake there swallows them.
  assert.ok((await pickPlatform('dnd2024')).includes('[Dnd2024CharacterForm]'), 'CharactersTab.jsx: dnd2024 lost its form');
  assert.ok((await pickPlatform('dnd5')).includes('[Dnd5CharacterForm]'), 'CharactersTab.jsx: dnd5 lost its form');
});

const openCharacter = async (provider) => {
  arrange({ character: { id: 'char-1', provider, name: 'Ferrik' } });
  stubs.setActivePageParams({ id: 'char-1' });

  const { container, dispose } = mount(() => CharacterTab({ onNavigate: () => {} }));
  await tick();

  const { textContent } = container;
  dispose();

  return textContent;
};

test('CharacterTab opens the sheet for a tlc character', async () => {
  const rendered = await openCharacter('tlc');

  // Deleting the tlc <Match> from CharacterTab.jsx REDs this: no Match holds and
  // the Switch renders nothing.
  assert.ok(
    rendered.includes('[Dnd5Sheet]'),
    `CharacterTab.jsx: provider 'tlc' did not open the sheet, rendered ${JSON.stringify(rendered)}`
  );
});

test('CharacterTab still opens the sheet for dnd5 and dnd2024 characters', async () => {
  assert.ok((await openCharacter('dnd5')).includes('[Dnd5Sheet]'), 'CharacterTab.jsx: dnd5 lost its sheet');
  assert.ok((await openCharacter('dnd2024')).includes('[Dnd5Sheet]'), 'CharacterTab.jsx: dnd2024 lost its sheet');
});

test('an unknown provider opens no sheet at all', async () => {
  // Guards the gate itself: if every provider rendered the marker, the two tests
  // above would pass with the Matches deleted.
  assert.ok(!(await openCharacter('pathfinder')).includes('[Dnd5Sheet]'), 'CharacterTab.jsx: an unknown provider opened a sheet');
});
