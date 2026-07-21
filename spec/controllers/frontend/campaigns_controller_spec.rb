# frozen_string_literal: true

describe Frontend::CampaignsController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }

  describe 'GET#index' do
    context 'for logged users' do
      let!(:campaign1) { create :campaign, :dnd5, user: user }
      let!(:campaign2) { create :campaign, :dnd2024 }
      let!(:character) { create :character, :dnd2024, user: user }

      before do
        create :campaign, :dnd2024

        create :campaign_character, campaign: campaign2, character: character
      end

      it 'returns data', :aggregate_failures do
        get :index, params: { charkeeper_access_token: access_token }

        response_values = response.parsed_body.dig('campaigns', 0)

        expect(response).to have_http_status :ok
        expect(response.parsed_body['campaigns'].size).to eq 2
        expect(response_values.keys).to contain_exactly('id', 'name', 'provider', 'own')
        expect(response.parsed_body['campaigns'].pluck('id')).to contain_exactly(campaign1.id, campaign2.id)
      end
    end
  end

  describe 'GET#show' do
    context 'for logged users' do
      let!(:campaign) { create :campaign, :dnd2024 }

      context 'for unexisting campaign' do
        it 'returns error' do
          get :show, params: { id: 'unexisting', charkeeper_access_token: access_token }

          expect(response).to have_http_status :not_found
        end
      end

      context 'for existing campaign' do
        it 'renders campaign' do
          get :show, params: { id: campaign.id, charkeeper_access_token: access_token }

          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe 'POST#create' do
    context 'for logged users' do
      let(:request) {
        post :create, params: { campaign: { name: name, provider: 'dnd2024' }, charkeeper_access_token: access_token }
      }

      context 'for invalid params' do
        let(:name) { '' }

        it 'does not create campaign', :aggregate_failures do
          expect { request }.not_to change(Campaign, :count)
          expect(response).to have_http_status :unprocessable_content
        end
      end

      context 'for valid params' do
        let(:name) { 'Homunculus fight' }

        it 'creates campaign', :aggregate_failures do
          expect { request }.to change(user.campaigns, :count).by(1)
          expect(response).to have_http_status :created
        end
      end

      # Provider enum: 'tlc' is accepted, anything outside the enum is not.
      context 'for tlc provider' do
        let(:request) {
          post :create, params: {
            campaign: { name: 'Leyfarers', provider: 'tlc' }, charkeeper_access_token: access_token
          }
        }

        it 'creates campaign', :aggregate_failures do
          expect { request }.to change(user.campaigns, :count).by(1)
          expect(response).to have_http_status :created
          expect(Campaign.last.provider).to eq 'tlc'
        end
      end

      context 'for an unsupported provider' do
        let(:request) {
          post :create, params: {
            campaign: { name: 'Leyfarers', provider: 'daggerheart' }, charkeeper_access_token: access_token
          }
        }

        it 'does not create campaign', :aggregate_failures do
          expect { request }.not_to change(Campaign, :count)
          expect(response).to have_http_status :unprocessable_content
        end
      end
    end
  end

  describe 'DELETE#destroy' do
    context 'for logged users' do
      let!(:campaign) { create :campaign, :dnd2024 }

      context 'for unexisting campaign' do
        it 'returns error' do
          delete :destroy, params: { id: 'unexisting', charkeeper_access_token: access_token }

          expect(response).to have_http_status :not_found
        end
      end

      context 'for not user campaign' do
        let!(:character) { create :character, :dnd2024, user: user }

        before { create :campaign_character, campaign: campaign, character: character }

        it 'returns error' do
          delete :destroy, params: { id: campaign.id, charkeeper_access_token: access_token }

          expect(response).to have_http_status :forbidden
        end
      end

      context 'for user campaign' do
        let(:request) { delete :destroy, params: { id: campaign.id, charkeeper_access_token: access_token } }

        before { campaign.update!(user: user) }

        it 'deletes campaign', :aggregate_failures do
          expect { request }.to change(Campaign, :count).by(-1)
          expect(response).to have_http_status :ok
          expect(response.parsed_body).to eq({ 'result' => 'ok' })
        end
      end
    end
  end
end
