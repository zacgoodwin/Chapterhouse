# frozen_string_literal: true

describe HomebrewsV2::Tlc::SubclassesController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }
  let!(:own_element) { create :tlc_homebrews_subclass, user: user }
  let!(:element) { create :tlc_homebrews_subclass }

  describe 'GET#show' do
    context 'for existing homebrew' do
      let(:request) { get :show, params: { id: element.id, charkeeper_access_token: access_token } }

      it 'returns data', :aggregate_failures do
        request

        expect(response).to have_http_status :ok
        expect(response.parsed_body['homebrew'].keys).to contain_exactly('id', 'features', 'info')
      end
    end
  end

  describe 'DELETE#destroy' do
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
        character.data['subclasses'] = { 'rogue' => own_element.id }
        character.save!
      end

      it 'discards homebrew', :aggregate_failures do
        expect { request }.to change(Homebrew.kept, :count).by(-1)
        expect(response).to have_http_status :ok
      end
    end
  end
end
