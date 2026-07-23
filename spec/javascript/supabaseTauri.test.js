// The Tauri path of helpers/supabase.jsx: no document (no Rails layout, no
// meta tags), so the supabaseConfig.js constants alone must configure and
// construct the client. Own file because the client singleton is per-process
// and the meta tests must never see non-empty constants.
import './support/jsxLoader.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { createClientCalls, stubSupabaseJs, clearDocument, CONFIG_STUB_URL } from './support/supabaseStub.js';

stubSupabaseJs((specifier) => (specifier === '../supabaseConfig' ? CONFIG_STUB_URL : null));
const { supabase, supabaseConfigured } = await import('../../app/javascript/applications/CharKeeperApp/helpers/supabase.jsx');

test('constants alone configure and construct the client (Tauri webview)', () => {
  clearDocument();

  assert.equal(supabaseConfigured(), true);
  supabase();
  assert.equal(createClientCalls.length, 1);
  assert.equal(createClientCalls[0].url, 'https://tauri.example.supabase.co');
  assert.equal(createClientCalls[0].key, 'tauri-anon-key');
});
