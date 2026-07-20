import { createContext, createEffect, useContext } from 'solid-js';
import { createStore } from 'solid-js/store';

import { supabase } from '../../CharKeeperApp/helpers/supabase';

const AppStateContext = createContext();

export const AppStateProvider = (props) => {
  const [appState, setAppState] = createStore({
    accessToken: props.accessToken, // eslint-disable-line solid/reactivity
    activePage: null,
    activePageParams: {},
    initialized: false
  });

  // same origin as CharKeeperApp: the shared supabase-js session in
  // localStorage carries the token between both SPAs
  const initSupabaseSession = async () => {
    const client = supabase();
    if (!client) return setAppState({ ...appState, accessToken: null, initialized: true });

    const { data } = await client.auth.getSession();
    setAppState({ ...appState, accessToken: data.session?.access_token ?? null, initialized: true });

    client.auth.onAuthStateChange((_event, session) => {
      setAppState('accessToken', session?.access_token ?? null);
    });
  }

  createEffect(() => {
    if (appState.accessToken !== undefined) return;

    initSupabaseSession();
  });

  const store = [
    appState,
    {
      setAccessToken(value) {
        setAppState({ ...appState, accessToken: value });
      },
      navigate(page, params) {
        setAppState({ ...appState, activePage: page, activePageParams: params });
      }
    }
  ];

  return (
    <AppStateContext.Provider value={store}>
      {props.children}
    </AppStateContext.Provider>
  );
}

export function useAppState() { return useContext(AppStateContext); }
