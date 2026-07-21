# frozen_string_literal: true

describe Frontend::Tlc::CharactersController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }
  let(:create_params) {
    {
      character: {
        name: 'Leyfarer', species: 'human', size: 'medium', main_class: 'bard', alignment: 'neutral'
      }, charkeeper_access_token: access_token
    }
  }
  # PH p.38 27-point-buy cost table; TLC creates are point-buy only.
  let(:point_buy_cost) { { 8 => 0, 9 => 1, 10 => 2, 11 => 3, 12 => 4, 13 => 5, 14 => 7, 15 => 9 } }

  describe 'POST#create' do
    context 'for logged users' do
      # AC 1. 201 Created is the dnd2024 create contract the frontend already
      # speaks; the plan's "200" means "succeeds".
      it 'creates a level-3 tlc character with point-buy scores', :aggregate_failures do
        expect { post(:create, params: create_params) }.to change(user.characters, :count).by(1)

        expect(response).to have_http_status :created
        expect(response.parsed_body.dig('character', 'provider')).to eq 'tlc'
        expect(response.parsed_body.dig('character', 'level')).to eq 3

        character = Tlc::Character.find(response.parsed_body.dig('character', 'id'))
        spent = character.data.abilities.values.sum { |score| point_buy_cost.fetch(score.to_i) }
        expect(spent).to eq 27
      end

      # AC 4: the builder is a pure function of the payload, so a duplicate
      # submit lands the same state rather than an accumulated one.
      it 'applies the same payload identically twice', :aggregate_failures do
        post :create, params: create_params
        first = Tlc::Character.find(response.parsed_body.dig('character', 'id'))

        post :create, params: create_params
        second = Tlc::Character.find(response.parsed_body.dig('character', 'id'))

        expect(second.id).not_to eq first.id
        expect(second.data.as_json).to eq first.data.as_json
        expect(second.feats.count).to eq first.feats.count
      end

      context 'for invalid request' do
        it 'returns error', :aggregate_failures do
          expect {
            post :create, params: create_params.deep_merge(character: { species: '' })
          }.not_to change(Character, :count)

          expect(response).to have_http_status :unprocessable_content
          expect(response.parsed_body['errors']).not_to be_nil
        end
      end
    end
  end

  describe 'PATCH#update' do
    context 'for logged users' do
      let!(:character) { create :character, :tlc, user: user }

      it 'updates character', :aggregate_failures do
        patch :update, params: {
          id: character.id, character: { classes: { bard: 12 } }, charkeeper_access_token: access_token
        }

        expect(response).to have_http_status :ok
        expect(character.reload.data.classes).to eq({ 'bard' => 12 })
      end

      # AC 2: action_policy ownership scoping (plan security threat 4).
      context 'for another user tlc character' do
        let!(:another_character) { create :character, :tlc }

        it 'returns 404' do
          patch :update, params: {
            id: another_character.id, character: { classes: { bard: 12 } }, charkeeper_access_token: access_token
          }

          expect(response).to have_http_status :not_found
        end
      end

      # AC 3: Character.tlc is STRICT, so an owned dnd2024 character is invisible here.
      context 'for own dnd2024 character' do
        let!(:dnd2024_character) { create :character, :dnd2024, user: user }

        it 'returns 404' do
          patch :update, params: {
            id: dnd2024_character.id, character: { classes: { bard: 12 } }, charkeeper_access_token: access_token
          }

          expect(response).to have_http_status :not_found
        end
      end
    end
  end
end
