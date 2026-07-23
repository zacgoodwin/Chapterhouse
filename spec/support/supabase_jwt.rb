# frozen_string_literal: true

# Local ES256 keypair for signing Supabase-shaped JWTs in specs. The public
# key is injected as a static JWK Set into config.x.supabase, so the token
# verifier never touches the network (its loader raises in test env if this
# stub is missing).
module SupabaseJwt
  KEY = OpenSSL::PKey::EC.generate('prime256v1')
  JWK = JWT::JWK.new(KEY, { alg: 'ES256', use: 'sig' })
  URL = 'https://test-project.supabase.local'

  def supabase_token_for(user, exp: 1.hour.from_now.to_i, aud: 'authenticated', iss: "#{URL}/auth/v1", sub: nil, key: KEY,
                         **claims)
    payload = {
      sub: sub || user.id,
      aud: aud,
      iss: iss,
      exp: exp,
      email: "#{user.username}@example.com",
      user_metadata: { name: user.username }
    }.merge(claims)

    JWT.encode(payload, key, 'ES256', kid: JWK.kid)
  end
end

Rails.application.config.x.supabase.url = SupabaseJwt::URL
# Non-empty so layout specs assert a real value flows into the meta tags
# (an empty anon_key makes those assertions pass vacuously).
Rails.application.config.x.supabase.anon_key = 'test-anon-key'
Rails.application.config.x.supabase.jwks = { keys: [SupabaseJwt::JWK.export] }

RSpec.configure do |config|
  config.include SupabaseJwt
end
