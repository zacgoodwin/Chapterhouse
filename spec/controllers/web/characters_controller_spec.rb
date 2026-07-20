# frozen_string_literal: true

describe Web::CharactersController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  describe 'GET#show' do
    context 'for logged users' do
      context 'for not existing character' do
        it 'returns error' do
          get :show, params: { id: 'unexisting', charkeeper_access_token: access_token, format: :pdf }

          expect(response).to have_http_status :not_found
        end
      end

      context 'for dnd5' do
        let!(:character) { create :character, user: user }

        before do
          character.update!(
            data: character.data.merge(
              health: { max: 10, current: 10, temp: 0 },
              hit_dice: { '6' => 0, '8' => 4, '10' => 0, '12' => 0 }
            )
          )
        end

        it 'returns data' do
          get :show, params: { id: character.id, charkeeper_access_token: access_token, format: :pdf }

          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
