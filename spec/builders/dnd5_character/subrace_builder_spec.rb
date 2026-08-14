# frozen_string_literal: true

describe Dnd5Character::SubraceBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) { Dnd5Character::BaseBuilder.new.call(result: { main_class: 'monk', race: 'dwarf', subrace: subrace }) }
  let!(:untouched) { result.deep_dup }

  context 'with a subrace granting a resistance' do
    let(:subrace) { 'stout' }

    it 'applies the resistance' do
      expect(build[:resistance]).to eq(['poison'])
    end

    it 'keeps resistances unique when already present' do
      result[:resistance] = ['poison']

      expect(build[:resistance]).to eq(['poison'])
    end
  end

  context 'with drow' do
    let(:subrace) { 'drow' }

    it 'grants the drow weapon training' do
      expect(build[:weapon_skills]).to eq(%w[shortsword rapier hand_crossbow])
    end
  end

  context 'with an unknown subrace' do
    let(:subrace) { 'deep_gnome' }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end

  context 'without a subrace' do
    let(:subrace) { nil }

    it 'falls back to the dummy builder' do
      expect(build).to eq(untouched)
    end
  end
end
