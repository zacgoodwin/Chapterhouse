# frozen_string_literal: true

describe HomebrewsV2::Tlc::SpeciesController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }
  let!(:own_element) { create :tlc_homebrews_species, user: user }
  let!(:element) { create :tlc_homebrews_species }

  describe 'GET#show' do
    context 'for unexisting homebrew' do
      let(:request) { get :show, params: { id: 'unexisting', charkeeper_access_token: access_token } }

      it 'returns error' do
        request

        expect(response).to have_http_status :not_found
      end
    end

    context 'for existing homebrew' do
      before { create :feat, :tlc, origin: 'species', origin_value: element.id, user: element.user }

      let(:request) { get :show, params: { id: element.id, charkeeper_access_token: access_token } }

      it 'returns data with its species traits', :aggregate_failures do
        request

        expect(response).to have_http_status :ok
        expect(response.parsed_body['homebrew'].keys).to contain_exactly('id', 'features', 'info')
        expect(response.parsed_body.dig('homebrew', 'features').size).to eq 1
      end
    end
  end

  describe 'DELETE#destroy' do
    context 'for unavailable homebrew' do
      let(:request) { delete :destroy, params: { id: element.id, charkeeper_access_token: access_token } }

      it 'returns error' do
        request

        expect(response).to have_http_status :not_found
      end
    end

    context 'for existing homebrew without using for character' do
      let(:request) { delete :destroy, params: { id: own_element.id, charkeeper_access_token: access_token } }

      it 'destroys homebrew', :aggregate_failures do
        expect { request }.to change(Homebrew, :count).by(-1)
        expect(response).to have_http_status :ok
      end
    end

    context 'for existing homebrew with using for character' do
      let(:request) { delete :destroy, params: { id: own_element.id, charkeeper_access_token: access_token } }

      before do
        character = create :character, :tlc, user: user
        character.data['species'] = own_element.id
        character.save!
      end

      it 'discards homebrew', :aggregate_failures do
        expect { request }.to change(Homebrew.kept, :count).by(-1)
        expect(response).to have_http_status :ok
      end
    end
  end
end
