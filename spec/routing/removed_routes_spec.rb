# frozen_string_literal: true

# the '*path' catch-all makes every path routable, so removed routes must land there
describe 'Removed provider routes' do
  it 'routes the removed mini-app page to not found' do
    expect(get: '/web_telegram').to route_to(controller: 'application', action: 'not_found', path: 'web_telegram')
  end

  it 'routes the removed webhook to not found' do
    expect(post: '/webhooks/telegram').to route_to(controller: 'application', action: 'not_found', path: 'webhooks/telegram')
  end

  it 'routes the removed frontend auth endpoint to not found' do
    expect(post: '/frontend/auth').to route_to(controller: 'application', action: 'not_found', path: 'frontend/auth')
  end

  it 'still routes the discord webhook' do
    expect(post: '/webhooks/discord').to route_to(controller: 'webhooks/discords', action: 'create')
  end
end
