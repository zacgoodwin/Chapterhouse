# frozen_string_literal: true

describe DummyBuilder do
  subject(:instance) { described_class.new }

  it 'returns the sheet untouched' do
    result = { main_class: 'bard' }

    expect(instance.call(result: result)).to eq(main_class: 'bard')
  end

  it 'swallows equip calls with any arguments' do
    expect(instance.equip(:weapon, count: 2)).to be_nil
  end
end
