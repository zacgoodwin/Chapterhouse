# frozen_string_literal: true

# Ticket #33 (E2) acceptance test 3 — instantiate half. A homebrew subclass's
# resource definition (info.resources) flows through the SAME
# CharactersContext::Tlc::RefreshResources machinery (ticket C8) the 12 seeded
# subclasses use, once the subclass is attached to a character. Proves the
# homebrew-source union added to RefreshResources#available_defs: a UUID-id
# homebrew subclass is looked up, its C8-shaped def surfaced, and a
# CustomResource + Character::Resource are instantiated with a Dentaku-computed max.
describe CharactersContext::Tlc::RefreshResources do
  subject(:service_call) { described_class.new.call(character: Tlc::Character.find(character.id)) }

  let(:user) { create :user }
  let!(:subclass) do
    create :tlc_homebrews_subclass, user: user, info: {
      'class_id' => 'rogue',
      'resources' => [
        {
          'slug' => 'gambler_homebrew_pool',
          'name' => 'Homebrew Pool',
          'description' => 'A homebrew resource pool.',
          'min_class_level' => 3,
          'max_formula' => 'rogue_level + proficiency_bonus',
          'reset_direction' => 1,
          'resets' => { 'long' => -1 }
        }
      ]
    }
  end

  let!(:character) do
    create :character, :tlc, user: user, data: {
      level: 5, main_class: 'rogue', classes: { 'rogue' => 5 }, subclasses: { 'rogue' => subclass.id }
    }
  end

  it 'instantiates the homebrew pool via C8 with a Dentaku-computed max', :aggregate_failures do
    service_call

    custom_resource = character.reload.custom_resources.find_by(origin_slug: 'gambler_homebrew_pool')
    expect(custom_resource).to be_present
    expect(custom_resource.name).to eq 'Homebrew Pool'
    # rogue_level(5) + proficiency_bonus(3) = 8
    expect(custom_resource.max_value).to eq 8

    resource = character.resources.find_by(custom_resource: custom_resource)
    expect(resource).to be_present
    expect(resource.value).to eq 8 # reset_direction 1 seeds at max
  end

  it 'does not instantiate a homebrew pool below its min_class_level' do
    low = create :character, :tlc, user: user, data: {
      level: 2, main_class: 'rogue', classes: { 'rogue' => 2 }, subclasses: { 'rogue' => subclass.id }
    }

    described_class.new.call(character: Tlc::Character.find(low.id))

    expect(low.reload.custom_resources.find_by(origin_slug: 'gambler_homebrew_pool')).to be_nil
  end
end
