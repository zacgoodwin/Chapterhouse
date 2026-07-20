# frozen_string_literal: true

FactoryBot.define do
  factory :channel do
    provider { 'owlbear' }
    external_id { '1234567890' }
  end
end
