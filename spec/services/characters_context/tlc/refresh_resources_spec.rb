# frozen_string_literal: true

# Gate tests for ticket C8 (TLC subclass resource seeding). One representative
# pool per formula shape, per the plan's Tests+evals section:
#   - Lucky Number: stored-value shape (plan acceptance test 5)
#   - Rune Priest runes: Dentaku formula shape, recomputes on level change (test 2)
#   - Hedge Your Bets: short-rest cadence (test 3)
#   - Ghost Shroud: session cadence (Steps item 5's "one session-refresh resource")
# plus detach-on-subclass-change (test 4). CustomResource#refreshed_value's
# parity with the real, shipped rest commands is proven separately in
# spec/models/custom_resource_spec.rb -- no TLC rest command exists yet (C1,
# ticket #17, is Blocked), so short/long/session refresh here is asserted via
# that shared method rather than a rest HTTP action.
describe CharactersContext::Tlc::RefreshResources do
  subject(:service_call) { described_class.new.call(character: Tlc::Character.find(character.id)) }

  describe 'Lucky Number (stored-value shape, acceptance test 5)' do
    let!(:character) do
      create :character, :tlc, data: {
        level: 5, main_class: 'rogue', classes: { 'rogue' => 5 }, subclasses: { 'rogue' => 'gambler' }
      }
    end

    it 'attaches a trackable Lucky Number resource capped at 20, settable 1-20', :aggregate_failures do
      service_call

      custom_resource = character.reload.custom_resources.find_by(origin_slug: 'gambler_lucky_number')
      expect(custom_resource).to be_present
      expect(custom_resource.max_value).to eq 20
      expect(custom_resource.reset_direction).to eq 0

      resource = character.resources.find_by(custom_resource: custom_resource)
      expect(resource).to be_present

      resource.update!(value: 1)
      expect(resource.reload.value).to eq 1

      resource.update!(value: 20)
      expect(resource.reload.value).to eq 20
    end

    it 'does not attach Hedge Your Bets below rogue level 9 (gated feature)' do
      service_call

      expect(character.reload.custom_resources.find_by(origin_slug: 'gambler_hedge_your_bets')).to be_nil
    end
  end

  describe 'Rune Priest runes (Dentaku formula shape, acceptance test 2)' do
    let!(:character) do
      create :character, :tlc, data: {
        level: 6, main_class: 'cleric', classes: { 'cleric' => 6 }, subclasses: { 'cleric' => 'rune_priest' }
      }
    end

    it 'computes floor(cleric_level / 2) + proficiency_bonus = 6 at cleric 6 / PB 3' do
      service_call

      resource = character.reload.custom_resources.find_by(origin_slug: 'rune_priest_runes')
      expect(resource.max_value).to eq 6
    end

    it 'recomputes on level change', :aggregate_failures do
      service_call
      resource = character.reload.custom_resources.find_by(origin_slug: 'rune_priest_runes')
      expect(resource.max_value).to eq 6

      character.data.level = 10
      character.data.classes = { 'cleric' => 10 }
      character.save!
      described_class.new.call(character: Tlc::Character.find(character.id))

      expect(resource.reload.max_value).to eq 9 # floor(10/2) + PB(10)=4 => 5+4
    end
  end

  describe 'Hedge Your Bets (short-rest cadence, acceptance test 3)' do
    let!(:character) do
      create :character, :tlc, data: {
        level: 9, main_class: 'rogue', classes: { 'rogue' => 9 }, subclasses: { 'rogue' => 'gambler' }
      }
    end

    it 'seeds a PB-sized pool that refreshes on short rest and on long rest', :aggregate_failures do
      service_call

      custom_resource = character.reload.custom_resources.find_by(origin_slug: 'gambler_hedge_your_bets')
      resource = character.resources.find_by(custom_resource: custom_resource)
      expect(custom_resource.max_value).to eq 4 # proficiency_bonus at character level 9
      expect(resource.value).to eq 4 # starts full

      resource.update!(value: 0) # spent

      expect(custom_resource.refreshed_value(resource.value, 'short')).to eq 4
      expect(custom_resource.refreshed_value(resource.value, 'long')).to eq 4
    end
  end

  describe 'Ghost Shroud (session cadence, one session-refresh resource)' do
    let!(:character) do
      create :character, :tlc, data: {
        level: 7, main_class: 'ranger', classes: { 'ranger' => 7 },
        abilities: { str: 10, dex: 10, con: 10, int: 10, wis: 16, cha: 10 },
        subclasses: { 'ranger' => 'ghostscale_reaver' }
      }
    end

    it 'is keyed to session cadence, not short/long, and refreshes accordingly', :aggregate_failures do
      service_call

      custom_resource = character.reload.custom_resources.find_by(origin_slug: 'ghostscale_reaver_ghost_shroud')
      expect(custom_resource.max_value).to eq 4 # 1 + wis modifier(16 => +3)
      expect(custom_resource.resets).to eq({ 'session' => -1 })

      expect(custom_resource.refreshed_value(0, 'session')).to eq 4
      expect(custom_resource.refreshed_value(0, 'long')).to eq 0 # a long rest does not touch it
      expect(custom_resource.refreshed_value(0, 'short')).to eq 0
    end
  end

  describe 'detach on subclass change (acceptance test 4)' do
    let!(:character) do
      create :character, :tlc, data: {
        level: 6, main_class: 'cleric', classes: { 'cleric' => 6 }, subclasses: { 'cleric' => 'rune_priest' }
      }
    end

    it 'removes both the character_resource and custom_resource once the subclass no longer matches', :aggregate_failures do
      service_call
      expect(character.reload.custom_resources.find_by(origin_slug: 'rune_priest_runes')).to be_present
      expect(Character::Resource.where(character_id: character.id).count).to eq 1

      character.data.subclasses = { 'cleric' => nil }
      character.save!
      described_class.new.call(character: Tlc::Character.find(character.id))

      expect(character.reload.custom_resources.find_by(origin_slug: 'rune_priest_runes')).to be_nil
      expect(Character::Resource.where(character_id: character.id)).to be_empty
    end
  end

  describe 'a player-created custom resource with the same character' do
    let!(:character) { create :character, :tlc, data: { level: 6, classes: {}, subclasses: {} } }
    let!(:player_resource) { create :custom_resource, resourceable: character, name: 'Inspiration', origin_slug: nil }

    it 'never touches resources without a subclass-grant origin_slug' do
      service_call

      expect(CustomResource.find(player_resource.id)).to eq player_resource
    end
  end
end
