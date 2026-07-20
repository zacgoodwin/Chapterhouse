# frozen_string_literal: true

# T3 (plan L682-685, decision 15): app/lib/formula.rb is the single Dentaku
# entrypoint for every add|set|concat modifier across dnd2024 and tlc. A bad
# formula in seeded/homebrew content must never raise out of here -- callers
# (Dnd2024Decorator, inherited by TlcDecorator) treat a nil return as "skip
# this modifier, log it" instead of letting the sheet 500. This spec pins
# that contract directly against Formula, independent of any decorator.
describe Formula do
  subject(:call) { described_class.new.call(formula: formula, variables: variables) }

  let(:variables) { { level: 4, str: 2 } }

  context 'with a valid formula' do
    let(:formula) { 'level + str' }

    it 'evaluates normally' do
      expect(call).to eq 6
    end
  end

  context 'with an unparseable formula (Dentaku::ParseError)' do
    let(:formula) { '1 +' }

    it 'returns nil instead of raising' do
      expect(call).to be_nil
    end
  end

  context 'with a formula referencing an unbound variable (Dentaku::UnboundVariableError)' do
    let(:formula) { 'leyfarer_rank_that_does_not_exist' }

    it 'returns nil instead of raising' do
      expect(call).to be_nil
    end
  end

  context 'with garbage input a hand-authored JSON row could plausibly contain' do
    # Each of these was fuzzed against the real Dentaku::Calculator#evaluate
    # (dentaku 3.5.7) and confirmed to already return nil rather than raise --
    # this locks that in as a spec instead of an assumption about gem
    # internals (see app/lib/formula.rb's comment on Formula#call).
    [
      ['unbalanced parens', '((1'],
      ['undefined function', 'undefined_func(1)'],
      ['wrong arg count', 'if(1, 2)'],
      ['divide by zero', '1 / 0'],
      ['zero-sided die', 'd(0)'],
      ['type mismatch', '"abc" + 1']
    ].each do |label, bad_formula|
      context "with #{label} (#{bad_formula.inspect})" do
        let(:formula) { bad_formula }
        let(:variables) { {} }

        it 'returns nil instead of raising' do
          expect(call).to be_nil
        end
      end
    end
  end
end
