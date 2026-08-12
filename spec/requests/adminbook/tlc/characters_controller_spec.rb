# frozen_string_literal: true

# #53: mirrors spec/requests/adminbook/dnd2024/characters_controller_spec.rb --
# the TLC adminbook block had feats/spells/items only, so TLC characters were
# invisible in adminbook. Fails if config/routes.rb's `namespace :tlc` block or
# Adminbook::Tlc::CharactersController goes missing.
describe 'Adminbook::Tlc::Characters' do
  describe 'GET#index' do
    context 'without characters' do
      it 'renders index page' do
        get '/adminbook/tlc/characters'

        expect(response).to have_http_status :ok
      end
    end

    context 'with characters' do
      let!(:character1) { create :character, :dnd2024 }
      let!(:character2) { create :character, :tlc }

      it 'renders index page, scoped strictly to Tlc::Character', :aggregate_failures do
        get '/adminbook/tlc/characters'

        expect(response).to have_http_status :ok
        expect(response.body).not_to include(character1.name)
        expect(response.body).to include(character2.name)
      end
    end
  end

  # There is no per-user admin role in this codebase (see
  # spec/requests/adminbook/tlc/feats_controller_spec.rb): "non-admin" is
  # whoever fails the HTTP Basic gate Adminbook::BaseController applies in
  # production. Off in test env by default, stubbed here like the sibling
  # feats/spells/items admin specs.
  describe 'auth (HTTP Basic inherited from Adminbook::BaseController)' do
    it 'returns 401 without credentials once the production gate is active' do
      allow(Rails.env).to receive(:production?).and_return(true)

      get '/adminbook/tlc/characters'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
