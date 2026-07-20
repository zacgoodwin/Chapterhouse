# frozen_string_literal: true

FactoryBot.define do
  factory :homebrew do
    user
    info { {} }
    type { 'Dnd2024::Homebrews::Race' }

    trait :dnd2024_race do
      type { 'Dnd2024::Homebrews::Race' }
      title { { 'en' => 'Title' } }
      description { { 'en' => 'Description' } }
    end

    trait :dnd2024_background do
      type { 'Dnd2024::Homebrews::Background' }
      title { { 'en' => 'Title' } }
      description { { 'en' => 'Description' } }
    end

    trait :dnd2024_subclass do
      type { 'Dnd2024::Homebrews::Subclass' }
      title { { 'en' => 'Title' } }
      description { { 'en' => 'Description' } }
      info { { 'class_id' => '1' } }
    end
  end
end
