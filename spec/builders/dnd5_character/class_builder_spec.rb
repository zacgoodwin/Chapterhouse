# frozen_string_literal: true

describe Dnd5Character::ClassBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { Dnd5Character::BaseBuilder.new.call(result: { main_class: main_class, race: 'human' }) }

  context 'with a known class' do
    let(:main_class) { 'monk' }

    it 'applies the class proficiencies and starting array', :aggregate_failures do
      expect(build[:weapon_core_skills]).to eq(['light'])
      expect(build[:weapon_skills]).to eq(['shortsword'])
      expect(build[:abilities]).to eq(str: 12, dex: 15, con: 13, int: 11, wis: 14, cha: 10)
      expect(build[:health]).to eq(current: 9, max: 9, temp: 0)
    end

    it 'fills the d8 hit dice slot' do
      expect(build[:hit_dice]).to eq(6 => 0, 8 => 1, 10 => 0, 12 => 0)
    end
  end

  Dnd5::Character::HIT_DICES.each_key do |class_slug|
    context "with #{class_slug}" do
      let(:main_class) { class_slug }

      it 'assigns abilities and health', :aggregate_failures do
        expect(build[:abilities].keys).to contain_exactly(:str, :dex, :con, :int, :wis, :cha)
        expect(build[:health]).to include(temp: 0)
        expect(build[:health][:current]).to eq(build[:health][:max])
      end

      it 'fills the hit dice slot from HIT_DICES' do
        expect(build[:hit_dice][Dnd5::Character::HIT_DICES[class_slug]]).to eq(1)
      end
    end
  end

  context 'with an unknown class' do
    let(:main_class) { 'bardbarian' }

    it 'falls back to the dummy builder' do
      expect(build).not_to have_key(:abilities)
    end
  end
end
