# frozen_string_literal: true

describe Dnd2024Character::BaseBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { { main_class: 'bard', species: 'human' } }

  it 'keeps incoming attributes' do
    expect(build).to include(main_class: 'bard', species: 'human')
  end

  it 'starts the character at first level of its main class', :aggregate_failures do
    expect(build[:classes]).to eq('bard' => 1)
    expect(build[:subclasses]).to eq('bard' => nil)
  end

  it 'zeroes the hit dice pool for every die size' do
    expect(build[:hit_dice]).to eq(6 => 0, 8 => 0, 10 => 0, 12 => 0)
  end

  it 'initializes empty proficiency and trait collections' do
    expect(build).to include(
      weapon_core_skills: [], weapon_skills: [], armor_proficiency: [], languages: [],
      selected_skills: {}, resistance: [], immunity: [], vulnerability: [], tools: [],
      skill_boosts: 0, any_skill_boosts: 0
    )
  end

  describe 'creation guide' do
    it 'opens on the first step by default' do
      expect(build[:guide_step]).to eq(1)
    end

    context 'when the guide is skipped' do
      let(:result) { { main_class: 'bard', skip_guide: true } }

      it 'leaves no guide step and drops the flag', :aggregate_failures do
        expect(build[:guide_step]).to be_nil
        expect(build).not_to have_key(:skip_guide)
      end
    end

    context 'when the flag is present but false' do
      let(:result) { { main_class: 'bard', skip_guide: false } }

      it 'opens on the first step and drops the flag', :aggregate_failures do
        expect(build[:guide_step]).to eq(1)
        expect(build).not_to have_key(:skip_guide)
      end
    end
  end

  it 'does not mutate the given result' do
    expect { build }.not_to change(result, :keys)
  end
end
