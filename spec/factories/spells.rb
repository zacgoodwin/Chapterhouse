# frozen_string_literal: true

FactoryBot.define do
  factory :spell do
    type { 'Dnd5::Spell' }
    sequence(:slug) { |i| "magic_missile-#{i}" }
    name { { en: 'Magic Missile' } }
    data {
      {
        level: 1,
        attacking: true
      }
    }

    trait :dnd2024 do
      type { 'Dnd2024::Spell' }
    end

    trait :tlc do
      initialize_with { Tlc::Spell.new }
      type { 'Tlc::Spell' }
      sequence(:slug) { |i| "tlc-spell-#{i}" }
      name { { en: 'Leyward' } }
    end
  end
end
