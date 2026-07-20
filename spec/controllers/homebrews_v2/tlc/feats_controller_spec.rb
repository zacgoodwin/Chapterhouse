# frozen_string_literal: true

# Ticket #33 (E2) acceptance test 4: another user browsing homebrew feats sees
# only their own rows plus publicly shared ones — standard homebrew visibility
# scoping (user_id + public union), identical to the dnd2024 feats browse.
describe HomebrewsV2::Tlc::FeatsController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  let!(:own_feat) { create :feat, :tlc, origin: 'feat', user: user }
  let!(:public_feat) { create :feat, :tlc, origin: 'feat', public: true }
  let!(:other_private_feat) { create :feat, :tlc, origin: 'feat' }

  describe 'GET#index' do
    let(:request) { get :index, params: { charkeeper_access_token: access_token } }

    it 'returns only own + public feats', :aggregate_failures do
      request

      expect(response).to have_http_status :ok
      expect(response.parsed_body['homebrews'].size).to eq 2
      expect(response.parsed_body.dig('homebrews', 0).keys).to(
        contain_exactly('id', 'title', 'own', 'books', 'upvoted', 'upvotes_count')
      )
    end
  end

  describe 'GET#show' do
    let(:request) { get :show, params: { id: own_feat.id, charkeeper_access_token: access_token } }

    it 'returns data', :aggregate_failures do
      request

      expect(response).to have_http_status :ok
      expect(response.parsed_body['homebrew'].keys).to(
        contain_exactly(
          'id', 'title', 'description', 'own', 'books', 'upvoted', 'upvotes_count', 'conditions', 'info', 'modifiers'
        )
      )
    end
  end

  describe 'POST#batch_destroy' do
    let(:request) {
      post :batch_destroy, params: {
        ids: [own_feat.id, public_feat.id, other_private_feat.id],
        charkeeper_access_token: access_token
      }
    }

    it 'destroys only the callers own feats', :aggregate_failures do
      expect { request }.to change(Tlc::Feat, :count).by(-1)
      expect(response).to have_http_status :ok
    end
  end
end
