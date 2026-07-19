# frozen_string_literal: true

module Web
  class HomebrewsController < Web::BaseController
    rate_limit to: 10, within: 1.minute, by: -> { request.ip }, name: 'homebrews', only: :show

    skip_before_action :authenticate

    layout 'homebrews_app'

    def show; end
  end
end
