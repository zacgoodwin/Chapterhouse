# frozen_string_literal: true

module Adminbook
  module Users
    class NotificationsController < Adminbook::BaseController
      def index
        @pagy, @notifications = pagy(User::Notification.order(created_at: :desc), limit: 25)
      end

      def new
        @notification = User::Notification.new
      end

      def edit
        @notification = User::Notification.find(params.expect(:id))
      end

      def create
        User::Notification.new(notification_params).save
        redirect_to adminbook_users_notifications_path
      end

      def update
        notification = User::Notification.find(params.expect(:id))
        notification.update(notification_params)
        redirect_to adminbook_users_notifications_path
      end

      def destroy
        notification = User::Notification.find(params.expect(:id))
        notification.destroy
        redirect_to adminbook_users_notifications_path
      end

      private

      def notification_params
        params.require(:notification).permit!.to_h
      end
    end
  end
end
