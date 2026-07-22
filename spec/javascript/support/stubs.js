// Stand-ins for the barrels a creation form imports. The field components record
// the props they were handed instead of drawing, so a test can assert on what the
// form actually passes down rather than on its source text.
export { translate } from '../../../app/javascript/applications/CharKeeperApp/helpers/translate.jsx';

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

export let onSaveCharacter = null;

export const CharacterForm = (props) => {
  onSaveCharacter = props.onSaveCharacter;
  return props.children;
};
