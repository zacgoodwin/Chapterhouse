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

    # #76 regression, end to end: a TLC character on a SHARED species/class must
    # surface the shared FEATURES, not an empty panel. The shared species trait
    # and class feature live as Dnd2024::Feat rows (db/data/tlc/* seed zero), so
    # a strict ::Tlc::Feat scope attached nothing and `features` came back []. The
    # union in refresh_feats.rb#feats fixes it. Revert that union -> this goes RED.
    it 'attaches shared species and class features to a created TLC character', :aggregate_failures do
      species_trait = create :feat, :dnd2024, origin: 0, origin_value: 'human', slug: 'resourceful'
      class_feature = create :feat, :dnd2024, origin: 1, origin_value: 'wizard', slug: 'wizard_magic_initiate'

      post '/frontend/tlc/characters',
           params: create_params.deep_merge(character: { name: 'Leyfarer Wizard', main_class: 'wizard' })
      expect(response).to have_http_status :created
      character_id = response.parsed_body.dig('character', 'id')

      # The full show serializer exposes `features` (the create response omits it).
      get "/frontend/characters/#{character_id}", params: { charkeeper_access_token: access_token }
      feature_slugs = response.parsed_body.dig('character', 'features').pluck('slug')
      expect(feature_slugs).not_to be_empty
      expect(feature_slugs).to include(species_trait.slug)
      expect(feature_slugs).to include(class_feature.slug)
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

  # C7 acceptance cases, end to end through the real update contract and the
  # real serializer. The never-block principle is the load-bearing assertion in
  # each: the write always succeeds and the complaint arrives as a warning.
  describe 'soft warnings' do
    let!(:character) {
      create :character, :tlc, user: user, data: {
        level: 4, species: 'orc', main_class: 'bard', classes: { bard: 4 }, subclasses: { bard: nil },
        abilities: { str: 12, dex: 16, con: 14, int: 11, wis: 16, cha: 16 }
      }
    }

    def show
      get "/frontend/characters/#{character.id}", params: { charkeeper_access_token: access_token }
      response.parsed_body['character']
    end

    # JSON, matching helpers/apiRequest.jsx:63-67 -- form encoding drops an
    # empty array, which is exactly the payload that restores the last dismissed
    # warning.
    def update(payload, target: character)
      patch "/frontend/tlc/characters/#{target.id}",
            params: { character: payload, charkeeper_access_token: access_token }, as: :json
    end

    def warning(payload, slug) = payload['warnings'].find { |item| item['slug'] == slug }

    # Acceptance test 7.
    it 'saves an under-prereq multiclass and warns from the PHB', :aggregate_failures do
      update({ classes: { bard: 3, paladin: 1 } })

      expect(response).to have_http_status :ok
      expect(character.reload.data.classes).to eq({ 'bard' => 3, 'paladin' => 1 })
      expect(warning(show, 'multiclass_prereq')).to include(
        'source' => 'PHB', 'message_key' => 'warnings.multiclassPrereq', 'dismissible' => true
      )
    end

    # Same scores, same multiclass, Human instead of Orc. Species is not an
    # update-contract field, so the bypass needs its own character rather than a
    # follow-up PATCH.
    it 'raises no multiclass warning for a Human (Greenhorn bypass)', :aggregate_failures do
      human = create :character, :tlc, user: user, data: {
        level: 4, species: 'human', main_class: 'bard', classes: { bard: 4 }, subclasses: { bard: nil },
        abilities: { str: 12, dex: 16, con: 14, int: 11, wis: 16, cha: 16 }
      }

      update({ classes: { bard: 3, paladin: 1 } }, target: human)
      expect(response).to have_http_status :ok

      get "/frontend/characters/#{human.id}", params: { charkeeper_access_token: access_token }
      expect(response.parsed_body.dig('character', 'warnings').pluck('slug')).not_to include 'multiclass_prereq'
    end

    # Acceptance test 2, third clause: a 4th trait without Mixed Ancestry is a
    # warning, NOT a 422.
    it 'saves a 4th species trait and warns instead of erroring', :aggregate_failures do
      traits = Array.new(4) { |index| create(:feat, :tlc, slug: "trait-#{index}").slug }

      update({ selected_traits: traits })

      expect(response).to have_http_status :ok
      expect(character.reload.data.selected_traits).to eq traits
      # Contract failures render top-level `errors` (base_controller.rb:43); a
      # never-block save must carry none.
      expect(response.parsed_body['errors']).to be_nil
      expect(warning(show, 'trait_count')).to include(
        'source' => 'TLC', 'context' => { 'selected' => 4, 'allowed' => 3 }
      )
    end

    it 'warns from TLC when level exceeds the campaign chapter cap', :aggregate_failures do
      create :campaign_character, character: character, campaign: create(:campaign, :tlc, chapter: 8)
      update({ classes: { bard: 13 } })

      expect(response).to have_http_status :ok
      expect(warning(show, 'level_vs_chapter_cap')).to include(
        'source' => 'TLC', 'context' => { 'level' => 13, 'cap' => 12, 'chapter' => 8 }
      )
    end

    # The Lady of Ivory -> Fabricate class of conflict: the grant is kept
    # (never-block) and flagged.
    it 'warns from TLC for an exempted banned-spell grant', :aggregate_failures do
      granting = create :feat, :tlc, slug: 'lady_of_ivory', info: { 'banned_exemption' => true }
      create :character_feat, character: character, feat: granting

      expect(warning(show, 'banned_spell_exempted')).to include(
        'source' => 'TLC', 'context' => { 'feats' => ['lady_of_ivory'] }
      )
    end

    describe 'dismiss and restore' do
      before { update({ classes: { bard: 3, paladin: 1 } }) }

      it 'hides a dismissed slug, lists it, and brings it back on restore', :aggregate_failures do
        update({ dismissed_warnings: %w[multiclass_prereq] })
        dismissed = show
        expect(dismissed['warnings'].pluck('slug')).not_to include 'multiclass_prereq'
        expect(dismissed['dismissed_warnings']).to eq %w[multiclass_prereq]

        update({ dismissed_warnings: [] })
        restored = show
        expect(restored['warnings'].pluck('slug')).to include 'multiclass_prereq'
        expect(restored['dismissed_warnings']).to eq []
      end

      it 'dedupes a repeated dismissal' do
        update({ dismissed_warnings: %w[multiclass_prereq multiclass_prereq] })

        expect(character.reload.data.dismissed_warnings).to eq %w[multiclass_prereq]
      end

      it 'rejects a slug outside the registry', :aggregate_failures do
        update({ dismissed_warnings: %w[not_a_warning] })

        expect(response).to have_http_status :unprocessable_content
        expect(character.reload.data.dismissed_warnings).to eq []
      end

      # Pins all? (not any?): one bad slug poisons the whole payload, so the
      # known slug alongside it is not stored either.
      it 'rejects a payload mixing a known slug with an unknown one', :aggregate_failures do
        update({ dismissed_warnings: %w[multiclass_prereq not_a_warning] })

        expect(response).to have_http_status :unprocessable_content
        expect(character.reload.data.dismissed_warnings).to eq []
      end

      # Only the delta is registry-bound. A slug already stored (dismissed
      # before it was retired from SLUGS) must not 422 every later mutation --
      # that would be the same unrestorable dead state from the other side.
      it 'still restores a stored slug the registry no longer knows', :aggregate_failures do
        stored = Character.find(character.id)
        stored.data.dismissed_warnings = %w[retired_slug]
        stored.save!

        update({ dismissed_warnings: %w[retired_slug multiclass_prereq] })
        expect(response).to have_http_status :ok

        update({ dismissed_warnings: [] })
        expect(response).to have_http_status :ok
        expect(character.reload.data.dismissed_warnings).to eq []
      end
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
