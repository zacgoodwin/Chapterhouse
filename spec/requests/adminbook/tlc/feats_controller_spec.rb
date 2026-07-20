# frozen_string_literal: true

# Request specs for the TLC feats admin (ticket #32). Auth is HTTP Basic on
# Adminbook::BaseController, gated to production/ru_production — in the test env
# it is off, so the CRUD examples run unauthenticated and the 401 example stubs
# the env to prove the gate is inherited.
describe 'Adminbook::Tlc::Feats' do
  let(:valid_params) do
    {
      slug: 'stoneheart', origin: 'species', origin_value: 'turtlefolk', kind: 'static',
      title: { en: 'Stoneheart' }, description: { en: 'Your skin is stone.' },
      conditions: '{}', price: '{}', visibility: 'public', verified: '1'
    }
  end

  describe 'POST#create' do
    it 'persists a Tlc::Feat but writes NEITHER eval field posted in the payload (T18)', :aggregate_failures do
      post '/adminbook/tlc/feats', params: {
        feat: valid_params.merge(
          eval_variables: '{"rce":"1"}',
          description_eval_variables: '{"rce":"2"}',
          bonus_eval_variables: '{"rce":"3"}'
        )
      }

      feat = Tlc::Feat.find_by(slug: 'stoneheart')
      expect(feat).to be_present
      expect(feat.title['en']).to eq('Stoneheart')
      expect(feat.eval_variables).to eq({})
      expect(feat.description_eval_variables).to eq({})
      expect(feat.bonus_eval_variables).to be_blank
    end

    it 'folds visibility + verified into the info meta column', :aggregate_failures do
      post '/adminbook/tlc/feats', params: { feat: valid_params.merge(visibility: 'locked', verified: '0') }

      feat = Tlc::Feat.find_by(slug: 'stoneheart')
      expect(feat.visibility).to eq('locked')
      expect(feat.verified?).to be(false)
    end
  end

  describe 'PATCH#update' do
    let!(:feat) { create(:feat, :tlc, slug: 'edit-me', title: { 'en' => 'Old' }) }

    it 'edits content + meta and still refuses eval fields', :aggregate_failures do
      patch "/adminbook/tlc/feats/#{feat.id}", params: {
        feat: valid_params.merge(slug: 'edit-me', title: { en: 'Renamed' }, visibility: 'hidden', verified: '0',
                                 eval_variables: '{"rce":"9"}')
      }

      feat.reload
      expect(feat.title['en']).to eq('Renamed')
      expect(feat.visibility).to eq('hidden')
      expect(feat.verified?).to be(false)
      expect(feat.eval_variables).to eq({})
    end
  end

  describe 'DELETE#destroy' do
    let!(:feat) { create(:feat, :tlc) }

    it 'removes the row' do
      expect { delete "/adminbook/tlc/feats/#{feat.id}" }.to change(Tlc::Feat, :count).by(-1)
    end
  end

  describe 'GET#index ?verified=false (verification queue)' do
    before do
      create(:feat, :tlc, slug: 'clean-row')
      create(:feat, :tlc, slug: 'garbled-row').update!(verified: false)
    end

    it 'lists only the unverified rows', :aggregate_failures do
      get '/adminbook/tlc/feats', params: { verified: 'false' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('garbled-row')
      expect(response.body).not_to include('clean-row')
    end

    it 'lists everything without the filter', :aggregate_failures do
      get '/adminbook/tlc/feats'

      expect(response.body).to include('garbled-row')
      expect(response.body).to include('clean-row')
    end
  end

  describe 'auth (HTTP Basic inherited from Adminbook::BaseController)' do
    it 'returns 401 without credentials once the production gate is active', :aggregate_failures do
      allow(Rails.env).to receive(:production?).and_return(true)

      get '/adminbook/tlc/feats'
      expect(response).to have_http_status(:unauthorized)

      get '/adminbook/tlc/spells'
      expect(response).to have_http_status(:unauthorized)

      get '/adminbook/tlc/items'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
