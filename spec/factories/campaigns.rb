# frozen_string_literal: true

FactoryBot.define do
  factory :campaign do
    sequence(:name) { |i| "Campaign #{i}" }
    provider { 'dnd5' }
    user

    trait :dnd5 do
      provider { 'dnd5' }
    end

    trait :dnd2024 do
      provider { 'dnd2024' }
    end

    trait :tlc do
      provider { 'tlc' }
    end
  end
end
