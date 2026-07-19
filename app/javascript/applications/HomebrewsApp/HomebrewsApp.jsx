import { HomebrewsAppContent } from './HomebrewsAppContent';

import { AppStateProvider, AppLocaleProvider, AppAlertProvider } from './context';

export const HomebrewsApp = (props) => (
  <AppStateProvider>
    <AppLocaleProvider locale={props.locale}>
      <AppAlertProvider>
        <HomebrewsAppContent />
      </AppAlertProvider>
    </AppLocaleProvider>
  </AppStateProvider>
);
