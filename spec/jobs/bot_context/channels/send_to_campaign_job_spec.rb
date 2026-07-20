# frozen_string_literal: true

describe BotContext::Channels::SendToCampaignJob do
  subject(:job_call) { described_class.perform_now(campaign_id, text) }

  let(:campaign_id) { SecureRandom.uuid }
  let(:text) { "roll result\n2d20" }
  let(:client) { Charkeeper::Container.resolve('api.supabase.client') }

  before { allow(client).to receive(:broadcast) }

  it 'broadcasts the message to the campaign topic' do
    job_call

    expect(client).to have_received(:broadcast).with(
      topic: "campaign:#{campaign_id}",
      event: 'message',
      payload: { message: text }
    )
  end
end
