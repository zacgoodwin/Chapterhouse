import { For } from 'solid-js';

import { useAppLocale } from '../../../context';
import { localize } from '../../../helpers';

const TRANSLATION = {
  en: {
    'str': 'Strength',
    'dex': 'Dexterity',
    'con': 'Constitution',
    'int': 'Intelligence',
    'wis': 'Wisdom',
    'cha': 'Charisma',
    'save_dc.str': 'Strength saving throw',
    'save_dc.dex': 'Dexterity saving throw',
    'save_dc.con': 'Constitution saving throw',
    'save_dc.int': 'Intelligence saving throw',
    'save_dc.wis': 'Wisdom saving throw',
    'save_dc.cha': 'Charisma saving throw',
    'armor_class': 'Armor Class',
    'initiative': 'Initiative',
    'speed': 'Speed',
    'speeds.swim': 'Swim speed',
    'speeds.flight': 'Flight speed',
    'speeds.climb': 'Climb speed',
    'attack': 'Attack',
    'unarmed_attacks': 'Unarmed attacks',
    'melee_attacks': 'Melee attacks',
    'thrown_attacks': 'Thrown attacks',
    'range_attacks': 'Range attacks',
    'damage': 'Damage',
    'unarmed_damage': 'Unarmed damage',
    'melee_damage': 'Melee damage',
    'thrown_damage': 'Thrown damage',
    'range_damage': 'Range damage'
  },
}

export const FeatureModifiers = (props) => {
  const [locale] = useAppLocale();

  return (
    <div class="flex gap-1 text-sm">
      <For each={Object.entries(props.items)}>
        {([key, values]) =>
          <p class="bg-gray-200 p-1 rounded">
            {localize(TRANSLATION, locale())[key]} {values.value}
          </p>
        }
      </For>
    </div>
  );
}
