# frozen_string_literal: true

FactoryBot.define do
  factory :user_identity, class: 'User::Identity' do
    provider { User::Identity::GOOGLE }
    sequence(:uid) { |i| i }
    username { 'login' }
    user
  end
end
