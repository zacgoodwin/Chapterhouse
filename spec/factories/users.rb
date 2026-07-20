# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |i| "user-#{i}" }
    locale { 'ru' }
  end
end
