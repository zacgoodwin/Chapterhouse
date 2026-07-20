# frozen_string_literal: true

describe AuthContext::VerifySupabaseTokenService do
  subject(:service_call) { described_class.new.call(token: token) }

  let(:user) { create :user }

  context 'with valid token' do
    let(:token) { supabase_token_for(user) }

    it 'returns the payload', :aggregate_failures do
      expect(service_call[:errors]).to be_nil
      expect(service_call[:result]['sub']).to eq user.id
      expect(service_call[:result]['aud']).to eq 'authenticated'
    end
  end

  context 'with expired token' do
    let(:token) { supabase_token_for(user, exp: 1.minute.ago.to_i) }

    it 'returns errors' do
      expect(service_call[:errors]).to be_present
    end
  end

  context 'with wrong audience' do
    let(:token) { supabase_token_for(user, aud: 'anon') }

    it 'returns errors' do
      expect(service_call[:errors]).to be_present
    end
  end

  context 'with wrong issuer' do
    let(:token) { supabase_token_for(user, iss: 'https://other.example.com/auth/v1') }

    it 'returns errors' do
      expect(service_call[:errors]).to be_present
    end
  end

  context 'with garbage token' do
    let(:token) { 'garbage' }

    it 'returns errors' do
      expect(service_call[:errors]).to be_present
    end
  end

  context 'without a static JWK Set in test env' do
    let(:token) { supabase_token_for(user) }

    around do |example|
      original = Rails.application.config.x.supabase.jwks
      Rails.application.config.x.supabase.jwks = nil
      example.run
    ensure
      Rails.application.config.x.supabase.jwks = original
    end

    it 'refuses to fetch over the network and returns errors' do
      expect(service_call[:errors].join).to include('not stubbed')
    end
  end
end
