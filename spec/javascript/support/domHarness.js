// DOM lane entry: import it for its side effect, before any dynamic import of a
// .jsx module. jsdom supplies the document and jsxHooks resolves solid-js to its
// client build, so `render` mounts real nodes and `createEffect` actually runs.
// That is the whole point of this lane: a branch that only evaluates after a
// fetch inside an effect is unreachable from the SSR harness (jsxLoader.js).
import { JSDOM } from 'jsdom';

import { registerJsxHooks } from './jsxHooks.js';

const jsdom = new JSDOM('<!doctype html><html><body></body></html>', { url: 'http://localhost/' });

// Node 21+ defines some of these (navigator) as accessors on globalThis, and a
// plain assignment from an ES module throws; define over them instead.
const define = (key, value) => Object.defineProperty(globalThis, key, { value, writable: true, configurable: true });

for (const key of ['window', 'document', 'navigator', 'Node', 'Element', 'HTMLElement', 'SVGElement', 'Event', 'CustomEvent']) {
  define(key, jsdom.window[key]);
}

// Gate-lane budget: deterministic, local, free. stubs.js intercepts the app's
// request layer, so a real fetch means a test wired something wrong -- fail loud
// rather than let a gate depend on the network.
const refuseFetch = (resource) => { throw new Error(`gate lane attempted a network fetch: ${resource}`); };
define('fetch', refuseFetch);
jsdom.window.fetch = refuseFetch;

registerJsxHooks({ dom: true });

// Dynamic: a static import would resolve before the hooks above are registered,
// and node would hand back solid's server build.
const { render } = await import('solid-js/web');

export const mount = (component) => {
  const container = document.createElement('div');
  document.body.appendChild(container);

  const dispose = render(component, container);

  return { container, dispose: () => { dispose(); container.remove(); } };
};

// One macrotask: long enough for the effect's fetch promises to settle and for
// solid to flush the updates they trigger.
export const tick = () => new Promise((resolve) => setTimeout(resolve, 0));
