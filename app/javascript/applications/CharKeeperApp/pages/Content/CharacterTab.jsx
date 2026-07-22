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
        {/* Kept exact: tlc has its own Match below, so this one stays 2024-only. */}
        <Match when={character().provider === 'dnd2024'}>
          <Dnd5 character={character()} onReloadCharacter={reloadCharacter} onReplaceCharacter={replaceCharacter} />
        </Match>
        {/* Interim scaffolding (plan L420-421): tlc borrows the Dnd5 sheet until
            the dedicated TLC sheet lands in D2. Kept as its own Match, not folded
            into the dnd2024 one, so D2 is a one-line component swap. */}
        <Match when={character().provider === 'tlc'}>
          <Dnd5 character={character()} onReloadCharacter={reloadCharacter} onReplaceCharacter={replaceCharacter} />
        </Match>
      </Switch>
    </>
  );
}
