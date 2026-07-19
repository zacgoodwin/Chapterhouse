# frozen_string_literal: true

module BotContext
  module Channels
    class SendToCampaignJob < ApplicationJob
      queue_as :default

      retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

      def perform(campaign_id, text)
        Charkeeper::Container.resolve('api.supabase.client').broadcast(
          topic: "campaign:#{campaign_id}",
          event: 'message',
          payload: { message: text }
        )
      end
    end
  end
end
