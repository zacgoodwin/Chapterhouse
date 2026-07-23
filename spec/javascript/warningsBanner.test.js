import { test } from 'node:test';
import assert from 'node:assert/strict';

// Registers the hooks that let node import .jsx; everything below has to be a
// dynamic import, or the module graph loads before the hooks exist.
import './support/jsxLoader.js';

const stubs = await import('./support/stubs.js');
const { renderToString } = await import('solid-js/web');
const { WarningsBanner } = await import(
  '../../app/javascript/applications/CharKeeperApp/components/molecules/WarningsBanner.jsx'
);
const { fetchDictionary } = await import('../../app/javascript/applications/CharKeeperApp/context/appLocale.jsx');
// The sheet itself: Dnd5.jsx mounts the banner (Dnd5.jsx:429). Its page/component
// tree resolves through support/stubs.js (real banner, null-stubbed siblings), so
// this render gates the mount -- drop the mount line and the title assertion REDs.
const { Dnd5 } = await import('../../app/javascript/applications/CharKeeperApp/pages/Content/Character/Dnd5.jsx');

const DICTIONARIES = Object.fromEntries(
  await Promise.all(['en', 'ru', 'es'].map(async (locale) => [locale, await fetchDictionary(locale)]))
);

// One active warning as the serializer emits it (Tlc::Warnings#warning):
// multiclass_prereq, source PHB, dismissible, message_key already camelCased.
const MULTICLASS_WARNING = {
  slug: 'multiclass_prereq',
  source: 'PHB',
  message_key: 'warnings.multiclassPrereq',
  dismissible: true,
  context: { classes: ['paladin'], required: { paladin: [['str'], ['cha']] }, minimum: 13 }
};

const character = (overrides = {}) => ({
  provider: 'tlc',
  id: 'char-1',
  dismissed_warnings: ['trait_count'],
  warnings: [MULTICLASS_WARNING],
  ...overrides
});

// Renders the real banner with the barrels stubbed (support/stubs.js): the Button
// records its props so a test can fire the dismiss the way a player taps it, and
// the request layer records the PATCH instead of hitting the network.
const render = (char, locale = 'en', onReloadCharacter = async () => {}) => {
  stubs.setAppLocale(locale, DICTIONARIES[locale]);
  stubs.resetRequests();

  const html = renderToString(() => WarningsBanner({ character: char, onReloadCharacter }));

  return { html, buttons: stubs.fields.filter((item) => item.kind === 'button') };
};

test('an active warning renders the title, translated message, and source label', () => {
  const { html, buttons } = render(character());

  assert.ok(html.includes(DICTIONARIES.en['warnings.title']), 'missing the warnings.title heading');
  assert.ok(html.includes(DICTIONARIES.en['warnings.multiclassPrereq']), 'missing the translated message');
  assert.ok(html.includes(DICTIONARIES.en['warnings.source.PHB']), "missing the Player's Handbook source label");
  // Dismissible warning offers exactly one Dismiss button.
  assert.equal(buttons.length, 1);
});

test('Dismiss PATCHes the slug appended to the stored list and reloads on success', async () => {
  let reloaded = 0;
  const { buttons } = render(character(), 'en', async () => { reloaded += 1; });

  await buttons[0].onClick();

  assert.equal(stubs.requests.length, 1);
  assert.equal(stubs.requests[0].url, '/frontend/tlc/characters/char-1.json');
  assert.equal(stubs.requests[0].options.method, 'PATCH');
  // Appended, not replaced: the existing dismissal survives the round-trip (#23).
  assert.deepEqual(
    stubs.requests[0].options.payload.character.dismissed_warnings,
    ['trait_count', 'multiclass_prereq']
  );
  assert.equal(reloaded, 1);
});

test('a failed dismiss does not reload', async () => {
  let reloaded = 0;
  const { buttons } = render(character(), 'en', async () => { reloaded += 1; });
  // render() resets the response to success, so arm the failure after it.
  stubs.setApiResponse({ errors_list: ['nope'] });

  await buttons[0].onClick();

  assert.equal(reloaded, 0);
});

test('an empty warnings list renders no banner and no crash', () => {
  const { html, buttons } = render(character({ warnings: [] }));

  assert.ok(!html.includes(DICTIONARIES.en['warnings.title']));
  assert.equal(buttons.length, 0);
});

test('a payload with no warnings key at all (a dnd2024 character) renders nothing', () => {
  const { html, buttons } = render({ provider: 'dnd2024', id: 'd-1', dismissed_warnings: [] });

  assert.ok(!html.includes(DICTIONARIES.en['warnings.title']));
  assert.equal(buttons.length, 0);
});

test('a non-dismissible warning renders the row but no Dismiss button', () => {
  const { html, buttons } = render(
    character({ warnings: [{ ...MULTICLASS_WARNING, dismissible: false }] })
  );

  assert.ok(html.includes(DICTIONARIES.en['warnings.multiclassPrereq']));
  assert.equal(buttons.length, 0);
});

test('a stale es/ru locale serves the en dictionary: message and source render, never blank', () => {
  for (const locale of ['es', 'ru']) {
    const { html } = render(character(), locale);

    const message = DICTIONARIES[locale]['warnings.multiclassPrereq'];
    const source = DICTIONARIES[locale]['warnings.source.PHB'];

    assert.ok(typeof message === 'string' && message.length > 0, `${locale} has no message`);
    assert.ok(html.includes(message), `${locale} drops its message`);
    assert.ok(html.includes(source), `${locale} drops its source label`);
    assert.ok(html.includes(DICTIONARIES[locale]['warnings.title']), `${locale} drops its title`);
    // The app is en-only: a stale locale must serve the real en message,
    // not a blank or renamed key (literal match so a dictionary regression REDs).
    assert.match(message, /multiclass/i);
  }
});

// classes/subclasses are the only character fields Dnd5's setup memos read
// directly (Object.keys/Object.values); the abilities column the SSR reaches
// touches nothing else. Everything but the banner renders to null via stubs.js.
const sheetCharacter = (overrides = {}) => ({ ...character(), classes: {}, subclasses: {}, ...overrides });

test('the sheet mounts the banner: rendering Dnd5 shows the warning title and message', () => {
  stubs.setAppLocale('en', DICTIONARIES.en);
  stubs.resetRequests();

  const html = renderToString(() => Dnd5({ character: sheetCharacter(), onReloadCharacter: async () => {} }));

  // Removing the <WarningsBanner .../> mount from Dnd5.jsx makes both go RED.
  assert.ok(html.includes(DICTIONARIES.en['warnings.title']), 'the sheet does not mount the banner title');
  assert.ok(html.includes(DICTIONARIES.en['warnings.multiclassPrereq']), 'the sheet does not mount the translated message');
});

test('a warning with no dismissed_warnings key still dismisses (guarded spread)', async () => {
  // dismissible warning present, dismissed_warnings absent: the unguarded spread
  // would throw. The payload is just the new slug.
  const { buttons } = render(character({ dismissed_warnings: undefined }));

  await buttons[0].onClick();

  assert.deepEqual(stubs.requests[0].options.payload.character.dismissed_warnings, ['multiclass_prereq']);
});
