# frozen_string_literal: true

# Sweeps every concrete character builder (class/species/background/legacy/race/
# subrace) against the invariants the create commands rely on: builders receive the
# hash a BaseBuilder produced and return it, and the collections they append to stay
# duplicate-free even when the value is already present (a missing `.uniq` shows up
# on a character sheet as a doubled proficiency).
#
# CustomBuilders read a homebrew record out of the database, so they are covered by
# the dispatcher specs instead.
concrete_builders =
  Rails.root.glob('app/builders/*_character/*/*_builder.rb')
       .reject { |path| path.basename('.rb').to_s == 'custom_builder' }
       .map { |path| path.relative_path_from(Rails.root / 'app/builders').to_s.delete_suffix('.rb').camelize }
       .sort

describe 'character builder contract' do # rubocop: disable RSpec/DescribeClass
  concrete_builders.each do |builder_name|
    describe builder_name do
      subject(:build) { described_builder.new.call(result: base_result) }

      let(:base_results) do
        {
          'Dnd2024Character' => { main_class: 'bard', species: 'elf', legacy: 'drow', background: 'acolyte' },
          'Dnd5Character' => { main_class: 'monk', race: 'dwarf', subrace: 'stout' },
          'TlcCharacter' => { main_class: 'paladin', species: 'elf', legacy: 'drow', background: 'acolyte' }
        }
      end
      let(:collection_keys) do
        %i[
          weapon_core_skills weapon_skills weapon_mastery armor_proficiency languages tools music
          resistance immunity vulnerability selected_feats
        ]
      end
      let(:described_builder) { builder_name.constantize }
      let(:provider) { builder_name.split('::').first }
      let(:base_result) { "#{provider}::BaseBuilder".constantize.new.call(result: base_results.fetch(provider)) }

      it 'returns the sheet it was given' do
        expect(build).to be_a(Hash).and include(main_class: base_result[:main_class])
      end

      it 'leaves no duplicates in the collections it appends to' do
        collections = build.slice(*collection_keys).select { |_key, value| value.is_a?(Array) }

        expect(collections).to eq(collections.transform_values(&:uniq))
      end

      it 'is idempotent for the collections it appends to' do
        first = described_builder.new.call(result: base_result).slice(*collection_keys).deep_dup
        second = described_builder.new.call(result: base_result).slice(*collection_keys)

        expect(second).to eq(first)
      end

      it 'keeps health and abilities well formed when it assigns them', :aggregate_failures do
        expect(build[:health]).to include(temp: 0, current: build.dig(:health, :max)) if build[:health]

        if build[:abilities]
          expect(build[:abilities].keys).to contain_exactly(:str, :dex, :con, :int, :wis, :cha)
          expect(build[:abilities].values).to all(be_between(1, 20))
        end
      end
    end
  end
end
