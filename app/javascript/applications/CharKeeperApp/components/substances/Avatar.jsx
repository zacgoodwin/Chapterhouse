import { createSignal, createEffect, batch } from 'solid-js';
import * as i18n from '@solid-primitives/i18n';

import { Button, Input, Label } from '../../components';
import { useAppState, useAppLocale, useAppAlert } from '../../context';
import { updateCharacterRequest } from '../../requests/updateCharacterRequest';
import { localize } from '../../helpers';

const TRANSLATION = {
  en: {
    fileSizeLimit: 'File size should be less than 1 MB',
    avatarFile: 'Select avatar file',
    avatarUrl: 'or paste link to image',
    avatarTransform: 'Image will be converted to square format'
  },
  ru: {
    fileSizeLimit: 'Размер файла должен быть меньше 1 МБ',
    avatarFile: 'Выберите файл аватара',
    avatarUrl: 'или укажите ссылку на изображение',
    avatarTransform: 'Изображение будет конфертировано в квадратный формат'
  },
  es: {
    fileSizeLimit: 'El tamaño del archivo debe ser menor a 1 MB',
    avatarFile: 'Selecciona el archivo del avatar',
    avatarUrl: 'o pega el enlace a la imagen',
    avatarTransform: 'La imagen se convertirá a un formato cuadrado'
  }
}

export const Avatar = (props) => {
  const character = () => props.character;

  const [lastActiveCharacterId, setLastActiveCharacterId] = createSignal(undefined);
  const [loading, setLoading] = createSignal(false);
  const [selectedFile, setSelectedFile] = createSignal(null);
  const [avatarUrl, setAvatarUrl] = createSignal('');

  const [name, setName] = createSignal(undefined);

  const [appState] = useAppState();
  const [{ renderAlert, renderAlerts, renderNotice }] = useAppAlert();
  const [locale, dict] = useAppLocale();

  const t = i18n.translator(dict);

  createEffect(() => {
    if (lastActiveCharacterId() === character().id) return;

    batch(() => {
      setName(character().name);
      setLastActiveCharacterId(character().id);
    });
  });

  const handleFileChange = (event) => {
    const target = event.target;
    if (target.files && target.files.length > 0) {
      const file = target.files[0];
      if (file.size > 1000000) return renderAlert(localize(TRANSLATION, locale()).fileSizeLimit);

      setSelectedFile(file);
    }
  }

  const updateCharacter = async () => {
    setLoading(true);

    const characterFormData = new FormData();
    if (character().name !== name()) characterFormData.append('name', name());
    if (selectedFile()) characterFormData.append('file', selectedFile());
    if (avatarUrl().length > 0) characterFormData.append('avatar_url', avatarUrl());
    characterFormData.append('only_head', true);

    const result = await updateCharacterRequest(appState.accessToken, character().provider, character().id, characterFormData, true);

    if (result.errors_list === undefined) {
      batch(() => {
        if (character().name !== name()) props.onReplaceCharacter({ name: name() });
        renderNotice(t('alerts.characterIsUpdated'));
        setLoading(false);
      });
    } else {
      batch(() => {
        renderAlerts(result.errors_list);
        setLoading(false);
      });
    }
  }

  return (
    <div class="blockable py-4 px-2 md:px-4 mb-4">
      <div>
        <Label labelText={localize(TRANSLATION, locale()).avatarFile} />
        <input class="block mb-2 dark:text-gray-200" type="file" accept="image/jpeg, image/png" onChange={handleFileChange} />
        <Input
          labelText={localize(TRANSLATION, locale()).avatarUrl}
          value={avatarUrl()}
          onInput={(value) => setAvatarUrl(value)}
        />
        <Label labelText={localize(TRANSLATION, locale()).avatarTransform} />
      </div>
      <Input
        containerClassList="mt-4"
        labelText={t('newCharacterPage.name')}
        value={name()}
        onInput={setName}
      />
      <Button default classList="mt-4" onClick={() => loading() ? null : updateCharacter()}>{loading() ? t('saving') : t('save')}</Button>
    </div>
  );
}
