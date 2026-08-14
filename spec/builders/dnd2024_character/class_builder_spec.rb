# frozen_string_literal: true

describe Dnd2024Character::ClassBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { Dnd2024Character::BaseBuilder.new.call(result: { main_class: main_class, species: 'human' }) }

  context 'with a known class' do
    let(:main_class) { 'bard' }

    it 'delegates to the class builder' do
      expect(build[:abilities]).to eq(Dnd2024Character::Classes::BardBuilder.new.call(result: result)[:abilities])
    end

    it 'fills the hit dice pool for the class die size' do
      expect(build[:hit_dice]).to eq(6 => 0, 8 => 1, 10 => 0, 12 => 0)
    end
  end

  context 'with a barbarian (d12 hit die)' do
    let(:main_class) { 'barbarian' }

    it 'fills the d12 slot' do
      expect(build[:hit_dice]).to eq(6 => 0, 8 => 0, 10 => 0, 12 => 1)
    end
  end

  # Every class in the platform config must build: an unbuilt class silently
  # falls back to DummyBuilder and leaves the sheet without abilities or health.
  Dnd2024::Character.classes_info.each_key do |class_slug|
    context "with #{class_slug}" do
      let(:main_class) { class_slug }

      it 'assigns abilities and health', :aggregate_failures do
        expect(build[:abilities].keys).to contain_exactly(:str, :dex, :con, :int, :wis, :cha)
        expect(build[:health]).to include(temp: 0)
        expect(build[:health][:current]).to eq(build[:health][:max])
      end

      it 'fills the hit dice slot from HIT_DICES' do
        expect(build[:hit_dice][Dnd2024::Character::HIT_DICES[class_slug]]).to eq(1)
      end
    end
  end

  context 'with an unknown class' do
    let(:main_class) { 'bardbarian' }
    let(:result) do
      Dnd2024Character::BaseBuilder.new.call(result: { main_class: main_class }).merge(hit_dice: { 8 => 0 })
    end

    it 'falls back to the dummy builder and leaves the sheet untouched', :aggregate_failures do
      expect(build).not_to have_key(:abilities)
      expect(build[:hit_dice]).to eq(8 => 0, nil => 1)
    end
  end
end
