# frozen_string_literal: true

# Replaces Authkeeper::Controllers::Authentication with the same public
# surface (authenticate / current_user / authentication_error) so the
# controller tree stays untouched. The bearer token is a Supabase Auth
# access token; users.id == auth.users.id (the JWT sub claim).
module SupabaseAuthentication
  extend ActiveSupport::Concern

  UUID_PATTERN = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  included do
    before_action :set_current_user

    helper_method :current_user
  end

  private

  def set_current_user
    token = bearer_token.presence || params[:charkeeper_access_token].presence
    return unless token

    verification = verify_supabase_token.call(token: token)
    return if verification[:errors].present?

    @current_user = find_or_provision_user(verification[:result])
  end

  def current_user = @current_user

  def authenticate
    return if current_user

    authentication_error
  end

  def authentication_error
    redirect_to root_path
  end

  def bearer_token
    pattern = /^Bearer /
    header = request.headers['Authorization']
    header.gsub(pattern, '') if header&.match(pattern)
  end

  def find_or_provision_user(payload)
    sub = payload['sub'].to_s
    return unless UUID_PATTERN.match?(sub)

    user = User.find_by(id: sub)
    return user if user && user.discarded_at.nil?
    return if user # discarded users stay signed out

    provision_user(payload, sub)
  end

  def provision_user(payload, sub)
    username = payload.dig('user_metadata', 'name').presence || payload['email'].to_s.split('@').first.presence
    return unless username

    result = add_user_command.call(id: sub, username: username)
    return result[:result] if result[:result]

    # id collision means a concurrent first request provisioned it;
    # username collision gets one retry with a unique suffix
    User.find_by(id: sub) || add_user_command.call(id: sub, username: "#{username}_#{sub.first(8)}")[:result]
  end

  def verify_supabase_token = Charkeeper::Container.resolve('services.auth_context.verify_supabase_token')
  def add_user_command = Charkeeper::Container.resolve('commands.auth_context.add_user')
end
