# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
# require 'rails/test_unit/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Charkeeper
  # Which credentials section (db/supabase/storage) this process reads.
  # Defaults to RAILS_ENV; the dev Fly app runs RAILS_ENV=production with
  # CREDENTIALS_ENV=development to get production behavior on dev data.
  # A typo must fail loudly at boot, not silently dig a nil section.
  CREDENTIALS_ENVS = %w[production development test local_production].freeze

  def self.credentials_env
    env = ENV['CREDENTIALS_ENV'].presence || Rails.env
    raise ArgumentError, "unknown CREDENTIALS_ENV #{env.inspect}" unless CREDENTIALS_ENVS.include?(env.to_s)

    # The dev Fly app must never fall through to the production section: a
    # dropped CREDENTIALS_ENV line would point it (and its release-step
    # db:migrate) at the prod database. FLY_APP_NAME is injected by Fly.
    if ENV['FLY_APP_NAME'] == 'chapterhouse-dev' && env.to_s == 'production'
      raise ArgumentError, 'chapterhouse-dev resolved the production credentials section — is CREDENTIALS_ENV missing?'
    end

    env.to_sym
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.active_job.queue_adapter = :good_job

    config.middleware.use Rack::Deflater
    # Rack::Brotli goes directly under Rack::Deflater, if Rack::Deflater is present
    config.middleware.use Rack::Brotli

    I18n.available_locales = %i[en]
    config.i18n.default_locale = :en

    config.time_zone = 'UTC'

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.generators.system_tests = nil
    config.generators do |g|
      g.test_framework :rspec, fixtures: true, views: false, view_specs: false, helper_specs: false,
                               routing_specs: false, controller_specs: false, request_specs: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.stylesheets false
      g.javascripts false
      g.helper false

      g.orm :active_record, primary_key_type: :uuid
    end
    #
    # config.time_zone = 'Central Time (US & Canada)'
    # config.eager_load_paths << Rails.root.join('extras')

    # Don't generate system test files.
    config.generators.system_tests = nil

    # config.hosts << 'sklh4i-2001-41d0-800-4d0f--.nl.tuna.am'


    # Catch 404s
    config.after_initialize do |app|
      app.routes.append do
        match '*path', to: 'application#not_found', via: :all
      end
    end
  end
end
