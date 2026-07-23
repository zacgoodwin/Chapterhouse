# frozen_string_literal: true

FactoryBot.define do
  factory :character do
    type { 'Dnd5::Character' }
    sequence(:name) { |i| "Grundar #{i}" }
    data {
      {
        level: 4,
        race: 'human',
        alignment: Dnd5::Character::NEUTRAL,
        main_class: 'monk',
        classes: { monk: 4 },
        subclasses: { monk: nil },
        abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 },
        speed: 30,
        selected_skills: %w[history]
      }
    }
    user

    trait :bard do
      data {
        {
          level: 4,
          race: 'human',
          alignment: Dnd5::Character::NEUTRAL,
          main_class: 'bard',
          classes: { bard: 4 },
          subclasses: { bard: nil },
          abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 },
          speed: 30,
          selected_skills: %w[history]
        }
      }
    end

    trait :dnd2024 do
      type { 'Dnd2024::Character' }
      data {
        {
          level: 4,
          species: 'human',
          alignment: Dnd5::Character::NEUTRAL,
          main_class: 'bard',
          classes: { bard: 4 },
          subclasses: { bard: nil },
          abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 },
          speed: 30,
          selected_skills: { 'history' => 1 }
        }
      }
    end

    # Data omits the five TLC fields on purpose so their StoreModel defaults surface.
    trait :tlc do
      type { 'Tlc::Character' }
      data {
        {
          level: 4,
          species: 'human',
          alignment: Dnd5::Character::NEUTRAL,
          main_class: 'bard',
          classes: { bard: 4 },
          subclasses: { bard: nil },
          abilities: { str: 13, dex: 16, con: 14, int: 11, wis: 16, cha: 10 },
          speed: 30,
          selected_skills: { 'history' => 1 }
        }
      }
    end
  end
end
