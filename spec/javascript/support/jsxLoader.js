// SSR lane entry: import it for its side effect, before any dynamic import of a
// .jsx module. Renders through `renderToString`, no DOM, and effects never run --
// use domHarness.js when a test needs either. Implementation in jsxHooks.js.
import { registerJsxHooks } from './jsxHooks.js';

registerJsxHooks();
