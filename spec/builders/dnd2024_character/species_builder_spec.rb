# frozen_string_literal: true

describe Dnd2024Character::SpeciesBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { Dnd2024Character::BaseBuilder.new.call(result: { main_class: 'bard', species: species }) }
  let!(:untouched) { result.deep_dup }

  context 'with a species carrying traits' do
    let(:species) { 'aasimar' }

    it 'applies the species traits' do
      expect(build[:resistance]).to eq(%w[necrotic radiant])
    end

    it 'keeps resistances unique when already present' do
      result[:resistance] = ['radiant']

      expect(build[:resistance]).to eq(%w[radiant necrotic])
    end
  end

  context 'with a config species that has no builder of its own' do
    let(:species) { 'human' }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end

  context 'with a homebrew species id' do
    let(:species) { homebrew.id.to_s }
    let(:homebrew) { create :dnd2024_homebrews_race }

    it 'resolves the homebrew record and leaves the sheet unchanged' do
      expect(build).to eq(untouched)
    end
  end

  context 'with an unknown species' do
    let(:species) { 'gelatinous_cube' }

    it 'returns the sheet unchanged' do
      expect(build).to eq(untouched)
    end
  end
end
