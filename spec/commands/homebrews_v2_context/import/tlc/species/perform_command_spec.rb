# frozen_string_literal: true

# Ticket #33 (E2) acceptance test 1 + E2E slice: author a homebrew TLC species
# with 2 base + 5 optional traits, import it, and confirm the trait rows land as
# Tlc::Feat species traits (origin 'species'), the base/optional split survives
# into info.trait_kind, the choose-N pool is readable, the species is selectable,
# and the rows sit in the tlc_content union. The "traits attach via C2" half is
# asserted structurally (the exact query C2's RefreshFeats runs returns the rows);
# CharactersContext::Tlc::RefreshFeats itself (ticket #6) is parked.
describe HomebrewsV2Context::Import::Tlc::Species::PerformCommand do
  subject(:command_call) { described_class.new.call(payload) }

  def trait(name, trait_kind, extra={})
    {
      trait_kind: trait_kind,
      title: { en: name },
      description: { en: "#{name} description" },
      kind: 'static'
    }.merge(extra)
  end

  let(:user) { create :user }
  let(:payload) do
    {
      user: user,
      title: { en: 'Snailfolk' },
      description: { en: 'A homebrew TLC species.' },
      creature_type: 'humanoid',
      interaction_tags: ['wilderfolk'],
      size: %w[small medium],
      vision: { darkvision: 60 },
      speed: 30,
      optional_pool_size: 3,
      traits: [
        trait('Boneless', 'base', modifiers: { 'resistance' => { 'type' => 'concat', 'value' => 'bludge' } }),
        trait('Wilderfolk', 'base'),
        trait('Molluscan Aegis', 'optional', is_lineage: false, grants_free_trait: 'snails_pace'),
        trait('Quick Withdraw', 'optional'),
        trait('Shelter in Place', 'optional'),
        trait('Slime Trail', 'optional'),
        trait('Wall Crawler', 'optional', is_lineage: true, lineage_options: [{ 'slug' => 'chipachi' }, { 'slug' => 'welkin' }])
      ]
    }
  end

  it 'creates the species container and 7 Tlc::Feat species traits', :aggregate_failures do
    expect { command_call }.to change(Tlc::Homebrews::Species, :count).by(1).and change(Tlc::Feat, :count).by(7)

    expect(command_call[:errors]).to be_nil
    species = command_call[:result]
    expect(species).to be_a Tlc::Homebrews::Species
    expect(species.user_id).to eq user.id

    traits = Tlc::Feat.where(origin: 'species', origin_value: species.id)
    expect(traits.count).to eq 7
    expect(traits.pluck(:type).uniq).to eq ['Tlc::Feat']
  end

  it 'splits base vs optional traits and preserves the choose-N pool', :aggregate_failures do
    command_call
    species = Tlc::Homebrews::Species.last
    traits = Tlc::Feat.where(origin: 'species', origin_value: species.id)

    base = traits.select { |feat| feat.info['trait_kind'] == 'base' }
    optional = traits.select { |feat| feat.info['trait_kind'] == 'optional' }

    expect(base.size).to eq 2
    expect(optional.size).to eq 5
    expect(species.info.optional_pool_size).to eq 3
    # lineage sub-options ride the trait row's info, ready for the D2 picker.
    lineage = optional.find { |feat| feat.info['is_lineage'] }
    expect(lineage.info['lineage_options']).to eq([{ 'slug' => 'chipachi' }, { 'slug' => 'welkin' }])
  end

  it 'persists species-level facts on the container info', :aggregate_failures do
    command_call
    species = Tlc::Homebrews::Species.last

    expect(species.info.creature_type).to eq 'humanoid'
    expect(species.info.interaction_tags).to eq ['wilderfolk']
    expect(species.info.size).to eq %w[small medium]
    expect(species.info.vision).to eq({ 'darkvision' => 60 })
  end

  it 'surfaces the traits in the tlc_content union and to the picker query', :aggregate_failures do
    command_call
    species = Tlc::Homebrews::Species.last

    # tlc_content union (P4): Tlc::Feat rows join the dnd2024+tlc content set.
    expect(Feat.tlc_content.where(origin_value: species.id).count).to eq 7

    # E2E: selecting the species on a character makes every trait discoverable by
    # the origin_value query RefreshFeats (C2) runs — the structural half of
    # "traits attach". The pool feeds the picker via the optional subset.
    character = create :character, :tlc, user: user
    character.data['species'] = species.id
    character.save!

    attachable = Tlc::Feat.where(origin: 'species', origin_value: species.id)
    optional_pool = attachable.select { |feat| feat.info['trait_kind'] == 'optional' }
    expect(attachable.count).to eq 7
    expect(optional_pool.size).to eq 5 # the choose-N pool
  end

  it 'is selectable via the shared homebrew browse scope for its author' do
    command_call
    species = Tlc::Homebrews::Species.last

    selectable = Homebrew.where(user_id: user.id, type: 'Tlc::Homebrews::Species').kept
    expect(selectable).to include(species)
  end

  it 'renders to_homebrew_json for the shared homebrews#show endpoint', :aggregate_failures do
    command_call
    json = Tlc::Homebrews::Species.last.to_homebrew_json.first

    expect(json[:optional_pool_size]).to eq 3
    expect(json[:size]).to eq %w[small medium]
    expect(json[:features].size).to eq 7
  end
end
