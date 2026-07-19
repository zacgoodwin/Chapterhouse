# frozen_string_literal: true

module SupabaseApi
  class Client < HttpService::Client
    include Requests::Broadcasts

    option :url, default: proc { Rails.application.config.x.supabase.url }

    private

    def headers
      key = Rails.application.config.x.supabase.service_role_key
      {
        'Content-type' => 'application/json',
        'apikey' => key,
        'Authorization' => "Bearer #{key}"
      }
    end
  end
end
