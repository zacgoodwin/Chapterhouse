import { Show } from 'solid-js';
import { createStore, reconcile } from 'solid-js/store';
import * as i18n from '@solid-primitives/i18n';

import { CharacterForm } from '../../../../pages';
import { Select, Input, Checkbox } from '../../../../components';
import { tlcConfig, tlcCreationSpecies } from '../../../../data/tlcConfig';
import { useAppLocale } from '../../../../context';
import { translate } from '../../../../helpers';

// Cloned from Forms/Dnd2024.jsx. Deltas, all of them deliberate:
//   * species come from tlcCreationSpecies, never dnd2024.json -- the merged
//     tlcConfig.species is a superset that still carries the five dnd2024-only
//     slugs (tlcConfig.js), and creation must not offer them;
//   * no D&D Beyond import -- there is no ImportContext::Tlc and the tlc
//     `import` route is deliberately unrouted (frontend/tlc/characters_controller.rb);
//   * no homebrew toggle -- /frontend/homebrews only serves a `dnd2024` bucket
//     (HomebrewsContext::FindAvailableService), so there is nothing to layer yet;
//   * no level or ability inputs -- TlcCharacter::BaseBuilder fixes level 3 and
//     point-buy scores server-side. The note tells the player that.
// Optional-trait selection is Phase D (D2); until then traits come from the API.
const TLC_DEFAULT_FORM = {
  name: '', species: undefined, legacy: undefined, size: undefined, background: undefined,
  main_class: undefined, alignment: 'neutral', skip_guide: false
};

export const TlcCharacterForm = (props) => {
  // Copy, never the constant itself: createStore writes through the proxy into the
  // object it is handed, so passing TLC_DEFAULT_FORM would let every keystroke edit
  // the module constant -- and the reset below spreads that same constant.
  const [characterTlcForm, setCharacterTlcForm] = createStore({ ...TLC_DEFAULT_FORM });

  const [locale, dict] = useAppLocale();
  const t = i18n.translator(dict);

  // A TLC-only slug has no `legacies` key at all; a redefined dnd2024 slug keeps
  // the 2024 ones. Both have to render without throwing.
  const legacies = () => tlcCreationSpecies[characterTlcForm.species]?.legacies ?? {};

  const saveCharacter = async () => {
    const result = await props.onCreateCharacter(characterTlcForm);

    if (result === null) setCharacterTlcForm(reconcile({ ...TLC_DEFAULT_FORM, skip_guide: true }));
  }

  return (
    <CharacterForm setCurrentTab={props.setCurrentTab} onSaveCharacter={saveCharacter}>
      <div class="flex flex-col gap-2">
        <p class="dark:text-snow text-sm">{t('newCharacterPage.tlc.start')}</p>
        <Input
          labelText={t('newCharacterPage.name')}
          value={characterTlcForm.name}
          onInput={(value) => setCharacterTlcForm({ ...characterTlcForm, name: value })}
        />
        <Select
          labelText={t('newCharacterPage.dnd2024.species')}
          items={translate(tlcCreationSpecies, locale())}
          selectedValue={characterTlcForm.species}
          onSelect={(value) => setCharacterTlcForm({ ...characterTlcForm, species: value, size: tlcCreationSpecies[value].sizes[0], legacy: undefined })}
        />
        <Show when={characterTlcForm.species !== undefined}>
          <Show when={Object.keys(legacies()).length > 0}>
            <Select
              labelText={t('newCharacterPage.dnd2024.legacy')}
              items={translate(legacies(), locale())}
              selectedValue={characterTlcForm.legacy}
              onSelect={(value) => setCharacterTlcForm({ ...characterTlcForm, legacy: value })}
            />
          </Show>
          <Select
            labelText={t('newCharacterPage.dnd2024.size')}
            items={tlcCreationSpecies[characterTlcForm.species].sizes.reduce((acc, item) => { acc[item] = t(`newCharacterPage.dnd2024.sizes.${item}`); return acc; }, {})}
            selectedValue={characterTlcForm.size}
            onSelect={(value) => setCharacterTlcForm({ ...characterTlcForm, size: value })}
          />
        </Show>
        <Select
          labelText={t('newCharacterPage.dnd2024.background')}
          items={translate(tlcConfig.backgrounds, locale())}
          selectedValue={characterTlcForm.background}
          onSelect={(value) => setCharacterTlcForm({ ...characterTlcForm, background: value })}
        />
        <Select
          labelText={t('newCharacterPage.dnd2024.mainClass')}
          items={translate(tlcConfig.classes, locale())}
          selectedValue={characterTlcForm.main_class}
          onSelect={(value) => setCharacterTlcForm({ ...characterTlcForm, main_class: value })}
        />
        <Select
          labelText={t('newCharacterPage.dnd2024.alignment')}
          items={translate(tlcConfig.alignments, locale())}
          selectedValue={characterTlcForm.alignment}
          onSelect={(value) => setCharacterTlcForm({ ...characterTlcForm, alignment: value })}
        />
        <Checkbox
          labelText={t('newCharacterPage.tlc.skipGuide')}
          labelPosition="right"
          labelClassList="ml-2"
          checked={characterTlcForm.skip_guide}
          onToggle={() => setCharacterTlcForm({ ...characterTlcForm, skip_guide: !characterTlcForm.skip_guide })}
        />
      </div>
    </CharacterForm>
  );
}
