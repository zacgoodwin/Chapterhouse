# frozen_string_literal: true

describe BotContext::Commands::Campaign do
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

  context 'for create command' do
    let(:arguments) { %w[create --system dnd5 --name TheEnd] }

    it 'creates campaign without channel', :aggregate_failures do
      expect { service_call }.to change(Campaign, :count).by(1)
      expect(Channel.count).to eq 0
    end
  end

  context 'for list command' do
    let(:arguments) { %w[list] }

    it 'returns empty list' do
      expect(service_call[:result]).to be_blank
    end

    context 'with existing campaign' do
      before { create :campaign, :daggerheart, user: user }

      it 'returns list' do
        expect(service_call[:result]).not_to be_blank
      end
    end
  end

  context 'for remove command' do
    let(:arguments) { %w[remove TheEnd] }

    it 'does not remove campaign' do
      expect { service_call }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'with existing campaign' do
      before { create :campaign, :daggerheart, user: user, name: 'TheEnd' }

      it 'removes campaign' do
        expect { service_call }.to change(Campaign, :count).by(-1)
      end
    end
  end

  context 'for removed provider-only commands' do
    %w[show set].each do |command|
      context "for #{command} command" do
        let(:arguments) { [command, 'TheEnd'] }

        it 'returns nil' do
          expect(service_call).to be_nil
        end
      end
    end
  end
end
