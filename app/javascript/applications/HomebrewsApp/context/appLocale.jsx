import { createSignal, createContext, useContext } from 'solid-js';

const AppLocaleContext = createContext();

export function AppLocaleProvider(props) {
  const [locale] = createSignal('en'); // English-only app

  const store = [locale];

  return (
    <AppLocaleContext.Provider value={store}>
      {props.children}
    </AppLocaleContext.Provider>
  );
}

export function useAppLocale() { return useContext(AppLocaleContext); }
