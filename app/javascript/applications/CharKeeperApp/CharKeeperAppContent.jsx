import { createEffect, createMemo, Switch, Match, batch } from 'solid-js';
import * as i18n from '@solid-primitives/i18n';
import { createWindowSize } from '@solid-primitives/resize-observer';

import { NavigationPage, ContentPage, LoginPage } from './pages';
import { useAppState, useAppLocale } from './context';
import { performResponse } from './helpers';

import { fetchUnreadNotificationsCountRequest } from './requests/fetchUnreadNotificationsCountRequest';
import { fetchUserInfoRequest } from './requests/fetchUserInfoRequest';

export const CharKeeperAppContent = () => {
  const size = createWindowSize();

  const [appState, { setAccessToken, navigate, changeUnreadNotificationsCount, changeUserInfo }] = useAppState();

  const [, dict, { setLocale }] = useAppLocale();

  const t = i18n.translator(dict);

  createEffect(() => {
    if (appState.accessToken !== undefined) return;
    if (!appState.initialized) return;

    setAccessToken(null);
  });

  createEffect(() => {
    if (!appState.accessToken) return;
    if (appState.unreadNotificationsCount !== undefined) return;

    const fetchUnreadNotificationsCount = async () => await fetchUnreadNotificationsCountRequest(appState.accessToken);

    Promise.all([fetchUnreadNotificationsCount()]).then(
      ([notificationsCountData]) => {
        if (notificationsCountData.unread !== undefined) changeUnreadNotificationsCount(notificationsCountData.unread);
      }
    );
  });

  createEffect(() => {
    if (!appState.accessToken) return;
    if (appState.username !== undefined) return;

    const fetchUserInfo = async () => await fetchUserInfoRequest(appState.accessToken);

    Promise.all([fetchUserInfo()]).then(
      ([userInfoData]) => {
        performResponse(
          userInfoData,
          function() {
            batch(() => {
              setLocale(userInfoData.locale);
              changeUserInfo({
                username: userInfoData.username,
                isAdmin: userInfoData.admin,
                colorSchema: userInfoData.color_schema
              });
            });
          },
          function() {
            setAccessToken(null);
          }
        );
      }
    );
  });

  const navigationPage = createMemo(() => {
    if (!appState.accessToken) return <></>;
    if (appState.unreadNotificationsCount === undefined) return <></>;

    return <NavigationPage />;
  });

  // 453x750
  // 420x690
  return (
    <Switch>
      <Match when={appState.accessToken && appState.unreadNotificationsCount !== undefined}>
        <div class="flex-1 flex flex-col bg-gray-50 overflow-hidden" classList={{ 'dark': appState.colorSchema === 'dark' }}>
          <section class="w-full flex-1 flex overflow-hidden">
            <Switch fallback={<ContentPage onNavigate={() => navigate(null, {})} />}>
              <Match when={size.width >= 768}>
                {navigationPage()}
                <ContentPage />
              </Match>
              <Match when={appState.activePage === null}>
                {navigationPage()}
              </Match>
            </Switch>
          </section>
        </div>
      </Match>
      <Match when={appState.accessToken === undefined}>
        <div class="h-screen flex justify-center items-center">
          <div>{t('loading')}</div>
        </div>
      </Match>
      <Match when={appState.accessToken === null}>
        <LoginPage />
      </Match>
    </Switch>
  );
}
