# frozen_string_literal: true

# Supabase project settings. url + anon_key identify the project; the JWT
# verification service derives issuer and JWKS endpoint from url.
# jwks may hold a static JWK Set ({ keys: [...] }) to bypass network fetch —
# test support injects one so the suite never talks to Supabase.
supabase_credentials = Rails.application.credentials.dig(Rails.env.to_sym, :supabase) || {}

Rails.application.config.x.supabase.url = ENV['SUPABASE_URL'].presence || supabase_credentials[:url]
Rails.application.config.x.supabase.anon_key = supabase_credentials[:anon_key]
Rails.application.config.x.supabase.service_role_key = supabase_credentials[:service_role_key]
Rails.application.config.x.supabase.jwks = nil
