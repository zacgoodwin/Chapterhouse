# frozen_string_literal: true

# A6 / acceptance test 13 (plan L367-369, L1010-1013): the REGRESSION RULE. The
# TLC merge edits shared files (config/routes.rb, CharacterTab.jsx, the A5a
# provider-check sweep, app/models/feat.rb, refresh_feats, the dnd2024/tlc
# decorators, ...) and stock dnd2024 behavior has to be provably unchanged
# before and after. This is that proof, deterministic and gate-run.
#
# Request specs, NOT controller specs, for the same reason as
# spec/requests/frontend/tlc/characters_spec.rb: config/application.rb ends the
# route set with `match '*path', to: 'application#not_found'`, so an unrouted
# path 404s -- the exact status the cross-provider cases assert. A controller
# spec bypasses the router and would pass even with a route deleted.
#
# The cross-provider cases here are the inverse of A3's (tlc_characters_spec.rb
# already proves a dnd2024 character 404s on tlc endpoints): a tlc character
# has to 404 on dnd2024 endpoints too, because Frontend::Tlc::CharactersController
# < Frontend::Dnd2024::CharactersController and could, in principle, widen the
# dnd2024 scope by accident when a shared method is touched.
describe 'Frontend::Dnd2024::Characters regression' do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }
  let(:create_params) {
    {
      character: {
        name: 'Stock Adventurer', species: 'human', size: 'medium', main_class: 'bard', alignment: 'neutral'
      }, charkeeper_access_token: access_token
    }
  }

  describe 'POST /frontend/dnd2024/characters' do
    # AC1 / plan step 2 ("dnd2024 create ... unchanged"). 201, not the 200 a
    # loosened contract or a swapped-in tlc command would still render.
    it 'creates a dnd2024 character and returns provider dnd2024', :aggregate_failures do
      expect { post('/frontend/dnd2024/characters', params: create_params) }.to change(user.characters, :count).by(1)

      expect(response).to have_http_status :created
      expect(response.parsed_body.dig('character', 'provider')).to eq 'dnd2024'
      expect(response.parsed_body.dig('character', 'level')).to eq 1

      character = Dnd2024::Character.find(response.parsed_body.dig('character', 'id'))
      expect(character.data.species).to eq 'human'
      expect(character.data.main_class).to eq 'bard'
    end

    it 'returns errors for an invalid payload', :aggregate_failures do
      expect {
        post '/frontend/dnd2024/characters', params: create_params.deep_merge(character: { species: '' })
      }.not_to change(Character, :count)

      expect(response).to have_http_status :unprocessable_content
      expect(response.parsed_body['errors']).not_to be_nil
    end
  end

  describe 'PATCH /frontend/dnd2024/characters/:id' do
    let!(:character) { create :character, :dnd2024, user: user }

    it 'updates the character', :aggregate_failures do
      patch "/frontend/dnd2024/characters/#{character.id}", params: {
        character: { classes: { bard: 5 } }, charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :ok
      expect(character.reload.data.classes).to eq({ 'bard' => 5 })
    end

    it 'returns 404 for another user dnd2024 character', :aggregate_failures do
      another_character = create :character, :dnd2024

      patch "/frontend/dnd2024/characters/#{another_character.id}", params: {
        character: { classes: { bard: 5 } }, charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
      expect(another_character.reload.data.classes).to eq({ 'bard' => 4 })
    end

    # Inverse of A3's case: STRICT provider scope (Character.dnd2024) has to
    # keep a tlc character invisible on the dnd2024 endpoint the TLC controller
    # inherits from.
    it 'returns 404 for an owned tlc character', :aggregate_failures do
      tlc_character = create :character, :tlc, user: user

      patch "/frontend/dnd2024/characters/#{tlc_character.id}", params: {
        character: { classes: { bard: 5 } }, charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
      expect(tlc_character.reload.data.classes).to eq({ 'bard' => 4 })
    end
  end

  describe 'POST /frontend/dnd2024/characters/:character_id/rest' do
    let!(:character) {
      create :character, :dnd2024, user: user, data: {
        level: 4, species: 'human', main_class: 'bard', classes: { bard: 4 },
        abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 },
        spent_spell_slots: { 1 => 3 }, hit_dice: { '8' => 4 }, spent_hit_dice: { '8' => 3 },
        health: { max: 10, current: 1 }, exhaustion: 2
      }
    }
    let!(:character_feat) {
      create :character_feat, character: character, feat: create(:feat, :dnd2024), used_count: 5, limit_refresh: 0
    }

    # Real command, no stub: proves the dnd2024-contract command is still wired
    # in after the TLC merge added its own rest subclasses alongside it.
    it 'performs a short rest', :aggregate_failures do
      post "/frontend/dnd2024/characters/#{character.id}/rest", params: {
        value: 'short_rest', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :ok
      expect(response.parsed_body).to eq({ 'result' => 'ok' })
      expect(character_feat.reload.used_count).to eq 0
    end

    it 'performs a long rest', :aggregate_failures do
      post "/frontend/dnd2024/characters/#{character.id}/rest", params: {
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
      post "/frontend/dnd2024/characters/#{character.id}/rest", params: {
        value: 'unexisting', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :unprocessable_content
    end

    it 'returns 404 for another user dnd2024 character', :aggregate_failures do
      another_character = create :character, :dnd2024

      post "/frontend/dnd2024/characters/#{another_character.id}/rest", params: {
        value: 'short_rest', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
      expect(another_character.reload.data.health).to be_nil
    end

    # Inverse of A3's case, and the plan's explicit "dnd2024 rest endpoint
    # ... 404s tlc characters". Frontend::Dnd2024::Characters::RestController
    # scopes find_character with .dnd2024, so a tlc id 404s before the
    # `type?: ::Dnd2024::Character` contract even runs.
    it 'returns 404 for an owned tlc character' do
      tlc_character = create :character, :tlc, user: user

      post "/frontend/dnd2024/characters/#{tlc_character.id}/rest", params: {
        value: 'short_rest', charkeeper_access_token: access_token
      }

      expect(response).to have_http_status :not_found
    end
  end

  # Plan step 2 ("... dnd2024 create/show/rest unchanged").
  # Frontend::CharactersController#show is provider-generic (Character.all),
  # so the regression risk is the serializer dispatch (character.type ->
  # "#{type}Serializer") picking the wrong class after the tlc serializer landed.
  describe 'GET /frontend/characters/:id' do
    let!(:character) {
      create :character, :dnd2024, user: user, data: {
        level: 4, species: 'human', main_class: 'bard', classes: { bard: 4 }, subclasses: { bard: nil },
        abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 }
      }
    }

    it 'serializes the dnd2024 provider with Dnd2024::CharacterSerializer, not a tlc field leaking in', :aggregate_failures do
      get "/frontend/characters/#{character.id}", params: { charkeeper_access_token: access_token }

      expect(response).to have_http_status :ok
      expect(response.parsed_body['character']).to include('provider' => 'dnd2024', 'level' => 4)
      expect(response.parsed_body['character']).not_to have_key('leyfarer_rank')
    end
  end

  # Plan step 2 ("campaign create with 'dnd2024' unchanged"). The provider enum
  # predates TLC; this proves the tlc addition (A3) didn't dislodge it.
  describe 'POST /frontend/campaigns' do
    it 'still accepts the dnd2024 provider', :aggregate_failures do
      expect {
        post '/frontend/campaigns', params: {
          campaign: { name: 'Waterdeep', provider: 'dnd2024' }, charkeeper_access_token: access_token
        }
      }.to change(user.campaigns, :count).by(1)

      expect(response).to have_http_status :created
      expect(Campaign.last.provider).to eq 'dnd2024'
    end
  end
end
