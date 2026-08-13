import { test, expect } from '@playwright/test';

// The eval-lane twin of spec/javascript/tlcRouting.test.js: the same two TLC
// surfaces, but against the deployed dev instance with real auth, a real bundle
// and real API responses. The gate lane proves the branches are wired; this
// proves the wiring survives the build, the API and the CSS.
//
// It asserts on what is deployed, which lags main -- a failure here can mean
// "dev has not been redeployed yet" as easily as "the code broke".
//
// Labels are the shipped en strings (i18n/en.json). The attribute is
// `datatestid`, lowercase: solid passes the JSX `dataTestId` prop through
// setAttribute, and HTML lowercases attribute names.
const TLC = "The Leyfarer's Chronicle";
const NEW_CHARACTER = '[datatestid="new-character-button"]';
const PLATFORM_SELECT = '[datatestid="new-character-platform-select"]';
const SAVE_CHARACTER = '[datatestid="character-save-button"]';

test.beforeAll(() => {
  if (process.env.QA_EMAIL && process.env.QA_PASSWORD) return;

  // Loud, not skipped: missing credentials mean the eval did not run, and an
  // eval that quietly reports success is worse than no eval.
  throw new Error(
    'QA_EMAIL and QA_PASSWORD are required. Put them in .env.qa.local at the repo root (gitignored, never commit them).'
  );
});

test.beforeEach(async ({ page }) => {
  await page.goto('/dashboard');

  // LoginPage renders one text input and one password input, neither tied to its
  // label by `for`, so position is the only handle there is.
  await page.locator('input[type="text"]').first().fill(process.env.QA_EMAIL);
  await page.locator('input[type="password"]').first().fill(process.env.QA_PASSWORD);
  // By class, not by role: the Button atom became a real <button> in 06e84572,
  // and this suite has to keep working against whatever is currently deployed.
  // The class is on both spellings; the h2 above it is not.
  await page.locator('.default-button').filter({ hasText: 'Sign in' }).click();

  // The + button lives behind `Show when={filteredCharacters()}`, so it is also
  // the signal that the characters fetch came back.
  await expect(page.locator(NEW_CHARACTER)).toBeVisible();
});

// Every Select is a label plus a div of clickable <li>s, no test id and no
// native <select>. Pick by the label the field carries.
const chooseFirst = async (page, labelText) => {
  const field = page.locator('.form-field').filter({ hasText: labelText });

  await field.click();
  await field.locator('li').first().click();
};

const openPlatform = async (page, platform) => {
  await page.locator(NEW_CHARACTER).click();

  const picker = page.locator(PLATFORM_SELECT);
  await picker.click();
  await picker.getByText(platform, { exact: true }).click();
};

test('the platform picker opens the TLC creation form', async ({ page }) => {
  await openPlatform(page, TLC);

  // TlcCharacterForm's intro paragraph, which neither neighbouring form has:
  // seeing it means CharactersTab routed the tlc platform to the right form.
  // Deliberately not the point-buy counter, which is newer than the deployed
  // build -- an eval asserts on what is live, not on what is on main.
  await expect(page.getByText('Leyfarers start at level 3')).toBeVisible();
});

test('a TLC character opens its sheet', async ({ page }) => {
  // Creates its own subject and deletes it again, so the eval needs no seeded
  // fixture on the dev account. The timestamp makes an escaped character
  // obvious if the cleanup below ever fails.
  const name = `Eval Leyfarer ${Date.now()}`;

  await openPlatform(page, TLC);
  // The name Input passes no containerClassList, so it has no .form-field hook.
  // It is the only text box on the page: the Selects render one only while an
  // open searchable dropdown is filtering.
  await page.locator('input[type="text"]').first().fill(name);
  // Species also fixes size; alignment defaults to neutral. Those three plus the
  // name are what CharactersContext::Tlc::CreateCommand requires.
  await chooseFirst(page, 'Species');
  await chooseFirst(page, 'Main class');
  // Everything after the Save click runs inside the try: the row assertion can
  // fail on a character that WAS created, and cleanup outside the try would
  // then never run, stranding it on the shared QA account.
  try {
    await page.locator(SAVE_CHARACTER).click();

    const row = page.locator('.character-item').filter({ hasText: name });
    await expect(row).toBeVisible();
    await row.click();

    // Below 768px the sheet replaces the list, so everything on screen now comes
    // from CharacterTab's tlc <Match>: the header it draws around
    // character().name, the sheet's own title (Dnd5/Info.jsx) and its tab strip.
    // Delete that Match and the Switch renders nothing at all.
    await expect(page.locator('.character-info-title')).toHaveText(name);
    await expect(page.locator('#character-navigation').getByText('Abilities', { exact: true })).toBeVisible();
  } finally {
    // Reload rather than walk back: the supabase session survives it, and the
    // list is where a fresh load lands.
    await page.goto('/dashboard');
    // count() does not auto-wait, unlike the expect() matchers. Without this the
    // check can read 0 while the characters fetch is still in flight and skip a
    // cleanup that was actually needed.
    await expect(page.locator(NEW_CHARACTER)).toBeVisible();
    const doomed = page.locator('.character-item').filter({ hasText: name });
    // Guarded, not an early `return`: the save itself may be what failed, so
    // there may be nothing to delete -- but `return` inside finally would
    // discard an in-flight assertion error and let a real failure pass silently.
    if (await doomed.count() > 0) {
      // The dots icon, not its wrapper: only the icon's own handler stops the
      // click from bubbling to the row, which would open the sheet instead.
      await doomed.locator('.character-item-dots svg').click();
      await doomed.getByText('Delete', { exact: true }).click();
      await page.locator('.modal').getByText('Delete', { exact: true }).click();
      await expect(doomed).toHaveCount(0);
    }
  }
});
