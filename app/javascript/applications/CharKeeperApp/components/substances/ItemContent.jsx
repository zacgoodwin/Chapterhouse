import { createMemo, Show } from 'solid-js';

import { useAppLocale } from '../../context';
import { modifier, localize } from '../../helpers';

const TRANSLATION = {
  en: {
    'dnd': {
      type: {
        light: 'Light',
        martial: 'Martial'
      },
      armorType: {
        light: 'Light Armor',
        medium: 'Medium Armor',
        heavy: 'Heavy Armor'
      },
      melee: 'Melee weapon',
      thrown: 'Melee/Thrown weapon',
      range: 'Range weapon',
      weight: 'Weight',
      price: 'Price',
      gold: 'gold',
      silver: 'silver',
      copper: 'copper',
      bludge: 'Bludgeoning',
      pierce: 'Piercing',
      slash: 'Slasing',
      damage: 'Damage',
      reach: 'Reach',
      heavy: 'Heavy',
      '2handed': 'Two-Handed',
      finesse: 'Finess',
      light: 'Light',
      versatile: 'Versatile',
      reload: 'Reload',
      caption: 'Captions',
      ac: 'Armor Class',
      maxDex: 'Maximum Dex',
      strReq: 'Strength requirements',
      stealth: 'Stealth',
      disadv: 'Disadvantage'
    }
  },
};

const renderDndPrice = (value, locale) => {
  if (value >= 100) return `${value / 100} ${localize(TRANSLATION, locale).dnd.gold}`;
  if (value >= 10) return `${value / 10} ${localize(TRANSLATION, locale).dnd.silver}`;
  return `${value} ${localize(TRANSLATION, locale).dnd.copper}`;
}

const DndWeapon = (props) => {
  const item = () => props.item;

  return (
    <>
      <p class="mt-4">{localize(TRANSLATION, props.locale).dnd.type[item().info.weapon_skill]}, {localize(TRANSLATION, props.locale).dnd[item().info.type]}</p>
      <p class="text-sm mt-2">{localize(TRANSLATION, props.locale).dnd.weight}: {item().data.weight}</p>
      <p class="text-sm mt-1">{localize(TRANSLATION, props.locale).dnd.price}: {renderDndPrice(item().data.price, props.locale)}</p>
      <p class="mt-2">{localize(TRANSLATION, props.locale).dnd.damage}: {item().info.damage} {localize(TRANSLATION, props.locale).dnd[item().info.damage_type]}</p>
      <p class="mt-2">{localize(TRANSLATION, props.locale).dnd.caption}: {Object.keys(item().info.caption).map((element) => localize(TRANSLATION, props.locale).dnd[element]).join(', ')}</p>
    </>
  );
}

const DndArmor = (props) => {
  const item = () => props.item;

  return (
    <>
      <p class="mt-4">{localize(TRANSLATION, props.locale).dnd.armorType[item().info.armor_skill]}</p>
      <p class="text-sm mt-2">{localize(TRANSLATION, props.locale).dnd.weight}: {item().data.weight}</p>
      <p class="text-sm mt-1">{localize(TRANSLATION, props.locale).dnd.price}: {renderDndPrice(item().data.price, props.locale)}</p>
      <p class="mt-2">{localize(TRANSLATION, props.locale).dnd.ac}: {item().info.ac}</p>
      <Show when={item().info.max_dex}>
        <p class="mt-2">{localize(TRANSLATION, props.locale).dnd.maxDex}: {modifier(item().info.max_dex)}</p>
      </Show>
      <Show when={item().info.str_req}>
        <p class="mt-2">{localize(TRANSLATION, props.locale).dnd.strReq}: {item().info.str_req}</p>
      </Show>
      <p class="mt-2">{localize(TRANSLATION, props.locale).dnd.stealth}: {item().info.stealth ? '-' : localize(TRANSLATION, props.locale).dnd.disadv}</p>
    </>
  );
}

const DndItem = (props) => {
  const item = () => props.item;

  return (
    <>
      <p class="text-sm mt-2">{localize(TRANSLATION, props.locale).dnd.weight}: {item().data.weight}</p>
      <p class="text-sm mt-1">{localize(TRANSLATION, props.locale).dnd.price}: {renderDndPrice(item().data.price, props.locale)}</p>
    </>
  );
}

const COMPONENTS = {
  'dnd5': {
    'weapon': DndWeapon,
    'armor': DndArmor,
    'shield': DndItem,
    'item': DndItem,
    'ammo': DndItem,
    'focus': DndItem,
    'tools': DndItem,
    'music': DndItem,
    'potion': DndItem
  },
  'dnd2024': {
    'weapon': DndWeapon,
    'armor': DndArmor,
    'shield': DndItem,
    'item': DndItem,
    'ammo': DndItem,
    'focus': DndItem,
    'tools': DndItem,
    'music': DndItem,
    'potion': DndItem
  }
}

export const ItemContent = (props) => {
  const item = () => props.item;

  const [locale] = useAppLocale();

  const ItemComponent = createMemo(() => {
    const Component = COMPONENTS[props.provider][item().kind]

    return <Component item={item()} locale={locale()} />;
  });

  return (
    <>
      <p class="text-xl">{item().name}</p>
      <Show when={props.description}>
        <p class="text-sm mt-4">{props.description}</p>
      </Show>
      {ItemComponent()}
    </>
  );
}
