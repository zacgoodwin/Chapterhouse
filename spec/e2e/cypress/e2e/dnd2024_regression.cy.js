import { selectOption } from '../helpers/actions';

// A6 / acceptance test 13 (plan L367-369, L1010-1013): the REGRESSION RULE. The
// TLC merge touches shared files (config/routes.rb, CharacterTab.jsx, the A5a
// provider-check sweep, ...), and stock dnd2024 behavior has to be provably
// unchanged. This is the browser leg of that proof -- create a dnd2024
// character through the wizard, open its sheet, run a short rest, and confirm
// nothing TLC leaked into the stock flow. The deterministic leg (status codes,
// strict cross-provider 404s) lives in
// spec/requests/frontend/dnd2024/regression_spec.rb, which is the gate an
// unconfigured box still runs -- this file is not that gate.
//
// Needs a signed-in user, and auth is Supabase rather than a Rails session, so
// the credentials come from the environment instead of a factory: nothing
// under app_commands/ can mint a Supabase Auth account, only a local `User`
// row, so cy.appFactories can't stand a session up on its own.
//
//   yarn cypress run --project ./spec/e2e \
//     --env CHARKEEPER_EMAIL=<user>,CHARKEEPER_PASSWORD=<password>
//
// Without them there is no session to create a character in, so the spec
// skips rather than failing on an unconfigured box. Cypress itself is also not
// a dependency of this repo (README "E2E tests"): `yarn add cypress@14.5.4
// --dev` and `rails server -e test -p 5002` first, `yarn remove cypress` after.
const email = Cypress.env('CHARKEEPER_EMAIL');
const password = Cypress.env('CHARKEEPER_PASSWORD');
const CHARACTER_NAME = `Cypress Dnd2024 ${Date.now()}`;

const describeWhenSignedIn = email && password ? describe : describe.skip;

describeWhenSignedIn('Stock dnd2024 regression', () => {
  it('creates a dnd2024 character through the wizard, opens its sheet, and rests', () => {
    cy.intercept('POST', '/frontend/dnd2024/characters.json').as('createDnd2024Character');

    cy.visit('/dashboard');
    cy.get('input[type="text"]').first().type(email);
    cy.get('input[type="password"]').type(password);
    cy.contains('.default-button', 'Sign in').click();

    // The floating "+" opens the creation wizard.
    cy.get('p[class*="rounded-full"]', { timeout: 20000 }).click();

    // Picking the platform swaps in Frontend::Dnd2024::CharactersController's
    // form -- the dnd2024 sibling of the tlc one, not tlc itself.
    selectOption('Platform', 'D&D 2024');
    cy.get('input[type="text"]').first().type(CHARACTER_NAME);
    selectOption('Species', 'Human');
    selectOption('Size', 'Medium');
    selectOption('Background', 'Entertainer');
    selectOption('Main class', 'Bard');
    selectOption('Alignment', 'Neutral');
    // Skip the new-character guide so the sheet renders directly.
    cy.contains('.flex.items-center', 'Skip new character guide').find('.toggle').click();

    cy.contains('.default-button', 'Save').click();

    // The create endpoint keeps returning 201 (Frontend::Dnd2024::CharactersController
    // #create -> render_character(..., :created)), not the 200 a mis-scoped or
    // stubbed command would let through.
    cy.wait('@createDnd2024Character').its('response.statusCode').should('eq', 201);

    cy.contains('.character-item', CHARACTER_NAME).should('contain', 'Level 1');

    // No PDF export change for dnd2024: AVAILABLE_PDF still includes it.
    cy.contains('.character-item', CHARACTER_NAME).find('.character-item-dots').click();
    cy.get('.character-item-dots-dropdown').should('be.visible').and('contain', 'PDF');
    cy.get('body').click(0, 0);

    // Opening it lands on the sheet's Abilities tab (mobile-viewport default) --
    // the "core stats" the acceptance criteria asks to see rendered, with the
    // stock ability names, not any TLC substitute.
    cy.contains('.character-item', CHARACTER_NAME).click();
    cy.contains('#character-navigation p', 'Abilities');
    cy.contains('.blockable', 'Strength');

    // Rest: real command, no stub -- a TLC-contract rest command 422s here
    // (`type?: ::Dnd2024::Character` rejects Tlc::Character; ticket A6 context).
    cy.contains('#character-navigation p', 'Rest').click();
    cy.contains('.default-button', 'Short rest').click();
    cy.contains('Rest is finished');

    // Back on Abilities: still the stock dnd2024 sheet.
    cy.contains('#character-navigation p', 'Abilities').click();
    cy.contains('.blockable', 'Strength');
  });
});
