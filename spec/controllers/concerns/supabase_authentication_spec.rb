# frozen_string_literal: true

describe SupabaseAuthentication, type: :controller do
  controller(Frontend::BaseController) do
    def index
      render json: { user_id: current_user.id }, status: :ok
    end
  end

  let!(:user) { create :user }

  def auth_header(token)
    @request.headers['Authorization'] = "Bearer #{token}"
  end

  context 'with valid bearer token' do
    it 'authenticates the matching user', :aggregate_failures do
      auth_header(supabase_token_for(user))
      get :index

      expect(response).to have_http_status :ok
      expect(response.parsed_body['user_id']).to eq user.id
    end
  end

  context 'with token in params' do
    it 'authenticates' do
      get :index, params: { charkeeper_access_token: supabase_token_for(user) }

      expect(response).to have_http_status :ok
    end
  end

  context 'without token' do
    it 'renders 401' do
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with garbage token' do
    it 'renders 401' do
      auth_header('garbage')
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with expired token' do
    it 'renders 401' do
      auth_header(supabase_token_for(user, exp: 1.hour.ago.to_i))
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with wrong audience' do
    it 'renders 401' do
      auth_header(supabase_token_for(user, aud: 'anon'))
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with wrong issuer' do
    it 'renders 401' do
      auth_header(supabase_token_for(user, iss: 'https://evil.example.com/auth/v1'))
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with token signed by a foreign key' do
    it 'renders 401' do
      auth_header(supabase_token_for(user, key: OpenSSL::PKey::EC.generate('prime256v1')))
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with non-uuid sub' do
    it 'renders 401' do
      auth_header(supabase_token_for(user, sub: 'not-a-uuid'))
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'with discarded user' do
    it 'renders 401' do
      user.update!(discarded_at: Time.current)
      auth_header(supabase_token_for(user))
      get :index

      expect(response).to have_http_status :unauthorized
    end
  end

  describe 'first-request provisioning' do
    let(:auth_id) { SecureRandom.uuid }

    before { create :homebrew_book, shared: true }

    it 'creates the app user keyed by the auth id with shared books', :aggregate_failures do
      auth_header(supabase_token_for(user, sub: auth_id, user_metadata: { name: 'newcomer' }))

      expect { get :index }.to change(User, :count).by(1)

      created = User.find(auth_id)
      expect(created.username).to eq 'newcomer'
      expect(created.user_books.count).to eq 1
      expect(response.parsed_body['user_id']).to eq auth_id
    end

    it 'does not duplicate on a second request', :aggregate_failures do
      token = supabase_token_for(user, sub: auth_id, user_metadata: { name: 'newcomer' })
      auth_header(token)
      get :index

      expect { get :index }.not_to change(User, :count)
      expect(response).to have_http_status :ok
    end

    it 'falls back to a suffixed username on collision', :aggregate_failures do
      auth_header(supabase_token_for(user, sub: auth_id, user_metadata: { name: user.username }))
      get :index

      expect(response).to have_http_status :ok
      expect(User.find(auth_id).username).to eq "#{user.username}_#{auth_id.first(8)}"
    end

    it 'derives username from email when metadata has no name', :aggregate_failures do
      auth_header(supabase_token_for(user, sub: auth_id, user_metadata: {}, email: 'solo@example.com'))
      get :index

      expect(response).to have_http_status :ok
      expect(User.find(auth_id).username).to eq 'solo'
    end
  end
end
