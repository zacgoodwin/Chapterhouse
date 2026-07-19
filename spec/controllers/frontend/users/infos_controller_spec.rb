# frozen_string_literal: true

describe Frontend::Users::InfosController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  describe 'GET#show' do
    context 'for logged users' do
      let(:request) { get :show, params: { charkeeper_access_token: access_token } }

      it 'renders user info', :aggregate_failures do
        request

        expect(response).to have_http_status :ok
        expect(response.parsed_body).to eq({
          'locale' => user.locale,
          'username' => user.username,
          'admin' => user.admin?,
          'color_schema' => user.color_schema,
          'provider_locales' => {}
        })
      end
    end
  end
end
