# frozen_string_literal: true

describe Dnd5Character::BaseBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { { main_class: 'monk', race: 'human' } }

  it 'keeps incoming attributes' do
    expect(build).to include(main_class: 'monk', race: 'human')
  end

  it 'starts the character at first level of its main class', :aggregate_failures do
    expect(build[:classes]).to eq('monk' => 1)
    expect(build[:subclasses]).to eq('monk' => nil)
  end

  it 'zeroes the hit dice pool for every die size' do
    expect(build[:hit_dice]).to eq(6 => 0, 8 => 0, 10 => 0, 12 => 0)
  end

  # dnd5 tracks selected skills as an array, dnd2024/TLC as a hash.
  it 'initializes empty proficiency and trait collections' do
    expect(build).to include(
      weapon_core_skills: [], weapon_skills: [], armor_proficiency: [], languages: [],
      selected_skills: [], resistance: [], immunity: [], vulnerability: [], tools: []
    )
  end

  it 'has no creation guide' do
    expect(build).not_to have_key(:guide_step)
  end
end
