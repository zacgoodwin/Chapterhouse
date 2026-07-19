# frozen_string_literal: true

module SupabaseApi
  module Requests
    module Broadcasts
      # server-side send to a Supabase Realtime broadcast channel without
      # holding a websocket; subscribers on the topic receive the event
      def broadcast(topic:, event:, payload:)
        post(
          path: 'realtime/v1/api/broadcast',
          body: { messages: [{ topic: topic, event: event, payload: payload }] },
          headers: headers
        )
      end
    end
  end
end
