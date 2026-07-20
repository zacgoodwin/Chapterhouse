# frozen_string_literal: true

# Ticket #33 (E2) acceptance test 2 — dnd2024 import path. Decision 37 widened the
# eval-exclusion rule to BOTH eval paths across BOTH providers, so the same smuggle
# must fail here: Import::Dnd2024::Feats::AddCommand's contract never declares the
# eval columns, so a smuggled value is stripped before create!. This guards the
# shared homebrew import surface against a regression that re-adds an eval field.
describe HomebrewsV2Context::Import::Dnd2024::Feats::AddCommand do
  subject(:command_call) { described_class.new.call(payload) }

  let(:user) { create :user }
  let(:payload) do
    {
      user: user,
      title: { en: 'Sneaky' },
      description: { en: 'A homebrew feat.' },
      origin: 'feat',
      origin_value: 'general',
      kind: 'static',
      level: 4,
      eval_variables: { 'flight' => 'system("rm -rf /")' },
      description_eval_variables: { 'value' => '`whoami`' },
      bonus_eval_variables: { 'ac' => 'exit' }
    }
  end

  it 'never persists a smuggled eval field', :aggregate_failures do
    expect { command_call }.to change(Dnd2024::Feat, :count).by(1)

    feat = command_call[:result]
    expect(feat.eval_variables).to eq({})
    expect(feat.description_eval_variables).to eq({})
    expect(feat.bonus_eval_variables).to be_nil
  end
end
