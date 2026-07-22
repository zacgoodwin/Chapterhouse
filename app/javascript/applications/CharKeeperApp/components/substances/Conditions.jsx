import { createSignal, createEffect, createMemo, Show, batch, For } from 'solid-js';

import { Select, ErrorWrapper, GuideWrapper } from '../../components';
import { dndConfigFor } from '../../data/tlcConfig';
import { useAppState, useAppLocale } from '../../context';
import { updateCharacterRequest } from '../../requests/updateCharacterRequest';
import { translate, localize, isDnd2024Family } from '../../helpers';

const TRANSLATION = {
  en: {
    conditions: 'Conditions',
    selectedStances: 'Active conditions',
  },
  ru: {
    conditions: 'Состояния',
    selectedStances: 'Активные состояния',
  },
  es: {
    conditions: 'Condiciones',
    selectedStances: 'Condiciones activas',
  }
}

export const Conditions = (props) => {
  const character = () => props.character;

  const [lastActiveCharacterId, setLastActiveCharacterId] = createSignal(undefined);
  const [selectedConditions, setSelectedConditions] = createSignal([]);

  const [appState] = useAppState();
  const [locale] = useAppLocale();

  createEffect(() => {
    if (lastActiveCharacterId() === character().id) return;

    batch(() => {
      setSelectedConditions(character().conditions);
      setLastActiveCharacterId(character().id);
    });
  });

  const providerConfig = createMemo(() => {
    // dndConfigFor keeps tlc on the merged config; the static dnd2024 import
    // it replaced never saw the tlc.json delta (plan eng finding 8).
    if (character().provider === 'dnd5' || isDnd2024Family(character().provider)) return dndConfigFor(character().provider);
  });

  const updateMultiFeatureValue = async (value) => {
    const newValue = selectedConditions().includes(value) ? selectedConditions().filter((item) => item !== value) : selectedConditions().concat([value]);

    await updateCharacterRequest(
      appState.accessToken, character().provider, character().id, { character: { conditions: newValue }, only_head: true }
    )
    setSelectedConditions(newValue);
  }

  return (
    <ErrorWrapper payload={{ character_id: character().id, key: 'Conditions' }}>
      <GuideWrapper character={character()}>
        <div class="blockable py-4 px-2 md:px-4">
          <h2 class="text-lg mb-2">{localize(TRANSLATION, locale()).conditions}</h2>
          <Select
            multi
            containerClassList="w-full"
            labelText={localize(TRANSLATION, locale()).selectedConditions}
            items={translate(providerConfig().conditions, locale())}
            selectedValues={selectedConditions()}
            onSelect={updateMultiFeatureValue}
          />
          <Show when={selectedConditions().length > 0}>
            <For each={selectedConditions()}>
              {(condition) =>
                <p class="mt-2 text-sm">{localize(providerConfig().conditions[condition].description, locale())}</p>
              }
            </For>
          </Show>
        </div>
      </GuideWrapper>
    </ErrorWrapper>
  );
}
