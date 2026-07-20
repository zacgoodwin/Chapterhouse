import { Show, createEffect, createSignal, batch } from 'solid-js';
import { createWindowSize } from '@solid-primitives/resize-observer';

import { PageHeader, IconButton, Input, Button, Select } from '../../components';
import { Arrow } from '../../assets';
import { useAppState, useAppLocale, useAppAlert } from '../../context';
import { updateUserRequest } from '../../requests/updateUserRequest';
import { localize, performResponse } from '../../helpers';

const TRANSLATION = {
  en: {
    light: 'Light',
    dark: 'Dark',
    username: 'Username',
    locale: 'Locale',
    colorSchema: 'Color schema',
    profile: 'Profile',
    save: 'Save',
    updated: 'Profile is updated'
  },
  ru: {
    light: 'Светлая',
    dark: 'Тёмная',
    username: 'Имя пользователя',
    locale: 'Язык',
    colorSchema: 'Цветовая палитра',
    profile: 'Профиль',
    save: 'Сохранить',
    updated: 'Профиль обновлён'
  },
  es: {
    light: 'Claro',
    dark: 'Oscuro',
    username: 'Nombre de usuario',
    locale: 'Idioma',
    colorSchema: 'Esquema de colores',
    profile: 'Perfil',
    save: 'Guardar',
    updated: 'Perfil actualizado'
  }
}

export const UsernameTab = (props) => {
  const size = createWindowSize();

  const [username, setUsername] = createSignal('');
  const [colorSchema, setColorSchema] = createSignal('');
  const [localeValue, setLocaleValue] = createSignal(undefined);

  const [appState, { changeUserInfo }] = useAppState();
  const [{ renderAlerts, renderNotice }] = useAppAlert();
  const [locale, , { setLocale }] = useAppLocale();

  createEffect(() => {
    batch(() => {
      setUsername(appState.username);
      setColorSchema(appState.colorSchema);
      setLocaleValue(locale());
    });
  });

  const updateProfile = async () => {
    let payload = { color_schema: colorSchema(), locale: localeValue() };
    if (username() !== appState.username) payload = { ...payload, username: username() };

    const result = await updateUserRequest(appState.accessToken, payload);

    performResponse(
      result,
      function() { // eslint-disable-line solid/reactivity
        batch(() => {
          changeUserInfo({ username: username(), colorSchema: colorSchema() });
          setLocale(localeValue());
        });
        renderNotice(localize(TRANSLATION, locale()).updated);
      },
      function() { renderAlerts(result.errors_list) }
    );
  }

  return (
    <>
      <Show when={size.width < 768}>
        <PageHeader
          leftContent={
            <IconButton onClick={props.onNavigate}>
              <Arrow back width={20} height={20} />
            </IconButton>
          }
        >
          <p>{localize(TRANSLATION, locale()).profile}</p>
        </PageHeader>
      </Show>
      <div class="p-4 flex-1 flex flex-col overflow-y-auto">
        <Input
          containerClassList="mb-2"
          labelText={localize(TRANSLATION, locale()).username}
          value={username()}
          onInput={setUsername}
        />
        <Select
          containerClassList="mb-2"
          labelText={localize(TRANSLATION, locale()).locale}
          items={{ 'en': 'English', 'ru': 'Русский', 'es': 'Español' }}
          selectedValue={localeValue()}
          onSelect={setLocaleValue}
        />
        <Select
          containerClassList="mb-2"
          labelText={localize(TRANSLATION, locale()).colorSchema}
          items={{ 'light': localize(TRANSLATION, locale()).light, 'dark': localize(TRANSLATION, locale()).dark }}
          selectedValue={colorSchema()}
          onSelect={setColorSchema}
        />
        <Button default textable classList="mt-4" onClick={updateProfile}>{localize(TRANSLATION, locale()).save}</Button>
      </div>
    </>
  );
}
