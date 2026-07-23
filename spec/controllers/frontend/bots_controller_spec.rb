# frozen_string_literal: true

describe Frontend::BotsController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  describe 'POST#create' do
    context 'for logged users' do
      let(:request) { post :create, params: { value: value, charkeeper_access_token: access_token } }

      context 'for invalid command' do
        let(:value) { '/rolld 20' }

        it 'returns errors messages', :aggregate_failures do
          request

          expect(response.parsed_body[:errors]).to eq(['Invalid command'])
          expect(response).to have_http_status :ok
        end
      end

      context 'for valid params' do
        let(:value) { '/roll d20' }

        it 'returns result', :aggregate_failures do
          request

          expect(response.parsed_body[:result].include?('Rolls: d20')).to be_truthy
          expect(response.parsed_body[:errors]).to be_nil
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
