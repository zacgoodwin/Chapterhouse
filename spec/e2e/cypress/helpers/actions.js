const DEFAULT_TIMEOUT = Cypress.config('defaultCommandTimeout');

export const scrollToBySelector = (selector, customTimeout = DEFAULT_TIMEOUT) => {
  return cy.get(selector, { timeout: customTimeout }).scrollIntoView();
};

export const clickBySelector = (
  selector,
  forceClick = false,
  customTimeout = DEFAULT_TIMEOUT,
) => {
  return scrollToBySelector(selector, customTimeout).click({ force: forceClick });
};

// The SPA's <Select> is a div, not a <select>: open the field carrying the label,
// then click the option in its dropdown. (The atoms spell test ids `dataTestId`,
// which the DOM lowercases to `datatestid`, so `[data-test-id]` never matches
// inside the SPA -- label text is the reliable handle.)
export const selectOption = (labelText, optionText) => {
  return cy.contains('.form-field', labelText).within(() => {
    cy.get('.default-select').click();
    cy.contains('.form-dropdown li', optionText).click();
  });
};
