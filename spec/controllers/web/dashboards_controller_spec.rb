# frozen_string_literal: true

describe Web::DashboardsController do
  describe 'GET#show' do
    render_views

    # The SPA reads the Supabase project identity from these meta tags at
    # runtime (helpers/supabase.jsx); without them browser login is dead.
    it 'renders the Supabase identity meta tags', :aggregate_failures do
      get :show

      expect(response).to have_http_status :ok
      config = Rails.application.config.x.supabase
      expect(response.body).to include(%(<meta name="supabase-url" content="#{config.url}">))
      expect(response.body).to include(%(<meta name="supabase-anon-key" content="#{config.anon_key}">))
    end
  end
end
