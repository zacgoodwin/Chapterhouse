import { createMemo, For, Show } from 'solid-js';

import { ErrorWrapper, GuideWrapper, Text } from '../../../../components';
import config from '../../../../data/dnd5.json';
import { dndConfigFor } from '../../../../data/tlcConfig';
import { useAppLocale } from '../../../../context';
import { localize, isDnd2024Family } from '../../../../helpers';

const TRANSLATION = {
  en: {
    alignment: 'Alignment',
    background: 'Background',
    species: 'Species',
    legacy: 'Legacy',
    race: 'Race',
    subrace: 'Subrace'
  },
}

export const Dnd5Info = (props) => {
  const character = () => props.character;
  // dndConfigFor keeps tlc on the merged config; the static dnd2024 import it
  // replaced never saw the tlc.json delta (plan eng finding 8). `config`
  // (dnd5.json) stays exact -- it only feeds the race/subrace branch below,
  // which availableKeys() never offers to a dnd2024-family character.
  const configNext = () => dndConfigFor(character().provider);

  const [locale] = useAppLocale();

  const availableKeys = createMemo(() => {
    if (character().provider === 'dnd5') return ['alignment', 'race', 'subrace'];
    if (isDnd2024Family(character().provider)) return ['alignment', 'species', 'legacy', 'background'];

    return [];
  })

  const renderValue = (item) => {
    if (item === 'alignment') return localize(configNext().alignments[character().alignment].name, locale());
    if (item === 'species') return character().names.species_name;
    // Out of scope (issue #64): a TLC-only species has no `legacies` key at all,
    // so this still throws for it same as before -- fixing that needs tlc legacy
    // data, not plumbing.
    if (item === 'legacy' && character().legacy) return localize(configNext().species[character().species].legacies[character().legacy].name, locale());
    if (item === 'background') return character().names.background_name;

    if (item === 'race') return localize(config.races[character().race].name, locale());
    if (item === 'subrace' && character().subrace) return localize(config.races[character().race].subraces[character().subrace].name, locale());

    return character()[item];
  }

  return (
    <ErrorWrapper payload={{ character_id: character().id, key: 'Dnd5Info' }}>
      <GuideWrapper character={character()}>
        <div class="character-info-block">
          <p class="character-info-title">{character().name}</p>
          <div class="character-info-grid">
            <For each={availableKeys()}>
              {(item) =>
                <Show when={character()[item]}>
                  <Text
                    labelText={localize(TRANSLATION, locale())[item]}
                    labelClassList="character-info-text"
                    text={renderValue(item)}
                  />
                </Show>
              }
            </For>
          </div>
        </div>
      </GuideWrapper>
    </ErrorWrapper>
  );
}
