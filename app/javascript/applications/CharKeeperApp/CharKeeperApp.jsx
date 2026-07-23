import { CharKeeperAppContent } from './CharKeeperAppContent';

import { AppStateProvider, AppLocaleProvider, AppAlertProvider } from './context';

export const CharKeeperApp = (props) => (
  <AppStateProvider
    username={props.username}
    isAdmin={props.admin}
    colorSchema={props.colorSchema}
    host={props.host}
  >
    <AppLocaleProvider>
      <AppAlertProvider>
        <CharKeeperAppContent />
      </AppAlertProvider>
    </AppLocaleProvider>
  </AppStateProvider>
);
