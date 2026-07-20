# frozen_string_literal: true

FactoryBot.define do
  factory :tlc_homebrews_subclass, class: 'Homebrew' do
    user
    info {
      { 'class_id' => 'rogue', 'resources' => [] }
    }
    type { 'Tlc::Homebrews::Subclass' }
    title { { 'en' => 'Subclass' } }
    description { { 'en' => 'A homebrew TLC subclass.' } }
  end
end
