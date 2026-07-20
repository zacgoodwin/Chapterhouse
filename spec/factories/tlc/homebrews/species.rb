# frozen_string_literal: true

FactoryBot.define do
  factory :tlc_homebrews_species, class: 'Homebrew' do
    user
    info {
      { 'optional_pool_size' => 3, 'size' => %w[small medium] }
    }
    type { 'Tlc::Homebrews::Species' }
    title { { 'en' => 'Species' } }
    description { { 'en' => 'A homebrew TLC species.' } }
  end
end
