import { createClient } from '@supabase/supabase-js';

import { SUPABASE_URL, SUPABASE_ANON_KEY } from '../supabaseConfig';

let client = null;

export const supabaseConfigured = () => Boolean(SUPABASE_URL && SUPABASE_ANON_KEY);

// singleton: session persists in localStorage (Tauri webview included),
// autoRefreshToken keeps the access token fresh in the background
export const supabase = () => {
  if (!supabaseConfigured()) return null;
  if (!client) {
    client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
  }
  return client;
}
