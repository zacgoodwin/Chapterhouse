# frozen_string_literal: true

describe Frontend::Campaigns::JoinsController do
  let!(:user) { create :user }
  let(:access_token) { supabase_token_for(user) }
  let!(:campaign) { create :campaign, :dnd2024 }

  describe 'GET#show' do
    context 'for logged users' do
      context 'for unexisting campaign' do
        it 'returns error' do
          get :show, params: { campaign_id: 'unexisting', charkeeper_access_token: access_token }

          expect(response).to have_http_status :not_found
        end
      end

      context 'for not user campaign' do
        it 'returns error' do
          get :show, params: { campaign_id: campaign.id, charkeeper_access_token: access_token }

          expect(response).to have_http_status :ok
        end
      end

      context 'for user campaign' do
        before { campaign.update!(user: user) }

        it 'renders campaign' do
          get :show, params: { campaign_id: campaign.id, charkeeper_access_token: access_token }

          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe 'POST#create' do
    let!(:dnd2024_character) { create :character, :dnd2024 }
    let!(:character) { create :character }

    context 'for logged users' do
      context 'for unexisting campaign' do
        let(:request) {
          post :create, params: {
            campaign_id: 'unexisting', character_id: dnd2024_character.id, charkeeper_access_token: access_token
          }
        }

        it 'returns error', :aggregate_failures do
          expect { request }.not_to change(campaign.campaign_characters, :count)
          expect(response).to have_http_status :not_found
        end
      end

      context 'for unexisting character' do
        let(:request) {
          post :create, params: {
            campaign_id: campaign.id, character_id: 'unexisting', charkeeper_access_token: access_token
          }
        }

        it 'returns error', :aggregate_failures do
          expect { request }.not_to change(campaign.campaign_characters, :count)
          expect(response).to have_http_status :not_found
        end
      end

      context 'for invalid character' do
        let(:request) {
          post :create, params: {
            campaign_id: campaign.id, character_id: character.id, charkeeper_access_token: access_token
          }
        }

        before { character.update!(user: user) }

        it 'returns error', :aggregate_failures do
          expect { request }.not_to change(campaign.campaign_characters, :count)
          expect(response).to have_http_status :not_found
        end
      end

      context 'for not user character' do
        let(:request) {
          post :create, params: {
            campaign_id: campaign.id, character_id: dnd2024_character.id, charkeeper_access_token: access_token
          }
        }

        it 'returns error', :aggregate_failures do
          expect { request }.not_to change(campaign.campaign_characters, :count)
          expect(response).to have_http_status :not_found
        end
      end

      context 'for valid character' do
        let(:request) {
          post :create, params: {
            campaign_id: campaign.id, character_id: dnd2024_character.id, charkeeper_access_token: access_token
          }
        }

        before { dnd2024_character.update!(user: user) }

        it 'creates campaign character', :aggregate_failures do
          expect { request }.to change(campaign.campaign_characters, :count).by(1)
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe 'DELETE#destroy' do
    context 'for logged users' do
      let!(:campaign_character) { create :campaign_character, campaign: campaign }

      context 'for unexisting campaign' do
        it 'returns error' do
          delete :destroy, params: {
            campaign_id: 'unexisting', character_id: campaign_character.id, charkeeper_access_token: access_token
          }

          expect(response).to have_http_status :not_found
        end
      end

      context 'for not user campaign' do
        it 'returns error' do
          delete :destroy, params: {
            campaign_id: campaign.id, character_id: campaign_character.id, charkeeper_access_token: access_token
          }

          expect(response).to have_http_status :forbidden
        end
      end

      context 'for user campaign' do
        let(:request) do
          delete :destroy, params: {
            campaign_id: campaign.id, character_id: campaign_character.id, charkeeper_access_token: access_token
          }
        end

        before { campaign.update!(user: user) }

        it 'deletes campaign character', :aggregate_failures do
          expect { request }.to change(Campaign::Character, :count).by(-1)
          expect(response).to have_http_status :ok
          expect(response.parsed_body).to eq({ 'result' => 'ok' })
        end
      end
    end
  end
end
