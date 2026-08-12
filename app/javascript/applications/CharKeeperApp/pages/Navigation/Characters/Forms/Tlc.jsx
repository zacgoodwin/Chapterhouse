import { Show, For } from 'solid-js';
import { createStore, reconcile } from 'solid-js/store';
import * as i18n from '@solid-primitives/i18n';

import { CharacterForm } from '../../../../pages';
import { Select, Input, Checkbox, Label, Button } from '../../../../components';
import { tlcConfig, tlcCreationSpecies } from '../../../../data/tlcConfig';
import { useAppLocale } from '../../../../context';
import { Minus, Plus } from '../../../../assets';
import { translate, localize, pointBuyFloor, pointBuyRemaining, canPointBuyChange } from '../../../../helpers';

// Cloned from Forms/Dnd2024.jsx. Deltas, all of them deliberate:
//   * species come from tlcCreationSpecies, never dnd2024.json -- the merged
//     tlcConfig.species is a superset that still carries the five dnd2024-only
//     slugs (tlcConfig.js), and creation must not offer them;
//   * no D&D Beyond import -- there is no ImportContext::Tlc and the tlc
//     `import` route is deliberately unrouted (frontend/tlc/characters_controller.rb);
//   * no homebrew toggle -- /frontend/homebrews only serves a `dnd2024` bucket
//     (HomebrewsContext::FindAvailableService), so there is nothing to layer yet;
//   * no level input -- TlcCharacter::BaseBuilder fixes level 3 server-side;
//   * point-buy abilities instead of dnd2024's class standard array, which is
//     what the intro paragraph promises (PH 2024 p.38, plan Phase A2). The
//     counter below only keeps the form honest; CharactersContext::Tlc::CreateCommand
//     re-prices the spread server-side.
// Optional-trait selection is Phase D (D2); until then traits come from the API.
//
// A function, not a constant: `abilities` is nested, so a spread of a shared
// object would hand every mount the same abilities object to mutate.
const blankTlcForm = () => ({
  name: '', species: undefined, legacy: undefined, size: undefined, background: undefined,
  main_class: undefined, alignment: 'neutral', skip_guide: false, abilities: pointBuyFloor()
});

export const TlcCharacterForm = (props) => {
  // Fresh object, never a shared one: createStore writes through the proxy into
  // the object it is handed.
  const [characterTlcForm, setCharacterTlcForm] = createStore(blankTlcForm());

  const [locale, dict] = useAppLocale();
  const t = i18n.translator(dict);

  // A TLC-only slug has no `legacies` key at all; a redefined dnd2024 slug keeps
  // the 2024 ones. Both have to render without throwing.
  const legacies = () => tlcCreationSpecies[characterTlcForm.species]?.legacies ?? {};

  const pointsRemaining = () => pointBuyRemaining(characterTlcForm.abilities);
  const canChangeAbility = (slug, step) => canPointBuyChange(characterTlcForm.abilities, slug, step);

  // Guarded here as well as on the button: a disabled Button is the UI telling the
  // player no, not the allocator enforcing the budget.
  const changeAbility = (slug, step) => {
    if (!canChangeAbility(slug, step)) return;

    setCharacterTlcForm('abilities', slug, characterTlcForm.abilities[slug] + step);
  }

  const saveCharacter = async () => {
    const result = await props.onCreateCharacter(characterTlcForm);

    if (result === null) setCharacterTlcForm(reconcile({ ...blankTlcForm(), skip_guide: true }));
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
        <div>
          <Label labelText={t('newCharacterPage.tlc.abilities')} />
          <p class="dark:text-snow text-sm mb-2">
            {t('newCharacterPage.tlc.pointsRemaining')} {pointsRemaining()}
          </p>
          <div class="grid grid-cols-3 emd:grid-cols-6 gap-x-2 gap-y-4">
            <For each={Object.entries(tlcConfig.abilities)}>
              {([slug, values]) =>
                <div>
                  <p class="ability-title dark:text-snow">{localize(values.name, locale())}</p>
                  <div class="ability-value-box">
                    <p class="text-2xl font-normal! dark:text-snow">{characterTlcForm.abilities[slug]}</p>
                  </div>
                  {/* Default size, not the sheet's `small`: DESIGN.md asks for 44px
                      increment controls and 40px is the largest the Button atom has.
                      ponytail: 40px ceiling, lift it in the atom when the creation
                      form is re-themed to the Stacked Accordion. */}
                  <div class="mt-2 flex justify-center gap-2">
                    <Button
                      default
                      disabled={!canChangeAbility(slug, -1)}
                      ariaLabel={`${t('newCharacterPage.tlc.decreaseAbility')} ${localize(values.name, locale())}`}
                      onClick={() => changeAbility(slug, -1)}
                    ><Minus /></Button>
                    <Button
                      default
                      disabled={!canChangeAbility(slug, 1)}
                      ariaLabel={`${t('newCharacterPage.tlc.increaseAbility')} ${localize(values.name, locale())}`}
                      onClick={() => changeAbility(slug, 1)}
                    ><Plus /></Button>
                  </div>
                </div>
              }
            </For>
          </div>
        </div>
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
