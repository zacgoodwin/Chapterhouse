# frozen_string_literal: true

# Ticket #33 (E2) acceptance test 2 — TLC import path. A homebrew feat payload
# that smuggles the three raw-Ruby-`eval`'d columns (eval_variables,
# description_eval_variables, bonus_eval_variables — Dnd2024Decorator#eval_variable
# L448) must NEVER persist them: the contract does not declare them, so
# dry-validation strips them before create!. Even a legitimate per-use `limit`
# routes into info, not description_eval_variables, so every eval field stays at
# its empty/nil default (plan T4 widened by decision 37).
describe HomebrewsV2Context::Import::Tlc::Feats::AddCommand do
  subject(:command_call) { described_class.new.call(payload) }

  let(:user) { create :user }
  let(:base_payload) do
    {
      user: user,
      title: { en: 'Adaptive Mycelia' },
      description: { en: 'A homebrew feat.' },
      origin: 'feat',
      origin_value: 'general',
      kind: 'static',
      level: 4
    }
  end

  context 'when the payload smuggles eval fields' do
    let(:payload) do
      base_payload.merge(
        eval_variables: { 'flight' => 'system("rm -rf /")' },
        description_eval_variables: { 'value' => '`whoami`' },
        bonus_eval_variables: { 'ac' => 'exit' }
      )
    end

    it 'creates the row with all eval fields empty/nil', :aggregate_failures do
      expect { command_call }.to change(Tlc::Feat, :count).by(1)

      feat = command_call[:result]
      expect(feat.eval_variables).to eq({})
      expect(feat.description_eval_variables).to eq({})
      expect(feat.bonus_eval_variables).to be_nil
    end
  end

  context 'when the payload carries a legitimate per-use limit' do
    let(:payload) { base_payload.merge(limit: 3, limit_refresh: 'long_rest') }

    it 'stores the limit in info, keeping every eval field empty', :aggregate_failures do
      command_call
      feat = Tlc::Feat.last

      expect(feat.info['limit']).to eq 3
      expect(feat.description_eval_variables).to eq({})
      expect(feat.eval_variables).to eq({})
      expect(feat.bonus_eval_variables).to be_nil
    end
  end
end
