# frozen_string_literal: true

describe TlcCharacter::BackgroundBuilder do
  subject(:build) { described_class.new.call(result: result) }

  let(:result) do
    TlcCharacter::BaseBuilder.new.call(result: { main_class: 'paladin', species: 'human', background: background })
  end
  let!(:untouched) { result.deep_dup }

  context 'with a config background' do
    let(:background) { 'wayfarer' }

    it 'applies feats, skills, ability boosts and tools', :aggregate_failures do
      expect(build[:selected_feats]).to eq(['lucky'])
      expect(build[:selected_skills]).to eq(insight: 1, stealth: 1)
      expect(build[:ability_boosts]).to eq(%w[dex wis cha])
      expect(build[:tools]).to eq(['thieves'])
    end
  end

  # Every config background must build: a background without a builder silently
  # leaves the sheet with no background skills, feat or ability boosts.
  Dnd2024::Character.backgrounds.each_key do |background_slug|
    context "with #{background_slug}" do
      let(:background) { background_slug }

      it 'assigns background skills and ability boosts', :aggregate_failures do
        expect(build[:selected_skills].size).to eq(2)
        expect(build[:ability_boosts].size).to eq(3)
      end
    end
  end

  context 'with a homebrew background' do
    let(:background) { homebrew.id.to_s }
    let(:homebrew) { create :dnd2024_homebrews_background }

    it 'copies feats, skills and ability boosts off the homebrew record', :aggregate_failures do
      expect(build[:selected_feats]).to eq(["Monk's Focus"])
      expect(build[:selected_skills]).to eq(%w[acrobatics religion])
      expect(build[:ability_boosts]).to eq(%w[str int cha])
    end
  end

  # A background can be added to the config before its builder exists.
  context 'with a configured background that has no builder' do
    let(:background) { 'mystery' }

    before { allow(Dnd2024::Character).to receive(:backgrounds).and_return('mystery' => {}) }

    it 'returns the sheet unchanged' do
      expect(build).to eq(untouched)
    end
  end

  context 'without a background' do
    let(:background) { nil }

    it 'returns the sheet unchanged' do
      expect(build).to eq(untouched)
    end
  end
end
