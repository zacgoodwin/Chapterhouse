import { createSignal, For, onMount, onCleanup } from 'solid-js';

import { ErrorWrapper } from '../../../components';
import { supabase } from '../../../helpers';

export const CampaignRolls = (props) => {
  const campaign = () => props.campaign;

  const [history, setHistory] = createSignal([]);

  let channel;

  onMount(() => {
    const client = supabase();
    if (!client) return;

    channel = client
      .channel(`campaign:${campaign().id}`)
      .on('broadcast', { event: 'message' }, ({ payload }) => {
        if (payload.message) setHistory(history().concat([payload.message.replace(/\n/g, '<br>')]));
      })
      .subscribe();
  });

  onCleanup(() => {
    if (channel) supabase()?.removeChannel(channel);
  });

  return (
    <ErrorWrapper payload={{ campaign_id: campaign().id, key: 'CampaignRolls' }}>
      <div class="flex-1 flex flex-col-reverse overflow-y-auto gap-2">
        <For each={history()}>
          {(item) =>
            <p
              class="py-1 dark:text-snow"
              innerHTML={item} // eslint-disable-line solid/no-innerhtml
            />
          }
        </For>
      </div>
    </ErrorWrapper>
  );
}
