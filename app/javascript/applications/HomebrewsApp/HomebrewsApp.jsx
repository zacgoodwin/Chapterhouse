import { HomebrewsAppContent } from './HomebrewsAppContent';

import { AppStateProvider, AppLocaleProvider, AppAlertProvider } from './context';

export const HomebrewsApp = () => (
  <AppStateProvider>
    <AppLocaleProvider>
      <AppAlertProvider>
        <HomebrewsAppContent />
      </AppAlertProvider>
    </AppLocaleProvider>
  </AppStateProvider>
);
