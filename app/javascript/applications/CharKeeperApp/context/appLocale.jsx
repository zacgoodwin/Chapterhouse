import { createSignal, createContext, useContext, createResource } from 'solid-js';
import * as i18n from '@solid-primitives/i18n';

import en from '../i18n/en.json';

const AppLocaleContext = createContext();

// en is the only dictionary — the app is English-only. fetchDictionary keeps
// its async shape because AppLocaleProvider feeds it to createResource and
// spec/javascript/tlcForm.test.js gates it directly.
export const fetchDictionary = async () => i18n.flatten(en);

export function AppLocaleProvider(props) {
  const [locale] = createSignal('en');
  const [dict] = createResource(locale, fetchDictionary);

  const store = [locale, dict];

  return (
    <AppLocaleContext.Provider value={store}>
      {props.children}
    </AppLocaleContext.Provider>
  );
}

export function useAppLocale() { return useContext(AppLocaleContext); }
