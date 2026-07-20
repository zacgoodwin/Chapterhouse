# frozen_string_literal: true

# Namespaced (not bare top-level constants/methods) to avoid polluting the
# global constant table shared by every other spec file in the process --
# mirrors TlcDecoratorParity in tlc_decorator_spec.rb.
module TlcFormulaLintFixtures
  # feats.json and species_traits.json both map to Tlc::Feat (see B1's
  # Tlc::Seeder::FILE_MODELS); items.json maps to Tlc::Item. spells.json rows
  # carry no `modifiers` key (Tlc::Seeder#spell_columns), so it is excluded.
  MODIFIER_BEARING_STEMS = %w[feats species_traits items].freeze

  def self.modifier_files
    tlc_data_dir = Rails.root.join('db/data/tlc')
    MODIFIER_BEARING_STEMS.filter_map { |stem|
      path = tlc_data_dir.join("#{stem}.json")
      path if path.exist?
    }
  end

  def self.seeded_row_count
    modifier_files.sum { |path| JSON.parse(File.read(path)).size }
  end

  # value not a String means a numeric/literal 'set' value, not a Dentaku
  # formula -- nothing to parse.
  def self.unparseable_modifier_formulas(variables)
    modifier_files.flat_map { |path|
      JSON.parse(File.read(path)).flat_map { |row| row_failures(path, row, variables) }
    }
  end

  def self.row_failures(path, row, variables)
    (row['modifiers'] || {}).filter_map { |modifier_key, modifier|
      value = modifier['value']
      next unless value.is_a?(String)
      next if Formula.new.call(formula: value, variables: variables)

      "#{File.basename(path)} slug '#{row['slug']}' modifier '#{modifier_key}': #{value.inspect}"
    }
  end
end

# T3 (plan L682-685, decision 15), the 2am-Friday test (plan Test Review,
# section 6): every seeded TLC modifier formula must parse and evaluate
# cleanly. A bad formula that reaches production only fails at decorate time,
# skipped-and-logged per T3's rescue (spec/decorators_v2/formula_rescue_spec.rb)
# -- correct, but silent, and easy to miss until a player hits it at the
# table. This spec catches it in CI instead: it iterates every modifier
# formula across db/data/tlc/*.json (the B1 loader's content files,
# app/services/tlc/seeder.rb) and fails naming the exact file + slug + bad
# formula.
#
# db/data/tlc/ ships on B1 (ticket #12/#39) and real rows land on B4; neither
# is merged as of this ticket, so the guard below makes this a vacuous pass
# today with a clear skip message. Once B1/B4 land this spec covers every row
# automatically -- no wiring needed on the content side.
describe 'TLC seeded modifier formulas' do # rubocop: disable RSpec/DescribeClass
  if TlcFormulaLintFixtures.seeded_row_count.zero?
    it 'has no seeded TLC content yet (B1/B4 not merged into this branch) -- vacuous pass' do
      skip "db/data/tlc/{#{TlcFormulaLintFixtures::MODIFIER_BEARING_STEMS.join(',')}}.json missing/empty " \
           'in this worktree (see ticket #12); nothing to lint yet, covers every row automatically once seeded'
    end
  else
    it 'parses and evaluates every seeded modifier formula against a fixture character' do
      # One fixture character, fully decorated once, gives the exact variable
      # set (proficiency_bonus, level, ability modifiers, per-class levels,
      # ...) every seeded formula will actually see at the table -- pulled
      # from the real TlcDecorator#formula_variables instead of a hand-rolled
      # copy that could drift from production.
      character = create(
        :character, :tlc,
        'data' => {
          'level' => 4, 'species' => 'human', 'main_class' => 'bard',
          'classes' => { 'bard' => 4 }, 'subclasses' => { 'bard' => nil },
          'abilities' => { 'str' => 10, 'dex' => 10, 'con' => 10, 'int' => 10, 'wis' => 10, 'cha' => 10 },
          'speed' => 30
        }
      )
      variables = TlcDecorator.new.call(character: Character.find(character.id)).send(:formula_variables)
      failures = TlcFormulaLintFixtures.unparseable_modifier_formulas(variables)

      expect(failures).to(
        be_empty,
        -> { "#{failures.size} seeded TLC modifier formula(s) failed to parse/evaluate:\n#{failures.join("\n")}" }
      )
    end
  end
end
