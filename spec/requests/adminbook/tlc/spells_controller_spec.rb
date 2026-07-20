# frozen_string_literal: true

describe 'Adminbook::Tlc::Spells' do
  let(:valid_params) do
    { slug: 'leyward', name: { en: 'Leyward' }, data: '{"level":1}', visibility: 'public', verified: '1' }
  end

  describe 'POST#create' do
    it 'persists a Tlc::Spell, folding meta into the data column while keeping gameplay data', :aggregate_failures do
      post '/adminbook/tlc/spells', params: { spell: valid_params.merge(visibility: 'locked', verified: '0') }

      spell = Spell.tlc.find_by(slug: 'leyward')
      expect(spell).to be_present
      expect(spell.data['level']).to eq(1)
      expect(spell.visibility).to eq('locked')
      expect(spell.verified?).to be(false)
    end
  end

  describe 'PATCH#update' do
    let!(:spell) { create(:spell, :tlc, slug: 'edit-spell') }

    it 'edits name + visibility', :aggregate_failures do
      patch "/adminbook/tlc/spells/#{spell.id}", params: {
        spell: valid_params.merge(slug: 'edit-spell', name: { en: 'Renamed' }, visibility: 'deprecated')
      }

      spell.reload
      expect(spell.name['en']).to eq('Renamed')
      expect(spell.visibility).to eq('deprecated')
    end
  end

  describe 'DELETE#destroy' do
    let!(:spell) { create(:spell, :tlc) }

    it 'removes the row' do
      expect { delete "/adminbook/tlc/spells/#{spell.id}" }.to change(Spell.tlc, :count).by(-1)
    end
  end

  describe 'GET#index' do
    before { create(:spell, :tlc, slug: 'listed-spell') }

    it 'renders', :aggregate_failures do
      get '/adminbook/tlc/spells'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('listed-spell')
    end
  end
end
