# frozen_string_literal: true

describe Frontend::Users::MonitoringController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  before { allow(Charkeeper::Container.resolve('monitoring.client')).to receive(:notify) }

  describe 'POST#create' do
    context 'for logged users' do
      let(:request) do
        post :create, params: { payload: { value: 'feedback' }, charkeeper_access_token: access_token }
      end

      it 'runs monitoring service', :aggregate_failures do
        request

        expect(Charkeeper::Container.resolve('monitoring.client')).to have_received(:notify)
        expect(response).to have_http_status :ok
      end
    end
  end
end
