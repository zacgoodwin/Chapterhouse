# frozen_string_literal: true

module AuthContext
  class VerifySupabaseTokenService
    include Deps[monitoring: 'monitoring.client']

    JWKS_CACHE_KEY = 'supabase_jwks_v1'
    JWKS_CACHE_TTL = 12.hours
    ALGORITHMS = %w[ES256 RS256].freeze
    AUDIENCE = 'authenticated'

    def call(token:)
      payload, _header = JWT.decode(
        token, nil, true,
        algorithms: ALGORITHMS,
        jwks: jwks_loader,
        verify_iss: true, iss: issuer,
        verify_aud: true, aud: AUDIENCE
      )
      { result: payload }
    rescue JWT::DecodeError => e
      { errors: [e.message] }
    rescue StandardError => e
      # JWKS fetch failures must produce 401, never 500
      monitoring.notify(exception: e, metadata: { source: :supabase_jwks }, severity: :error)
      { errors: [e.message] }
    end

    private

    def config = Rails.application.config.x.supabase

    def issuer = "#{config.url}/auth/v1"

    # jwt gem contract: called with kid_not_found/invalidate when the token's
    # kid is absent from the returned set; must then return a fresh set
    def jwks_loader
      lambda do |options|
        return config.jwks if config.jwks.present?

        raise 'Supabase JWKS is not stubbed in test environment' if Rails.env.test?

        Rails.cache.delete(JWKS_CACHE_KEY) if options[:kid_not_found] || options[:invalidate]
        Rails.cache.fetch(JWKS_CACHE_KEY, expires_in: JWKS_CACHE_TTL) { fetch_jwks }
      end
    end

    def fetch_jwks
      response = Faraday.get("#{issuer}/.well-known/jwks.json")
      raise "Supabase JWKS endpoint returned #{response.status}" unless response.success?

      JSON.parse(response.body, symbolize_names: true)
    end
  end
end
