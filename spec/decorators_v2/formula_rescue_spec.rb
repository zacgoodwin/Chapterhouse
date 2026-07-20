# frozen_string_literal: true

# T3 (plan L682-685, decision 15): a bad Dentaku formula in seeded/homebrew
# content must not 500 the sheet. Dnd2024Decorator (inherited unchanged by
# TlcDecorator -- it is still an empty subclass, see tlc_decorator_spec.rb)
# rescues per modifier: log slug + formula + character id + provider, skip
# that modifier only, the rest of the sheet still renders. This spec
# exercises the rescue through the real decorator pipeline for both an
# unparseable and an unbound-variable formula, and proves it is
# provider-agnostic: same behavior for a tlc character and a dnd2024 one,
# because the rescue lives in the shared Dnd2024Decorator code path, not a
# tlc-only override (acceptance criterion 4 -- rescue does not alter stock
# dnd2024 paths, proved separately by the untouched dnd2024_decorator_spec.rb
# staying green).
# Namespaced (not bare top-level constants) to avoid polluting the global
# constant table shared by every other spec file in the process -- mirrors
# TlcDecoratorParity in tlc_decorator_spec.rb.
module FormulaRescueFixtures
  SCENARIOS = [
    { label: 'tlc', decorator: TlcDecorator, character_trait: :tlc, feat_trait: :tlc, provider: 'tlc' },
    { label: 'dnd2024', decorator: Dnd2024Decorator, character_trait: :dnd2024, feat_trait: :dnd2024, provider: 'dnd2024' }
  ].freeze

  BAD_FORMULAS = {
    'an unparseable formula (Dentaku::ParseError)' => '1 +',
    'an unbound-variable formula (Dentaku::UnboundVariableError)' => 'nonexistent_variable_xyz'
  }.freeze
end

describe 'Dentaku formula rescue-and-log' do # rubocop: disable RSpec/DescribeClass
  let(:monitoring_client) { Charkeeper::Container.resolve('monitoring.client') }

  before { allow(monitoring_client).to receive(:notify) }

  FormulaRescueFixtures::SCENARIOS.each do |scenario|
    context "for a #{scenario[:label]} character" do
      let!(:character) { create(:character, scenario[:character_trait]) }
      # dex 16 -> ability modifier (16 / 2) - 5 = 3; base initiative before any
      # feat bonus is applied, per Dnd2024Decorator#calculate_secondary_abilities.
      let(:base_initiative) { 3 }

      FormulaRescueFixtures::BAD_FORMULAS.each do |description, bad_formula|
        context "with #{description}" do
          let!(:feat) {
            create :feat, scenario[:feat_trait], slug: 'broken-initiative-feat', modifiers: {
              'initiative' => { 'type' => 'add', 'value' => bad_formula }
            }
          }

          before { create :character_feat, feat: feat, character: character, ready_to_use: true }

          it 'renders the sheet without raising, omitting only the broken modifier', :aggregate_failures do
            result = nil
            expect {
              result = scenario[:decorator].new.call(character: Character.find(character.id))
            }.not_to raise_error

            # the broken feat contributes nothing; initiative stays at its
            # unmodified base instead of the sheet 500ing or the field
            # vanishing entirely
            expect(result.initiative).to eq base_initiative
            # the rest of the sheet still computed normally
            expect(result.armor_class).to be_a(Integer)
            expect(result.features).not_to be_empty
          end

          it 'logs slug + formula + character_id + provider', :aggregate_failures do
            scenario[:decorator].new.call(character: Character.find(character.id))

            expect(monitoring_client).to have_received(:notify).with(
              exception: an_instance_of(Monitoring::FormulaError),
              metadata: {
                slug: 'broken-initiative-feat',
                formula: bad_formula,
                character_id: character.id,
                provider: scenario[:provider]
              },
              severity: :info
            )
          end
        end
      end
    end
  end
end
