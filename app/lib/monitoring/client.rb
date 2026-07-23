# frozen_string_literal: true

module Monitoring
  ReceiveDiscordWebhook = Class.new(StandardError)
  ValidationError = Class.new(StandardError)
  FrontendError = Class.new(StandardError)
  FeatVariableError = Class.new(StandardError)
  FormulaError = Class.new(StandardError)
  TooManyRequestsError = Class.new(StandardError)

  class Client
    include Deps[provider: 'monitoring.providers.rails']

    def notify(exception:, metadata: {}, severity: nil)
      return unless Rails.env.production?

      provider.notify(exception: exception, metadata: metadata, severity: severity)
    end
  end
end
