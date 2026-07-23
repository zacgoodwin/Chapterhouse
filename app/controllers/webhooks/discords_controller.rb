# frozen_string_literal: true

module Webhooks
  class DiscordsController < ApplicationController
    include Deps[
      monitoring: 'monitoring.client',
      discord_client: 'api.discord.client'
    ]

    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate
    before_action :validate_discord_signature

    def create
      monitoring_discord_webhook
      send_callback unless params[:type] == 1
      params[:type] == 1 ? pong_response : interaction_response
    end

    private

    # rubocop: disable Layout/LineLength
    def send_callback
      discord_client.send_callback(
        interaction_id: params[:id],
        interaction_token: params[:token],
        params: {
          type: 4,
          data: {
            content: "#{params.dig(:member, :user, :global_name)} sends request `/#{params.dig(:data, :name)} #{params.dig(:data, :options, 0, :value)}`"
          }
        }
      )
    end
    # rubocop: enable Layout/LineLength

    def pong_response
      render json: { type: 1 }, status: :ok
    end

    def interaction_response
      head :accepted
    end

    def validate_discord_signature
      # A section without the key or a request without the headers must be a
      # 401, not a TypeError 500 — this endpoint is unauthenticated.
      return head :unauthorized if public_key.blank? || signature.blank? || timestamp.blank?

      verify_key = RbNaCl::VerifyKey.new([public_key].pack('H*'))
      verify_key.verify([signature].pack('H*'), "#{timestamp}#{body}")
    rescue RbNaCl::BadSignatureError, RbNaCl::LengthError => _e
      head :unauthorized
    end

    def monitoring_discord_webhook
      monitoring.notify(
        exception: Monitoring::ReceiveDiscordWebhook.new('Discord webhook is received'),
        metadata: { params: params.permit!.to_h },
        severity: :info
      )
    end

    def public_key = Rails.application.credentials.dig(Charkeeper.credentials_env, :discord_public_key)
    def signature = request.headers['X-Signature-Ed25519']
    def timestamp = request.headers['X-Signature-Timestamp']
    def body = request.body.string
  end
end
