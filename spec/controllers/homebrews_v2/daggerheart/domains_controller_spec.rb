# frozen_string_literal: true

describe HomebrewsV2::Daggerheart::DomainsController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }
  let!(:own_element) { create :homebrew, :daggerheart_domain, user: user }
  let!(:element) { create :homebrew, :daggerheart_domain }

  describe 'GET#show' do
    context 'for logged users' do
      context 'for unexisting homebrew' do
        let(:request) { get :show, params: { id: 'unexisting', charkeeper_access_token: access_token } }

        it 'returns error' do
          request

          expect(response).to have_http_status :not_found
        end
      end

      context 'for existing homebrew' do
        let(:request) { get :show, params: { id: element.id, charkeeper_access_token: access_token } }

        it 'returns data', :aggregate_failures do
          request

          expect(response).to have_http_status :ok
          expect(response.parsed_body['homebrew'].keys).to contain_exactly('id', 'features')
        end
      end
    end
  end

  describe 'DELETE#destroy' do
    context 'for logged users' do
      context 'for unexisting homebrew' do
        let(:request) { delete :destroy, params: { id: 'unexisting', charkeeper_access_token: access_token } }

        it 'returns error' do
          request

          expect(response).to have_http_status :not_found
        end
      end

      context 'for unavailable homebrew' do
        let(:request) { delete :destroy, params: { id: element.id, charkeeper_access_token: access_token } }

        it 'returns error' do
          request

          expect(response).to have_http_status :not_found
        end
      end

      context 'for existing homebrew' do
        let(:request) { delete :destroy, params: { id: own_element.id, charkeeper_access_token: access_token } }

        it 'discards homebrew', :aggregate_failures do
          expect { request }.to change(Homebrew.kept, :count).by(-1)
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
