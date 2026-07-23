// The SPA's Supabase identity arrives as meta tags rendered by
// layouts/charkeeper_app.html.erb; helpers/supabase.jsx reads them at call
// time. The committed supabaseConfig.js constants are empty strings, so this
// meta path is the only thing that makes browser login possible — a
// regression here bricks LoginPage silently.
// Test order matters: the module-level client singleton is claimed by the
// first configured supabase() call, so the unconfigured tests run first and
// assert the recorder is untouched as a precondition.
import './support/jsxLoader.js';
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { createClientCalls, stubSupabaseJs, setMetas, clearDocument } from './support/supabaseStub.js';

stubSupabaseJs();
const { supabase, supabaseConfigured } = await import('../../app/javascript/applications/CharKeeperApp/helpers/supabase.jsx');

test('no document and empty constants: unconfigured, supabase() null', () => {
  clearDocument();

  assert.equal(createClientCalls.length, 0);
  assert.equal(supabaseConfigured(), false);
  assert.equal(supabase(), null);
  assert.equal(createClientCalls.length, 0);
});

test('blank meta content (unset credentials render empty attrs): unconfigured', () => {
  setMetas({ 'supabase-url': '', 'supabase-anon-key': '' });

  assert.equal(createClientCalls.length, 0);
  assert.equal(supabaseConfigured(), false);
  assert.equal(supabase(), null);
});

test('meta tags present: configured, createClient gets the meta identity once', () => {
  setMetas({ 'supabase-url': 'https://meta.example.supabase.co', 'supabase-anon-key': 'meta-anon-key' });

  assert.equal(supabaseConfigured(), true);
  const client = supabase();
  assert.deepEqual(client, { __stub: true });
  assert.equal(createClientCalls.length, 1);
  const call = createClientCalls[0];
  assert.equal(call.url, 'https://meta.example.supabase.co');
  assert.equal(call.key, 'meta-anon-key');
  assert.deepEqual(call.opts.auth, { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true });

  // singleton: a second call reuses the client
  assert.equal(supabase(), client);
  assert.equal(createClientCalls.length, 1);
});
