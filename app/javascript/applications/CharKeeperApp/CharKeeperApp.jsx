import { CharKeeperAppContent } from './CharKeeperAppContent';

import { AppStateProvider, AppLocaleProvider, AppAlertProvider } from './context';

export const CharKeeperApp = (props) => (
  <AppStateProvider
    username={props.username}
    isAdmin={props.admin}
    colorSchema={props.colorSchema}
    providerLocales={props.providerLocales}
    host={props.host}
  >
    <AppLocaleProvider locale={props.locale}>
      <AppAlertProvider>
        <CharKeeperAppContent />
      </AppAlertProvider>
    </AppLocaleProvider>
  </AppStateProvider>
);
