// Stand-ins for the barrels a creation form imports. The field components record
// the props they were handed instead of drawing, so a test can assert on what the
// form actually passes down rather than on its source text.
export { translate, localize } from '../../../app/javascript/applications/CharKeeperApp/helpers/translate.jsx';
// The TLC form's point-buy allocator has to run for real, or a test asserting on
// the remaining-points counter asserts on a stub.
export {
  POINT_BUY_MIN, POINT_BUY_MAX, POINT_BUY_BUDGET, POINT_BUY_COST,
  pointBuyFloor, pointBuySpent, pointBuyRemaining, canPointBuyChange
} from '../../../app/javascript/applications/CharKeeperApp/helpers/pointBuy.js';

// Dnd5.jsx mounts the REAL WarningsBanner at the top of its sheet body
// (Dnd5.jsx:429). A render-gate for that mount imports Dnd5 through these barrels,
// so the banner has to be the real component (re-exported here) while the rest of
// Dnd5's page/component tree is inert -- the abilities column the render exercises
// never reads their props. isDnd2024Family/localize come from their real helpers so
// the memos Dnd5 builds at setup behave as they do in the app.
export { WarningsBanner } from '../../../app/javascript/applications/CharKeeperApp/components/molecules/WarningsBanner.jsx';
export { isDnd2024Family } from '../../../app/javascript/applications/CharKeeperApp/helpers/provider.jsx';

const nullComponent = () => null;
// A component that renders its own name as text. The DOM lane asserts on which
// one landed in the container, which is how the platform/provider branches get
// gated; solid inserts a returned string as a text node in either compile mode.
const marker = (name) => () => `[${name}]`;
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
// The four destinations CharactersTab/CharacterTab route to. Markers, not nulls:
// "which form did the platform picker open" is the assertion.
export const TlcCharacterForm = marker('TlcCharacterForm');
export const Dnd2024CharacterForm = marker('Dnd2024CharacterForm');
export const Dnd5CharacterForm = marker('Dnd5CharacterForm');
export const Dnd5 = marker('Dnd5Sheet');
export const CharactersListItem = marker('CharactersListItem');
// components barrel
// ErrorWrapper/GuideWrapper only guard/wrap in the real app; a test rendering
// what they wrap has to see their children, not a swallowed null.
export const ErrorWrapper = (props) => props.children;
export const GuideWrapper = (props) => props.children;
export const CharacterNavigation = nullComponent;
export const Equipment = nullComponent;
export const Notes = nullComponent;
export const Avatar = nullComponent;
export const ContentWrapper = nullComponent;
export const Feats = nullComponent;
export const Conditions = nullComponent;
export const Combat = nullComponent;
export const Gold = nullComponent;
export const Loading = nullComponent;
export const IconButton = nullComponent;
// PageHeader/Modal only decorate in the real app; a test asserting on what sits
// inside them has to see their children.
export const PageHeader = (props) => props.children;
export const createModal = () => ({ Modal: (props) => props.children, openModal: () => {}, closeModal: () => {} });
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
  // `live` keeps the props object itself, whose members are getters: read through
  // it to see a prop AFTER a handler ran (a +/- button that just went disabled),
  // rather than the value frozen at render time.
  fields.push({ kind, live: props, ...Object.fromEntries(Object.keys(props).map((key) => [key, props[key]])) });
  return null;
};

export const Select = record('select');
export const Input = record('input');
export const Checkbox = record('checkbox');
export const Button = record('button');
export const Label = record('label');
export const Text = record('text');

export let onSaveCharacter = null;

export const CharacterForm = (props) => {
  onSaveCharacter = props.onSaveCharacter;
  return props.children;
};

// A component reading appState (WarningsBanner's dismiss) needs the accessToken.
// activePageParams is what CharacterTab's fetch effect keys off, so a test picks
// the character it opens by setting it before mounting. Plain object, not a
// store: nothing under test re-reads it after mount.
export const appState = { accessToken: 'test-token', activePageParams: {}, isAdmin: false };
export const setActivePageParams = (params) => { appState.activePageParams = params; };
export const useAppState = () => [appState, { navigate: () => {} }];
export const useAppAlert = () => [{ renderAlerts: () => {}, renderNotice: () => {} }];

// The `/helpers` barrel is redirected here, so a real request module
// (updateCharacterRequest) linked in a test resolves its network layer to these.
// `options` passes the payload through unstringified so a test can read the PATCH
// body; `apiRequest` records the call and returns whatever the test set.
export const requests = [];
let apiResponse = {};
// A function value is called with the request url, so a test driving a component
// that fires several different requests can answer each one.
export const setApiResponse = (value) => { apiResponse = value; };
export const resetRequests = () => { requests.length = 0; apiResponse = {}; };

export const options = (method, accessToken, payload) => ({ method, accessToken, payload });
export const formDataOptions = (method, accessToken, payload) => ({ method, accessToken, payload });
export const apiRequest = async ({ url, options }) => {
  requests.push({ url, options });
  return typeof apiResponse === 'function' ? apiResponse(url) : apiResponse;
};
