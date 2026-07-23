# frozen_string_literal: true

module Web
  class BaseController < ApplicationController
    before_action :close_cookie_banner
    before_action :set_locale

    rescue_from ActionController::TooManyRequests, with: :too_many_requests
    rescue_from I18n::InvalidLocale, with: :page_not_found

    private

    def close_cookie_banner
      close_banner = params[:close_cookie_banner]
      return if close_banner.blank?

      cookies[:charkeeper_cookie_banner] = {
        value: 'clicked',
        domain: current_domain,
        expires: 1.year.from_now
      }.compact
    end

    def set_locale
      locale = params[:locale]&.to_sym
      I18n.locale =
        if I18n.available_locales.include?(locale)
          locale
        else
          current_locale
        end
    end

    def current_locale
      # A stale cookie (or user row) can still carry a dropped locale like :ru;
      # assigning it to I18n.locale would raise I18n::InvalidLocale.
      locale = current_user&.locale.presence&.to_sym || cookies[:charkeeper_locale].presence&.to_sym
      I18n.available_locales.include?(locale) ? locale : I18n.default_locale
    end

    def current_domain
      'charkeeper.org' if Rails.env.production?
    end

    def too_many_requests
      redirect_to too_many_requests_path
    end
  end
end
