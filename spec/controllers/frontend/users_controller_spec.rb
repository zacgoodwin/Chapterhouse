# frozen_string_literal: true

describe Frontend::UsersController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  describe 'PATCH#update' do
    context 'for logged users' do
      it 'updates user', :aggregate_failures do
        patch :update, params: { user: { locale: 'en' }, charkeeper_access_token: access_token }

        expect(response).to have_http_status :ok
        expect(user.reload.locale).to eq 'en'
      end

      context 'for empty request' do
        it 'returns error', :aggregate_failures do
          patch :update, params: { user: { locale: '' }, charkeeper_access_token: access_token }

          expect(response).to have_http_status :unprocessable_content
          expect(response.parsed_body['errors']['locale']).to eq(['Locale must be filled'])
        end
      end

      context 'for invalid request' do
        it 'returns error', :aggregate_failures do
          patch :update, params: { user: { locale: 'it' }, charkeeper_access_token: access_token }

          expect(response).to have_http_status :unprocessable_content
          expect(response.parsed_body['errors']['locale']).to eq(['Invalid locale value'])
        end
      end
    end
  end

  describe 'DELETE#destroy' do
    before { allow(UsersContext::RemoveProfileJob).to receive(:perform_later) }

    context 'for logged users' do
      it 'calls job for removing user', :aggregate_failures do
        delete :destroy, params: { charkeeper_access_token: access_token }

        expect(response).to have_http_status :ok
        expect(UsersContext::RemoveProfileJob).to have_received(:perform_later).with(user_id: user.id)
      end
    end
  end
end
