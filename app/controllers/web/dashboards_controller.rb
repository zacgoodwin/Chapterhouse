# frozen_string_literal: true

module Web
  class DashboardsController < Web::BaseController
    rate_limit to: 10, within: 1.minute, by: -> { request.ip }, name: 'dashboard', only: :show

    # unauthenticated SPA shell: the client holds the Supabase session and
    # shows LoginPage when there is none
    skip_before_action :authenticate

    layout 'charkeeper_app'

    def show; end
  end
end
