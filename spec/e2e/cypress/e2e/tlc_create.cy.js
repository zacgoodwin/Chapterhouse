import { selectOption } from '../helpers/actions';

// Acceptance test 10 (plan L516) at its interim scope: create a TLC character
// through the wizard and land on a rendered sheet. The Aptitudes/Breaks tab
// assertions belong to Phase D, when a dedicated Tlc sheet replaces the borrowed
// Dnd5 one.
//
// Needs a signed-in user, and auth is Supabase rather than a Rails session, so
// the credentials come from the environment instead of a factory:
//
//   yarn cypress run --project ./spec/e2e \
//     --env CHARKEEPER_EMAIL=<user>,CHARKEEPER_PASSWORD=<password>
//
// Without them there is no session to create a character in, so the spec skips
// rather than failing on an unconfigured box.
const email = Cypress.env('CHARKEEPER_EMAIL');
const password = Cypress.env('CHARKEEPER_PASSWORD');
const CHARACTER_NAME = `Cypress Leyfarer ${Date.now()}`;

const describeWhenSignedIn = email && password ? describe : describe.skip;

describeWhenSignedIn('TLC character creation', () => {
  it('creates a TLC character through the wizard and opens its sheet', () => {
    cy.intercept('POST', '/frontend/tlc/characters.json').as('createTlcCharacter');

    cy.visit('/dashboard');
    cy.get('input[type="text"]').first().type(email);
    cy.get('input[type="password"]').type(password);
    cy.contains('.default-button', 'Sign in').click();

    // The floating "+" opens the creation wizard.
    cy.get('p[class*="rounded-full"]', { timeout: 20000 }).click();

    // The provider label comes from en i18n; picking it swaps in the TLC form.
    selectOption('Platform', "The Leyfarer's Chronicle");
    cy.contains('Leyfarers start at level 3 with point-buy ability scores.');
    // Interim form: no D&D Beyond import affordance, because tlc has no import route.
    cy.get('input[type="file"]').should('not.exist');

    cy.get('input[type="text"]').first().type(CHARACTER_NAME);
    selectOption('Species', 'Birdfolk');
    selectOption('Size', 'Medium');
    selectOption('Background', 'Guide');
    selectOption('Main class', 'Ranger');
    // Skip the new-character guide so the sheet renders directly.
    cy.contains('.flex.items-center', 'Skip new character guide').find('.toggle').click();

    cy.contains('.default-button', 'Save').click();

    // The POST has to land on the tlc endpoint, not dnd2024's.
    cy.wait('@createTlcCharacter').its('response.statusCode').should('eq', 200);

    // Back on the list: the row renders and the TLC filter tab appears, labelled
    // from en i18n with no missing-key artifact.
    cy.contains('.character-item', CHARACTER_NAME).should('contain', 'Level 3');
    cy.contains('#character-navigation p', "The Leyfarer's Chronicle");

    // No PDF export for tlc: AVAILABLE_PDF stays ['dnd5', 'dnd2024'].
    cy.contains('.character-item', CHARACTER_NAME).find('.character-item-dots').click();
    cy.get('.character-item-dots-dropdown').should('be.visible').and('not.contain', 'PDF');
    cy.get('body').click(0, 0);

    // Opening it hits the tlc <Match> in CharacterTab, which renders the interim
    // Dnd5 sheet.
    cy.contains('.character-item', CHARACTER_NAME).click();
    cy.contains('#character-navigation p', 'Abilities');
  });
});
