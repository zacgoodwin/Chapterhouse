# frozen_string_literal: true

describe Frontend::Users::FeedbacksController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  describe 'POST#create' do
    context 'for logged users' do
      context 'for invalid params' do
        let(:request) do
          post :create, params: { feedback: { value: '' }, charkeeper_access_token: access_token }
        end

        it 'does not create feedback', :aggregate_failures do
          expect { request }.not_to change(User::Feedback, :count)
          expect(response).to have_http_status :unprocessable_content
        end
      end

      context 'for valid params' do
        let(:request) do
          post :create, params: { feedback: { value: 'feedback' }, charkeeper_access_token: access_token }
        end

        it 'creates feedback', :aggregate_failures do
          expect { request }.to change(user.feedbacks, :count).by(1)
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
