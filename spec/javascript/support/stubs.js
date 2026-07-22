// Stand-ins for the barrels a creation form imports. The field components record
// the props they were handed instead of drawing, so a test can assert on what the
// form actually passes down rather than on its source text.
export { translate, localize } from '../../../app/javascript/applications/CharKeeperApp/helpers/translate.jsx';

// Dnd5.jsx mounts the REAL WarningsBanner at the top of its sheet body
// (Dnd5.jsx:429). A render-gate for that mount imports Dnd5 through these barrels,
// so the banner has to be the real component (re-exported here) while the rest of
// Dnd5's page/component tree is inert -- the abilities column the render exercises
// never reads their props. isDnd2024Family/localize come from their real helpers so
// the memos Dnd5 builds at setup behave as they do in the app.
export { WarningsBanner } from '../../../app/javascript/applications/CharKeeperApp/components/molecules/WarningsBanner.jsx';
export { isDnd2024Family } from '../../../app/javascript/applications/CharKeeperApp/helpers/provider.jsx';

const nullComponent = () => null;
// pages barrel
export const Dnd5Abilities = nullComponent;
export const Dnd5Combat = nullComponent;
export const Dnd5Rest = nullComponent;
export const Dnd5ClassLevels = nullComponent;
export const Dnd5Professions = nullComponent;
export const Dnd5Spells = nullComponent;
export const Dnd5Skills = nullComponent;
export const Dnd5Proficiency = nullComponent;
export const Dnd2024WildShapes = nullComponent;
export const BeastFeatures = nullComponent;
export const Dnd5Craft = nullComponent;
export const Dnd5Bonuses = nullComponent;
export const Dnd2024Spells = nullComponent;
export const Dnd5Info = nullComponent;
export const Dnd2024Bonuses = nullComponent;
// components barrel
export const CharacterNavigation = nullComponent;
export const Equipment = nullComponent;
export const Notes = nullComponent;
export const Avatar = nullComponent;
export const ContentWrapper = nullComponent;
export const Feats = nullComponent;
export const Conditions = nullComponent;
export const Combat = nullComponent;
export const Gold = nullComponent;
export const createRoll = () => ({ Roll: nullComponent, openD20Test: () => {}, openD20Attack: () => {} });

export const fields = [];

let currentLocale = 'en';
let currentDict = {};

export const setAppLocale = (locale, dict) => {
  currentLocale = locale;
  currentDict = dict;
  fields.length = 0;
};

export const useAppLocale = () => [() => currentLocale, () => currentDict, { setLocale: setAppLocale }];

const record = (kind) => (props) => {
  // Read every prop the form passes eagerly: SSR does not, and an accessor that
  // throws (a missing species, say) has to fail the test, not pass unevaluated.
  fields.push({ kind, ...Object.fromEntries(Object.keys(props).map((key) => [key, props[key]])) });
  return null;
};

export const Select = record('select');
export const Input = record('input');
export const Checkbox = record('checkbox');
export const Button = record('button');

export let onSaveCharacter = null;

export const CharacterForm = (props) => {
  onSaveCharacter = props.onSaveCharacter;
  return props.children;
};

// A component reading appState (WarningsBanner's dismiss) needs the accessToken.
export const useAppState = () => [{ accessToken: 'test-token' }, {}];

// The `/helpers` barrel is redirected here, so a real request module
// (updateCharacterRequest) linked in a test resolves its network layer to these.
// `options` passes the payload through unstringified so a test can read the PATCH
// body; `apiRequest` records the call and returns whatever the test set.
export const requests = [];
let apiResponse = {};
export const setApiResponse = (value) => { apiResponse = value; };
export const resetRequests = () => { requests.length = 0; apiResponse = {}; };

export const options = (method, accessToken, payload) => ({ method, accessToken, payload });
export const formDataOptions = (method, accessToken, payload) => ({ method, accessToken, payload });
export const apiRequest = async ({ url, options }) => {
  requests.push({ url, options });
  return apiResponse;
};
