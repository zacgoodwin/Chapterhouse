# frozen_string_literal: true

describe 'Health check' do
  describe 'GET /up' do
    it 'returns 200 without authentication' do
      get '/up'

      expect(response).to have_http_status :ok
    end
  end
end
