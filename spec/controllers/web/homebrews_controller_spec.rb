# frozen_string_literal: true

describe Web::HomebrewsController do
  describe 'GET#show' do
    render_views

    # The Homebrews SPA shares the CharKeeperApp supabase-js session, so this
    # layout needs the same identity meta tags or the app renders logged out.
    it 'renders the Supabase identity meta tags', :aggregate_failures do
      get :show

      expect(response).to have_http_status :ok
      config = Rails.application.config.x.supabase
      expect(response.body).to include(%(<meta name="supabase-url" content="#{config.url}">))
      expect(response.body).to include(%(<meta name="supabase-anon-key" content="#{config.anon_key}">))
    end
  end
end
