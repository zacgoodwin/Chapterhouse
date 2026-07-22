import { createSignal, createContext, useContext, createResource } from 'solid-js';
import * as i18n from '@solid-primitives/i18n';

const AppLocaleContext = createContext();

const FALLBACKS = {
  'ru-DHM': 'ru'
}

// en is the only complete dictionary; ru/es lag it deliberately (TLC strings are
// en-only for now). Without the merge below a missing key resolves to undefined
// and the label renders blank, so every locale is layered over en.
// Exported for spec/javascript/tlcForm.test.js -- the layering is what keeps a
// ru/es label from rendering blank, so it is gated directly.
export const fetchDictionary = async (locale) => {
  const target = FALLBACKS[locale] || locale;
  const dictionary = await import(`../i18n/${target}.json`);
  if (target === 'en') return i18n.flatten(dictionary);

  return { ...i18n.flatten(await import('../i18n/en.json')), ...i18n.flatten(dictionary) };
}

export function AppLocaleProvider(props) {
  const [locale, setLocale] = createSignal(props.locale || 'en'); // eslint-disable-line solid/reactivity
  const [dict] = createResource(locale, fetchDictionary);

  const store = [
    locale,
    dict,
    {
      setLocale(value) {
        setLocale(value);
      }
    }
  ];

  return (
    <AppLocaleContext.Provider value={store}>
      {props.children}
    </AppLocaleContext.Provider>
  );
}

export function useAppLocale() { return useContext(AppLocaleContext); }
