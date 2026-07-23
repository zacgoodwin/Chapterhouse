# frozen_string_literal: true

# Supabase project settings. url + anon_key identify the project; the JWT
# verification service derives issuer and JWKS endpoint from url.
# jwks may hold a static JWK Set ({ keys: [...] }) to bypass network fetch —
# test support injects one so the suite never talks to Supabase.
supabase_credentials = Rails.application.credentials.dig(Charkeeper.credentials_env, :supabase) || {}

# No ENV override: url, anon_key, and service_role_key must come from the
# same credentials section or the SPA gets project A's URL with project B's
# key (split-brain login failure).
Rails.application.config.x.supabase.url = supabase_credentials[:url]
Rails.application.config.x.supabase.anon_key = supabase_credentials[:anon_key]
Rails.application.config.x.supabase.service_role_key = supabase_credentials[:service_role_key]
Rails.application.config.x.supabase.jwks = nil
