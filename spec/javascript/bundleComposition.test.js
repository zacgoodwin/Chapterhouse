// Gate test for issue #93 (solid-js 1.9.14 bump, seroval GHSA-mv8w-475r-vwqw).
// seroval's vulnerable fromJSON() deserializer only runs on SSR hydration
// paths this SPA never uses (render + Portal only, no hydrate/renderToString).
// esbuild tree-shakes it out today; this test pins that fact so a future
// solid-js/SSR-adjacent dependency bump can't silently ship it to the client.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';

const root = path.join(import.meta.dirname, '..', '..');
const bundlePath = path.join(root, 'app/assets/builds/application.js');
const mapPath = path.join(root, 'app/assets/builds/application.js.map');

test('bundle: seroval never ships in the client bundle or its sourcemap', () => {
  execFileSync(process.execPath, ['esbuild.config.js'], { cwd: root });

  const bundle = readFileSync(bundlePath, 'utf8');
  assert.equal(bundle.includes('seroval'), false, 'seroval leaked into application.js — an SSR/hydration path entered the client bundle');
  assert.equal(bundle.includes('fromJSON'), false, 'fromJSON leaked into application.js — seroval\'s vulnerable deserializer entered the client bundle');

  const map = JSON.parse(readFileSync(mapPath, 'utf8'));
  const serovalSources = map.sources.filter((s) => s.includes('seroval'));
  assert.deepEqual(serovalSources, [], 'seroval source files leaked into the sourcemap');
});
