// Lets `node --test` import the SPA's .jsx modules: babel compiles them with the
// same preset esbuild.config.js uses, in SSR mode so no DOM is needed, and the
// barrels a component pulls (pages/components/context/helpers) are redirected to
// stubs.js -- the real ones drag in the whole app, including the gitignored
// supabaseConfig.js.
import { registerHooks } from 'node:module';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import { transformSync } from '@babel/core';
import solid from 'babel-preset-solid';

const STUBS = new URL('./stubs.js', import.meta.url).href;
const BARRELS = ['/pages', '/components', '/context', '/helpers'];

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (BARRELS.some((barrel) => specifier.endsWith(barrel))) return { url: STUBS, shortCircuit: true };

    // esbuild resolves extensionless imports; node does not.
    if (!specifier.startsWith('.')) return nextResolve(specifier, context);

    return ['', '.js', '.jsx'].reduce((found, extension) => {
      if (found) return found;
      try { return nextResolve(specifier + extension, context); } catch { return null; }
    }, null) ?? nextResolve(specifier, context);
  },
  load(url, context, nextLoad) {
    // registerHooks catches require() too: leave dependencies to node.
    if (url.includes('/node_modules/')) return nextLoad(url, context);

    // A .json import without the type attribute (appLocale.jsx's dictionaries)
    // is a bundler-ism node rejects. esbuild's json loader gives it a default
    // export plus one named export per top-level key; mirror that, or the
    // dictionary under test is not the one the app ships.
    if (url.endsWith('.json') && context.importAttributes?.type !== 'json') {
      const data = JSON.parse(readFileSync(fileURLToPath(url), 'utf8'));
      const named = Object.keys(data)
        .filter((key) => /^[A-Za-z_$][\w$]*$/.test(key))
        .map((key) => `export const ${key} = data[${JSON.stringify(key)}];`);

      return { format: 'module', shortCircuit: true, source: `const data = ${JSON.stringify(data)};\nexport default data;\n${named.join('\n')}` };
    }

    if (!url.endsWith('.jsx')) return nextLoad(url, context);

    const source = readFileSync(fileURLToPath(url), 'utf8');
    const { code } = transformSync(source, {
      presets: [[solid, { generate: 'ssr', hydratable: false }]],
      filename: fileURLToPath(url),
      babelrc: false,
      configFile: false
    });

    return { format: 'module', source: code, shortCircuit: true };
  }
});
