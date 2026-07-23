// Precedence contract of helpers/supabase.jsx: meta tags (Rails runtime) win
// over supabaseConfig.js constants even when both are set. Own file because
// the constants stub and the client singleton are per-process.
import './support/jsxLoader.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { createClientCalls, stubSupabaseJs, setMetas, CONFIG_STUB_URL } from './support/supabaseStub.js';

stubSupabaseJs((specifier) => (specifier === '../supabaseConfig' ? CONFIG_STUB_URL : null));
const { supabase, supabaseConfigured } = await import('../../app/javascript/applications/CharKeeperApp/helpers/supabase.jsx');

test('meta tags win over non-empty supabaseConfig constants', () => {
  setMetas({ 'supabase-url': 'https://meta.example.supabase.co', 'supabase-anon-key': 'meta-anon-key' });

  assert.equal(supabaseConfigured(), true);
  supabase();
  assert.equal(createClientCalls.length, 1);
  assert.equal(createClientCalls[0].url, 'https://meta.example.supabase.co');
  assert.equal(createClientCalls[0].key, 'meta-anon-key');
});
