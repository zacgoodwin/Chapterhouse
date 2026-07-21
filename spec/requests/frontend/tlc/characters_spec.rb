# frozen_string_literal: true

# Request specs, NOT controller specs, on purpose: config/application.rb ends the
# route set with `match '*path', to: 'application#not_found'`, so an unrouted TLC
# path returns 404 -- the exact status AC2/AC3 assert as success. Controller specs
# bypass the router and would pass with every TLC route missing.
#
# Nothing here stubs a command: the rest examples exist because the dnd2024 rest
# contracts (`type?: ::Dnd2024::Character`) reject Tlc::Character, and a stubbed
# service hides that as a 200.
describe 'Frontend::Tlc::Characters' do
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

  describe 'POST /frontend/tlc/characters' do
    # AC1. 201 Created is the dnd2024 create contract the frontend already
    # speaks; the plan's "200" means "succeeds".
    it 'creates a level-3 tlc character with point-buy scores', :aggregate_failures do
      expect { post('/frontend/tlc/characters', params: create_params) }.to change(user.characters, :count).by(1)

      expect(response).to have_http_status :created
      expect(response.parsed_body.dig('character', 'provider')).to eq 'tlc'
      expect(response.parsed_body.dig('character', 'level')).to eq 3

      character = Tlc::Character.find(response.parsed_body.dig('character', 'id'))
      spent = character.data.abilities.values.sum { |score| point_buy_cost.fetch(score.to_i) }
      expect(spent).to eq 27
    end

    # AC4: the builder is a pure function of the payload, so a duplicate submit
    # lands the same state rather than an accumulated one. There is no
    # server-side dedupe (plan L717) -- two rows, byte-identical data.
    it 'applies the same payload identically twice', :aggregate_failures do
      post '/frontend/tlc/characters', params: create_params
      first = Tlc::Character.find(response.parsed_body.dig('character', 'id'))

      post '/frontend/tlc/characters', params: create_params
      second = Tlc::Character.find(response.parsed_body.dig('character', 'id'))

      expect(second.id).not_to eq first.id
      expect(second.data.as_json).to eq first.data.as_json
      expect(second.feats.count).to eq first.feats.count
      expect(first.reload.data.as_json).to eq second.data.as_json
    end

    it 'returns errors for an invalid payload', :aggregate_failures do
      expect {
        post '/frontend/tlc/characters', params: create_params.deep_merge(character: { species: '' })
      }.not_to change(Character, :count)

      expect(response).to have_http_status :unprocessable_content
      expect(response.parsed_body['errors']).not_to be_nil
    end
  end

  describe 'PATCH /frontend/tlc/characters/:id' do
    let!(:character) { create :character, :tlc, user: user }

    it 'updates the character', :aggregate_failures do
      patch "/frontend/tlc/characters/#{character.id}", params: {
        character: { classes: { bard: 12 } }, charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :ok
      expect(character.reload.data.classes).to eq({ 'bard' => 12 })
    end

    # AC2: action_policy ownership scoping (plan security threat 4).
    it 'returns 404 for another user tlc character', :aggregate_failures do
      another_character = create :character, :tlc

      patch "/frontend/tlc/characters/#{another_character.id}", params: {
        character: { classes: { bard: 12 } }, charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
      expect(another_character.reload.data.classes).to eq({ 'bard' => 4 })
    end

    # AC3: Character.tlc is STRICT, so an owned dnd2024 character is invisible here.
    it 'returns 404 for an owned dnd2024 character', :aggregate_failures do
      dnd2024_character = create :character, :dnd2024, user: user

      patch "/frontend/tlc/characters/#{dnd2024_character.id}", params: {
        character: { classes: { bard: 12 } }, charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
      expect(dnd2024_character.reload.data.classes).to eq({ 'bard' => 4 })
    end
  end

  describe 'POST /frontend/tlc/characters/:character_id/rest' do
    let!(:character) {
      create :character, :tlc, user: user, data: {
        level: 4, species: 'human', main_class: 'bard', classes: { bard: 4 },
        abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 },
        spent_spell_slots: { 1 => 3 }, hit_dice: { '8' => 4 }, spent_hit_dice: { '8' => 3 },
        health: { max: 10, current: 1 }, exhaustion: 2
      }
    }
    let!(:character_feat) {
      create :character_feat, character: character, feat: create(:feat, :tlc), used_count: 5, limit_refresh: 0
    }

    # Real command, no stub: proves the TLC-contract command is wired in. With
    # the dnd2024 command this is a 422 "type?" error.
    it 'performs a short rest', :aggregate_failures do
      post "/frontend/tlc/characters/#{character.id}/rest", params: {
        value: 'short_rest', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :ok
      expect(response.parsed_body).to eq({ 'result' => 'ok' })
      expect(character_feat.reload.used_count).to eq 0
    end

    it 'performs a long rest', :aggregate_failures do
      post "/frontend/tlc/characters/#{character.id}/rest", params: {
        value: 'long_rest', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :ok
      data = character.reload.data
      expect(data.health).to eq({ 'max' => 10, 'current' => 10 })
      expect(data.spent_spell_slots).to eq({ '1' => 0 })
      expect(data.spent_hit_dice).to eq({ '8' => 1 })
      expect(data.exhaustion).to eq 1
      expect(character_feat.reload.used_count).to eq 0
    end

    it 'returns 422 for an unknown rest value' do
      post "/frontend/tlc/characters/#{character.id}/rest", params: {
        value: 'unexisting', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :unprocessable_content
    end

    # AC2.
    it 'returns 404 for another user tlc character', :aggregate_failures do
      another_character = create :character, :tlc

      post "/frontend/tlc/characters/#{another_character.id}/rest", params: {
        value: 'short_rest', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
      expect(another_character.reload.data.health).to be_nil
    end

    # AC3.
    it 'returns 404 for an owned dnd2024 character' do
      dnd2024_character = create :character, :dnd2024, user: user

      post "/frontend/tlc/characters/#{dnd2024_character.id}/rest", params: {
        value: 'short_rest', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
    end
  end

  # Serializer: Frontend::CharactersController#show resolves
  # "Tlc::Character" -> Tlc::CharacterSerializer, so the five TLC fields must
  # round-trip NON-default values (defaults would also pass on a missing field).
  describe 'GET /frontend/characters/:id' do
    let!(:character) {
      create :character, :tlc, user: user, data: {
        level: 4, species: 'human', main_class: 'bard', classes: { bard: 4 }, subclasses: { bard: nil },
        abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 },
        leyfarer_rank: 3, leyfarer_focus: 'warden', selected_traits: %w[alpha beta],
        mixed_species: 'elf', dismissed_warnings: %w[w1]
      }
    }

    it 'serializes the tlc provider and the five TLC fields', :aggregate_failures do
      get "/frontend/characters/#{character.id}", params: { charkeeper_access_token: access_token }

      expect(response).to have_http_status :ok
      expect(response.parsed_body['character']).to include(
        'provider' => 'tlc', 'leyfarer_rank' => 3, 'leyfarer_focus' => 'warden',
        'selected_traits' => %w[alpha beta], 'mixed_species' => 'elf', 'dismissed_warnings' => %w[w1]
      )
    end
  end

  # AC5: the campaign provider enum. Lives here because it is one of this
  # ticket's acceptance cases; the flow itself is upstream's.
  describe 'POST /frontend/campaigns' do
    it 'accepts the tlc provider', :aggregate_failures do
      expect {
        post '/frontend/campaigns', params: {
          campaign: { name: 'Leyfarers', provider: 'tlc' }, charkeeper_access_token: access_token
        }
      }.to change(user.campaigns, :count).by(1)

      expect(response).to have_http_status :created
      expect(Campaign.last.provider).to eq 'tlc'
    end

    it 'still rejects a provider outside the enum', :aggregate_failures do
      expect {
        post '/frontend/campaigns', params: {
          campaign: { name: 'Leyfarers', provider: 'daggerheart' }, charkeeper_access_token: access_token
        }
      }.not_to change(Campaign, :count)

      expect(response).to have_http_status :unprocessable_content
    end
  end
end
