# frozen_string_literal: true

describe TlcCharacter::LegaciesBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) do
    TlcCharacter::BaseBuilder.new.call(result: { main_class: 'paladin', species: 'elf', legacy: legacy })
  end
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

  context 'without a legacy' do
    let(:legacy) { nil }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end
end
