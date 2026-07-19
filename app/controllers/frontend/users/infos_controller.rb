# frozen_string_literal: true

module Frontend
  module Users
    class InfosController < Frontend::BaseController
      def show
        # platform marker used to be written at signin; supabase-js owns
        # signin now, so the SPA reports it with the first info fetch
        current_user.platforms.find_or_create_by!(name: params[:platform]) if params[:platform].present?

        render json: {
          locale: current_user.locale,
          username: current_user.username,
          admin: current_user.admin?,
          color_schema: current_user.color_schema,
          provider_locales: current_user.provider_locales
        }, status: :ok
      end
    end
  end
end
