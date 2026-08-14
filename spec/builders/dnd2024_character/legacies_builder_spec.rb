# frozen_string_literal: true

describe Dnd2024Character::LegaciesBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { Dnd2024Character::BaseBuilder.new.call(result: { main_class: 'bard', species: 'elf', legacy: legacy }) }
  let!(:untouched) { result.deep_dup }

  context 'with drow' do
    let(:legacy) { 'drow' }

    it 'grants superior darkvision' do
      expect(build[:darkvision]).to eq(120)
    end
  end

  context 'with wood_elf' do
    let(:legacy) { 'wood_elf' }

    it 'raises the walking speed' do
      expect(build[:speed]).to eq(35)
    end
  end

  context 'with a legacy that has no builder' do
    let(:legacy) { 'high_elf' }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end

  # A species without legacies (dwarf, human, ...) reaches the builder with a nil
  # legacy; NoMethodError on nil#camelize is a NameError, so it lands on the dummy.
  context 'without a legacy' do
    let(:result) { Dnd2024Character::BaseBuilder.new.call(result: { main_class: 'bard', species: 'human' }) }
    let(:legacy) { nil }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end
end
