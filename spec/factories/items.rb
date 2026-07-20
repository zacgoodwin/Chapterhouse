# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    type { 'Dnd5::Item' }
    slug { 'torch' }
    name { { en: 'Torch', ru: 'Факел' } }
    kind { 'item' }
    data {
      {
        weight: 1.0,
        price: 1
      }
    }

    trait :tlc do
      initialize_with { Tlc::Item.new }
      type { 'Tlc::Item' }
      sequence(:slug) { |i| "tlc-item-#{i}" }
      name { { en: 'Leyfarers Journal', ru: 'Leyfarers Journal' } }
      kind { 'gear' }
    end
  end
end
