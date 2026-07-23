import { createClient } from '@supabase/supabase-js';

import { SUPABASE_URL, SUPABASE_ANON_KEY } from '../supabaseConfig';

let client = null;

// Rails injects the project identity as meta tags (layouts/charkeeper_app),
// so one image serves any environment. supabaseConfig.js is the fallback for
// hosts without the Rails layout (Tauri webview).
const metaContent = (name) =>
  (typeof document !== 'undefined' && document.querySelector(`meta[name="${name}"]`)?.content) || '';
const supabaseUrl = () => metaContent('supabase-url') || SUPABASE_URL;
const supabaseAnonKey = () => metaContent('supabase-anon-key') || SUPABASE_ANON_KEY;

export const supabaseConfigured = () => Boolean(supabaseUrl() && supabaseAnonKey());

// singleton: session persists in localStorage (Tauri webview included),
// autoRefreshToken keeps the access token fresh in the background
export const supabase = () => {
  if (!supabaseConfigured()) return null;
  if (!client) {
    client = createClient(supabaseUrl(), supabaseAnonKey(), {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
  }
  return client;
}
