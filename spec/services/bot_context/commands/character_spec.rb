# frozen_string_literal: true

describe BotContext::Commands::Character do
  subject(:service_call) do
    I18n.with_locale(:en) do
      described_class.new.call(arguments: arguments, data: { user: user })
    end
  end

  let(:arguments) { [] }
  let(:user) { create :user }

  context 'when user is nil' do
    let(:user) { nil }

    it 'returns nil' do
      expect(service_call).to be_nil
    end
  end

  context 'when arguments is not match' do
    it 'returns nil' do
      expect(service_call).to be_nil
    end
  end

  context 'for list command' do
    let(:arguments) { %w[list] }

    it 'returns empty list' do
      expect(service_call[:result]).to be_blank
    end

    context 'with existing character' do
      before { create :character, :daggerheart, user: user }

      it 'returns list' do
        expect(service_call[:result]).not_to be_blank
      end
    end
  end

  context 'for removed provider-only joinCampaign command' do
    let!(:character) { create :character, :daggerheart, user: user, name: 'Characterio' }
    let(:arguments) { ['joinCampaign', character.name] }

    it 'returns nil' do
      expect(service_call).to be_nil
    end
  end
end
