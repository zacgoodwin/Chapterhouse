# frozen_string_literal: true

describe Adminbook::Users::NotificationsController do
  describe 'POST#create' do
    let!(:user) { create :user }

    context 'for invalid params' do
      let(:request) { post :create, params: { notification: { title: '', value: '', user_id: nil } } }

      it 'does not create notification' do
        expect { request }.not_to change(User::Notification, :count)
      end
    end

    context 'for valid params' do
      let(:request) { post :create, params: { notification: { title: 'Title', value: 'Value', user_id: user.id } } }

      it 'creates notification' do
        expect { request }.to change(user.notifications, :count).by(1)
      end
    end
  end
end
