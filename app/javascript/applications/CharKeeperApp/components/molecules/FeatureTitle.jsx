import { Show, For } from 'solid-js';

import { Button } from '../../components';
import { useAppLocale } from '../../context';
import { PlusSmall, Minus, Campfire, LongCampfire, Moon, Picnic, Combat } from '../../assets';
import { localize } from '../../helpers';

const FEATURE_ICONS = {
  'one_at_short_rest': Picnic, 'short_rest': Campfire, 'long_rest': LongCampfire, 'session': Moon, 'combat': Combat
}
const TRANSLATION = {
  en: {
    one_at_short_rest: 'Short - 1, long - full',
    short_rest: 'Short rest',
    long_rest: 'Long rest',
    session: 'Session rest',
    combat: 'Combat rest',
    ap: 'AP',
    sp: 'SP',
    mp: 'MP',
    hope: 'Hope',
    stress: 'Stress',
    health: 'Health',
    armor: 'Armor',
    spent: 'Resource is spent',
    a: 'A',
    r: 'R'
  },
  ru: {
    one_at_short_rest: 'Короткий - 1, длинный - все',
    short_rest: 'Короткий отдых',
    long_rest: 'Длинный отдых',
    session: 'Между сессиями',
    combat: 'Между боями',
    ap: 'ОД',
    sp: 'ОВ',
    mp: 'ОМ',
    hope: 'Надежда',
    stress: 'Стресс',
    health: 'Здоровье',
    armor: 'Броня',
    spent: 'Ресурс потрачен',
    a: 'Д',
    r: 'Р'
  },
  es: {
    one_at_short_rest: 'Corto - 1, largo - todo',
    short_rest: 'Descanso corto',
    long_rest: 'Descanso largo',
    session: 'Descanso entre sesiones',
    combat: 'Descanso entre batallas',
    ap: 'PA',
    sp: 'PE',
    mp: 'PM',
    hope: 'Esperanza',
    stress: 'Estrés',
    health: 'Health',
    armor: 'Armor',
    spent: 'Resource is spent',
    a: 'A',
    r: 'R'
  }
}
const PRICE_WITHOUT_VALUE = ['r'];

export const FeatureTitle = (props) => {
  const feature = () => props.feature;

  const IconComponent = FEATURE_ICONS[feature().limit_refresh]; // eslint-disable-line solid/reactivity

  const [locale] = useAppLocale();

  return (
    <div class="flex">
      <div class="flex-1">
        <p class="flex items-center">
          {feature().title}
        </p>
        <div class="flex items-center gap-x-4">
          <Show when={Object.keys(feature().price).length > 0}>
            <div class="flex gap-x-2">
              <For each={Object.entries(feature().price)}>
                {([slug, value]) =>
                  <Show when={localize(TRANSLATION, locale())[slug]}>
                    <p class="text-xs">
                      <Show when={!PRICE_WITHOUT_VALUE.includes(slug)} fallback={localize(TRANSLATION, locale())[slug]}>
                        {localize(TRANSLATION, locale())[slug]} {value}
                      </Show>
                    </p>
                  </Show>
                }
              </For>
            </div>
          </Show>
        </div>
      </div>
      <div class="flex items-center gap-x-4">
        <Show when={feature().limit !== undefined}>
          <div class="flex items-center">
            <Button default size="small" onClick={(event) => (feature().limit === 0 && feature().used_count !== 0) || feature().used_count !== feature().limit ? props.onSpendEnergy(event, feature()) : event.stopPropagation()}>
              <Minus />
            </Button>
            <p class="flex items-center justify-center mx-2">
              <span class="w-6 text-center">{feature().limit === 0 ? -feature().used_count : feature().limit - (feature().used_count === null ? feature().limit : feature().used_count)}</span>
              <Show when={IconComponent}>
                <span title={localize(TRANSLATION, locale())[feature().limit_refresh]}><IconComponent /></span>
              </Show>
            </p>
            <Button default size="small" onClick={(event) => feature().limit === 0 || feature().used_count === null || feature().used_count > 0 ? props.onRestoreEnergy(event, feature()) : event.stopPropagation()}>
              <PlusSmall />
            </Button>
          </div>
        </Show>
      </div>
    </div>
  );
}
