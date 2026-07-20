# frozen_string_literal: true

describe Channel do
  it 'factory should be valid' do
    channel = build :channel

    expect(channel).to be_valid
  end

  # guards against silent enum renumbering after provider removals
  it 'keeps provider enum mapping' do
    expect(described_class.providers).to eq('owlbear' => 1)
  end
end
