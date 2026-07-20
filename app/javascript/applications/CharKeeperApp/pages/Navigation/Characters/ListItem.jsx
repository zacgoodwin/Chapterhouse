import { createSignal, createMemo, Show } from 'solid-js';
import * as i18n from '@solid-primitives/i18n';

import { IconButton } from '../../../components';
import { Dots, Avatar } from '../../../assets';
import dnd2024Config from '../../../data/dnd2024.json';
import dnd5Config from '../../../data/dnd5.json';
import { useAppLocale } from '../../../context';
import { clickOutside, localize } from '../../../helpers';

const AVAILABLE_PDF = ['dnd5', 'dnd2024'];
const TRANSLATION = {
  en: {
    delete: 'Delete'
  },
  ru: {
    delete: 'Удалить'
  },
  es: {
    delete: 'Eliminar'
  }
}

export const CharactersListItem = (props) => {
  const character = () => props.character;

  const [isOpen, setIsOpen] = createSignal(false);

  const [locale, dict] = useAppLocale();

  const t = i18n.translator(dict);

  const toggleMenu = (event) => {
    event.stopPropagation();

    setIsOpen(!isOpen());
  }

  const viewClick = (event) => {
    event.stopPropagation();

    props.onViewClick();
    setIsOpen(false);
  }

  const deleteClick = (event) => {
    setIsOpen(false);
    props.onDeleteCharacter(event);
  }

  const firstText = createMemo(() => {
    if (character().provider === 'dnd5') {
      return `${t('charactersPage.level')} ${character().level} | ${character().subrace ? localize(dnd5Config.races[character().race].subraces[character().subrace].name, locale()) : localize(dnd5Config.races[character().race].name, locale())}`;
    }
    if (character().provider === 'dnd2024') {
      return `${t('charactersPage.level')} ${character().level} | ${character().legacy ? localize(props.dnd2024Races[character().species].legacies[character().legacy].name, locale()) : localize(props.dnd2024Races[character().species].name, locale())}`;
    }
  });

  const secondText = createMemo(() => {
    if (character().provider === 'dnd5') {
      return Object.keys(character().classes).map((item) => localize(dnd5Config.classes[item].name, locale())).join(' * ');
    }
    if (character().provider === 'dnd2024') {
      return Object.keys(character().classes).map((item) => localize(dnd2024Config.classes[item].name, locale())).join(' * ');
    }
  });

  return (
    <div
      class="character-item"
      classList={{ 'character-item-not-active': !props.isActive, 'character-item-active': props.isActive }}
      onClick={props.onClick} // eslint-disable-line solid/reactivity
    >
      <div class="avatar-block">
        <Show when={character().avatar} fallback={<Avatar width={64} height={64} />}>
          <img src={character().avatar} class="avatar" />
        </Show>
      </div>
      <div
        class="character-item-box"
        classList={{ 'character-item-box-not-active': !props.isActive, 'character-item-box-active': props.isActive }}
      >
        <div class="flex-1 overflow-hidden">
          <p class="character-item-name truncate-text" classList={{ 'text-white!': props.isActive }}>{character().name}</p>
          <p class="character-item-first-text" classList={{ 'text-white!': props.isActive }}>{firstText()}</p>
          <p class="character-item-second-text" classList={{ 'text-white!': props.isActive }}>{secondText()}</p>
        </div>
        <div class="character-item-dots" use:clickOutside={() => setIsOpen(false)}>
          <IconButton onClick={toggleMenu}>
            <Dots />
          </IconButton>
          <Show when={isOpen()}>
            <div class="character-item-dots-dropdown">
              <p class="dots-item" onClick={deleteClick}>{localize(TRANSLATION, locale()).delete}</p>
              <Show when={!window.__TAURI_INTERNALS__ && AVAILABLE_PDF.includes(character().provider)}>
                <p class="dots-item" onClick={(e) => viewClick(e)}>PDF</p>
              </Show>
            </div>
          </Show>
        </div>
      </div>
    </div>
  );
}
