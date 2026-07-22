import { Show, For } from 'solid-js';
import * as i18n from '@solid-primitives/i18n';

import { Button } from '../../components';
import { useAppState, useAppLocale } from '../../context';
import { updateCharacterRequest } from '../../requests/updateCharacterRequest';

// Renders the active soft warnings the serializer computes (Tlc::Warnings ->
// character.warnings). Self-gates on the `warnings` key: dnd5/dnd2024 payloads
// carry none, so the banner is inert for them with no provider check -- which
// keeps A5a's `=== 'dnd2024'` sweep guard untouched.
export const WarningsBanner = (props) => {
  const [appState] = useAppState();
  const [, dict] = useAppLocale();

  const t = i18n.translator(dict);

  const warnings = () => props.character.warnings || [];

  // Append the slug to the stored list; the update contract binds only the
  // delta (#23), so the existing dismissals round-trip. Reload only on success,
  // the Dnd5.jsx updateCharacter idiom.
  const dismiss = async (slug) => {
    const result = await updateCharacterRequest(
      appState.accessToken,
      props.character.provider,
      props.character.id,
      { character: { dismissed_warnings: [...(props.character.dismissed_warnings || []), slug] } }
    );

    if (result.errors_list === undefined) await props.onReloadCharacter();
  };

  return (
    <Show when={warnings().length > 0}>
      <div class="blockable p-4 mb-2 dark:text-snow">
        <h2 class="text-lg mb-2">{t('warnings.title')}</h2>
        <For each={warnings()}>
          {(warning) => (
            <div class="flex items-center justify-between gap-x-4 py-1">
              <div class="flex-1">
                <p>{t(warning.message_key)}</p>
                <span class="text-xs opacity-70">{t(`warnings.source.${warning.source}`)}</span>
              </div>
              <Show when={warning.dismissible}>
                <Button default size="small" textable onClick={() => dismiss(warning.slug)}>
                  {t('warnings.dismiss')}
                </Button>
              </Show>
            </div>
          )}
        </For>
      </div>
    </Show>
  );
}
