# frozen_string_literal: true

FactoryBot.define do
  factory :tlc_homebrews_feat, class: 'Homebrew' do
    user
    info {
      { 'repeatable' => false }
    }
    type { 'Tlc::Homebrews::Feat' }
    title { { 'en' => 'Feat' } }
    description { { 'en' => 'A homebrew TLC feat.' } }
  end
end
