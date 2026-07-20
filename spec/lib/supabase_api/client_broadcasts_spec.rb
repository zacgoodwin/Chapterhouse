# frozen_string_literal: true

describe SupabaseApi::Client do
  subject(:client) { described_class.new(url: 'https://test-project.supabase.local') }

  # stubbing the transport keeps the spec offline; the request shape is the contract
  before { allow(client).to receive(:post) } # rubocop: disable RSpec/SubjectStub

  it 'posts broadcast message with topic, event and payload', :aggregate_failures do
    client.broadcast(topic: 'campaign:abc', event: 'message', payload: { message: 'text' })

    expect(client).to have_received(:post).with( # rubocop: disable RSpec/SubjectStub
      path: 'realtime/v1/api/broadcast',
      body: { messages: [{ topic: 'campaign:abc', event: 'message', payload: { message: 'text' } }] },
      headers: hash_including('apikey', 'Authorization')
    )
  end
end
