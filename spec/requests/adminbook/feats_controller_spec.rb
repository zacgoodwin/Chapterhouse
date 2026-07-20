# frozen_string_literal: true

# Request specs for the base adminbook feats admin (ticket #41). Auth is HTTP
# Basic on Adminbook::BaseController, gated to production/ru_production — in
# the test env it is off, so these run unauthenticated (see
# spec/requests/adminbook/tlc/feats_controller_spec.rb for the 401 coverage).
describe 'Adminbook::Feats' do
  let(:valid_params) do
    {
      slug: 'vanilla-round-trip', origin: 'feat', origin_value: '', kind: 'static', exclude: '', limit_refresh: '',
      title: { en: 'Vanilla' }, description: { en: 'Desc' },
      bonus_eval_variables: '{}', description_eval_variables: '{}', eval_variables: '{}', options: '{}',
      conditions: '{}', price: '{}', info: '{}'
    }
  end

  describe 'JSON textarea dialect (ticket #41: gsub("nil", "null") corrupted string values)' do
    it 'round-trips a JSON string value that contains the substring "nil" byte-identical', :aggregate_failures do
      post '/adminbook/feats', params: {
        provider: 'dnd2024', feat: valid_params.merge(conditions: '{"note":"vanilla extract, nil-safe"}')
      }

      feat = Dnd2024::Feat.find_by(slug: 'vanilla-round-trip')
      expect(feat).to be_present
      expect(feat.conditions).to eq('note' => 'vanilla extract, nil-safe')
    end

    it 'still parses a pasted Ruby-hash-style value with a bare nil (legacy fallback)', :aggregate_failures do
      post '/adminbook/feats', params: {
        provider: 'dnd2024', feat: valid_params.merge(price: '{"a" => nil}')
      }

      feat = Dnd2024::Feat.find_by(slug: 'vanilla-round-trip')
      expect(feat).to be_present
      expect(feat.price).to eq('a' => nil)
    end
  end
end
