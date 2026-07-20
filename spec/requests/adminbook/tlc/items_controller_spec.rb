# frozen_string_literal: true

describe 'Adminbook::Tlc::Items' do
  let(:valid_params) do
    { slug: 'journal', name: { en: 'Journal' }, kind: 'gear', modifiers: '{}', visibility: 'public', verified: '1' }
  end

  describe 'POST#create' do
    it 'persists a Tlc::Item, folding meta into the info column', :aggregate_failures do
      post '/adminbook/tlc/items', params: { item: valid_params.merge(visibility: 'hidden', verified: '0') }

      item = Item.tlc.find_by(slug: 'journal')
      expect(item).to be_present
      expect(item.kind).to eq('gear')
      expect(item.visibility).to eq('hidden')
      expect(item.verified?).to be(false)
    end
  end

  describe 'PATCH#update' do
    let!(:item) { create(:item, :tlc, slug: 'edit-item') }

    it 'edits name + visibility', :aggregate_failures do
      patch "/adminbook/tlc/items/#{item.id}", params: {
        item: valid_params.merge(slug: 'edit-item', name: { en: 'Renamed' }, visibility: 'deprecated')
      }

      item.reload
      expect(item.name['en']).to eq('Renamed')
      expect(item.visibility).to eq('deprecated')
    end
  end

  describe 'DELETE#destroy' do
    let!(:item) { create(:item, :tlc) }

    it 'removes the row' do
      expect { delete "/adminbook/tlc/items/#{item.id}" }.to change(Item.tlc, :count).by(-1)
    end
  end

  describe 'GET#index' do
    before { create(:item, :tlc, slug: 'listed-item') }

    it 'renders', :aggregate_failures do
      get '/adminbook/tlc/items'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('listed-item')
    end
  end
end
