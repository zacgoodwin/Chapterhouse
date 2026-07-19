# frozen_string_literal: true

describe Adminbook::NotificationsController do
  describe 'POST#create' do
    let(:request) { post :create, params: { notification: { value: 'Value', locale: 'en', targets: 'discord' } } }

    it 'creates notification without delivery' do
      expect { request }.to change(Notification, :count).by(1)
    end
  end
end
