# frozen_string_literal: true

describe Web::Users::OmniauthCallbacksController do
  let(:configuration) { Authkeeper::Configuration.new }

  before do
    allow(Authkeeper).to receive_messages(configuration: configuration)

    configuration.omniauth_providers = %w[google]
    configuration.access_token_name = :charkeeper_access_token
  end

  describe 'POST#create' do
    let(:code) { nil }
    let(:request) { post :create, params: { provider: provider, code: code } }

    context 'for unexisting provider' do
      let(:provider) { 'unknown' }

      it 'redirects to root path', :aggregate_failures do
        expect { request }.not_to change(User, :count)
        expect(response).to redirect_to root_path
      end
    end

    context 'for google' do
      let(:provider) { 'google' }

      context 'for blank code' do
        it 'redirects to login path', :aggregate_failures do
          expect { request }.not_to change(User, :count)
          expect(response).to redirect_to root_path
        end
      end

      context 'for present code' do
        let(:code) { 'code' }

        before do
          allow(Authkeeper::Container.resolve('services.providers.google')).to(
            receive(:call).and_return(google_auth_result)
          )
        end

        context 'for invalid code' do
          let(:google_auth_result) { { result: nil } }

          it 'redirects to login path', :aggregate_failures do
            expect { request }.not_to change(User, :count)
            expect(response).to redirect_to root_path
          end
        end

        context 'for valid code' do
          let(:google_auth_result) { { result: auth_payload } }

          context 'for not logged user' do
            let(:auth_payload) do
              {
                uid: '123',
                provider: 'google',
                login: 'octocat'
              }
            end

            it 'redirects to dashboard_path', :aggregate_failures do
              expect { request }.to change(User, :count)
              expect(response).to redirect_to dashboard_path
            end

            context 'for disabled russian provider' do
              before { allow(Rails.env).to receive(:ru_production?).and_return(true) }

              it 'redirects to login path', :aggregate_failures do
                expect { request }.not_to change(User, :count)
                expect(response).to redirect_to root_path
              end

              context 'when user exists' do
                let!(:user) { create :user }

                before { create :user_identity, user: user, uid: '123' }

                it 'redirects to dashboard_path', :aggregate_failures do
                  expect { request }.not_to change(User, :count)
                  expect(response).to redirect_to dashboard_path
                  expect(user.reload.russian_login).to be_truthy
                end

                context 'when user logged before' do
                  before { user.update!(russian_login: true) }

                  it 'redirects to login path', :aggregate_failures do
                    expect { request }.not_to change(User, :count)
                    expect(response).to redirect_to root_path
                  end
                end
              end
            end
          end

          context 'for logged user' do
            sign_in_user

            context 'for valid payload' do
              let(:auth_payload) do
                {
                  uid: '123',
                  provider: 'google',
                  login: 'octocat'
                }
              end

              it 'redirects to dashboard_path', :aggregate_failures do
                expect { request }.to change(User::Identity, :count).by(1)
                expect(response).to redirect_to dashboard_path
              end

              context 'when identity belongs to another user' do
                let!(:identity) { create :user_identity, uid: '123' }

                it 'redirects to dashboard_path', :aggregate_failures do
                  expect { request }.not_to change(User::Identity, :count)
                  expect(identity.reload.user).to eq @current_user
                  expect(response).to redirect_to dashboard_path
                end
              end
            end
          end
        end
      end
    end
  end
end
