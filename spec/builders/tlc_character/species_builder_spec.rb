# frozen_string_literal: true

describe TlcCharacter::SpeciesBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { TlcCharacter::BaseBuilder.new.call(result: { main_class: 'paladin', species: species }) }
  let!(:untouched) { result.deep_dup }

  context 'with a species carrying traits' do
    let(:species) { 'dwarf' }

    it 'applies the species traits' do
      expect(build[:resistance]).to eq(%w[poison])
    end

    it 'keeps resistances unique when already present' do
      result[:resistance] = ['poison']

      expect(build[:resistance]).to eq(['poison'])
    end
  end

  context 'with a dnd2024 species that has no TLC builder of its own' do
    let(:species) { 'human' }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end

  # The dispatcher tests the dnd2024 species list, so TLC-only species
  # (birdfolk, catfolk, ...) route to CustomBuilder, which finds no homebrew
  # record and returns the sheet untouched. Current behaviour, not intent.
  context 'with a TLC-only species' do
    let(:species) { 'birdfolk' }

    it 'applies no species traits' do
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
end
