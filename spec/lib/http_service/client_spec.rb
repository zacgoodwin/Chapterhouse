# frozen_string_literal: true

describe HttpService::Client do
  subject(:client) { described_class.new(url: 'https://api.test.local', connection: connection) }

  let(:requests) { [] }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) do
    Faraday.new('https://api.test.local') do |conn|
      conn.response :json, content_type: /\bjson$/
      conn.adapter :test, stubs
    end
  end

  def record(env)
    requests << { params: env.params, headers: env.request_headers, body: env.body }
  end

  describe '#get' do
    it 'passes params and headers through and reports success with the parsed body', :aggregate_failures do
      stubs.get('/items') do |env|
        record(env)
        [200, { 'Content-Type' => 'application/json' }, '{"items":[1]}']
      end

      result = client.get(path: '/items', params: { page: '2' }, headers: { 'apikey' => 'secret' })

      expect(result).to eq(success: true, body: { 'items' => [1] })
      expect(requests.first).to include(params: { 'page' => '2' })
      expect(requests.first[:headers]).to include('apikey' => 'secret')
    end

    it 'reports failure instead of raising on an error response' do
      stubs.get('/items') { [500, {}, 'boom'] }

      expect(client.get(path: '/items')).to eq(success: false, body: 'boom')
    end
  end

  describe '#post' do
    it 'sends a json body with params and headers', :aggregate_failures do
      stubs.post('/items') do |env|
        record(env)
        [201, { 'Content-Type' => 'application/json' }, '{"id":1}']
      end

      result = client.post(path: '/items', body: { name: 'sword' }, params: { dry: 'true' },
                           headers: { 'Authorization' => 'Bearer token' })

      expect(result).to eq('id' => 1)
      expect(requests.first[:body]).to eq('{"name":"sword"}')
      expect(requests.first[:params]).to eq('dry' => 'true')
      expect(requests.first[:headers]).to include('Authorization' => 'Bearer token')
    end

    it 'returns nil when the response is not successful' do
      stubs.post('/items') { [422, {}, 'invalid'] }

      expect(client.post(path: '/items', body: { name: '' })).to be_nil
    end
  end

  describe '#form_post' do
    it 'sends a form encoded body', :aggregate_failures do
      stubs.post('/oauth/token') do |env|
        record(env)
        [200, { 'Content-Type' => 'application/json' }, '{"access_token":"abc"}']
      end

      result = client.form_post(path: '/oauth/token', body: { grant_type: 'refresh_token', token: 'a b' },
                                params: { redirect: 'false' }, headers: { 'apikey' => 'secret' })

      expect(result).to eq('access_token' => 'abc')
      expect(requests.first[:body]).to eq('grant_type=refresh_token&token=a+b')
      expect(requests.first[:params]).to eq('redirect' => 'false')
      expect(requests.first[:headers]).to include('apikey' => 'secret')
    end

    it 'returns nil when the response is not successful' do
      stubs.post('/oauth/token') { [401, {}, 'nope'] }

      expect(client.form_post(path: '/oauth/token', body: {})).to be_nil
    end
  end

  describe '#delete' do
    it 'passes params and headers through and reports success', :aggregate_failures do
      stubs.delete('/items/1') do |env|
        record(env)
        [200, { 'Content-Type' => 'application/json' }, '{"deleted":true}']
      end

      result = client.delete(path: '/items/1', params: { force: 'true' }, headers: { 'apikey' => 'secret' })

      expect(result).to eq(success: true, body: { 'deleted' => true })
      expect(requests.first).to include(params: { 'force' => 'true' })
    end
  end

  # The guard exists so a forgotten stub fails loudly instead of hitting the network.
  describe 'unstubbed requests in the test environment' do
    subject(:client) { described_class.new(url: 'https://api.test.local') }

    it 'raises for every verb', :aggregate_failures do
      expect { client.get(path: '/items') }.to raise_error(StandardError, 'please stub request in test env')
      expect { client.post(path: '/items') }.to raise_error(StandardError, 'please stub request in test env')
      expect { client.form_post(path: '/items') }.to raise_error(StandardError, 'please stub request in test env')
      expect { client.delete(path: '/items/1') }.to raise_error(StandardError, 'please stub request in test env')
    end
  end
end
