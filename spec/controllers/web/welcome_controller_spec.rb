# frozen_string_literal: true

describe Web::WelcomeController do
  describe 'GET#index' do
    it 'returns data' do
      get :index

      expect(response).to have_http_status :ok
    end

    context 'with a stale locale cookie from a dropped locale' do
      it 'falls back to the default locale instead of raising I18n::InvalidLocale' do
        cookies[:charkeeper_locale] = 'ru'

        get :index

        expect(response).to have_http_status :ok
      end
    end

    context 'with rendered views' do
      render_views

      # english-only conversion removed the MacOS/Android/Firefox binary
      # download links (the binaries left public/). The page must render
      # without them but keep the extension source links.
      it 'renders without the removed download links', :aggregate_failures do
        get :index

        expect(response).to have_http_status :ok
        expect(response.body).not_to include('Charkeeper_aarch64.dmg')
        expect(response.body).not_to include('Charkeeper.apk')
        expect(response.body).not_to include('charkeeper-1.0.xpi')
        expect(response.body).not_to include('switch_locale')
        expect(response.body).to include('https://github.com/kortirso/charkeeper_mozext')
      end
    end
  end

  describe 'GET#privacy' do
    it 'returns data' do
      get :privacy

      expect(response).to have_http_status :ok
    end
  end

  describe 'GET#bot_commands' do
    it 'returns data' do
      get :bot_commands

      expect(response).to have_http_status :ok
    end
  end

  describe 'GET#tips' do
    it 'returns data' do
      get :tips

      expect(response).to have_http_status :ok
    end
  end

  describe 'GET#changelogs' do
    it 'returns data' do
      get :changelogs

      expect(response).to have_http_status :ok
    end
  end

  describe 'GET#too_many_requests' do
    it 'returns data' do
      get :too_many_requests

      expect(response).to have_http_status :ok
    end
  end
end
