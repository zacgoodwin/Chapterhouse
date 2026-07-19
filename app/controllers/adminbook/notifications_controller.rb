# frozen_string_literal: true

module Adminbook
  class NotificationsController < Adminbook::BaseController
    def index
      @pagy, @notifications = pagy(Notification.order(created_at: :desc), limit: 25)
    end

    def new
      @notification = Notification.new
    end

    def create
      Notification.new(transform_params(notification_params)).save
      redirect_to adminbook_notifications_path
    end

    private

    def transform_params(updating_params)
      updating_params['targets'] = updating_params['targets'].split(',')
      updating_params
    end

    def notification_params
      params.require(:notification).permit!.to_h
    end
  end
end
