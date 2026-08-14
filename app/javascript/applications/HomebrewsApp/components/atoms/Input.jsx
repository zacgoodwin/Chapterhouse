import { splitProps } from 'solid-js';

import { Label } from './Label';

const INPUT_STYLES = "w-full h-12 px-2 border border-gray-200 bg-white dark:bg-neutral-700 dark:border-gray-500 rounded";

export const Input = (props) => {
  const [labelProps] = splitProps(props, ['labelText', 'labelClassList']);

  const handleKeyDown = (event) => {
    if (!props.onKeyDown) return;
    if (event.key !== 'Enter') return;

    props.onKeyDown(event);
  }

  return (
    <div class={props.containerClassList}>
      <Label { ...labelProps } />
      <input
        type={props.numeric ? 'number' : 'text'}
        pattern={props.numeric ? '[0-9]*' : undefined}
        inputmode={props.numeric ? 'numeric' : undefined}
        class={INPUT_STYLES}
        placeholder={props.placeholder || ''}
        onInput={(e) => props.onInput(e.target.value)}
        onKeyDown={handleKeyDown}
        value={props.value}
      />
    </div>
  );
}
