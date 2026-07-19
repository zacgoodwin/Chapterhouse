# frozen_string_literal: true

describe User::Identity do
  it 'factory should be valid' do
    user_identity = build :user_identity

    expect(user_identity).to be_valid
  end

  # guards against silent enum renumbering after provider removals
  it 'keeps provider enum mapping' do
    expect(described_class.providers).to eq('google' => 1, 'discord' => 2, 'yandex' => 3)
  end
end
