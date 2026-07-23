// Shared harness for testing helpers/supabase.jsx under plain node:
// supabase-js's CJS dist crashes at import (auth-js localStorage interop), so
// createClient is stubbed with a recorder; document is stubbed per-test.
// Import this module (and call stubSupabaseJs) BEFORE importing supabase.jsx.
// The client singleton and the supabaseConfig stub are per-process, which is
// why the supabase tests are split across three files.
import { registerHooks } from 'node:module';

export const createClientCalls = [];
globalThis.__createClientCalls = createClientCalls;

const SUPABASE_STUB = 'export const createClient = (url, key, opts) => { globalThis.__createClientCalls.push({ url, key, opts }); return { __stub: true }; };';

// Non-empty constants for the Tauri-fallback tests; pass as extraResolve.
export const CONFIG_STUB_URL = `data:text/javascript,${encodeURIComponent(
  'export const SUPABASE_URL = "https://tauri.example.supabase.co"; export const SUPABASE_ANON_KEY = "tauri-anon-key";'
)}`;

export const stubSupabaseJs = (extraResolve) => {
  registerHooks({
    resolve(specifier, context, nextResolve) {
      if (specifier === '@supabase/supabase-js') {
        return { url: `data:text/javascript,${encodeURIComponent(SUPABASE_STUB)}`, shortCircuit: true };
      }
      const redirected = extraResolve?.(specifier);
      if (redirected) return { url: redirected, shortCircuit: true };
      return nextResolve(specifier, context);
    }
  });
};

export const setMetas = (map) => {
  global.document = {
    querySelector: (selector) => {
      const name = selector.match(/meta\[name="(.+)"\]/)?.[1];
      return map[name] === undefined ? null : { content: map[name] };
    }
  };
};

export const clearDocument = () => { delete global.document; };
