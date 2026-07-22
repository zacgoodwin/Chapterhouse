import { createSignal, createEffect, Show, Switch, Match } from 'solid-js';
import { createWindowSize } from '@solid-primitives/resize-observer';

import { Dnd5 } from '../../pages';
import { PageHeader, IconButton } from '../../components';
import { Arrow } from '../../assets';
import { useAppState } from '../../context';
import { fetchCharacterRequest } from '../../requests/fetchCharacterRequest';

export const CharacterTab = (props) => {
  const size = createWindowSize();
  const [character, setCharacter] = createSignal({});
  const [appState] = useAppState();

  createEffect(() => {
    if (appState.activePageParams.id === character().id) return;

    const fetchCharacter = async () => await fetchCharacterRequest(appState.accessToken, appState.activePageParams.id);

    Promise.all([fetchCharacter()]).then(
      ([characterData]) => {
        setCharacter(characterData.character);
      }
    );
  });

  const reloadCharacter = async () => {
    const characterData = await fetchCharacterRequest(appState.accessToken, appState.activePageParams.id);
    setCharacter(characterData.character);

    return characterData.character;
  }

  const replaceCharacter = (data) => setCharacter({ ...character(), ...data });

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
          <p>{character().name}</p>
        </PageHeader>
      </Show>
      <Switch>
        <Match when={character().provider === 'dnd5'}>
          <Dnd5 character={character()} onReloadCharacter={reloadCharacter} onReplaceCharacter={replaceCharacter} />
        </Match>
        {/* Kept exact: routing the tlc provider to a sheet is A5b's Match, not this ticket's. */}
        <Match when={character().provider === 'dnd2024'}>
          <Dnd5 character={character()} onReloadCharacter={reloadCharacter} onReplaceCharacter={replaceCharacter} />
        </Match>
      </Switch>
    </>
  );
}
