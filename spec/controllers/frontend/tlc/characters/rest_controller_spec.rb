# frozen_string_literal: true

describe Frontend::Tlc::Characters::RestController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }
  let!(:user_character) { create :character, :tlc, user: user }
  # Rest semantics are still the inherited dnd2024 commands until C1.
  let(:service) { Charkeeper::Container.resolve('commands.characters_context.dnd2024.make_short_rest') }

  before { allow(service).to receive(:call) }

  describe 'POST#create' do
    context 'for logged users' do
      context 'for unexisting character' do
        it 'returns 404' do
          post :create, params: { character_id: 'unexisting', charkeeper_access_token: access_token }

          expect(response).to have_http_status :not_found
        end
      end

      # AC 2: another user's tlc character is not reachable.
      context 'for another user tlc character' do
        let!(:another_character) { create :character, :tlc }

        it 'returns 404' do
          post :create, params: {
            character_id: another_character.id, value: 'short_rest', charkeeper_access_token: access_token
          }

          expect(response).to have_http_status :not_found
        end
      end

      # AC 3: own dnd2024 character must not resolve on a tlc endpoint.
      context 'for own dnd2024 character' do
        let!(:dnd2024_character) { create :character, :dnd2024, user: user }

        it 'returns 404', :aggregate_failures do
          post :create, params: {
            character_id: dnd2024_character.id, value: 'short_rest', charkeeper_access_token: access_token
          }

          expect(response).to have_http_status :not_found
          expect(service).not_to have_received(:call)
        end
      end

      context 'for own tlc character' do
        it 'calls the rest command', :aggregate_failures do
          post :create, params: {
            character_id: user_character.id, value: 'short_rest', charkeeper_access_token: access_token
          }

          expect(service).to have_received(:call)
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
