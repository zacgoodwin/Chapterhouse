# frozen_string_literal: true

describe AuthContext::AddUserCommand do
  subject(:command_call) { instance.call({ id: id, username: username }) }

  let(:instance) { described_class.new }
  let(:id) { SecureRandom.uuid }
  let(:username) { 'username' }

  it 'creates user with the supabase auth id', :aggregate_failures do
    expect { command_call }.to change(User, :count).by(1)
    expect(User::Book.count).to be_zero
    expect(command_call[:result].is_a?(User)).to be_truthy
    expect(command_call[:result].id).to eq id
  end

  context 'with homebrew books' do
    before { create :homebrew_book, shared: true }

    it 'creates user and attaches book', :aggregate_failures do
      expect { command_call }.to(
        change(User, :count).by(1)
          .and(change(User::Book, :count).by(1))
      )
      expect(command_call[:result].is_a?(User)).to be_truthy
    end
  end

  context 'for duplicate username' do
    before { create :user, username: username }

    it 'returns errors and creates no user', :aggregate_failures do
      expect { command_call }.not_to change(User, :count)
      expect(command_call[:errors]).to be_present
    end
  end

  context 'for missing id' do
    subject(:command_call) { instance.call({ username: username }) }

    it 'returns errors' do
      expect(command_call[:errors]).to be_present
    end
  end
end
