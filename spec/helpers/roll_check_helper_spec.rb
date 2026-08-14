# frozen_string_literal: true

describe RollCheckHelper do
  subject(:message) { helper.dnd_roll_result_message(result) }

  context 'with a critical success' do
    let(:result) { { status: :crit_success, total: 30 } }

    it 'reports the crit instead of the total' do
      expect(message).to eq(I18n.t('services.bot_context.representers.check.dnd.crit_success'))
    end
  end

  context 'with a critical failure' do
    let(:result) { { status: :crit_failure, total: 3 } }

    it 'reports the crit instead of the total' do
      expect(message).to eq(I18n.t('services.bot_context.representers.check.dnd.crit_failure'))
    end
  end

  context 'with a regular roll' do
    let(:result) { { status: :success, total: 17 } }

    it 'interpolates the total', :aggregate_failures do
      expect(message).to eq(I18n.t('services.bot_context.representers.check.dnd.success', result: 17))
      expect(message).to include('17')
    end
  end

  context 'with an unknown status' do
    let(:result) { { status: :whatever, total: 8 } }

    it 'falls back to the total message' do
      expect(message).to eq(I18n.t('services.bot_context.representers.check.dnd.success', result: 8))
    end
  end
end
