# frozen_string_literal: true

module Web
  class DashboardsController < Web::BaseController
    include Authkeeper::ApplicationHelper

    rate_limit to: 10, within: 1.minute, by: -> { request.ip }, name: 'dashboard', only: :show

    layout 'charkeeper_app'

    def show
      @access_token = cookies[Authkeeper.configuration.access_token_name]
      @identities = current_user.identities.hashable_pluck(:id, :uid, :provider)
      @oauth_links = {
        google: omniauth_link(:google),
        discord: omniauth_link(:discord),
        yandex: omniauth_link(:yandex)
      }

      if Rails.env.production?
        @oauth_links[:yandex] = nil
      end
      if Rails.env.ru_production?
        @oauth_links[:google] = nil
        @oauth_links[:discord] = nil
      end
    end
  end
end
