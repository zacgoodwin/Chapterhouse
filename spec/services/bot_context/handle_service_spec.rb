# frozen_string_literal: true

describe BotContext::HandleService do
  subject(:service_call) do
    I18n.with_locale(:en) do
      described_class.new.call(source: source, message: text, data: {
        user: user,
        character: command_character
      })
    end
  end

  let!(:user) { create :user }
  let(:command_character) { nil }
  let(:text) { '/roll d20' }

  context 'for web request' do
    let(:source) { :web }

    it 'sends response message' do
      expect(service_call[:result].include?('Rolls: d20')).to be_truthy
    end

    context 'for digital request' do
      let(:text) { '/roll 20' }

      it 'sends response message' do
        expect(service_call[:result].include?('Rolls: 20')).to be_truthy
      end
    end

    context 'for unexisting command' do
      let(:text) { '/rolld d20' }

      it 'sends error' do
        expect(service_call[:errors].include?('Invalid command')).to be_truthy
      end
    end

    context 'for argument error' do
      let(:text) { '/module create d20' }

      it 'sends error' do
        expect(service_call[:errors].include?('Invalid command')).to be_truthy
      end
    end
  end

  context 'for raw request' do
    let(:source) { :raw }
    let!(:campaign) { create :campaign, :dnd5 }
    let!(:character) { create :character }
    let(:command_character) { Dnd5::Character.find_by(id: character&.id) }
    let(:text) { '/check attr str' }

    before do
      create :campaign_character, campaign: campaign, character: character
      create :channel, external_id: '1', campaign: campaign
    end

    it 'returns command result' do
      expect(service_call[:errors]).to be_nil
    end
  end
end
