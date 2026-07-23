import { Portal } from 'solid-js/web';
import { createSignal, createMemo, Show, Switch, Match, For, batch } from 'solid-js';
import { createStore, reconcile } from 'solid-js/store';

import { ErrorWrapper, Dice, Button } from '../../components';
import { useAppState, useAppLocale, useAppAlert } from '../../context';
import { clickOutside, modifier, localize } from '../../helpers';
import { Close } from '../../assets';
import { createCharacterBotRequest } from '../../requests/createCharacterBotRequest';

const TRANSLATION = {
  en: {
    advantage: 'Advantage',
    disadvantage: 'Disadvantage',
    roll: 'Roll',
    crit: 'Crit',
    critFailure: 'Crit fail',
    attack: 'Attack',
    damage: 'Damage'
  },
}
const SINGLE_ADVANTAGE_PROVIDERS = ['dnd'];
const D20_TESTS_PROVIDERS = ['dnd'];

export const createRoll = () => {
  // D20 check data
  const [d20Test, setD20Test] = createStore({});
  const [d20TestResult, setD20TestResult] = createSignal(undefined);

  // generic roll data
  const [dices, setDices] = createStore({});
  const [dicesResult, setDicesResult] = createSignal(undefined);

  const [appState] = useAppState();
  const [{ renderAlerts }] = useAppAlert();
  const [locale] = useAppLocale();

  return {
    openD20Test(command, title, bonus, maxAdv = 1) {
      batch(() => {
        setD20Test({ command: command, title: title, bonus: bonus, maxAdv: maxAdv, adv: 0, addBonus: 0 });
        setD20TestResult(undefined);
      });
    },
    openD20Attack(command, title, bonus, dices, damageBonus, maxAdv = 1) {
      batch(() => {
        setD20Test({ command: command, title: title, bonus: bonus, maxAdv: maxAdv, adv: 0, addBonus: 0 });
        setDices({ dices: dices, damageBonus: damageBonus, title: localize(TRANSLATION, locale()).damage, open: true });
        setD20TestResult(undefined);
        setDicesResult(undefined);
      });
    },
    openDices(dices, damageBonus) {
      batch(() => {
        setDices({ dices: dices, damageBonus: damageBonus, title: localize(TRANSLATION, locale()).damage, open: true });
        setDicesResult(undefined);
      });
    },
    Roll(props) {
      const open = createMemo(() => {
        return d20Test.command || dices.open;
      });

      const openRolls = () => {
        batch(() => {
          setDices({ dices: [], damageBonus: 0, open: true });
          setDicesResult(undefined);
        });
      }

      const openD20Test = () => {
        batch(() => {
          setD20Test({ command: '/check attr empty', title: null, bonus: 0, maxAdv: 10, adv: 0, addBonus: 0 });
          setD20TestResult(undefined);
        });
      }

      const closeD20Test = () => {
        batch(() => {
          setD20Test(reconcile({}));
          setD20TestResult(undefined);
        });
      }

      const close = () => {
        if (!open()) return;

        batch(() => {
          setD20Test(reconcile({}));
          setD20TestResult(undefined);
          setDices(reconcile({}));
          setDicesResult(undefined);
        });
      }

      const performRoll = async () => {
        const rolls = [];
        if (d20Test.command) rolls.push(generateD20Test());
        if (dices.dices) rolls.push(generateDiceRoll());

        const result = await createCharacterBotRequest(appState.accessToken, props.characterId, { values: rolls });
        if (result.errors_list === undefined) {
          let resultsIndex = 0;
          batch(() => {
            if (d20Test.command) {
              setD20TestResult(result.result[resultsIndex].result);
              resultsIndex += 1;
            }
            if (dices.dices) {
              setDicesResult(result.result[resultsIndex].result);
              resultsIndex += 1;
            }
          });
        } else renderAlerts(result.errors_list);
      }

      const generateD20Test = () => {
        const options = [];
        if (d20Test.adv > 0) options.push(`--adv ${d20Test.adv}`);
        if (d20Test.adv < 0) options.push(`--dis ${Math.abs(d20Test.adv)}`);
        if (d20Test.bonus + d20Test.addBonus > 0) options.push(`--bonus ${d20Test.bonus + d20Test.addBonus}`);
        if (d20Test.bonus + d20Test.addBonus < 0) options.push(`--penalty ${Math.abs(d20Test.bonus + d20Test.addBonus)}`);

        return options.length > 0 ? `${d20Test.command} ${options.join(' ')}` : d20Test.command;
      }

      const generateDiceRoll = () => {
        let value = `/roll ${dices.dices.join(' ').toLowerCase()}`;
        if (dices.damageBonus !== 0) value += ` ${dices.damageBonus}`;

        return value;
      }

      const updateAdvantage = (advantageModifier) => {
        if (SINGLE_ADVANTAGE_PROVIDERS.includes(props.provider)) {
          if (d20Test.adv + advantageModifier > 1) advantageModifier = -1;
          if (d20Test.adv + advantageModifier < -1) advantageModifier = 1;

          batch(() => {
            setD20Test({ ...d20Test, adv: d20Test.adv + advantageModifier });
            setD20TestResult(undefined);
          });
        }
      }

      const rerollD20Test = async (index) => {
        const result = await createCharacterBotRequest(appState.accessToken, props.characterId, { values: ['/roll d20'] });

        const newRollResults = [...d20TestResult().rolls.slice(0, index), result.result[0].result.rolls[0], ...d20TestResult().rolls.slice(index + 1)];

        let total = d20Test.bonus + d20Test.addBonus;
        let status = null;
        let finalRoll = 0;

        if (d20Test.adv > 0) {
          const maxRoll = Math.max(...newRollResults.map((item) => item[1]));
          finalRoll = maxRoll;
          total += maxRoll;
          if (maxRoll === 20) status = 'crit_success';
          if (maxRoll === 1) status = 'crit_failure';
        } else if (d20Test.adv < 0) {
          const minRoll = Math.min(...newRollResults.map((item) => item[1]));
          finalRoll = minRoll;
          total += minRoll;
          if (minRoll === 1) status = 'crit_failure';
          if (minRoll === 20) status = 'crit_success';
        } else {
          total += newRollResults[0][1];
          finalRoll = newRollResults[0][1];
          if (newRollResults[0][1] === 1) status = 'crit_failure';
          if (newRollResults[0][1] === 20) status = 'crit_success';
        }

        setD20TestResult({ ...d20TestResult(), rolls: newRollResults, total: total, status: status, final_roll: finalRoll });
      }

      const addDice = (dice) => setDices({ ...dices, dices: [...dices.dices, dice] });

      const setSimpleBonus = (modifier) => {
        batch(() => {
          setDices({ ...dices, damageBonus: dices.damageBonus + modifier });
          if (dicesResult()) setDicesResult({ ...dicesResult(), total: dicesResult().total + modifier });
        });
      }

      const removeDice = (index) => {
        batch(() => {
          const newDices = [...dices.dices.slice(0, index), ...dices.dices.slice(index + 1)];
          setDices({ ...dices, dices: newDices });

          if (dicesResult() === undefined) {
            setDicesResult(undefined);
          } else {
            const newRollResults = [...dicesResult().rolls.slice(0, index), ...dicesResult().rolls.slice(index + 1)];
            const total = newRollResults.reduce((acc, item) => acc + item[1], 0);
            setDicesResult({ ...dicesResult(), rolls: newRollResults, total: total });
          }
        });
      }

      const refreshDice = async (index) => {
        if (dicesResult()) {
          const dice = dicesResult().rolls[index][0]

          const result = await createCharacterBotRequest(appState.accessToken, props.characterId, { values: [`/roll ${dice}`] });
          if (result.errors_list === undefined) {
            const newDamageResults = [...dicesResult().rolls.slice(0, index), result.result[0].result.rolls[0], ...dicesResult().rolls.slice(index + 1)];

            const total = newDamageResults.reduce((acc, item) => acc + item[1], 0);
            setDicesResult({ ...dicesResult(), rolls: newDamageResults, total: total });
          } else renderAlerts(result.errors_list);
        } else {
          removeDice(index);
        }
      }

      return (
        <Portal>
          <ErrorWrapper payload={{ provider: props.provider, key: 'Roll' }}>
            <div
              class="dice-portal"
              classList={{ 'dark': appState.colorSchema === 'dark', 'w-full sm:w-auto': open() }}
              use:clickOutside={() => close()}
            >
              <div class="dice-tests-box">
                <div class="flex flex-col gap-2 flex-1">
                  {/* D20 check block - D&D */}
                  <Show when={d20Test.command}>
                    <div class="blockable dice-test">
                      <Show when={d20Test.title}><p>{d20Test.title}</p></Show>
                      <div class="dice-list">
                        <Show
                          when={d20TestResult() === undefined}
                          fallback={
                            <Dice
                              text={d20TestResult().rolls[0][1]}
                              minimum={d20TestResult().rolls[0][1] !== d20TestResult().final_roll}
                              onClick={() => rerollD20Test(0)}
                            />
                          }
                        >
                          <Dice text="D20" />
                        </Show>
                        <Show when={d20Test.adv !== 0}>
                          <For each={Array.from([...Array(Math.abs(d20Test.adv)).keys()], (x) => x + 1)}>
                            {(index) =>
                              <Show
                                when={d20TestResult() === undefined}
                                fallback={
                                  <Dice
                                    text={d20TestResult().rolls[index][1]}
                                    minimum={d20TestResult().rolls[index][1] !== d20TestResult().final_roll}
                                    onClick={() => rerollD20Test(index)}
                                  />
                                }
                              >
                                <Dice text={d20Test.adv > 0 ? 'Adv' : 'Dis'} />
                              </Show>
                            }
                          </For>
                        </Show>
                        <Show when={d20Test.bonus + d20Test.addBonus !== 0}>
                          <p class="text-xl ml-2 dark:text-snow">{modifier(d20Test.bonus + d20Test.addBonus)}</p>
                        </Show>
                        <Show when={d20TestResult() !== undefined}>
                          <div class="roll-results">
                            <p class="font-medium! text-xl">{d20TestResult().total}</p>
                            <span class={`roll-result ${d20TestResult().status}`}>
                              <Switch>
                                <Match when={d20TestResult().status === 'crit_success'}>{localize(TRANSLATION, locale()).crit}</Match>
                                <Match when={d20TestResult().status === 'crit_failure'}>{localize(TRANSLATION, locale()).critFailure}</Match>
                              </Switch>
                            </span>
                          </div>
                        </Show>
                      </div>
                      <div class="flex gap-x-4">
                        <div class="flex-1">
                          <p
                            class="mb-1 dice-button"
                            onClick={() => d20Test.adv >= d20Test.maxAdv ? null : updateAdvantage(1)}
                          >{localize(TRANSLATION, locale()).advantage}</p>
                          <p
                            class="dice-button"
                            onClick={() => d20Test.adv <= -d20Test.maxAdv ? null : updateAdvantage(-1)}
                          >{localize(TRANSLATION, locale()).disadvantage}</p>
                        </div>
                        <div class="flex-1">
                          <p class="total-advantage">{d20Test.addBonus}</p>
                          <div class="flex gap-x-2">
                            <p class="dice-button flex-1" onClick={() => setD20Test({ ...d20Test, addBonus: d20Test.addBonus - 1 })}>-</p>
                            <p class="dice-button flex-1" onClick={() => setD20Test({ ...d20Test, addBonus: d20Test.addBonus + 1 })}>+</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </Show>
                  {/* generic dice roll block */}
                  <Show when={dices.open}>
                    <div class="blockable dice-test">
                      <Show when={dices.title}>
                        <p>
                          {dices.title}
                          <Show when={d20Test.title}>
                            , {d20Test.title}
                          </Show>
                        </p>
                      </Show>
                      <div class="dice-list">
                        <For each={dices.dices}>
                          {(dice, index) =>
                            <Dice
                              type={dice}
                              onClick={() => refreshDice(index())}
                              text={dicesResult() ? (dicesResult().rolls.length - 1 >= index() && dicesResult().rolls[index()][0].includes('d') ? dicesResult().rolls[index()][1] : dice) : dice}
                            />
                          }
                        </For>
                        <Show when={dices.damageBonus !== 0}><p class="text-xl ml-2">{modifier(dices.damageBonus)}</p></Show>
                        <Show when={dicesResult() !== undefined}>
                          <div class="roll-results">
                            <p class="font-medium! text-xl">{dicesResult().total}</p>
                          </div>
                        </Show>
                      </div>
                      <div class="flex gap-x-2">
                        <p class="dice-button flex-1" onClick={() => setSimpleBonus(-1)}>-</p>
                        <p class="dice-button flex-1" onClick={() => setSimpleBonus(1)}>+</p>
                      </div>
                    </div>
                  </Show>
                  {/* roll button */}
                  <Show when={open()}>
                    <Button withSuspense default textable classList="flex-1" onClick={performRoll}>
                      {localize(TRANSLATION, locale()).roll}
                    </Button>
                  </Show>
                  <div class="dice-opens">
                    <Show when={D20_TESTS_PROVIDERS.includes(props.provider)}>
                      <div class="blockable dice-opens-list" classList={{ 'w-auto': open() }}>
                        <Dice
                          onClick={() => d20Test.command ? closeD20Test() : openD20Test()}
                          text={d20Test.command ? <Close /> : 'D20'}
                        />
                      </div>
                    </Show>
                  </div>
                </div>
                {/* dice selection */}
                <Show when={!open() || dices.open}>
                  <div class="blockable ml-2 p-2 flex flex-col gap-2" classList={{ 'w-auto': open() }}>
                    <Show when={open()}>
                      <For each={['D4', 'D6', 'D8', 'D10', 'D12', 'D20', 'D100']}>
                        {(item) =>
                          <Dice type={item === 'D100' ? 'D20' : item} onClick={() => addDice(item)} text={item} />
                        }
                      </For>
                    </Show>
                    <Dice
                      onClick={() => open() ? close() : openRolls()}
                      text={open() ? <Close /> : 'Dx'}
                    />
                  </div>
                </Show>
              </div>
            </div>
          </ErrorWrapper>
        </Portal>
      );
    }
  }
}
