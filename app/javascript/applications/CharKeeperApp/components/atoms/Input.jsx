import { splitProps } from 'solid-js';

import { Label } from './Label';

export const Input = (props) => {
  const [labelProps] = splitProps(props, ['labelText', 'labelClassList']);

  const handleKeyDown = (event) => {
    if (!props.onKeyDown) return;
    if (event.key !== 'Enter') return;

    props.onKeyDown(event);
  }

  const type = () => {
    if (props.numeric) return 'number';
    if (props.password) return 'password';

    return 'text';
  }

  return (
    <div class={props.containerClassList}>
      <Label { ...labelProps } />
      <input
        type={type()}
        pattern={props.numeric ? '[0-9]*' : undefined}
        inputmode={props.numeric ? 'numeric' : undefined}
        class="default-input"
        classList={{
          'h-8! text-sm': props.size === 'small'
        }}
        placeholder={props.placeholder || ''}
        onInput={(e) => props.onInput(e.target.value)}
        onKeyDown={handleKeyDown}
        value={props.value}
        dataTestId={props.dataTestId}
      />
    </div>
  );
}
