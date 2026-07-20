# frozen_string_literal: true

describe Frontend::HomebrewsController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  describe 'GET#index' do
    context 'for logged users' do
      it 'returns data', :aggregate_failures do
        get :index, params: { charkeeper_access_token: access_token }

        expect(response).to have_http_status :ok
        expect(response.parsed_body.keys).to contain_exactly('dnd2024')
      end
    end
  end
end
