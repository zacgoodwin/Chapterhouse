# frozen_string_literal: true

describe Dnd5Character::RaceBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { Dnd5Character::BaseBuilder.new.call(result: { main_class: 'monk', race: race }) }
  let!(:untouched) { result.deep_dup }

  context 'with a known race' do
    let(:race) { 'dragonborn' }

    it 'applies speed and languages', :aggregate_failures do
      expect(build[:speed]).to eq(30)
      expect(build[:languages]).to eq(%w[common draconic])
    end

    it 'keeps languages unique when already present' do
      result[:languages] = ['common']

      expect(build[:languages]).to eq(%w[common draconic])
    end
  end

  context 'with a two-word race slug' do
    let(:race) { 'half_elf' }

    it 'resolves the camelized builder' do
      expect(build[:speed]).to eq(30)
    end
  end

  Dnd5::Character.config['races'].each_key do |race_slug|
    context "with #{race_slug}" do
      let(:race) { race_slug }

      it 'sets a walking speed and at least one language', :aggregate_failures do
        expect(build[:speed]).to be_positive
        expect(build[:languages]).to include('common')
      end
    end
  end

  context 'with an unknown race' do
    let(:race) { 'gelatinous_cube' }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end

  context 'without a race' do
    let(:race) { nil }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end
end
