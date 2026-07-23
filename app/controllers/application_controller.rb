# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include SupabaseAuthentication

  append_view_path Rails.root.join('app/views/controllers')

  authorize :user, through: :current_user

  before_action :authenticate, except: %i[not_found]
  before_action :set_locale
  before_action do
    Rails.error.set_context(
      request_url: request.original_url,
      params: request.filtered_parameters.inspect,
      session: session.inspect
    )
  end

  rescue_from ActiveRecord::RecordNotFound, with: :page_not_found
  rescue_from ActionPolicy::Unauthorized, with: :access_denied

  def not_found = page_not_found

  # https://github.com/dry-rb/dry-auto_inject/issues/91
  def initialize = super # rubocop: disable Style/RedundantInitialize

  private

  def page_not_found
    render template: 'web/shared/404', status: :not_found, formats: [:html]
  end

  def set_locale
    I18n.locale = current_user ? user_locale : I18n.default_locale
  end

  def user_locale
    # Guard against a stale locale value (e.g. :ru) raising I18n::InvalidLocale.
    locale = current_user.locale&.to_sym
    I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  end
end
