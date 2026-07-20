# frozen_string_literal: true

module Adminbook
  class BaseController < ApplicationController
    include Pagy::Backend

    http_basic_authenticate_with name: Rails.application.credentials.admin&.fetch(:username, '') || '',
                                 password: Rails.application.credentials.admin&.fetch(:password, '') || '',
                                 if: -> { Rails.env.production? || Rails.env.ru_production? }

    skip_before_action :authenticate

    layout 'adminbook'

    private

    # Admin JSON textareas accept plain JSON, but also tolerate a legacy
    # Ruby-hash paste dialect (`=>` for `:`, bare `nil`). Parse as JSON first
    # so any valid JSON string value round-trips untouched — including one
    # whose text happens to contain the substring "nil" (e.g. "vanilla"),
    # which the old unconditional gsub silently mangled. Only rewrite to the
    # legacy dialect and retry when the first parse actually fails, so a
    # Ruby-hash-style paste (`{"a" => nil}`) still works.
    def parse_admin_json(value)
      JSON.parse(value.to_s)
    rescue JSON::ParserError
      JSON.parse(value.to_s.gsub(' =>', ':').gsub('nil', 'null'))
    end
  end
end
