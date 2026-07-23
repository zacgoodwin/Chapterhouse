// Supabase project identity for the SPA. The anon key is public by design
// (RLS/Data API are disabled server-side; the key only grants Auth flows).
// Normally these stay empty: the Rails layout injects the identity as meta
// tags at runtime (layouts/charkeeper_app.html.erb, read by helpers/
// supabase.jsx). Fill them only when building for a host without the Rails
// layout (Tauri webview), and never commit the filled values.
export const SUPABASE_URL = '';
export const SUPABASE_ANON_KEY = '';
