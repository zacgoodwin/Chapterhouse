import { Switch, Match } from 'solid-js';
import * as i18n from '@solid-primitives/i18n';

import { ErrorWrapper, Equipment } from '../../../components';
import { useAppLocale } from '../../../context';

export const CampaignItems = (props) => {
  const campaign = () => props.campaign;

  const [, dict] = useAppLocale();
  const t = i18n.translator(dict);

  const itemFilter = (item) => item.kind === 'item';
  const weaponFilter = (item) => item.kind.includes('weapon');
  const armorFilter = (item) => item.kind.includes('armor') || item.kind.includes('shield');
  const ammoFilter = (item) => item.kind === 'ammo';
  const focusFilter = (item) => item.kind === 'focus';
  const toolsFilter = (item) => item.kind === 'tools';
  const musicFilter = (item) => item.kind === 'music';
  const potionFilter = (item) => item.kind === 'potion';

  return (
    <ErrorWrapper payload={{ campaign_id: campaign().id, key: 'CampaignItems' }}>
      <Switch>
        <Match when={campaign().provider === 'dnd5' || campaign().provider === 'dnd2024'}>
          <Equipment
            forCampaign
            withWeight
            withPrice
            character={campaign()}
            characters={props.characters}
            itemFilters={[
              { title: t('equipment.itemsList'), callback: itemFilter },
              { title: t('equipment.weaponsList'), callback: weaponFilter },
              { title: t('equipment.armorList'), callback: armorFilter },
              { title: t('equipment.consumables'), callback: potionFilter},
              { title: t('equipment.ammoList'), callback: ammoFilter },
              { title: t('equipment.focusList'), callback: focusFilter },
              { title: t('equipment.toolsList'), callback: toolsFilter },
              { title: t('equipment.musicList'), callback: musicFilter}
            ]}
            onReloadCharacter={() => console.log('Equipment refresh')}
          />
        </Match>
      </Switch>
    </ErrorWrapper>
  );
}
