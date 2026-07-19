# frozen_string_literal: true

module Web
  module Campaigns
    class JoinsController < Web::BaseController
      layout 'charkeeper_app'

      skip_before_action :authenticate
      before_action :find_campaign, only: %i[show]

      def show; end

      private

      def find_campaign
        @campaign = Campaign.find(params.expect(:campaign_id))
      end
    end
  end
end
