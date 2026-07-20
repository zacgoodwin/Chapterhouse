# frozen_string_literal: true

# Gate tests for db/data/tlc/resources.json (ticket C8: TLC subclass resource
# seeding). Pure data/shape checks -- no DB, no character fixtures. The
# formula-evaluates-for-real behavior lives in
# spec/services/characters_context/tlc/refresh_resources_spec.rb.
describe 'TLC subclass resource definitions (db/data/tlc/resources.json)' do # rubocop: disable RSpec/DescribeClass
  let(:expected_subclasses) do
    %w[
      sunforge path_of_the_primordial college_of_calamity rune_priest frog_knight
      way_of_the_twisting_hand oath_of_the_ivory_knight ghostscale_reaver gambler
      mirage lady_of_ivory technomancer
    ]
  end
  let(:known_cadences) { %w[short long session] }
  let(:entries) { CharactersContext::Tlc::RefreshResources.definitions }
  let(:all_resources) { entries.flat_map { |entry| entry['resources'] } }

  it 'has a definition entry for all 12 TLC subclasses (plan Phase B2 roster)' do
    expect(entries.pluck('subclass')).to match_array(expected_subclasses)
  end

  it 'every entry names the owning class' do
    expect(entries.pluck('class')).to all(be_present)
  end

  it 'resource slugs are globally unique' do
    slugs = all_resources.pluck('slug')

    expect(slugs).to match_array(slugs.uniq)
  end

  describe 'each resource definition' do
    it 'has exactly one of max_formula / max_value', :aggregate_failures do
      all_resources.each do |resource|
        has_formula = resource['max_formula'].present?
        has_static = !resource['max_value'].nil?

        expect(has_formula ^ has_static).to be(true), "#{resource['slug']}: expected exactly one of max_formula/max_value"
      end
    end

    it 'has a valid reset_direction (0 or 1)', :aggregate_failures do
      all_resources.each do |resource|
        expect(resource['reset_direction']).to be_in([0, 1]), resource['slug']
      end
    end

    it 'has a non-empty resets hash using only known cadence keys', :aggregate_failures do
      all_resources.each do |resource|
        expect(resource['resets']).to be_present, resource['slug']
        expect(resource['resets'].keys).to all(be_in(known_cadences)), resource['slug']
      end
    end

    it 'has a display_hint', :aggregate_failures do
      all_resources.each do |resource|
        expect(resource['display_hint']).to be_present, resource['slug']
      end
    end

    it 'every max_formula parses under Dentaku against a representative variable set', :aggregate_failures do
      variables = {
        proficiency_bonus: 4, str: 1, dex: 1, con: 1, int: 1, wis: 1, cha: 1,
        artificer_level: 9, barbarian_level: 9, bard_level: 9, cleric_level: 9, druid_level: 9,
        fighter_level: 9, monk_level: 9, paladin_level: 9, ranger_level: 9, rogue_level: 9,
        sorcerer_level: 9, warlock_level: 9, wizard_level: 9
      }
      calculator = Formula.new

      all_resources.select { |resource| resource['max_formula'].present? }.each do |resource|
        result = calculator.call(formula: resource['max_formula'], variables: variables)

        expect(result).not_to be_nil, "#{resource['slug']}: #{resource['max_formula']} failed to evaluate"
      end
    end
  end

  # The one Section-9-named acceptance pin (players-guide-digest.md L51-57):
  # Rune Priest / Divine Code / Lucky Number / Sunshard / Dumb Luck / Ghost
  # Shroud / Hedge Your Bets are the seven named pools; every other subclass
  # is intentionally empty (choice/toggle mechanics, or -- Mirage -- an
  # unscoped scaling rule the digest itself excludes from the counters list).
  it 'seeds exactly the seven Section-9-named pools' do
    expect(all_resources.pluck('slug')).to contain_exactly(
      'sunforge_infusion_slots', 'college_of_calamity_dumb_luck', 'rune_priest_runes',
      'ghostscale_reaver_ghost_shroud', 'gambler_lucky_number', 'gambler_hedge_your_bets',
      'technomancer_divine_code'
    )
  end
end
